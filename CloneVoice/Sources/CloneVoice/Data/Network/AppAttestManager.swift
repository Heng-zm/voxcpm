import Foundation
import DeviceCheck
import CryptoKit

/// Manages hardware-backed Apple App Attest cryptographic verification.
public final class AppAttestManager: Sendable {
    public static let shared = AppAttestManager()
    
    private let keyIdentifierStorageKey = "com.clonevoice.appattest.keyId"
    
    public init() {}
    
    /// Returns true if App Attest is supported on the current hardware.
    public var isSupported: Bool {
        return DCAppAttestService.shared.isSupported
    }
    
    /// Generates or retrieves an existing hardware-backed attestation key ID.
    public func getOrCreateKeyId() async throws -> String {
        if let stored = try? SecureStorageService.shared.retrieve(key: keyIdentifierStorageKey),
           let keyId = String(data: stored, encoding: .utf8) {
            return keyId
        }
        
        guard isSupported else {
            // Development / Simulator fallback identifier
            return "simulated-attest-key-\(UUID().uuidString)"
        }
        
        let newKeyId = try await DCAppAttestService.shared.generateKey()
        if let data = newKeyId.data(using: .utf8) {
            try? SecureStorageService.shared.save(key: keyIdentifierStorageKey, data: data)
        }
        return newKeyId
    }
    
    /// Generates an assertion digest for client request payload integrity.
    public func generateAssertion(for clientData: Data) async throws -> String {
        let keyId = try await getOrCreateKeyId()
        let hash = Data(SHA256.hash(data: clientData))
        
        guard isSupported else {
            return "simulated-assertion-\(hash.base64EncodedString())"
        }
        
        let assertion = try await DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: hash)
        return assertion.base64EncodedString()
    }
}
