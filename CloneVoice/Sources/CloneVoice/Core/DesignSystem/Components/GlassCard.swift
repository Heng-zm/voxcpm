import SwiftUI

/// Versatile card container adhering to the Liquid Glass Design System.
public struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat
    var specularIntensity: Double
    var glowColor: Color?
    @ViewBuilder var content: () -> Content
    
    public init(
        cornerRadius: CGFloat = DesignTokens.Radii.large,
        specularIntensity: Double = 0.35,
        glowColor: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.specularIntensity = specularIntensity
        self.glowColor = glowColor
        self.content = content
    }
    
    public var body: some View {
        content()
            .liquidGlass(
                cornerRadius: cornerRadius,
                specularIntensity: specularIntensity,
                interactiveGlow: glowColor
            )
    }
}
