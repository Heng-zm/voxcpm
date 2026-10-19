import SwiftUI

/// Badge signifying verified C2PA Content Credentials provenance.
public struct C2PAProvenanceBadge: View {
    var hasProvenance: Bool
    
    public init(hasProvenance: Bool = true) {
        self.hasProvenance = hasProvenance
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 11, weight: .semibold))
            
            Text("C2PA Certified")
                .font(.system(size: 11, weight: .medium, design: .rounded))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(DesignTokens.Colors.acousticEmerald.opacity(0.15))
        .foregroundColor(DesignTokens.Colors.acousticEmerald)
        .clipShape(Capsule())
    }
}
