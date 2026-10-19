import AVFoundation
import Foundation

/// Swift 6 actor-isolated audio recording engine utilizing AVAudioEngine.
public actor AudioEngineActor: AudioRecordingProtocol {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    private var recordedURL: URL?
    private var startTime: Date?
    private(set) var isRecording = false
    
    public init() {}
    
    public func startRecording(to destinationURL: URL) throws -> AsyncStream<Float> {
        guard !isRecording else {
            throw AudioEngineError.recordingFailed("Recording already active.")
        }
        
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setPreferredSampleRate(48000.0)
        try session.setActive(true)
        #endif
        
        let engine = AVAudioEngine()
        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        
        guard inputFormat.sampleRate > 0 else {
            throw AudioEngineError.invalidFormat
        }
        
        // Output format: 48kHz 16-bit Mono Linear PCM for optimal VoxCPM2 compatibility
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 48000.0,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioEngineError.invalidFormat
        }
        
        let file = try AVAudioFile(
            forWriting: destinationURL,
            settings: targetFormat.settings
        )
        
        self.audioEngine = engine
        self.inputNode = input
        self.audioFile = file
        self.recordedURL = destinationURL
        self.startTime = Date()
        self.isRecording = true
        
        return AsyncStream { continuation in
            input.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
                // Write buffer to disk
                try? file.write(from: buffer)
                
                // Compute real-time RMS level
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameCount = Int(buffer.frameLength)
                var sum: Float = 0
                for i in 0..<frameCount {
                    let sample = channelData[i]
                    sum += sample * sample
                }
                let rms = sqrt(sum / Float(max(1, frameCount)))
                let normalized = AudioConverter.normalizeDecibels(rms: rms)
                
                continuation.yield(normalized)
            }
            
            do {
                try engine.start()
            } catch {
                continuation.finish()
            }
            
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    _ = try? await self?.stopRecording()
                }
            }
        }
    }
    
    public func stopRecording() throws -> TimeInterval {
        guard isRecording else { return 0 }
        
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        
        let duration = startTime.map { Date().timeIntervalSince($0) } ?? 0
        
        self.audioEngine = nil
        self.inputNode = nil
        self.audioFile = nil
        self.isRecording = false
        self.startTime = nil
        
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
        return duration
    }
    
    public func isRecordingActive() -> Bool {
        return isRecording
    }
}
