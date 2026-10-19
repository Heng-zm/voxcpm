import Foundation
import SwiftData

@Model
public final class VoiceProfileEntity {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var createdAt: Date
    public var referenceAudioFilename: String
    public var sampleDuration: Double
    public var acousticFeaturesHash: String
    public var isBiometricLocked: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \ConsentContractEntity.profile)
    public var consentContract: ConsentContractEntity?
    
    @Relationship(deleteRule: .cascade, inverse: \GeneratedUtteranceEntity.profile)
    public var utterances: [GeneratedUtteranceEntity] = []
    
    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        referenceAudioFilename: String,
        sampleDuration: Double,
        acousticFeaturesHash: String,
        isBiometricLocked: Bool = true
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.referenceAudioFilename = referenceAudioFilename
        self.sampleDuration = sampleDuration
        self.acousticFeaturesHash = acousticFeaturesHash
        self.isBiometricLocked = isBiometricLocked
    }
    
    public func toDomain() -> VoiceProfile {
        VoiceProfile(
            id: id,
            name: name,
            createdAt: createdAt,
            referenceAudioFilename: referenceAudioFilename,
            sampleDuration: sampleDuration,
            acousticFeaturesHash: acousticFeaturesHash,
            isBiometricLocked: isBiometricLocked,
            consentContractId: consentContract?.id
        )
    }
}
