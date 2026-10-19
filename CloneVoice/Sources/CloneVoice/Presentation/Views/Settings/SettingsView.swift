import SwiftUI

/// Settings and diagnostics for backend inference connection, zero-retention, and security.
public struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env
    
    @State private var backendURLString: String = "http://127.0.0.1:8000"
    @State private var backendStatus: BackendStatus = .offline(reason: "Not checked")
    @State private var isCheckingHealth = false
    @State private var purgeConfirmation = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassMeshGlow(energy: 0.05)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Backend Connection Card
                        backendConfigSection
                        
                        // Hardware & Security Card
                        securitySection
                        
                        // Ephemeral Zero-Retention & Privacy Card
                        privacySection
                        
                        // About Section
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                backendURLString = env.inferenceClient.baseURL.absoluteString
                await checkHealth()
            }
        }
    }
    
    private var backendConfigSection: some View {
        GlassCard(cornerRadius: DesignTokens.Radii.large) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Inference Backend", systemImage: "server.rack")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    
                    Spacer()
                    
                    statusIndicator
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("API ENDPOINT")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("https://voxcpm-xsp6.onrender.com", text: $backendURLString)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, design: .monospaced))
                        
                        Button("Update") {
                            if let url = URL(string: backendURLString) {
                                env.inferenceClient.baseURL = url
                                UserDefaults.standard.set(backendURLString, forKey: "custom_backend_url")
                                Task {
                                    await checkHealth()
                                }
                            }
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(DesignTokens.Colors.acousticCyan)
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: {
                    Task {
                        await checkHealth()
                    }
                }) {
                    HStack {
                        if isCheckingHealth {
                            ProgressView()
                                .tint(DesignTokens.Colors.acousticCyan)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Test Connection & GPU VRAM")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .padding(16)
        }
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        switch backendStatus {
        case .ready(let gpu, let vram):
            HStack(spacing: 5) {
                Circle().fill(DesignTokens.Colors.acousticEmerald).frame(width: 8, height: 8)
                Text("\(gpu) (\(String(format: "%.0f", vram))GB)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.acousticEmerald)
            }
        case .busy(let queue):
            HStack(spacing: 5) {
                Circle().fill(DesignTokens.Colors.warningAmber).frame(width: 8, height: 8)
                Text("Busy (Queue: \(queue))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.warningAmber)
            }
        case .offline(let reason):
            HStack(spacing: 5) {
                Circle().fill(DesignTokens.Colors.destructiveRed).frame(width: 8, height: 8)
                Text(reason.prefix(18))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.destructiveRed)
            }
        }
    }
    
    private var securitySection: some View {
        GlassCard(cornerRadius: DesignTokens.Radii.large) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Security & Biometrics", systemImage: "lock.shield.fill")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                
                HStack {
                    Text("Apple Secure Enclave")
                        .font(.system(size: 13))
                    Spacer()
                    Text("Hardware Enabled")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.acousticEmerald)
                }
                
                Divider()
                
                HStack {
                    Text("Apple App Attest")
                        .font(.system(size: 13))
                    Spacer()
                    Text(AppAttestManager.shared.isSupported ? "Supported" : "Simulated")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                HStack {
                    Text("C2PA Cryptographic Signature")
                        .font(.system(size: 13))
                    Spacer()
                    Text("SHA-256 Manifests")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.acousticCyan)
                }
            }
            .padding(16)
        }
    }
    
    private var privacySection: some View {
        GlassCard(cornerRadius: DesignTokens.Radii.large) {
            VStack(alignment: .leading, spacing: 14) {
                Label("Zero-Retention Privacy", systemImage: "hand.raised.fill")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                
                Text("Clone Voice processes inference ephemerally. Reference samples sent to the backend are held strictly in GPU RAM and scrubbed immediately after latent extraction.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Button(action: {
                    EphemeralStorageCleaner.shared.clearTemporaryDirectory()
                    purgeConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash.slash.fill")
                        Text(purgeConfirmation ? "Local Cache Scrubbed ✓" : "Scrub Local Temporary Audio Now")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(purgeConfirmation ? DesignTokens.Colors.acousticEmerald : DesignTokens.Colors.destructiveRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .padding(16)
        }
    }
    
    private var aboutSection: some View {
        GlassCard(cornerRadius: DesignTokens.Radii.large) {
            VStack(spacing: 6) {
                Text("Clone Voice — Native iOS 26.0+")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                
                Text("Engineered with Swift 6, SwiftUI Liquid Glass, and OpenBMB VoxCPM2.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
        }
    }
    
    private func checkHealth() async {
        isCheckingHealth = true
        do {
            backendStatus = try await env.inferenceClient.checkHealth()
        } catch {
            backendStatus = .offline(reason: error.localizedDescription)
        }
        isCheckingHealth = false
    }
}
