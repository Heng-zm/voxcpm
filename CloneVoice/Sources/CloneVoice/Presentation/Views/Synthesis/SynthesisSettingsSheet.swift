import SwiftUI

/// Settings sheet for verified VoxCPM2 inference parameters.
///
/// NOTE: Non-verified sliders (such as speed, emotion, or similarity) are strictly omitted
/// in compliance with official OpenBMB VoxCPM2 runtime specifications.
public struct SynthesisSettingsSheet: View {
    @Binding var settings: SynthesisSettings
    @Environment(\.dismiss) private var dismiss
    
    public init(settings: Binding<SynthesisSettings>) {
        self._settings = settings
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassMeshGlow(energy: 0.05)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Presets
                        HStack(spacing: 12) {
                            Button("Standard (10 Steps)") {
                                settings = .standard
                            }
                            .buttonStyle(.bordered)
                            .tint(DesignTokens.Colors.acousticCyan)
                            
                            Button("Studio (20 Steps)") {
                                settings = .highFidelity
                            }
                            .buttonStyle(.bordered)
                            .tint(DesignTokens.Colors.acousticIndigo)
                        }
                        .padding(.top, 12)
                        
                        // Classifier-Free Guidance (cfg_value)
                        GlassCard(cornerRadius: DesignTokens.Radii.medium) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Classifier-Free Guidance (cfg_value)")
                                        .font(.system(size: 14, weight: .bold))
                                    Spacer()
                                    Text(String(format: "%.1f", settings.cfgValue))
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundColor(DesignTokens.Colors.acousticCyan)
                                }
                                
                                Slider(value: $settings.cfgValue, in: 1.0...3.0, step: 0.1)
                                    .tint(DesignTokens.Colors.acousticCyan)
                                
                                Text("VoxCPM2 recommended range: 1.0 to 3.0. Higher values follow acoustic conditioning more strictly.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                        }
                        
                        // Diffusion Sampling Steps (inference_timesteps)
                        GlassCard(cornerRadius: DesignTokens.Radii.medium) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Diffusion Sampling Steps (inference_timesteps)")
                                        .font(.system(size: 14, weight: .bold))
                                    Spacer()
                                    Text("\(settings.inferenceTimesteps) steps")
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundColor(DesignTokens.Colors.acousticIndigo)
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { Double(settings.inferenceTimesteps) },
                                        set: { settings.inferenceTimesteps = Int($0) }
                                    ),
                                    in: 4...30,
                                    step: 1
                                )
                                .tint(DesignTokens.Colors.acousticIndigo)
                                
                                Text("Recommended: 4 to 30 steps. 10 steps balances low latency and acoustic naturalness.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                        }
                        
                        // AudioVAE Denoising Toggle
                        GlassCard(cornerRadius: DesignTokens.Radii.medium) {
                            Toggle(isOn: $settings.denoise) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AudioVAE Denoising Post-processing")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Applies OpenBMB's integrated super-resolution vocoder denoiser.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(DesignTokens.Colors.acousticEmerald)
                            .padding(16)
                        }
                        
                        // Reproducibility Seed (Optional)
                        GlassCard(cornerRadius: DesignTokens.Radii.medium) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Diffusion Seed (Optional)")
                                    .font(.system(size: 14, weight: .bold))
                                
                                TextField(
                                    "Random by default (e.g. 42)",
                                    text: Binding(
                                        get: { settings.seed.map(String.init) ?? "" },
                                        set: { settings.seed = Int($0) }
                                    )
                                )
                                .textFieldStyle(.plain)
                                .font(.system(size: 14, design: .monospaced))
                                #if os(iOS)
                                .keyboardType(.numberPad)
                                #endif
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .padding(16)
                        }
                        
                        // Ephemeral Zero-Retention
                        GlassCard(cornerRadius: DesignTokens.Radii.medium) {
                            Toggle(isOn: $settings.zeroRetention) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Zero-Retention Privacy")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Discards audio reference from RAM immediately upon synthesis.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(DesignTokens.Colors.acousticCyan)
                            .padding(16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("VoxCPM2 Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                }
            }
        }
    }
}
