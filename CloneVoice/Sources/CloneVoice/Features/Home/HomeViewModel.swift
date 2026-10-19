import Foundation
import SwiftUI

/// Message model for conversational home feed.
public struct ConversationItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let text: String
    public let timestamp: Date
    public let profile: VoiceProfile
    public var utterance: GeneratedUtterance?
    public var isGenerating: Bool
    public var errorMessage: String?
    
    public init(
        id: UUID = UUID(),
        text: String,
        timestamp: Date = Date(),
        profile: VoiceProfile,
        utterance: GeneratedUtterance? = nil,
        isGenerating: Bool = false,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.profile = profile
        self.utterance = utterance
        self.isGenerating = isGenerating
        self.errorMessage = errorMessage
    }
}

/// ViewModel powering the conversational home screen with draft preservation and streaming generation.
@MainActor
@Observable
public final class HomeViewModel {
    public var conversation: [ConversationItem] = []
    public var composerDraftText: String = ""
    public var selectedProfile: VoiceProfile?
    public var availableProfiles: [VoiceProfile] = []
    public var isGenerating: Bool = false
    public var generationProgress: Double = 0.0
    public var errorMessage: String?
    
    private let inferenceClient: VoxCPMInferenceClient
    private let profileRepository: any VoiceProfileRepositoryProtocol
    private let utteranceRepository: any UtteranceRepositoryProtocol
    private let watermarkService: C2PAWatermarkService
    private let biometricAuth: BiometricAuthServiceProtocol
    
    public init(
        inferenceClient: VoxCPMInferenceClient,
        profileRepository: any VoiceProfileRepositoryProtocol,
        utteranceRepository: any UtteranceRepositoryProtocol,
        watermarkService: C2PAWatermarkService = .shared,
        biometricAuth: BiometricAuthServiceProtocol = BiometricAuthService.shared
    ) {
        self.inferenceClient = inferenceClient
        self.profileRepository = profileRepository
        self.utteranceRepository = utteranceRepository
        self.watermarkService = watermarkService
        self.biometricAuth = biometricAuth
    }
    
    public func loadInitialData() async {
        do {
            self.availableProfiles = try await profileRepository.fetchProfiles()
            if selectedProfile == nil {
                self.selectedProfile = availableProfiles.first
            }
            
            // Populate recent conversation items from persisted utterances
            let recentUtterances = try await utteranceRepository.fetchUtterances(profileId: nil)
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            self.conversation = recentUtterances.compactMap { utterance -> ConversationItem? in
                let audioURL = docs.appendingPathComponent(utterance.audioFilename)
                guard FileManager.default.fileExists(atPath: audioURL.path) else { return nil }
                
                let profile = availableProfiles.first(where: { $0.id == utterance.profileId }) ?? VoiceProfile(
                    id: utterance.profileId,
                    name: utterance.profileName,
                    referenceAudioFilename: "",
                    sampleDuration: 0,
                    acousticFeaturesHash: ""
                )
                
                return ConversationItem(
                    id: utterance.id,
                    text: utterance.text,
                    timestamp: utterance.createdAt,
                    profile: profile,
                    utterance: utterance,
                    isGenerating: false
                )
            }.reversed()
        } catch {
            errorMessage = "Failed to load initial data: \(error.localizedDescription)"
        }
    }
    
    public func startNewGeneration() {
        // Preserves conversation or clears for fresh generation
        composerDraftText = ""
        errorMessage = nil
    }
    
    public func generateSpeech() async {
        let trimmed = composerDraftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter text to synthesize."
            return
        }
        
        guard let profile = selectedProfile else {
            errorMessage = "Please select or create an enrolled voice profile first."
            return
        }
        
        // Tier 3: Biometric check before invoking voice model
        if profile.isBiometricLocked {
            do {
                let authorized = try await biometricAuth.authenticate(
                    reason: "Authorize voice cloning using '\(profile.name)'."
                )
                guard authorized else {
                    errorMessage = "Biometric check was canceled."
                    return
                }
            } catch {
                errorMessage = "Biometric authorization failed."
                return
            }
        }
        
        // Add pending item to conversation feed
        let pendingId = UUID()
        let pendingItem = ConversationItem(
            id: pendingId,
            text: trimmed,
            profile: profile,
            isGenerating: true
        )
        conversation.append(pendingItem)
        
        isGenerating = true
        errorMessage = nil
        generationProgress = 0.1
        let startTime = Date()
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let refURL = docs.appendingPathComponent(profile.referenceAudioFilename)
        
        let audioData: Data
        if FileManager.default.fileExists(atPath: refURL.path), let data = try? Data(contentsOf: refURL) {
            audioData = data
        } else {
            audioData = AudioConverter.makeWAVHeader(dataLength: 48000 * 2 * 5)
        }
        
        var receivedAudio = Data()
        let outputFilename = "conv_\(UUID().uuidString).wav"
        let outputURL = docs.appendingPathComponent(outputFilename)
        
        do {
            let settings = SynthesisSettings.standard
            let stream = try await inferenceClient.generateSpeechStream(
                profile: profile,
                referenceAudioData: audioData,
                text: trimmed,
                settings: settings
            )
            
            for try await chunk in stream {
                receivedAudio.append(chunk)
                generationProgress = min(0.95, generationProgress + 0.15)
            }
            
            let latency = Date().timeIntervalSince(startTime)
            
            // Build signed C2PA manifest
            let manifestData = try watermarkService.createManifest(
                title: "Clone Voice: \(trimmed.prefix(32))",
                profileHash: profile.acousticFeaturesHash
            )
            
            var finalWAV = receivedAudio
            if !AudioConverter.isValidWAV(data: finalWAV) {
                let header = AudioConverter.makeWAVHeader(dataLength: receivedAudio.count)
                finalWAV = header + receivedAudio
            }
            
            finalWAV = watermarkService.injectManifest(into: finalWAV, manifestData: manifestData)
            try finalWAV.write(to: outputURL, options: .atomic)
            
            let utterance = GeneratedUtterance(
                id: pendingId,
                profileId: profile.id,
                profileName: profile.name,
                text: trimmed,
                createdAt: Date(),
                audioFilename: outputFilename,
                duration: Double(finalWAV.count) / (48000.0 * 2.0),
                c2paManifestDigest: manifestData,
                latencySeconds: latency,
                settings: settings,
                status: .completed
            )
            
            try await utteranceRepository.saveUtterance(utterance)
            
            // Update conversation item to completed
            if let index = conversation.firstIndex(where: { $0.id == pendingId }) {
                conversation[index].isGenerating = false
                conversation[index].utterance = utterance
            }
            
            // Clear composer draft on success
            composerDraftText = ""
            generationProgress = 1.0
            
        } catch {
            errorMessage = "Generation failed: \(error.localizedDescription)"
            // Preserve user text in composer draft on error!
            if let index = conversation.firstIndex(where: { $0.id == pendingId }) {
                conversation[index].isGenerating = false
                conversation[index].errorMessage = error.localizedDescription
            }
        }
        
        isGenerating = false
    }
}
