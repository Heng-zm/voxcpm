import Foundation

public enum GenerationStatus: String, Sendable, Codable, Equatable {
    case queued
    case generating
    case completed
    case failed
}

/// Represents a speech utterance synthesized by VoxCPM2 from an enrolled VoiceProfile.
public struct GeneratedUtterance: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public let profileId: UUID
    public let profileName: String
    public let text: String
    public let createdAt: Date
    public var audioFilename: String
    public var duration: TimeInterval
    public var c2paManifestDigest: Data?
    public var latencySeconds: Double
    public var modelIdentifier: String
    public var settings: SynthesisSettings
    public var status: GenerationStatus
    public var errorMessage: String?
    
    public init(
        id: UUID = UUID(),
        profileId: UUID,
        profileName: String,
        text: String,
        createdAt: Date = Date(),
        audioFilename: String,
        duration: TimeInterval,
        c2paManifestDigest: Data? = nil,
        latencySeconds: Double,
        modelIdentifier: String = "OpenBMB/VoxCPM2",
        settings: SynthesisSettings = .standard,
        status: GenerationStatus = .completed,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.profileId = profileId
        self.profileName = profileName
        self.text = text
        self.createdAt = createdAt
        self.audioFilename = audioFilename
        self.duration = duration
        self.c2paManifestDigest = c2paManifestDigest
        self.latencySeconds = latencySeconds
        self.modelIdentifier = modelIdentifier
        self.settings = settings
        self.status = status
        self.errorMessage = errorMessage
    }
}
