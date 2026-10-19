import SwiftUI

/// Generation history view displaying verified past speech syntheses with playback and regenerate actions.
public struct HistoryView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    
    @State private var viewModel: HistoryViewModel?
    @State private var isClearConfirmationPresented = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassMeshGlow(energy: 0.05)
                
                ScrollView {
                    VStack(spacing: 16) {
                        if let vm = viewModel {
                            if vm.isLoading {
                                ProgressView()
                                    .padding(.top, 40)
                            } else if vm.utterances.isEmpty {
                                emptyHistoryView
                            } else {
                                ForEach(vm.utterances) { utterance in
                                    historyCard(utterance, vm: vm)
                                }
                            }
                            
                            if let error = vm.errorMessage {
                                Text(error)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(DesignTokens.Colors.destructiveRed)
                                    .padding()
                            }
                        } else {
                            ProgressView()
                                .padding(.top, 40)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let vm = viewModel, !vm.utterances.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All") {
                            isClearConfirmationPresented = true
                        }
                        .font(.system(size: 14))
                        .foregroundColor(DesignTokens.Colors.destructiveRed)
                    }
                }
            }
            .task {
                if viewModel == nil {
                    viewModel = HistoryViewModel(repository: env.utteranceRepository)
                }
                await viewModel?.loadHistory()
            }
            .confirmationDialog(
                "Clear History",
                isPresented: $isClearConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Delete All History Records", role: .destructive) {
                    Task {
                        await viewModel?.clearAllHistory()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes all previously synthesized audio files from your device.")
            }
        }
    }
    
    private var emptyHistoryView: some View {
        GlassCard(cornerRadius: DesignTokens.Radii.large) {
            VStack(spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 44))
                    .foregroundColor(DesignTokens.Colors.acousticCyan)
                
                Text("No Generation History")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                Text("Synthesized speech from your conversations and voice studio will be archived here.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(28)
        }
        .padding(.top, 40)
    }
    
    private func historyCard(_ utterance: GeneratedUtterance, vm: HistoryViewModel) -> some View {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = docs.appendingPathComponent(utterance.audioFilename)
        
        return GlassCard(cornerRadius: DesignTokens.Radii.medium) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with profile name and timestamp
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(utterance.profileName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(DesignTokens.Colors.acousticCyan)
                        
                        Text(utterance.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Model badge
                    Text(utterance.modelIdentifier)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.secondary)
                        .clipShape(Capsule())
                }
                
                // Original Text
                Text(utterance.text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.primary)
                
                // Reusable Native Audio Player
                if FileManager.default.fileExists(atPath: audioURL.path) {
                    AudioPlayerView(
                        audioURL: audioURL,
                        voiceName: utterance.profileName,
                        modelIdentifier: utterance.modelIdentifier
                    )
                }
                
                // Bottom Action Bar
                HStack {
                    // Regenerate Action: reloads text and voice into studio
                    Button(action: {
                        router.activeProfileForSynthesis = VoiceProfile(
                            id: utterance.profileId,
                            name: utterance.profileName,
                            referenceAudioFilename: "",
                            sampleDuration: 0,
                            acousticFeaturesHash: ""
                        )
                        router.selectedTab = .synthesis
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Regenerate")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.acousticCyan)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await vm.deleteUtterance(utterance)
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
            .padding(14)
        }
    }
}
