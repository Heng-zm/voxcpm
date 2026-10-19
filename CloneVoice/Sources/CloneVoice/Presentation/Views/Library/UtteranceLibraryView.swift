import SwiftUI

/// Library view displaying previously synthesized voice utterances with playback and provenance inspect.
public struct UtteranceLibraryView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: LibraryViewModel?
    @State private var inspectedManifest: C2PAManifest?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassMeshGlow(energy: viewModel?.currentPlaybackLevel ?? 0.05)
                
                ScrollView {
                    VStack(spacing: 16) {
                        if let vm = viewModel {
                            if vm.utterances.isEmpty {
                                emptyLibraryView
                            } else {
                                ForEach(vm.utterances) { utterance in
                                    utteranceRow(utterance, vm: vm)
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
            .navigationTitle("Generated Library")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel == nil {
                    viewModel = LibraryViewModel(
                        repository: env.utteranceRepository,
                        streamPlayer: env.streamPlayer,
                        watermarkService: env.watermarkService
                    )
                }
                await viewModel?.loadUtterances()
            }
            .sheet(item: $inspectedManifest) { manifest in
                ProvenanceDetailSheet(manifest: manifest)
            }
        }
    }
    
    private var emptyLibraryView: some View {
        GlassCard(cornerRadius: DesignTokens.Radii.large) {
            VStack(spacing: 16) {
                Image(systemName: "waveform.badge.magnifyingglass")
                    .font(.system(size: 44))
                    .foregroundColor(DesignTokens.Colors.acousticCyan)
                
                Text("No Synthesized Audio Yet")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                Text("Generate speech in the Voice Studio to build your personal voice generation library.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
        .padding(.top, 40)
    }
    
    private func utteranceRow(_ utterance: GeneratedUtterance, vm: LibraryViewModel) -> some View {
        let isCurrent = vm.currentlyPlayingId == utterance.id && vm.isPlaying
        
        return GlassCard(
            cornerRadius: DesignTokens.Radii.medium,
            specularIntensity: isCurrent ? 0.6 : 0.25,
            glowColor: isCurrent ? DesignTokens.Colors.acousticCyan : nil
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with profile name and timestamp
                HStack {
                    Text(utterance.profileName)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(DesignTokens.Colors.acousticCyan)
                    
                    Spacer()
                    
                    Text(utterance.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Utterance text
                Text(utterance.text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                
                // Footer row with playback, duration, and provenance button
                HStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await vm.playUtterance(utterance)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isCurrent ? "pause.fill" : "play.fill")
                                .font(.system(size: 13, weight: .bold))
                            
                            Text(isCurrent ? "Playing" : "Play")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(DesignTokens.Colors.acousticCyan.opacity(0.2))
                        .foregroundColor(DesignTokens.Colors.acousticCyan)
                        .clipShape(Capsule())
                    }
                    
                    Text(String(format: "%.1fs", utterance.duration))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        vm.inspectProvenance(for: utterance)
                        if let manifest = vm.inspectedProvenance {
                            self.inspectedManifest = manifest
                        }
                    }) {
                        C2PAProvenanceBadge(hasProvenance: true)
                    }
                    
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
            }
            .padding(14)
        }
    }
}

extension C2PAManifest: Identifiable {
    public var id: String { voiceProfileHash + generatedAt.description }
}
