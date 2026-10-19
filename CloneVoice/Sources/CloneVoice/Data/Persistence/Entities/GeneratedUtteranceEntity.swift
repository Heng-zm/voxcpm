import Foundation
import SwiftData

@Model
public final class GeneratedUtteranceEntity {
    @Attribute(.unique) public var id: UUID
    public var profileId: UUID
    public var profileName: String
    public var text: String
    public var createdAt: Date
    public var audioFilename: String
    public var duration: Double
    public var c2paManifestDigest: Data?
    public var latencySeconds: Double
    public var settingsJSON: String
    
    public var profile: VoiceProfileEntity?
    
    public init(
        id: UUID = UUID(),
        profileId: UUID,
        profileName: String,
        text: String,
        createdAt: Date = Date(),
        audioFilename: String,
        duration: Double,
        c2paManifestDigest: Data? = nil,
        latencySeconds: Double,
        settingsJSON: String
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
        self.settingsJSON = settingsJSON
    }
    
    public func toDomain() -> GeneratedUtterance {
        let decodedSettings: SynthesisSettings
        if let data = settingsJSON.data(using: .utf8),
           let settings = try? JSONDecoder().decode(SynthesisSettings.self, from: data) {
            decodedSettings = settings
        } else {
            decodedSettings = .standard
        }
        
        return GeneratedUtterance(
            id: id,
            profileId: profileId,
            profileName: profileName,
            text: text,
            createdAt: createdAt,
            audioFilename: audioFilename,
            duration: duration,
            c2paManifestDigest: c2paManifestDigest,
            latencySeconds: latencySeconds,
            settings: decodedSettings
        )
    }
}
