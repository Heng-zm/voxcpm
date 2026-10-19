import SwiftUI

/// Core design tokens defining colors, radii, shadows, and animation physics for Liquid Glass.
public enum DesignTokens {
    
    public enum Colors {
        public static let glassTintDark = Color(red: 0.08, green: 0.10, blue: 0.14)
        public static let glassTintLight = Color(red: 0.96, green: 0.97, blue: 0.99)
        
        public static let acousticCyan = Color(red: 0.0, green: 0.85, blue: 1.0)
        public static let acousticIndigo = Color(red: 0.38, green: 0.28, blue: 0.98)
        public static let acousticViolet = Color(red: 0.70, green: 0.20, blue: 0.95)
        public static let acousticEmerald = Color(red: 0.10, green: 0.88, blue: 0.60)
        
        public static let rimSpecularLight = Color.white.opacity(0.45)
        public static let rimSpecularDark = Color.white.opacity(0.18)
        
        public static let destructiveRed = Color(red: 1.0, green: 0.25, blue: 0.28)
        public static let warningAmber = Color(red: 1.0, green: 0.75, blue: 0.15)
    }
    
    public enum Radii {
        public static let small: CGFloat = 12
        public static let medium: CGFloat = 20
        public static let large: CGFloat = 28
        public static let capsule: CGFloat = 999
    }
    
    public enum Animations {
        public static let fluidSpring = Animation.spring(response: 0.42, dampingFraction: 0.82, blendDuration: 0.1)
        public static let snappySpring = Animation.spring(response: 0.28, dampingFraction: 0.75)
        public static let pulse = Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)
    }
}
