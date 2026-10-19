import Foundation

/// Represents a speech utterance synthesized by VoxCPM2 from a VoiceProfile.
public struct GeneratedUtterance: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public let profileId: UUID
    public let profileName: String
    public let text: String
    public let createdAt: Date
    public let audioFilename: String
    public let duration: TimeInterval
    public let c2paManifestDigest: Data?
    public let latencySeconds: Double
    public let settings: SynthesisSettings
    
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
        settings: SynthesisSettings
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
        self.settings = settings
    }
}
