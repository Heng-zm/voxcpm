import SwiftUI

/// Coordinates the full 3-tier enrollment flow sheet.
public struct EnrollmentFlowCoordinator: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    
    var onFinished: () -> Void
    @State private var viewModel: EnrollmentViewModel?
    
    public init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }
    
    public var body: some View {
        ZStack {
            LiquidGlassMeshGlow(energy: 0.15)
            
            if let vm = viewModel {
                switch vm.currentStep {
                case .consentAgreement:
                    ConsentAgreementView(
                        profileName: Bindable(vm).profileName,
                        onAccept: {
                            vm.currentStep = .liveRecording
                        },
                        onCancel: {
                            dismiss()
                        }
                    )
                case .liveRecording:
                    VoiceRecordingStudioView(
                        viewModel: vm,
                        onCompleteRecording: {
                            vm.currentStep = .biometricSign
                        },
                        onBack: {
                            vm.currentStep = .consentAgreement
                        }
                    )
                case .biometricSign:
                    biometricSignStepView(vm: vm)
                case .completed:
                    completionStepView(vm: vm)
                }
            } else {
                ProgressView()
            }
        }
        .task {
            if viewModel == nil {
                viewModel = EnrollmentViewModel(
                    audioEngine: env.audioEngine,
                    repository: env.profileRepository,
                    biometricAuth: env.biometricAuth
                )
            }
        }
    }
    
    private func biometricSignStepView(vm: EnrollmentViewModel) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "faceid")
                .font(.system(size: 64))
                .foregroundColor(DesignTokens.Colors.acousticCyan)
            
            VStack(spacing: 8) {
                Text("Biometric Signature Required")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                
                Text("Authenticate with Face ID to sign the cryptographic consent contract and lock your voice profile.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            GlassCard(cornerRadius: DesignTokens.Radii.medium) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.acousticEmerald)
                    Text("Sample verified (\(String(format: "%.1f", vm.recordedDuration))s at 48kHz)")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                }
                .padding(14)
            }
            .padding(.horizontal, 24)
            
            if let error = vm.errorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.destructiveRed)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            LiquidGlassButton(
                title: "Sign with Face ID & Save",
                systemImage: "lock.shield.fill",
                style: .primary,
                isLoading: vm.isProcessing,
                action: {
                    Task {
                        let success = await vm.completeEnrollment()
                        if success {
                            HapticFeedback.success()
                        }
                    }
                }
            )
            .padding(24)
        }
    }
    
    private func completionStepView(vm: EnrollmentViewModel) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.acousticEmerald.opacity(0.2))
                    .frame(width: 96, height: 96)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.acousticEmerald)
            }
            
            VStack(spacing: 8) {
                Text("Voice Enrolled Successfully")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text("'\(vm.profileName)' is encrypted and ready for speech generation with VoxCPM2.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            LiquidGlassButton(
                title: "Open Voice Studio",
                systemImage: "sparkles",
                style: .primary,
                action: {
                    onFinished()
                    dismiss()
                }
            )
            .padding(24)
        }
    }
}
