import SwiftUI

/// Dynamic background mesh that animates and responds to acoustic energy.
public struct LiquidGlassMeshGlow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    
    var energy: Float
    
    public init(energy: Float = 0.0) {
        self.energy = energy
    }
    
    public var body: some View {
        ZStack {
            // Base background
            (colorScheme == .dark ? Color.black : Color(white: 0.98))
                .ignoresSafeArea()
            
            // Floating ambient luminescent orbs
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                let scale = reduceMotion ? CGFloat(1.0) : CGFloat(1.0 + energy * 0.45)
                
                ZStack {
                    // Cyan top-left orb
                    Circle()
                        .fill(DesignTokens.Colors.acousticCyan.opacity(colorScheme == .dark ? 0.25 : 0.20))
                        .frame(width: width * 0.75, height: width * 0.75)
                        .blur(radius: 60)
                        .offset(x: -width * 0.2, y: -height * 0.15)
                        .scaleEffect(scale)
                    
                    // Indigo center orb
                    Circle()
                        .fill(DesignTokens.Colors.acousticIndigo.opacity(colorScheme == .dark ? 0.30 : 0.18))
                        .frame(width: width * 0.85, height: width * 0.85)
                        .blur(radius: 80)
                        .offset(x: width * 0.15, y: height * 0.2)
                        .scaleEffect(scale * 0.9)
                    
                    // Violet bottom-right accent orb
                    Circle()
                        .fill(DesignTokens.Colors.acousticViolet.opacity(colorScheme == .dark ? 0.22 : 0.14))
                        .frame(width: width * 0.65, height: width * 0.65)
                        .blur(radius: 70)
                        .offset(x: width * 0.25, y: height * 0.45)
                }
                .compositingGroup()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}
