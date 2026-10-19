import Foundation
import AVFoundation
import SwiftUI

/// Observable ViewModel for managing audio playback, seeking, and lifecycle transitions.
@MainActor
@Observable
public final class AudioPlayerViewModel: NSObject, AVAudioPlayerDelegate {
    public var isPlaying: Bool = false
    public var currentTime: TimeInterval = 0.0
    public var duration: TimeInterval = 0.0
    public var progress: Double = 0.0
    public var errorMessage: String?
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var currentURL: URL?
    
    public override init() {
        super.init()
    }
    
    public func loadAudio(from url: URL) {
        stop()
        self.currentURL = url
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            
            self.audioPlayer = player
            self.duration = player.duration
            self.currentTime = 0.0
            self.progress = 0.0
            self.errorMessage = nil
        } catch {
            self.errorMessage = "Failed to load audio: \(error.localizedDescription)"
        }
    }
    
    public func togglePlayPause() {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            player.pause()
            self.isPlaying = false
            stopTimer()
        } else {
            // If at end, seek back to start
            if currentTime >= duration - 0.1 {
                player.currentTime = 0
            }
            player.play()
            self.isPlaying = true
            startTimer()
        }
    }
    
    public func seek(to progress: Double) {
        guard let player = audioPlayer else { return }
        let clamped = max(0.0, min(1.0, progress))
        let targetTime = clamped * duration
        player.currentTime = targetTime
        self.currentTime = targetTime
        self.progress = clamped
    }
    
    public func stop() {
        stopTimer()
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0.0
        progress = 0.0
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            Task { @MainActor in
                self.currentTime = player.currentTime
                if self.duration > 0 {
                    self.progress = player.currentTime / self.duration
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - AVAudioPlayerDelegate
    public nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.stopTimer()
            self.isPlaying = false
            self.currentTime = self.duration
            self.progress = 1.0
        }
    }
}
