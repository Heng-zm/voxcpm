import SwiftUI

/// Main voice profiles gallery view with fluid Liquid Glass styling and gesture navigation.
public struct VoiceDeckView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    @State private var viewModel: VoiceDeckViewModel?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Reactive Liquid Glass ambient background
                LiquidGlassMeshGlow(energy: 0.1)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Bar
                        headerSection
                        
                        if let vm = viewModel {
                            if vm.isLoading {
                                ProgressView()
                                    .padding(.top, 60)
                            } else if vm.profiles.isEmpty {
                                emptyStateView
                            } else {
                                profilesListView(vm: vm)
                            }
                            
                            if let error = vm.errorMessage {
                                Text(error)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(DesignTokens.Colors.destructiveRed)
                                    .padding()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Voice Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        router.isEnrollmentPresented = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(DesignTokens.Colors.acousticCyan)
                    }
                }
            }
            .task {
                if viewModel == nil {
                    viewModel = VoiceDeckViewModel(
                        repository: env.profileRepository,
                        biometricAuth: env.biometricAuth
                    )
                }
                await viewModel?.loadProfiles()
            }
            .sheet(isPresented: Bindable(router).isEnrollmentPresented) {
                EnrollmentFlowCoordinator(onFinished: {
                    Task {
                        await viewModel?.loadProfiles()
                    }
                })
            }
        }
    }
    
    private var headerSection: some View {
        GlassCard(cornerRadius: DesignTokens.Radii.large, specularIntensity: 0.4) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Liquid Voice Cloning")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DesignTokens.Colors.acousticCyan, DesignTokens.Colors.acousticIndigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Spacer()
                    Image(systemName: "sparkles")
                        .foregroundColor(DesignTokens.Colors.acousticCyan)
                }
                
                Text("Select an authenticated voice profile or enroll a new voice with verifiable biometric consent.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .padding(16)
        }
    }
    
    private var emptyStateView: some View {
        GlassCard(cornerRadius: DesignTokens.Radii.large) {
            VStack(spacing: 20) {
                Image(systemName: "mic.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(DesignTokens.Colors.acousticCyan)
                
                VStack(spacing: 8) {
                    Text("No Voice Profiles Enrolled")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    
                    Text("Create your first digital voice profile with 3-tier consent and biometric hardware protection.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                LiquidGlassButton(
                    title: "Enroll New Voice",
                    systemImage: "waveform.circle.fill",
                    action: {
                        router.isEnrollmentPresented = true
                    }
                )
            }
            .padding(32)
        }
        .padding(.top, 40)
    }
    
    private func profilesListView(vm: VoiceDeckViewModel) -> some View {
        LazyVStack(spacing: 16) {
            ForEach(vm.profiles) { profile in
                VoiceProfileCardView(
                    profile: profile,
                    isSelected: router.activeProfileForSynthesis?.id == profile.id,
                    onSelectForSynthesis: {
                        Task {
                            let authorized = await vm.authorizeProfileAccess(profile: profile)
                            if authorized {
                                router.activeProfileForSynthesis = profile
                                router.selectedTab = .synthesis
                            }
                        }
                    },
                    onDelete: {
                        Task {
                            await vm.deleteProfile(profile)
                        }
                    }
                )
            }
        }
    }
}
