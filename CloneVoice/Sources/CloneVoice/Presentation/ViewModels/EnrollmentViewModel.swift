import Foundation
import SwiftUI

public enum EnrollmentStep: Int, CaseIterable {
    case consentAgreement
    case liveRecording
    case biometricSign
    case completed
}

/// ViewModel coordinating the 3-tier consent and recording enrollment pipeline.
@MainActor
@Observable
public final class EnrollmentViewModel {
    public var currentStep: EnrollmentStep = .consentAgreement
    public var profileName: String = ""
    public var isRecording: Bool = false
    public var currentRMSLevel: Float = 0.0
    public var recordedDuration: TimeInterval = 0.0
    public var errorMessage: String?
    public var isProcessing: Bool = false
    
    // Randomized verification sentence preventing replay of unauthorized recordings
    public let verificationPhrase: String
    
    private let audioEngine: AudioEngineActor
    private let repository: any VoiceProfileRepositoryProtocol
    private let biometricAuth: BiometricAuthServiceProtocol
    private var recordedAudioURL: URL?
    
    public init(
        audioEngine: AudioEngineActor,
        repository: any VoiceProfileRepositoryProtocol,
        biometricAuth: BiometricAuthServiceProtocol
    ) {
        self.audioEngine = audioEngine
        self.repository = repository
        self.biometricAuth = biometricAuth
        
        let randomCode = Int.random(in: 1000...9999)
        self.verificationPhrase = "I verify on \(Date().formatted(date: .abbreviated, time: .omitted)) with verification code \(randomCode) that this voice is my own, and I authorize Clone Voice to construct a personalized digital replica for my exclusive use."
    }
    
    public func startLiveRecording() async {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("enrollment_\(UUID().uuidString).wav")
        self.recordedAudioURL = fileURL
        self.errorMessage = nil
        
        do {
            let stream = try await audioEngine.startRecording(to: fileURL)
            self.isRecording = true
            
            Task {
                for await level in stream {
                    await MainActor.run {
                        self.currentRMSLevel = level
                    }
                }
            }
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    public func stopLiveRecording() async {
        guard isRecording else { return }
        
        do {
            let duration = try await audioEngine.stopRecording()
            self.recordedDuration = duration
            self.isRecording = false
            self.currentRMSLevel = 0.0
            
            if duration < 5.0 {
                errorMessage = "Recording must be at least 5 seconds for accurate acoustic cloning."
            } else {
                currentStep = .biometricSign
            }
        } catch {
            errorMessage = "Failed to stop recording: \(error.localizedDescription)"
            self.isRecording = false
        }
    }
    
    public func completeEnrollment() async -> Bool {
        guard let audioURL = self.recordedAudioURL,
              !profileName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Profile name and valid audio sample are required."
            return false
        }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            // Tier 3: Biometric signature via Secure Enclave
            let timestamp = Date()
            let biometricSig = try await biometricAuth.generateConsentSignature(
                phrase: verificationPhrase,
                timestamp: timestamp
            )
            
            // Move audio to permanent documents directory
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let permanentFilename = "profile_\(UUID().uuidString).wav"
            let permanentURL = docs.appendingPathComponent(permanentFilename)
            try FileManager.default.moveItem(at: audioURL, to: permanentURL)
            
            let profileId = UUID()
            let consentContract = ConsentContract(
                timestamp: timestamp,
                termsVersion: "2026.1",
                verificationScriptText: verificationPhrase,
                spokenVerificationAudioFilename: permanentFilename,
                biometricSignatureSHA256: biometricSig,
                deviceModelIdentifier: "Apple-Device"
            )
            
            let profile = VoiceProfile(
                id: profileId,
                name: profileName,
                createdAt: timestamp,
                referenceAudioFilename: permanentFilename,
                sampleDuration: recordedDuration,
                acousticFeaturesHash: biometricSig,
                isBiometricLocked: true,
                consentContractId: consentContract.id
            )
            
            try await repository.saveProfile(profile, consent: consentContract)
            isProcessing = false
            currentStep = .completed
            return true
        } catch {
            errorMessage = "Enrollment failed: \(error.localizedDescription)"
            isProcessing = false
            return false
        }
    }
}
