import Foundation
import SwiftData

@Model
public final class ConsentContractEntity {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var termsVersion: String
    public var verificationScriptText: String
    public var spokenVerificationAudioFilename: String
    public var biometricSignatureSHA256: String
    public var deviceModelIdentifier: String
    
    public var profile: VoiceProfileEntity?
    
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
    
    public func toDomain() -> ConsentContract {
        ConsentContract(
            id: id,
            timestamp: timestamp,
            termsVersion: termsVersion,
            verificationScriptText: verificationScriptText,
            spokenVerificationAudioFilename: spokenVerificationAudioFilename,
            biometricSignatureSHA256: biometricSignatureSHA256,
            deviceModelIdentifier: deviceModelIdentifier
        )
    }
}
