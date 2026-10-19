import SwiftUI

/// Status badge displaying biometric protection status (Face ID / Secure Enclave).
public struct BiometricLockBadge: View {
    var isLocked: Bool
    
    public init(isLocked: Bool) {
        self.isLocked = isLocked
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: isLocked ? "faceid" : "lock.open")
                .font(.system(size: 11, weight: .semibold))
            
            Text(isLocked ? "Face ID Protected" : "Unlocked")
                .font(.system(size: 11, weight: .medium, design: .rounded))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            isLocked
                ? DesignTokens.Colors.acousticCyan.opacity(0.15)
                : Color.secondary.opacity(0.12)
        )
        .foregroundColor(
            isLocked ? DesignTokens.Colors.acousticCyan : Color.secondary
        )
        .clipShape(Capsule())
    }
}
