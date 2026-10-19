import Foundation

public enum BiometricAuthError: Error, LocalizedError, Sendable {
    case notAvailable
    case canceled
    case failed
    case securityEnclaveError(String)
    
    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication (Face ID / Touch ID) is not configured on this device."
        case .canceled:
            return "Authentication was canceled by the user."
        case .failed:
            return "Biometric verification failed."
        case .securityEnclaveError(let reason):
            return "Secure Enclave cryptographic operation failed: \(reason)"
        }
    }
}

public protocol BiometricAuthServiceProtocol: Sendable {
    /// Evaluates device owner biometric policy (Face ID / Touch ID).
    func authenticate(reason: String) async throws -> Bool
    
    /// Generates a hardware-backed SHA-256 cryptographic assertion for the consent contract.
    func generateConsentSignature(phrase: String, timestamp: Date) async throws -> String
    
    /// Checks whether biometrics can be evaluated on this hardware.
    func canEvaluateBiometrics() -> Bool
}
