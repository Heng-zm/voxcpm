import Foundation

public enum AudioEngineError: Error, LocalizedError, Sendable {
    case permissionDenied
    case deviceUnavailable
    case recordingFailed(String)
    case playbackFailed(String)
    case invalidFormat
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission was denied by the user."
        case .deviceUnavailable:
            return "No audio input/output device is currently available."
        case .recordingFailed(let reason):
            return "Audio recording failed: \(reason)"
        case .playbackFailed(let reason):
            return "Audio playback failed: \(reason)"
        case .invalidFormat:
            return "Unsupported audio format or sample rate."
        }
    }
}

public protocol AudioRecordingProtocol: Sendable {
    /// Starts recording to the specified file URL at 48kHz / 16-bit PCM.
    /// Returns an AsyncStream of normalized RMS amplitude levels [0.0...1.0] for UI visualizers.
    func startRecording(to destinationURL: URL) async throws -> AsyncStream<Float>
    
    /// Stops the active recording session and returns total recorded duration.
    func stopRecording() async throws -> TimeInterval
    
    /// Checks if a recording is currently in progress.
    func isRecordingActive() async -> Bool
}

public protocol AudioPlaybackProtocol: Sendable {
    /// Plays an audio file from a local URL, returning an AsyncStream of normalized playback amplitude.
    func play(from fileURL: URL) async throws -> AsyncStream<Float>
    
    /// Enqueues incoming PCM/WAV chunks into a real-time streaming player.
    func enqueueChunk(_ chunk: Data) async throws
    
    /// Stops playback immediately.
    func stop() async
    
    /// Checks if playback is actively running.
    func isPlayingActive() async -> Bool
}
