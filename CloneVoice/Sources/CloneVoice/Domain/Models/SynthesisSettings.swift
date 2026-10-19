import Foundation

/// Verified generation settings supported directly by the official OpenBMB VoxCPM2 inference engine.
///
/// NOTE: Speed, emotion, and similarity sliders are intentionally NOT included because they are
/// not native runtime parameters of VoxCPM2's inference interface.
public struct SynthesisSettings: Sendable, Equatable, Codable {
    /// Classifier-Free Guidance scale. Typical range: 1.0 to 3.0 (higher adheres more strictly to voice reference).
    public var cfgValue: Float
    
    /// Number of diffusion sampling steps. Recommended range: 4 to 30. (10 steps is standard for interactive streaming).
    public var inferenceTimesteps: Int
    
    /// Whether to run AudioVAE denoising post-processing.
    public var denoise: Bool
    
    /// Optional seed for reproducible diffusion sampling.
    public var seed: Int?
    
    /// Zero-data-retention flag instructing backend to discard reference audio from RAM after generation.
    public var zeroRetention: Bool
    
    /// Default verified VoxCPM2 production settings
    public static let standard = SynthesisSettings(
        cfgValue: 2.0,
        inferenceTimesteps: 10,
        denoise: true,
        seed: nil,
        zeroRetention: true
    )
    
    /// High-fidelity studio settings with deeper diffusion sampling
    public static let highFidelity = SynthesisSettings(
        cfgValue: 2.5,
        inferenceTimesteps: 20,
        denoise: true,
        seed: nil,
        zeroRetention: true
    )
    
    public init(
        cfgValue: Float = 2.0,
        inferenceTimesteps: Int = 10,
        denoise: Bool = true,
        seed: Int? = nil,
        zeroRetention: Bool = true
    ) {
        self.cfgValue = max(1.0, min(3.0, cfgValue))
        self.inferenceTimesteps = max(4, min(30, inferenceTimesteps))
        self.denoise = denoise
        self.seed = seed
        self.zeroRetention = zeroRetention
    }
}
