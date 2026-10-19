import Foundation
import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

public enum VoiceCreationMode {
    case record
    case importFile
}

/// ViewModel driving the Create Voice sheet with recording, file import, validation, and consent.
@MainActor
@Observable
public final class CreateVoiceViewModel {
    public var profileName: String = ""
    public var mode: VoiceCreationMode = .record
    public var isRecording: Bool = false
    public var currentRMSLevel: Float = 0.0
    public var audioDuration: TimeInterval = 0.0
    public var audioFileSize: Int = 0
    public var audioFormatInfo: String = ""
    public var temporaryAudioURL: URL?
    public var isAudioReady: Bool = false
    public var hasUserConsent: Bool = false
    public var isProcessing: Bool = false
    public var errorMessage: String?
    
    // Explicit randomized phrase for liveness validation
    public let randomizedPhrase: String
    
    private let audioEngine: AudioEngineActor
    private let repository: any VoiceProfileRepositoryProtocol
    private let biometricAuth: BiometricAuthServiceProtocol
    
    public init(
        audioEngine: AudioEngineActor,
        repository: any VoiceProfileRepositoryProtocol,
        biometricAuth: BiometricAuthServiceProtocol
    ) {
        self.audioEngine = audioEngine
        self.repository = repository
        self.biometricAuth = biometricAuth
        
        let sessionCode = Int.random(in: 10000...99999)
        self.randomizedPhrase = "I, the speaker, authorize Clone Voice on session \(sessionCode) to generate a personalized digital voice replica for my exclusive use."
    }
    
    public func startRecording() async {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("rec_\(UUID().uuidString).wav")
        self.temporaryAudioURL = fileURL
        self.errorMessage = nil
        self.isAudioReady = false
        
        do {
            #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            let permission = await session.requestRecordPermission()
            guard permission else {
                errorMessage = "Microphone access denied. Please enable microphone permissions in Settings."
                return
            }
            #endif
            
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
    
    public func stopRecording() async {
        guard isRecording else { return }
        
        do {
            let duration = try await audioEngine.stopRecording()
            self.audioDuration = duration
            self.isRecording = false
            self.currentRMSLevel = 0.0
            
            if duration < 3.0 {
                errorMessage = "Sample is too short (\(String(format: "%.1f", duration))s). Minimum 3 seconds is required for VoxCPM2."
                self.isAudioReady = false
                return
            }
            
            validateAndPrepareAudio(from: temporaryAudioURL)
        } catch {
            errorMessage = "Failed to stop recording: \(error.localizedDescription)"
            self.isRecording = false
        }
    }
    
    public func handleImportedFile(result: Result<[URL], Error>) {
        do {
            guard let selectedURL = try result.get().first else { return }
            
            guard selectedURL.startAccessingSecurityScopedResource() else {
                errorMessage = "Unable to access security-scoped audio file."
                return
            }
            defer { selectedURL.stopAccessingSecurityScopedResource() }
            
            let tempDir = FileManager.default.temporaryDirectory
            let destinationURL = tempDir.appendingPathComponent("import_\(UUID().uuidString).\(selectedURL.pathExtension)")
            
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try? FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: selectedURL, to: destinationURL)
            
            self.temporaryAudioURL = destinationURL
            validateAndPrepareAudio(from: destinationURL)
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
    }
    
    private func validateAndPrepareAudio(from url: URL?) {
        guard let url = url, FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "Audio file not found."
            isAudioReady = false
            return
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            self.audioFileSize = attributes[.size] as? Int ?? 0
            
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let sampleRate = format.sampleRate
            let length = Double(audioFile.length) / sampleRate
            self.audioDuration = length
            self.audioFormatInfo = "\(Int(sampleRate)) Hz, \(format.channelCount == 1 ? "Mono" : "Stereo")"
            
            if length < 3.0 {
                errorMessage = "Audio duration (\(String(format: "%.1f", length))s) is below the minimum 3.0 seconds required."
                isAudioReady = false
                return
            }
            
            self.errorMessage = nil
            self.isAudioReady = true
        } catch {
            errorMessage = "Audio validation failed: \(error.localizedDescription)"
            isAudioReady = false
        }
    }
    
    public func saveProfile() async -> Bool {
        guard let audioURL = temporaryAudioURL, isAudioReady else {
            errorMessage = "Please record or import a valid reference audio sample."
            return false
        }
        
        let trimmedName = profileName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a name for the voice profile."
            return false
        }
        
        guard hasUserConsent else {
            errorMessage = "You must confirm voice ownership or legal authorization before proceeding."
            return false
        }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            let timestamp = Date()
            let biometricSig = try await biometricAuth.generateConsentSignature(
                phrase: randomizedPhrase,
                timestamp: timestamp
            )
            
            // Move audio to permanent documents folder
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let permanentFilename = "profile_\(UUID().uuidString).wav"
            let permanentURL = docs.appendingPathComponent(permanentFilename)
            try FileManager.default.copyItem(at: audioURL, to: permanentURL)
            
            let consent = ConsentContract(
                timestamp: timestamp,
                termsVersion: "2026.1",
                verificationScriptText: randomizedPhrase,
                spokenVerificationAudioFilename: permanentFilename,
                biometricSignatureSHA256: biometricSig,
                deviceModelIdentifier: "Apple-Device"
            )
            
            let profile = VoiceProfile(
                id: UUID(),
                name: trimmedName,
                createdAt: timestamp,
                referenceAudioFilename: permanentFilename,
                sampleDuration: audioDuration,
                acousticFeaturesHash: biometricSig,
                isBiometricLocked: true,
                consentContractId: consent.id
            )
            
            try await repository.saveProfile(profile, consent: consent)
            isProcessing = false
            return true
        } catch {
            errorMessage = "Failed to create profile: \(error.localizedDescription)"
            isProcessing = false
            return false
        }
    }
}
