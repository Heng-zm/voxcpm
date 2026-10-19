import Foundation
import Security

/// Thread-safe Keychain service for cryptographic tokens and biometric verification credentials.
public final class SecureStorageService: Sendable {
    public static let shared = SecureStorageService()
    
    private let serviceIdentifier = "com.clonevoice.keychain"
    
    public init() {}
    
    public func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecureStorageError.failedToSave(status)
        }
    }
    
    public func retrieve(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = item as? Data else {
            throw SecureStorageError.failedToRetrieve(status)
        }
        return data
    }
    
    public func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.failedToDelete(status)
        }
    }
}

public enum SecureStorageError: Error, LocalizedError, Sendable {
    case failedToSave(OSStatus)
    case failedToRetrieve(OSStatus)
    case failedToDelete(OSStatus)
    
    public var errorDescription: String? {
        switch self {
        case .failedToSave(let code):
            return "Failed to save secret to Keychain (OSStatus: \(code))."
        case .failedToRetrieve(let code):
            return "Failed to read secret from Keychain (OSStatus: \(code))."
        case .failedToDelete(let code):
            return "Failed to delete secret from Keychain (OSStatus: \(code))."
        }
    }
}
