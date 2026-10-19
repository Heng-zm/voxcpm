import SwiftUI

/// Core studio view for synthesizing cloned voice speech via VoxCPM2 with real-time streaming playback.
public struct SpeechGenerationStudioView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    @State private var viewModel: SynthesisViewModel?
    @State private var isSettingsPresented = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassMeshGlow(energy: viewModel?.currentPlaybackLevel ?? 0.05)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Banner
                        profileBannerSection
                        
                        // Text Editor Card
                        textEditorSection
                        
                        // Waveform & Streaming Player Card
                        audioPlaybackCard
                        
                        if let vm = viewModel, let error = vm.errorMessage {
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.destructiveRed)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Generate Button
                        generateButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Voice Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        isSettingsPresented = true
                    }) {
                        Image(systemName: "slider.horizontal.2.square")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.acousticCyan)
                    }
                }
            }
            .task {
                if viewModel == nil {
                    viewModel = SynthesisViewModel(
                        inferenceService: env.activeInferenceService,
                        utteranceRepository: env.utteranceRepository,
                        streamPlayer: env.streamPlayer,
                        watermarkService: env.watermarkService,
                        biometricAuth: env.biometricAuth
                    )
                }
                if let active = router.activeProfileForSynthesis {
                    viewModel?.selectedProfile = active
                }
            }
            .onChange(of: router.activeProfileForSynthesis) { _, newProfile in
                viewModel?.selectedProfile = newProfile
            }
            .onChange(of: env.executionTarget) { _, _ in
                viewModel?.updateInferenceService(env.activeInferenceService)
            }
            .sheet(isPresented: $isSettingsPresented) {
                if let vm = viewModel {
                    SynthesisSettingsSheet(settings: Bindable(vm).settings)
                }
            }
        }
    }
    
    private var profileBannerSection: some View {
        GlassCard(cornerRadius: DesignTokens.Radii.large, specularIntensity: 0.4) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.acousticCyan, DesignTokens.Colors.acousticIndigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "person.wave.2.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel?.selectedProfile?.name ?? "No Profile Selected")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    
                    Text("VoxCPM2 48kHz Neural Clone")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let profile = viewModel?.selectedProfile {
                    BiometricLockBadge(isLocked: profile.isBiometricLocked)
                } else {
                    Button("Select") {
                        router.selectedTab = .library
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignTokens.Colors.acousticCyan)
                }
            }
            .padding(14)
        }
    }
    
    private var textEditorSection: some View {
        GlassCard(cornerRadius: DesignTokens.Radii.large) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("TARGET SPEECH SCRIPT")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\((viewModel?.inputText.count ?? 0)) characters")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                if let vm = viewModel {
                    TextEditor(text: Bindable(vm).inputText)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 16, weight: .regular))
                }
                
                // Quick Sample Prompts
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        samplePromptChip("Hello! This is a cloned voice demonstration.")
                        samplePromptChip("Every voice holds an unmistakable timbre and rhythm.")
                        samplePromptChip("Welcome to the next generation of Liquid Glass speech synthesis.")
                    }
                }
            }
            .padding(16)
        }
    }
    
    private func samplePromptChip(_ text: String) -> some View {
        Button(action: {
            viewModel?.inputText = text
        }) {
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .foregroundColor(.secondary)
                .clipShape(Capsule())
        }
    }
    
    private var audioPlaybackCard: some View {
        GlassCard(
            cornerRadius: DesignTokens.Radii.large,
            specularIntensity: (viewModel?.isPlaying ?? false) ? 0.6 : 0.25,
            glowColor: (viewModel?.isPlaying ?? false) ? DesignTokens.Colors.acousticCyan : nil
        ) {
            VStack(spacing: 12) {
                DynamicWaveformView(
                    level: viewModel?.currentPlaybackLevel ?? 0.0,
                    barCount: 30,
                    isLive: (viewModel?.isPlaying ?? false) || (viewModel?.isSynthesizing ?? false)
                )
                
                if let vm = viewModel, vm.isSynthesizing {
                    ProgressView(value: vm.generationProgress)
                        .tint(DesignTokens.Colors.acousticCyan)
                        .padding(.horizontal, 8)
                    
                    Text("Streaming continuous speech representations...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.acousticCyan)
                } else if let utterance = viewModel?.latestUtterance {
                    HStack {
                        C2PAProvenanceBadge(hasProvenance: true)
                        
                        Spacer()
                        
                        Text(String(format: "Generated in %.2fs", utterance.latencySeconds))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(16)
        }
    }
    
    private var generateButton: some View {
        LiquidGlassButton(
            title: (viewModel?.isSynthesizing ?? false) ? "Synthesizing Speech..." : "Generate Voice with VoxCPM2",
            systemImage: "sparkles",
            style: .primary,
            isLoading: viewModel?.isSynthesizing ?? false,
            action: {
                Task {
                    await viewModel?.generateSpeech()
                }
            }
        )
        .disabled((viewModel?.selectedProfile == nil) || (viewModel?.inputText.trimmingCharacters(in: .whitespaces).isEmpty ?? true))
        .opacity((viewModel?.selectedProfile != nil && !(viewModel?.inputText.trimmingCharacters(in: .whitespaces).isEmpty ?? true)) ? 1.0 : 0.5)
    }
}
