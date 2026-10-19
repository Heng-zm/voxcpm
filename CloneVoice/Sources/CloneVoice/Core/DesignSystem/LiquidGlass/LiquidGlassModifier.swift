import SwiftUI

/// Core Liquid Glass material modifier with dynamic specular refraction and accessibility fallback.
public struct LiquidGlassModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme
    
    var cornerRadius: CGFloat
    var specularIntensity: Double
    var interactiveGlow: Color?
    
    public init(
        cornerRadius: CGFloat = DesignTokens.Radii.large,
        specularIntensity: Double = 0.4,
        interactiveGlow: Color? = nil
    ) {
        self.cornerRadius = cornerRadius
        self.specularIntensity = specularIntensity
        self.interactiveGlow = interactiveGlow
    }
    
    public func body(content: Content) -> some View {
        content
            .background {
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(colorScheme == .dark ? Color(white: 0.14) : Color(white: 0.94))
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                        }
                } else {
                    ZStack {
                        // Base optical glass material
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                        
                        // Optional reactive acoustic glow under glass
                        if let glow = interactiveGlow {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(glow.opacity(colorScheme == .dark ? 0.16 : 0.22))
                                .blur(radius: 12)
                        }
                        
                        // Internal specular gradient reflection
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.10 : 0.30),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // External specular rim stroke
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(specularIntensity),
                                        Color.white.opacity(0.08),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    }
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.06),
                        radius: 18,
                        x: 0,
                        y: 10
                    )
                }
            }
    }
}

public extension View {
    func liquidGlass(
        cornerRadius: CGFloat = DesignTokens.Radii.large,
        specularIntensity: Double = 0.4,
        interactiveGlow: Color? = nil
    ) -> some View {
        modifier(
            LiquidGlassModifier(
                cornerRadius: cornerRadius,
                specularIntensity: specularIntensity,
                interactiveGlow: interactiveGlow
            )
        )
    }
}
