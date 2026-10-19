import Foundation

/// Represents a verifiable cryptographic consent contract authorizing digital voice replication.
public struct ConsentContract: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let termsVersion: String
    public let verificationScriptText: String
    public let spokenVerificationAudioFilename: String
    public let biometricSignatureSHA256: String
    public let deviceModelIdentifier: String
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        termsVersion: String,
        verificationScriptText: String,
        spokenVerificationAudioFilename: String,
        biometricSignatureSHA256: String,
        deviceModelIdentifier: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.termsVersion = termsVersion
        self.verificationScriptText = verificationScriptText
        self.spokenVerificationAudioFilename = spokenVerificationAudioFilename
        self.biometricSignatureSHA256 = biometricSignatureSHA256
        self.deviceModelIdentifier = deviceModelIdentifier
    }
}
