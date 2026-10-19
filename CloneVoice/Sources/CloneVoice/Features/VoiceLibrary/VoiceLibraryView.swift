import SwiftUI

/// Voice Library screen displaying verified profiles, audio previews, search, sorting, and management.
public struct VoiceLibraryView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    
    @State private var viewModel: VoiceLibraryViewModel?
    @State private var isCreateVoicePresented = false
    @State private var isRenameAlertPresented = false
    @State private var profileToRename: VoiceProfile?
    @State private var renameText = ""
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassMeshGlow(energy: 0.05)
                
                ScrollView {
                    VStack(spacing: 16) {
                        if let vm = viewModel {
                            // Search and Sort Bar
                            searchAndSortBar(vm: vm)
                            
                            if vm.isLoading {
                                ProgressView()
                                    .padding(.top, 40)
                            } else if vm.filteredProfiles.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(vm.filteredProfiles) { profile in
                                    profileRow(profile, vm: vm)
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
            .navigationTitle("Voice Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isCreateVoicePresented = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(DesignTokens.Colors.acousticCyan)
                    }
                }
            }
            .task {
                if viewModel == nil {
                    viewModel = VoiceLibraryViewModel(repository: env.profileRepository)
                }
                await viewModel?.loadProfiles()
            }
            .sheet(isPresented: $isCreateVoicePresented) {
                CreateVoiceSheet(onCreated: {
                    Task {
                        await viewModel?.loadProfiles()
                    }
                })
            }
            .alert("Rename Voice Profile", isPresented: $isRenameAlertPresented) {
                TextField("New profile name", text: $renameText)
                Button("Save") {
                    if let target = profileToRename {
                        Task {
                            await viewModel?.renameProfile(target, newName: renameText)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    private func searchAndSortBar(vm: VoiceLibraryViewModel) -> some View {
        HStack(spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search profiles...", text: Bindable(vm).searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                
                if !vm.searchQuery.isEmpty {
                    Button(action: { vm.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Menu {
                ForEach(ProfileSortOption.allCases) { option in
                    Button(action: { vm.sortOption = option }) {
                        HStack {
                            Text(option.rawValue)
                            if vm.sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .font(.system(size: 20))
                    .foregroundColor(DesignTokens.Colors.acousticCyan)
            }
        }
        .padding(.top, 4)
    }
    
    private var emptyStateView: some View {
        GlassCard(cornerRadius: DesignTokens.Radii.large) {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 44))
                    .foregroundColor(DesignTokens.Colors.acousticCyan)
                
                Text("No Voice Profiles")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                Text("Record or import an authorized voice sample to begin generating speech with VoxCPM2.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                LiquidGlassButton(
                    title: "Create Profile",
                    systemImage: "waveform.badge.plus",
                    action: {
                        isCreateVoicePresented = true
                    }
                )
            }
            .padding(28)
        }
        .padding(.top, 30)
    }
    
    private func profileRow(_ profile: VoiceProfile, vm: VoiceLibraryViewModel) -> some View {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = docs.appendingPathComponent(profile.referenceAudioFilename)
        
        return GlassCard(cornerRadius: DesignTokens.Radii.medium) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(profile.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        
                        Text("Enrolled \(profile.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            profileToRename = profile
                            renameText = profile.name
                            isRenameAlertPresented = true
                        }) {
                            Label("Rename", systemImage: "pencil")
                        }
                        
                        Button(action: {
                            router.activeProfileForSynthesis = profile
                            router.selectedTab = .synthesis
                        }) {
                            Label("Use in Studio", systemImage: "waveform.badge.mic")
                        }
                        
                        Button(role: .destructive, action: {
                            Task {
                                await vm.deleteProfile(profile)
                            }
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Verified Metadata (Strictly factual - no fabricated similarity scores!)
                HStack(spacing: 16) {
                    Label(String(format: "%.1fs duration", profile.sampleDuration), systemImage: "clock")
                    Label("48kHz Linear PCM", systemImage: "waveform")
                    BiometricLockBadge(isLocked: profile.isBiometricLocked)
                }
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                
                // Reference Audio Preview Player
                if FileManager.default.fileExists(atPath: audioURL.path) {
                    AudioPlayerView(
                        audioURL: audioURL,
                        voiceName: "Reference: \(profile.name)",
                        modelIdentifier: "Acoustic Sample"
                    )
                }
            }
            .padding(14)
        }
    }
}
