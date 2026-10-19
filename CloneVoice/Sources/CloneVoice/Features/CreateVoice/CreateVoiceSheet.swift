import SwiftUI
import UniformTypeIdentifiers

/// Sheet for creating a new voice profile via native microphone recording or audio file import.
public struct CreateVoiceSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    
    var onCreated: () -> Void
    @State private var viewModel: CreateVoiceViewModel?
    @State private var isFileImporterPresented = false
    
    public init(onCreated: @escaping () -> Void) {
        self.onCreated = onCreated
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassMeshGlow(energy: viewModel?.currentRMSLevel ?? 0.05)
                
                ScrollView {
                    VStack(spacing: 20) {
                        if let vm = viewModel {
                            // Profile Name Field
                            nameSection(vm: vm)
                            
                            // Segmented Mode Picker
                            Picker("Source", selection: Bindable(vm).mode) {
                                Text("Record Sample").tag(VoiceCreationMode.record)
                                Text("Import Audio File").tag(VoiceCreationMode.importFile)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 4)
                            
                            // Audio Acquisition Area
                            if vm.mode == .record {
                                recordSection(vm: vm)
                            } else {
                                importSection(vm: vm)
                            }
                            
                            // Audio Preview & Verified Metadata Card
                            if vm.isAudioReady, let audioURL = vm.temporaryAudioURL {
                                previewSection(audioURL: audioURL, vm: vm)
                            }
                            
                            // Consent Section
                            consentSection(vm: vm)
                            
                            // Error Message
                            if let error = vm.errorMessage {
                                Text(error)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(DesignTokens.Colors.destructiveRed)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            // Submit Action Button
                            LiquidGlassButton(
                                title: "Create Voice Profile",
                                systemImage: "waveform.badge.plus",
                                style: .primary,
                                isLoading: vm.isProcessing,
                                action: {
                                    Task {
                                        let success = await vm.saveProfile()
                                        if success {
                                            HapticFeedback.success()
                                            onCreated()
                                            dismiss()
                                        }
                                    }
                                }
                            )
                            .disabled(!vm.isAudioReady || !vm.hasUserConsent || vm.profileName.trimmingCharacters(in: .whitespaces).isEmpty)
                            .opacity((vm.isAudioReady && vm.hasUserConsent && !vm.profileName.trimmingCharacters(in: .whitespaces).isEmpty) ? 1.0 : 0.5)
                        } else {
                            ProgressView()
                                .padding(.top, 40)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("New Voice Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                if viewModel == nil {
                    viewModel = CreateVoiceViewModel(
                        audioEngine: env.audioEngine,
                        repository: env.profileRepository,
                        biometricAuth: env.biometricAuth
                    )
                }
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.audio, .wav, .mp3, .mpeg4Audio],
                allowsMultipleSelection: false
            ) { result in
                viewModel?.handleImportedFile(result: result)
            }
        }
    }
    
    private func nameSection(vm: CreateVoiceViewModel) -> some View {
        GlassCard(cornerRadius: DesignTokens.Radii.medium) {
            VStack(alignment: .leading, spacing: 6) {
                Text("VOICE PROFILE NAME")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                
                TextField("e.g. Aria - Natural Conversational", text: Bindable(vm).profileName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(14)
        }
    }
    
    private func recordSection(vm: CreateVoiceViewModel) -> some View {
        GlassCard(
            cornerRadius: DesignTokens.Radii.large,
            specularIntensity: vm.isRecording ? 0.6 : 0.25,
            glowColor: vm.isRecording ? DesignTokens.Colors.acousticCyan : nil
        ) {
            VStack(spacing: 16) {
                Text(vm.isRecording ? "Listening & Capturing Reference..." : "Record 5–15 Seconds of Clean Speech")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                DynamicWaveformView(
                    level: vm.currentRMSLevel,
                    barCount: 30,
                    isLive: vm.isRecording
                )
                
                if vm.isRecording {
                    LiquidGlassButton(
                        title: "Stop Recording",
                        systemImage: "stop.fill",
                        style: .destructive,
                        action: {
                            Task {
                                await vm.stopRecording()
                            }
                        }
                    )
                } else {
                    LiquidGlassButton(
                        title: vm.isAudioReady ? "Re-record Sample" : "Start Recording",
                        systemImage: "mic.fill",
                        style: .primary,
                        action: {
                            Task {
                                await vm.startRecording()
                            }
                        }
                    )
                }
            }
            .padding(18)
        }
    }
    
    private func importSection(vm: CreateVoiceViewModel) -> some View {
        GlassCard(cornerRadius: DesignTokens.Radii.large) {
            VStack(spacing: 16) {
                Image(systemName: "folder.badge.waveform")
                    .font(.system(size: 40))
                    .foregroundColor(DesignTokens.Colors.acousticCyan)
                
                VStack(spacing: 4) {
                    Text("Select Audio from Files")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    
                    Text("Supports WAV, M4A, FLAC, and MP3 (recommended 5–15 seconds of clean speech).")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                LiquidGlassButton(
                    title: "Browse Files",
                    systemImage: "doc.badge.plus",
                    style: .secondary,
                    action: {
                        isFileImporterPresented = true
                    }
                )
            }
            .padding(20)
        }
    }
    
    private func previewSection(audioURL: URL, vm: CreateVoiceViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("REFERENCE AUDIO PREVIEW")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            AudioPlayerView(
                audioURL: audioURL,
                voiceName: vm.profileName.isEmpty ? "Reference Sample" : vm.profileName,
                modelIdentifier: "Input: \(vm.audioFormatInfo)"
            )
            
            HStack(spacing: 16) {
                Label(String(format: "%.1f seconds", vm.audioDuration), systemImage: "clock")
                Label(String(format: "%.1f KB", Double(vm.audioFileSize) / 1024.0), systemImage: "internaldrive")
            }
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
        }
    }
    
    private func consentSection(vm: CreateVoiceViewModel) -> some View {
        GlassCard(cornerRadius: DesignTokens.Radii.medium) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(DesignTokens.Colors.acousticCyan)
                    Text("Verified Voice Consent")
                        .font(.system(size: 14, weight: .bold))
                }
                
                Text("By enabling this profile, you declare under penalty of perjury that you are the biological owner of this voice or hold express legal power of attorney to reproduce it.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
                
                Toggle(isOn: Bindable(vm).hasUserConsent) {
                    Text("I confirm ownership and consent to voice cloning.")
                        .font(.system(size: 13, weight: .semibold))
                }
                .tint(DesignTokens.Colors.acousticCyan)
            }
            .padding(14)
        }
    }
}
