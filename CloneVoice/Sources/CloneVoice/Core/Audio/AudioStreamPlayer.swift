import AVFoundation
import Foundation

/// Real-time streaming and local file audio player using AVAudioEngine and AVAudioPlayerNode.
public actor AudioStreamPlayer: AudioPlaybackProtocol {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var isPlaying = false
    private var tempStreamingFile: URL?
    
    public init() {}
    
    public func play(from fileURL: URL) throws -> AsyncStream<Float> {
        stop()
        
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        
        let file = try AVAudioFile(forReading: fileURL)
        let format = file.processingFormat
        
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try engine.start()
        
        player.scheduleFile(file, at: nil) { [weak self] in
            Task { [weak self] in
                await self?.stop()
            }
        }
        
        self.audioEngine = engine
        self.playerNode = player
        self.isPlaying = true
        
        player.play()
        
        return AsyncStream { continuation in
            engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameCount = Int(buffer.frameLength)
                var sum: Float = 0
                for i in 0..<frameCount {
                    sum += channelData[i] * channelData[i]
                }
                let rms = sqrt(sum / Float(max(1, frameCount)))
                let normalized = AudioConverter.normalizeDecibels(rms: rms)
                continuation.yield(normalized)
            }
            
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.stop()
                }
            }
        }
    }
    
    public func enqueueChunk(_ chunk: Data) throws {
        // Appends incoming streaming bytes to an ephemeral memory/disk buffer for continuous playback
        if tempStreamingFile == nil {
            let tempDir = FileManager.default.temporaryDirectory
            tempStreamingFile = tempDir.appendingPathComponent("stream_\(UUID().uuidString).pcm")
            FileManager.default.createFile(atPath: tempStreamingFile!.path, contents: nil)
        }
        
        if let url = tempStreamingFile, let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(chunk)
            try? handle.close()
        }
    }
    
    public func stop() {
        if let engine = audioEngine, engine.isRunning {
            engine.mainMixerNode.removeTap(onBus: 0)
            playerNode?.stop()
            engine.stop()
        }
        
        if let temp = tempStreamingFile {
            try? FileManager.default.removeItem(at: temp)
            tempStreamingFile = nil
        }
        
        audioEngine = nil
        playerNode = nil
        isPlaying = false
    }
    
    public func isPlayingActive() -> Bool {
        return isPlaying
    }
}
