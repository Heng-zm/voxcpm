import SwiftUI

/// Tier 2: Live randomized verification script recording with real-time waveform visualizer.
public struct VoiceRecordingStudioView: View {
    @Bindable var viewModel: EnrollmentViewModel
    var onCompleteRecording: () -> Void
    var onBack: () -> Void
    
    public init(
        viewModel: EnrollmentViewModel,
        onCompleteRecording: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onCompleteRecording = onCompleteRecording
        self.onBack = onBack
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                Spacer()
                Text("Verification Studio")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Image(systemName: "waveform")
                    .foregroundColor(DesignTokens.Colors.acousticCyan)
            }
            .padding(.top, 16)
            
            // Instruction
            Text("Read the randomized verification script aloud clearly in a quiet environment:")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Randomized verification prompt card
            GlassCard(
                cornerRadius: DesignTokens.Radii.large,
                specularIntensity: viewModel.isRecording ? 0.6 : 0.3,
                glowColor: viewModel.isRecording ? DesignTokens.Colors.acousticCyan : nil
            ) {
                VStack(spacing: 16) {
                    Text("LIVE VERIFICATION PHRASE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(DesignTokens.Colors.acousticCyan)
                    
                    Text("\"\(viewModel.verificationPhrase)\"")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(20)
            }
            
            // Real-time audio waveform visualizer
            GlassCard(cornerRadius: DesignTokens.Radii.medium) {
                VStack(spacing: 8) {
                    DynamicWaveformView(
                        level: viewModel.currentRMSLevel,
                        barCount: 32,
                        isLive: viewModel.isRecording
                    )
                    
                    Text(
                        viewModel.isRecording
                            ? "Recording in progress (48kHz Studio)..."
                            : "Microphone idle. Tap button below to begin."
                    )
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                }
                .padding(14)
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.destructiveRed)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Big Record Action Button
            if viewModel.isRecording {
                LiquidGlassButton(
                    title: "Stop Recording",
                    systemImage: "stop.circle.fill",
                    style: .destructive,
                    action: {
                        Task {
                            await viewModel.stopLiveRecording()
                            if viewModel.recordedDuration >= 5.0 {
                                onCompleteRecording()
                            }
                        }
                    }
                )
            } else {
                LiquidGlassButton(
                    title: "Start Recording Verification",
                    systemImage: "mic.circle.fill",
                    style: .primary,
                    action: {
                        Task {
                            await viewModel.startLiveRecording()
                        }
                    }
                )
            }
        }
        .padding(24)
    }
}
