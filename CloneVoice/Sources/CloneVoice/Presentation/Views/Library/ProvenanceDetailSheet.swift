import SwiftUI

/// Details inspector for C2PA Content Credentials cryptographic metadata.
public struct ProvenanceDetailSheet: View {
    var manifest: C2PAManifest
    @Environment(\.dismiss) private var dismiss
    
    public init(manifest: C2PAManifest) {
        self.manifest = manifest
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassMeshGlow(energy: 0.05)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Provenance Seal
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.acousticEmerald.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 40))
                                .foregroundColor(DesignTokens.Colors.acousticEmerald)
                        }
                        .padding(.top, 16)
                        
                        Text("Verified Content Credentials")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        
                        Text("This audio file contains cryptographic metadata certifying its algorithmic generation in compliance with C2PA synthetic media standards.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Metadata Table
                        GlassCard(cornerRadius: DesignTokens.Radii.large) {
                            VStack(spacing: 14) {
                                metadataRow(title: "Claim Generator", value: manifest.claimGenerator)
                                Divider()
                                metadataRow(title: "Inference Engine", value: manifest.engine)
                                Divider()
                                metadataRow(title: "Audio Format", value: manifest.format)
                                Divider()
                                metadataRow(title: "Timestamp", value: manifest.generatedAt.formatted(date: .abbreviated, time: .standard))
                                Divider()
                                metadataRow(title: "Digital Source", value: "Trained Algorithmic Media")
                                Divider()
                                metadataRow(title: "Profile Hash", value: String(manifest.voiceProfileHash.prefix(16)) + "...")
                                Divider()
                                metadataRow(title: "Watermark Status", value: manifest.watermarked ? "Active (Inaudible)" : "Disabled")
                            }
                            .padding(16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Provenance Inspector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                }
            }
        }
    }
    
    private func metadataRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}
