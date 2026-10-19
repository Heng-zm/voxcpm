import Foundation

/// Represents an enrolled voice profile capable of synthesizing speech via VoxCPM2.
public struct VoiceProfile: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public var name: String
    public let createdAt: Date
    public var referenceAudioFilename: String
    public var sampleDuration: TimeInterval
    public var acousticFeaturesHash: String
    public var isBiometricLocked: Bool
    public var consentContractId: UUID?
    
    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        referenceAudioFilename: String,
        sampleDuration: TimeInterval,
        acousticFeaturesHash: String,
        isBiometricLocked: Bool = true,
        consentContractId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.referenceAudioFilename = referenceAudioFilename
        self.sampleDuration = sampleDuration
        self.acousticFeaturesHash = acousticFeaturesHash
        self.isBiometricLocked = isBiometricLocked
        self.consentContractId = consentContractId
    }
}
