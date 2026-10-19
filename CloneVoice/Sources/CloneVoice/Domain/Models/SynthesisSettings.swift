import Foundation

/// Configuration parameters for the VoxCPM2 inference engine.
public struct SynthesisSettings: Sendable, Equatable, Codable {
    public var cfgScale: Float
    public var timesteps: Int
    public var emotionInstruction: String?
    public var speedMultiplier: Float
    public var watermarkEnabled: Bool
    public var zeroRetention: Bool
    
    public static let standard = SynthesisSettings(
        cfgScale: 2.0,
        timesteps: 10,
        emotionInstruction: nil,
        speedMultiplier: 1.0,
        watermarkEnabled: true,
        zeroRetention: true
    )
    
    public static let expressive = SynthesisSettings(
        cfgScale: 2.5,
        timesteps: 15,
        emotionInstruction: "Speak with natural cadence, warm resonance, and subtle conversational pauses.",
        speedMultiplier: 1.0,
        watermarkEnabled: true,
        zeroRetention: true
    )
    
    public init(
        cfgScale: Float = 2.0,
        timesteps: Int = 10,
        emotionInstruction: String? = nil,
        speedMultiplier: Float = 1.0,
        watermarkEnabled: Bool = true,
        zeroRetention: Bool = true
    ) {
        self.cfgScale = max(1.0, min(5.0, cfgScale))
        self.timesteps = max(5, min(30, timesteps))
        self.emotionInstruction = emotionInstruction
        self.speedMultiplier = max(0.5, min(2.0, speedMultiplier))
        self.watermarkEnabled = watermarkEnabled
        self.zeroRetention = zeroRetention
    }
}
