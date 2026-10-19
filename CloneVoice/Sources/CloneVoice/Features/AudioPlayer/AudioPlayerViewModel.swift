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
        #if os(iOS)
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            if type == .began {
                Task { @MainActor [weak self] in
                    self?.pause()
                }
            }
        }
        #endif
    }
    
    public func loadAudio(from url: URL) {
        stop()
        self.currentURL = url
        
        do {
            #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            #endif
            
            guard let fileData = try? Data(contentsOf: url), !fileData.isEmpty else {
                self.errorMessage = "Audio file is empty or missing"
                return
            }
            
            // Clean file by stripping any corrupting non-standard chunks and repairing header
            let cleanData = AudioConverter.extractCleanWAV(from: fileData)
            if cleanData != fileData {
                try? cleanData.write(to: url, options: .atomic)
            }
            
            // Try file-based player, with in-memory Data player as resilient fallback
            var activePlayer: AVAudioPlayer? = try? AVAudioPlayer(contentsOf: url)
            if activePlayer == nil {
                activePlayer = try? AVAudioPlayer(data: cleanData)
            }
            
            guard let player = activePlayer else {
                self.errorMessage = "Failed to decode WAV audio"
                return
            }
            
            player.delegate = self
            player.prepareToPlay()
            self.audioPlayer = player
            
            // Compute real duration from PCM samples if player reports 0.0
            let pcmBytes = max(0, cleanData.count - 44)
            let computedDuration = Double(pcmBytes) / (48000.0 * 2.0)
            let finalDuration = player.duration > 0.05 ? player.duration : computedDuration
            
            self.duration = max(0.1, finalDuration)
            self.currentTime = 0.0
            self.progress = 0.0
            self.errorMessage = nil
        } catch {
            self.errorMessage = "Failed to load audio: \(error.localizedDescription)"
        }
    }
    
    public func togglePlayPause() {
        if audioPlayer == nil, let url = currentURL {
            loadAudio(from: url)
        }
        guard let player = audioPlayer else { return }
        
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        
        if player.isPlaying {
            player.pause()
            self.isPlaying = false
            stopTimer()
        } else {
            // If at end, seek back to start
            if currentTime >= duration - 0.1 || currentTime >= duration {
                player.currentTime = 0
                self.currentTime = 0
                self.progress = 0.0
            }
            player.play()
            self.isPlaying = true
            startTimer()
        }
    }
    
    public func pause() {
        guard let player = audioPlayer, player.isPlaying else { return }
        player.pause()
        self.isPlaying = false
        stopTimer()
    }
    
    public func seek(to progress: Double) {
        guard let player = audioPlayer, duration > 0, duration.isFinite else { return }
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
            Task { @MainActor [weak self] in
                guard let self = self, let player = self.audioPlayer else { return }
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
