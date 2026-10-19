import SwiftUI

/// Settings sheet for fine-tuning VoxCPM2 synthesis parameters.
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
                            Button("Standard Speed") {
                                settings = .standard
                            }
                            .buttonStyle(.bordered)
                            .tint(DesignTokens.Colors.acousticCyan)
                            
                            Button("Expressive Studio") {
                                settings = .expressive
                            }
                            .buttonStyle(.bordered)
                            .tint(DesignTokens.Colors.acousticIndigo)
                        }
                        .padding(.top, 12)
                        
                        // CFG Guidance Scale
                        GlassCard(cornerRadius: DesignTokens.Radii.medium) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Classifier-Free Guidance (CFG)")
                                        .font(.system(size: 14, weight: .bold))
                                    Spacer()
                                    Text(String(format: "%.1f", settings.cfgScale))
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundColor(DesignTokens.Colors.acousticCyan)
                                }
                                
                                Slider(value: $settings.cfgScale, in: 1.0...4.0, step: 0.1)
                                    .tint(DesignTokens.Colors.acousticCyan)
                                
                                Text("Higher values adhere more strictly to acoustic features and tone prompt.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                        }
                        
                        // Diffusion Sampling Steps
                        GlassCard(cornerRadius: DesignTokens.Radii.medium) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Diffusion Timesteps")
                                        .font(.system(size: 14, weight: .bold))
                                    Spacer()
                                    Text("\(settings.timesteps) steps")
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundColor(DesignTokens.Colors.acousticIndigo)
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { Double(settings.timesteps) },
                                        set: { settings.timesteps = Int($0) }
                                    ),
                                    in: 8...25,
                                    step: 1
                                )
                                .tint(DesignTokens.Colors.acousticIndigo)
                                
                                Text("10 steps is optimized for low-latency streaming; 20+ steps yields maximum fidelity.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                        }
                        
                        // Controllable Emotion Instruction Prompt
                        GlassCard(cornerRadius: DesignTokens.Radii.medium) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Emotion & Cadence Instruction")
                                    .font(.system(size: 14, weight: .bold))
                                
                                TextField(
                                    "e.g. Speak warmly with gentle cadence and thoughtful pacing",
                                    text: Binding(
                                        get: { settings.emotionInstruction ?? "" },
                                        set: { settings.emotionInstruction = $0.isEmpty ? nil : $0 }
                                    )
                                )
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .padding(16)
                        }
                        
                        // Ethics & Privacy Toggles
                        GlassCard(cornerRadius: DesignTokens.Radii.medium) {
                            VStack(spacing: 14) {
                                Toggle(isOn: $settings.watermarkEnabled) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("C2PA Content Credentials")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Embeds immutable cryptographic provenance manifest.")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tint(DesignTokens.Colors.acousticEmerald)
                                
                                Divider()
                                
                                Toggle(isOn: $settings.zeroRetention) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Zero-Retention Backend")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Discards audio buffer immediately after generation.")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tint(DesignTokens.Colors.acousticCyan)
                            }
                            .padding(16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Synthesis Engine Config")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                }
            }
        }
    }
}
