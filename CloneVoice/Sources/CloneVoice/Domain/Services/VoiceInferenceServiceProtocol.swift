import Foundation

public enum BackendStatus: Sendable, Equatable, Codable {
    case ready(gpuModel: String, vramAvailableGB: Double)
    case busy(queuePosition: Int)
    case offline(reason: String)
}

/// Abstract contract for speech synthesis backends (Remote VoxCPM2 or future on-device MLX/CoreML).
public protocol VoiceInferenceServiceProtocol: Sendable {
    /// Generates audio from text and reference voice profile, streaming binary audio chunks as they arrive.
    func generateSpeechStream(
        profile: VoiceProfile,
        referenceAudioData: Data,
        text: String,
        settings: SynthesisSettings
    ) async throws -> AsyncThrowingStream<Data, Error>
    
    /// Queries the backend health, device capabilities, and availability.
    func checkHealth() async throws -> BackendStatus
}
