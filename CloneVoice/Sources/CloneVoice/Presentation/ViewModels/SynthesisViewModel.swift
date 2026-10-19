import Foundation
import SwiftUI

/// ViewModel managing real-time speech generation and streaming playback.
@MainActor
@Observable
public final class SynthesisViewModel {
    public var selectedProfile: VoiceProfile?
    public var inputText: String = ""
    public var settings: SynthesisSettings = .standard
    public var isSynthesizing: Bool = false
    public var isPlaying: Bool = false
    public var currentPlaybackLevel: Float = 0.0
    public var generationProgress: Double = 0.0
    public var errorMessage: String?
    public var latestUtterance: GeneratedUtterance?
    
    private let inferenceClient: VoxCPMInferenceClient
    private let utteranceRepository: any UtteranceRepositoryProtocol
    private let streamPlayer: AudioStreamPlayer
    private let watermarkService: C2PAWatermarkService
    private let biometricAuth: BiometricAuthServiceProtocol
    
    public init(
        inferenceClient: VoxCPMInferenceClient,
        utteranceRepository: any UtteranceRepositoryProtocol,
        streamPlayer: AudioStreamPlayer,
        watermarkService: C2PAWatermarkService = .shared,
        biometricAuth: BiometricAuthServiceProtocol = BiometricAuthService.shared
    ) {
        self.inferenceClient = inferenceClient
        self.utteranceRepository = utteranceRepository
        self.streamPlayer = streamPlayer
        self.watermarkService = watermarkService
        self.biometricAuth = biometricAuth
    }
    
    public func generateSpeech() async {
        guard let profile = selectedProfile else {
            errorMessage = "Please select an enrolled voice profile first."
            return
        }
        
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please input text to synthesize."
            return
        }
        
        // Ensure biometric authorization before invoking synthesis
        if profile.isBiometricLocked {
            do {
                let authorized = try await biometricAuth.authenticate(
                    reason: "Authorize voice synthesis using '\(profile.name)'."
                )
                guard authorized else {
                    errorMessage = "Biometric authorization was canceled."
                    return
                }
            } catch {
                errorMessage = "Biometric check failed."
                return
            }
        }
        
        isSynthesizing = true
        errorMessage = nil
        generationProgress = 0.1
        let startTime = Date()
        
        // Locate reference audio
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let refURL = docs.appendingPathComponent(profile.referenceAudioFilename)
        
        let audioData: Data
        if FileManager.default.fileExists(atPath: refURL.path), let data = try? Data(contentsOf: refURL) {
            audioData = data
        } else {
            // Fallback synthetic header if file is virtual
            audioData = AudioConverter.makeWAVHeader(dataLength: 48000 * 2 * 5)
        }
        
        var receivedAudio = Data()
        let outputFilename = "utterance_\(UUID().uuidString).wav"
        let outputURL = docs.appendingPathComponent(outputFilename)
        
        do {
            let stream = try await inferenceClient.generateSpeechStream(
                profile: profile,
                referenceAudioData: audioData,
                text: trimmed,
                settings: settings
            )
            
            for try await chunk in stream {
                receivedAudio.append(chunk)
                try await streamPlayer.enqueueChunk(chunk)
                generationProgress = min(0.95, generationProgress + 0.15)
            }
            
            let latency = Date().timeIntervalSince(startTime)
            
            // Build signed C2PA provenance manifest
            let manifestData = try watermarkService.createManifest(
                title: "Clone Voice Synthesis: \(trimmed.prefix(32))",
                profileHash: profile.acousticFeaturesHash
            )
            
            // If received audio lacks a valid WAV header, prepend one
            var finalWAV = receivedAudio
            if !AudioConverter.isValidWAV(data: finalWAV) {
                let header = AudioConverter.makeWAVHeader(dataLength: receivedAudio.count)
                finalWAV = header + receivedAudio
            }
            
            // Inject C2PA provenance into the WAV container
            if settings.watermarkEnabled {
                finalWAV = watermarkService.injectManifest(into: finalWAV, manifestData: manifestData)
            }
            
            // Write to persistent storage
            try finalWAV.write(to: outputURL, options: .atomic)
            
            let utterance = GeneratedUtterance(
                profileId: profile.id,
                profileName: profile.name,
                text: trimmed,
                createdAt: Date(),
                audioFilename: outputFilename,
                duration: Double(finalWAV.count) / (48000.0 * 2.0),
                c2paManifestDigest: manifestData,
                latencySeconds: latency,
                settings: settings
            )
            
            try await utteranceRepository.saveUtterance(utterance)
            self.latestUtterance = utterance
            generationProgress = 1.0
            
            // Play back the generated audio
            await playUtterance(outputURL)
            
        } catch {
            errorMessage = "Synthesis failed: \(error.localizedDescription)"
        }
        
        isSynthesizing = false
    }
    
    public func playUtterance(_ url: URL) async {
        do {
            let stream = try await streamPlayer.play(from: url)
            self.isPlaying = true
            
            Task {
                for await level in stream {
                    await MainActor.run {
                        self.currentPlaybackLevel = level
                    }
                }
                await MainActor.run {
                    self.isPlaying = false
                    self.currentPlaybackLevel = 0.0
                }
            }
        } catch {
            errorMessage = "Playback failed: \(error.localizedDescription)"
            isPlaying = false
        }
    }
    
    public func stopPlayback() async {
        await streamPlayer.stop()
        isPlaying = false
        currentPlaybackLevel = 0.0
    }
}
