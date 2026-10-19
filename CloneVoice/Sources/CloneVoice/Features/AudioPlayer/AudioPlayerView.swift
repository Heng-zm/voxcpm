import SwiftUI

/// Reusable native audio player view with scrubbing, duration display, and export actions.
public struct AudioPlayerView: View {
    var audioURL: URL
    var voiceName: String
    var modelIdentifier: String
    
    @State private var viewModel = AudioPlayerViewModel()
    @State private var isSharePresented = false
    @State private var isSeeking = false
    @State private var seekProgress: Double = 0.0
    
    public init(
        audioURL: URL,
        voiceName: String,
        modelIdentifier: String = "OpenBMB/VoxCPM2"
    ) {
        self.audioURL = audioURL
        self.voiceName = voiceName
        self.modelIdentifier = modelIdentifier
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Header Info Row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(voiceName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(modelIdentifier)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Share & Export Button
                Button(action: {
                    isSharePresented = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.acousticCyan)
                        .padding(8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
            
            // Scrubbing Progress Slider
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { isSeeking ? seekProgress : viewModel.progress },
                        set: { newValue in
                            seekProgress = newValue
                            isSeeking = true
                        }
                    ),
                    in: 0.0...1.0,
                    onEditingChanged: { editing in
                        if !editing {
                            viewModel.seek(to: seekProgress)
                            isSeeking = false
                        }
                    }
                )
                .tint(DesignTokens.Colors.acousticCyan)
                
                // Timestamp Row
                HStack {
                    Text(formatTime(isSeeking ? seekProgress * viewModel.duration : viewModel.currentTime))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTime(viewModel.duration, isDuration: true))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            // Error feedback if loading failed
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.destructiveRed)
                    .multilineTextAlignment(.center)
            }
            
            // Play / Pause Control
            Button(action: {
                HapticFeedback.light()
                viewModel.togglePlayPause()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                    
                    Text(viewModel.isPlaying ? "Pause" : "Play")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(DesignTokens.Colors.acousticCyan.opacity(0.18))
                .foregroundColor(DesignTokens.Colors.acousticCyan)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.small, style: .continuous))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radii.medium, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radii.medium, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                }
        )
        .onAppear {
            viewModel.loadAudio(from: audioURL)
        }
        .onDisappear {
            viewModel.stop()
        }
        .onChange(of: audioURL) { _, newURL in
            viewModel.loadAudio(from: newURL)
        }
        #if canImport(UIKit)
        .sheet(isPresented: $isSharePresented) {
            ShareSheet(activityItems: [audioURL])
        }
        #endif
    }
    
    private func formatTime(_ time: TimeInterval, isDuration: Bool = false) -> String {
        guard !time.isNaN && !time.isInfinite && time > 0 else { return "0:00" }
        let totalSeconds = isDuration ? max(1, Int(round(time))) : Int(max(0, time))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
