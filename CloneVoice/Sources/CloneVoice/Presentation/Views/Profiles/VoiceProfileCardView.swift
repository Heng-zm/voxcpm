import SwiftUI

/// Profile card utilizing Liquid Glass materials and concentric continuous rounded styling.
public struct VoiceProfileCardView: View {
    var profile: VoiceProfile
    var isSelected: Bool
    var onSelectForSynthesis: () -> Void
    var onDelete: () -> Void
    
    public init(
        profile: VoiceProfile,
        isSelected: Bool,
        onSelectForSynthesis: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.profile = profile
        self.isSelected = isSelected
        self.onSelectForSynthesis = onSelectForSynthesis
        self.onDelete = onDelete
    }
    
    public var body: some View {
        GlassCard(
            cornerRadius: DesignTokens.Radii.large,
            specularIntensity: isSelected ? 0.6 : 0.25,
            glowColor: isSelected ? DesignTokens.Colors.acousticCyan : nil
        ) {
            VStack(alignment: .leading, spacing: 16) {
                // Header row
                HStack {
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
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "waveform")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Enrolled \(profile.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    BiometricLockBadge(isLocked: profile.isBiometricLocked)
                }
                
                // Audio stats bar
                HStack(spacing: 20) {
                    Label(
                        String(format: "%.1fs Sample", profile.sampleDuration),
                        systemImage: "mic.fill"
                    )
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    
                    Label(
                        "48 kHz Studio",
                        systemImage: "sparkles"
                    )
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                }
                
                Divider()
                    .overlay(Color.white.opacity(0.15))
                
                // Action Buttons
                HStack(spacing: 12) {
                    LiquidGlassButton(
                        title: "Synthesize",
                        systemImage: "waveform.badge.mic",
                        style: .primary,
                        action: onSelectForSynthesis
                    )
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.destructiveRed)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.medium))
                    }
                }
            }
            .padding(20)
        }
    }
}
