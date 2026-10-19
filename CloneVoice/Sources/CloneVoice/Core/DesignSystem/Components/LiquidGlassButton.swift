import SwiftUI

/// Tactile, specular interactive button designed for the Liquid Glass Design System.
public struct LiquidGlassButton: View {
    public enum Style {
        case primary
        case secondary
        case destructive
    }
    
    var title: String
    var systemImage: String?
    var style: Style
    var isLoading: Bool
    var action: () -> Void
    
    @State private var isPressed = false
    
    public init(
        title: String,
        systemImage: String? = nil,
        style: Style = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else if let image = systemImage {
                    Image(systemName: image)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radii.medium, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(DesignTokens.Animations.snappySpring, value: isPressed)
        }
        .buttonStyle(PressDetectingButtonStyle(isPressed: $isPressed))
        .disabled(isLoading)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [
                    DesignTokens.Colors.acousticCyan.opacity(0.85),
                    DesignTokens.Colors.acousticIndigo.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            Color.white.opacity(0.12)
        case .destructive:
            DesignTokens.Colors.destructiveRed.opacity(0.85)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .primary
        }
    }
}

private struct PressDetectingButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}
