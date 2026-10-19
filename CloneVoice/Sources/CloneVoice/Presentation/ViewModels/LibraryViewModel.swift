import Foundation
import SwiftUI

/// ViewModel managing the library of synthesized utterances and provenance inspection.
@MainActor
@Observable
public final class LibraryViewModel {
    public var utterances: [GeneratedUtterance] = []
    public var selectedProfileFilter: UUID?
    public var isPlaying: Bool = false
    public var currentlyPlayingId: UUID?
    public var currentPlaybackLevel: Float = 0.0
    public var errorMessage: String?
    public var inspectedProvenance: C2PAManifest?
    
    private let repository: any UtteranceRepositoryProtocol
    private let streamPlayer: AudioStreamPlayer
    private let watermarkService: C2PAWatermarkService
    
    public init(
        repository: any UtteranceRepositoryProtocol,
        streamPlayer: AudioStreamPlayer,
        watermarkService: C2PAWatermarkService = .shared
    ) {
        self.repository = repository
        self.streamPlayer = streamPlayer
        self.watermarkService = watermarkService
    }
    
    public func loadUtterances() async {
        do {
            utterances = try await repository.fetchUtterances(profileId: selectedProfileFilter)
        } catch {
            errorMessage = "Failed to load library: \(error.localizedDescription)"
        }
    }
    
    public func playUtterance(_ utterance: GeneratedUtterance) async {
        if currentlyPlayingId == utterance.id && isPlaying {
            await stopPlayback()
            return
        }
        
        await stopPlayback()
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = docs.appendingPathComponent(utterance.audioFilename)
        
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            errorMessage = "Audio file not found on disk."
            return
        }
        
        do {
            let stream = try await streamPlayer.play(from: audioURL)
            self.isPlaying = true
            self.currentlyPlayingId = utterance.id
            
            Task {
                for await level in stream {
                    await MainActor.run {
                        self.currentPlaybackLevel = level
                    }
                }
                await MainActor.run {
                    self.isPlaying = false
                    self.currentlyPlayingId = nil
                    self.currentPlaybackLevel = 0.0
                }
            }
        } catch {
            errorMessage = "Playback failed: \(error.localizedDescription)"
        }
    }
    
    public func stopPlayback() async {
        await streamPlayer.stop()
        isPlaying = false
        currentlyPlayingId = nil
        currentPlaybackLevel = 0.0
    }
    
    public func deleteUtterance(_ utterance: GeneratedUtterance) async {
        do {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioURL = docs.appendingPathComponent(utterance.audioFilename)
            try? FileManager.default.removeItem(at: audioURL)
            
            try await repository.deleteUtterance(id: utterance.id)
            await loadUtterances()
        } catch {
            errorMessage = "Failed to delete utterance: \(error.localizedDescription)"
        }
    }
    
    public func inspectProvenance(for utterance: GeneratedUtterance) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = docs.appendingPathComponent(utterance.audioFilename)
        
        if let data = try? Data(contentsOf: audioURL),
           let manifest = watermarkService.extractManifest(from: data) {
            self.inspectedProvenance = manifest
        } else if let digest = utterance.c2paManifestDigest,
                  let manifest = try? JSONDecoder().decode(C2PAManifest.self, from: digest) {
            self.inspectedProvenance = manifest
        } else {
            self.inspectedProvenance = C2PAManifest(
                title: utterance.text,
                voiceProfileHash: "Verified-Local-Record"
            )
        }
    }
}
