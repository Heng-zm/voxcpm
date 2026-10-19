import SwiftUI

/// Conversational home screen inspired by ChatGPT iOS app's minimal simplicity.
/// Features a message feed with inline audio players and a floating Liquid Glass composer.
public struct HomeConversationView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    
    @State private var viewModel: HomeViewModel?
    @State private var isVoicePickerPresented = false
    @State private var isAudioImporterPresented = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassMeshGlow(energy: 0.05)
                
                VStack(spacing: 0) {
                    // Top Bar: Voice Selector Pill & New Generation
                    topActionBar
                    
                    // Main Scrollable Conversation Feed
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 16) {
                                if let vm = viewModel {
                                    if vm.conversation.isEmpty {
                                        emptyStateView
                                    } else {
                                        ForEach(vm.conversation) { item in
                                            conversationBubble(item: item)
                                                .id(item.id)
                                        }
                                    }
                                } else {
                                    ProgressView()
                                        .padding(.top, 60)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 120) // Space for floating composer
                        }
                        .onChange(of: viewModel?.conversation.count) { _, _ in
                            if let lastId = viewModel?.conversation.last?.id {
                                withAnimation {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                // Floating Liquid Glass Composer (Anchored to bottom)
                VStack {
                    Spacer()
                    floatingComposer
                }
            }
            .navigationTitle("Clone Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        viewModel?.startNewGeneration()
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.acousticCyan)
                    }
                }
            }
            .task {
                if viewModel == nil {
                    viewModel = HomeViewModel(
                        inferenceClient: env.inferenceClient,
                        profileRepository: env.profileRepository,
                        utteranceRepository: env.utteranceRepository,
                        watermarkService: env.watermarkService,
                        biometricAuth: env.biometricAuth
                    )
                }
                await viewModel?.loadInitialData()
            }
            .sheet(isPresented: $isVoicePickerPresented) {
                voiceSelectorSheet
            }
            .fileImporter(
                isPresented: $isAudioImporterPresented,
                allowedContentTypes: [.audio, .wav, .mp3],
                allowsMultipleSelection: false
            ) { result in
                // Routes directly to voice enrollment
                router.isEnrollmentPresented = true
            }
        }
    }
    
    // MARK: - Top Action Bar
    private var topActionBar: some View {
        HStack {
            Button(action: {
                isVoicePickerPresented = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "person.wave.2.fill")
                        .font(.system(size: 12, weight: .bold))
                    
                    Text(viewModel?.selectedProfile?.name ?? "Select Voice")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .foregroundColor(.primary)
                .clipShape(Capsule())
                .overlay {
                    Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                }
            }
            
            Spacer()
            
            if let profile = viewModel?.selectedProfile {
                BiometricLockBadge(isLocked: profile.isBiometricLocked)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty State (Section C.1)
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 80)
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignTokens.Colors.acousticCyan.opacity(0.25),
                                DesignTokens.Colors.acousticIndigo.opacity(0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "waveform")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignTokens.Colors.acousticCyan, DesignTokens.Colors.acousticIndigo],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("Give your words a voice.")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                
                Text("Create a voice profile, enter your text, and generate speech with your chosen voice.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            if viewModel?.availableProfiles.isEmpty ?? true {
                Button(action: {
                    router.isEnrollmentPresented = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Voice Profile")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignTokens.Colors.acousticCyan)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(20)
    }
    
    // MARK: - Conversational Message Bubble
    private func conversationBubble(item: ConversationItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Text Message Bubble (Aligned Right)
            HStack {
                Spacer(minLength: 40)
                
                Text(item.text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [
                                DesignTokens.Colors.acousticCyan.opacity(0.85),
                                DesignTokens.Colors.acousticIndigo.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            
            // Generated Voice Audio Response Bubble (Aligned Left)
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "waveform.circle.fill")
                            .foregroundColor(DesignTokens.Colors.acousticCyan)
                        Text(item.profile.name)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        
                        Spacer()
                        
                        Text(item.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    if item.isGenerating {
                        HStack(spacing: 10) {
                            ProgressView()
                                .tint(DesignTokens.Colors.acousticCyan)
                            Text("VoxCPM2 is synthesizing audio...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.acousticCyan)
                        }
                        .padding(.vertical, 6)
                    } else if let error = item.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DesignTokens.Colors.destructiveRed)
                            Text(error)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.destructiveRed)
                        }
                    } else if let utterance = item.utterance {
                        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let audioURL = docs.appendingPathComponent(utterance.audioFilename)
                        
                        if FileManager.default.fileExists(atPath: audioURL.path) {
                            AudioPlayerView(
                                audioURL: audioURL,
                                voiceName: utterance.profileName,
                                modelIdentifier: utterance.modelIdentifier
                            )
                        }
                    }
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                }
                
                Spacer(minLength: 40)
            }
        }
    }
    
    // MARK: - Floating Liquid Glass Composer (Section B & C.1)
    private var floatingComposer: some View {
        GlassCard(cornerRadius: 24, specularIntensity: 0.5) {
            VStack(spacing: 8) {
                if let vm = viewModel, let error = vm.errorMessage {
                    HStack {
                        Text(error)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.destructiveRed)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
                
                HStack(alignment: .bottom, spacing: 10) {
                    // Audio Import Action
                    Button(action: {
                        isAudioImporterPresented = true
                    }) {
                        Image(systemName: "waveform.badge.mic")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 38, height: 38)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    
                    // Multiline Text Input
                    if let vm = viewModel {
                        TextField("Type words to clone into speech...", text: Bindable(vm).composerDraftText, axis: .vertical)
                            .lineLimit(1...5)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // Generate Action Button
                    Button(action: {
                        Task {
                            await viewModel?.generateSpeech()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            DesignTokens.Colors.acousticCyan,
                                            DesignTokens.Colors.acousticIndigo
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 38, height: 38)
                            
                            if viewModel?.isGenerating ?? false {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled((viewModel?.isGenerating ?? false) || (viewModel?.composerDraftText.trimmingCharacters(in: .whitespaces).isEmpty ?? true))
                    .opacity((viewModel?.composerDraftText.trimmingCharacters(in: .whitespaces).isEmpty ?? true) ? 0.4 : 1.0)
                }
            }
            .padding(10)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }
    
    // MARK: - Voice Selector Sheet
    private var voiceSelectorSheet: some View {
        NavigationStack {
            List {
                if let vm = viewModel {
                    ForEach(vm.availableProfiles) { profile in
                        Button(action: {
                            vm.selectedProfile = profile
                            isVoicePickerPresented = false
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(profile.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Text(String(format: "%.1fs reference sample", profile.sampleDuration))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if vm.selectedProfile?.id == profile.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignTokens.Colors.acousticCyan)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        isVoicePickerPresented = false
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        isVoicePickerPresented = false
                        router.isEnrollmentPresented = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
