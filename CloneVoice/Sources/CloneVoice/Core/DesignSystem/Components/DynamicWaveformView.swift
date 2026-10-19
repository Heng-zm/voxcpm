import SwiftUI

/// Real-time audio waveform visualizer reactive to RMS input levels.
public struct DynamicWaveformView: View {
    var level: Float
    var barCount: Int
    var isLive: Bool
    
    @State private var phase: Double = 0
    
    public init(level: Float, barCount: Int = 28, isLive: Bool = true) {
        self.level = level
        self.barCount = barCount
        self.isLive = isLive
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                let normalizedIndex = Double(index) / Double(barCount)
                let height = calculateHeight(for: normalizedIndex)
                
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignTokens.Colors.acousticCyan,
                                DesignTokens.Colors.acousticIndigo,
                                DesignTokens.Colors.acousticViolet
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: height)
                    .animation(DesignTokens.Animations.snappySpring, value: height)
            }
        }
        .frame(height: 72)
        .padding(.vertical, 8)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }
    
    private func calculateHeight(for normalizedIndex: Double) -> CGFloat {
        let centerDistance = abs(normalizedIndex - 0.5) * 2.0 // 0 at center, 1 at edges
        let bellCurve = max(0.2, 1.0 - pow(centerDistance, 2))
        
        if isLive && level > 0.01 {
            let variance = sin((normalizedIndex + phase) * .pi * 4) * 0.25
            let dynamicScale = CGFloat(level) + CGFloat(variance)
            return max(8, min(64, dynamicScale * 56 * CGFloat(bellCurve)))
        } else {
            // Resting subtle breathing wave
            let idle = sin(normalizedIndex * .pi * 2 + phase * .pi * 2) * 6
            return max(8, 14 + CGFloat(idle) * CGFloat(bellCurve))
        }
    }
}
