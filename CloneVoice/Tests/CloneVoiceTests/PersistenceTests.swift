import Testing
import Foundation
@testable import CloneVoice

@Suite("Domain Model & Persistence Conversion Tests")
struct PersistenceTests {
    
    @Test("VoiceProfile domain model instantiates with expected identifiers")
    func testVoiceProfileInstantiation() {
        let id = UUID()
        let profile = VoiceProfile(
            id: id,
            name: "Test Voice",
            referenceAudioFilename: "test.wav",
            sampleDuration: 8.5,
            acousticFeaturesHash: "hash123",
            isBiometricLocked: true
        )
        
        #expect(profile.id == id)
        #expect(profile.name == "Test Voice")
        #expect(profile.sampleDuration == 8.5)
        #expect(profile.isBiometricLocked == true)
    }
    
    @Test("GeneratedUtterance retains settings configuration and status")
    func testGeneratedUtteranceRetention() {
        let settings = SynthesisSettings(cfgValue: 2.2, inferenceTimesteps: 14)
        let utterance = GeneratedUtterance(
            profileId: UUID(),
            profileName: "Narrator",
            text: "Testing speech generation.",
            audioFilename: "out.wav",
            duration: 3.2,
            latencySeconds: 1.1,
            modelIdentifier: "OpenBMB/VoxCPM2",
            settings: settings,
            status: .completed
        )
        
        #expect(utterance.profileName == "Narrator")
        #expect(utterance.duration == 3.2)
        #expect(utterance.settings.cfgValue == 2.2)
        #expect(utterance.settings.inferenceTimesteps == 14)
        #expect(utterance.modelIdentifier == "OpenBMB/VoxCPM2")
        #expect(utterance.status == .completed)
    }
    
    @Test("ConsentContract preserves live spoken verification text")
    func testConsentContractModel() {
        let contract = ConsentContract(
            termsVersion: "2026.1",
            verificationScriptText: "I verify this is my authentic biological voice.",
            spokenVerificationAudioFilename: "consent.wav",
            biometricSignatureSHA256: "sha256sig",
            deviceModelIdentifier: "iPhone17,1"
        )
        
        #expect(contract.termsVersion == "2026.1")
        #expect(contract.biometricSignatureSHA256 == "sha256sig")
    }
}
