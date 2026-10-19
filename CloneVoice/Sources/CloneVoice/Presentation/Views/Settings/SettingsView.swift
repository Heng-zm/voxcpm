import SwiftUI

/// Settings and diagnostics for backend inference connection, zero-retention, and security.
public struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env
    
    @State private var backendURLString: String = "https://voxcpm-xsp6.onrender.com"
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
                
                // Execution Target Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("SYNTHESIS HARDWARE TARGET")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Picker("Target", selection: Bindable(env).executionTarget) {
                        ForEach(InferenceExecutionTarget.allCases) { target in
                            Text(target.rawValue).tag(target)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: env.executionTarget) { _, _ in
                        Task {
                            await checkHealth()
                        }
                    }
                }
                
                if env.executionTarget == .onDeviceGPU {
                    HStack(spacing: 10) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 20))
                            .foregroundColor(DesignTokens.Colors.acousticCyan)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Running on Device GPU (\(env.onDeviceService.deviceName))")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("100% On-Device execution. Audio never leaves your iPhone.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignTokens.Colors.acousticCyan.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(DesignTokens.Colors.acousticCyan.opacity(0.25), lineWidth: 1)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("REMOTE API ENDPOINT")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("https://voxcpm-xsp6.onrender.com", text: $backendURLString)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14, design: .monospaced))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .onSubmit {
                                    updateEndpoint()
                                }
                            
                            Button("Update") {
                                updateEndpoint()
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(DesignTokens.Colors.acousticCyan)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
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
            VStack(spacing: 8) {
                Text("Clone Voice")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0") (Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "6")) • Production")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(DesignTokens.Colors.acousticCyan)
                
                Text("Engineered with Swift 6, On-Device Metal GPU, and Apple Privacy Manifest compliance.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
        }
    }
    
    private func updateEndpoint() {
        let trimmed = backendURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let formatted = (trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")) ? trimmed : "https://\(trimmed)"
        if let url = URL(string: formatted) {
            backendURLString = formatted
            env.inferenceClient.baseURL = url
            UserDefaults.standard.set(formatted, forKey: "custom_backend_url")
            Task {
                await checkHealth()
            }
        }
    }
    
    private func checkHealth() async {
        isCheckingHealth = true
        if env.executionTarget == .remoteCloud {
            let trimmed = backendURLString.trimmingCharacters(in: .whitespacesAndNewlines)
            let formatted = (trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")) ? trimmed : "https://\(trimmed)"
            if let url = URL(string: formatted), url != env.inferenceClient.baseURL {
                env.inferenceClient.baseURL = url
                UserDefaults.standard.set(formatted, forKey: "custom_backend_url")
            }
        }
        do {
            backendStatus = try await env.activeInferenceService.checkHealth()
        } catch {
            backendStatus = .offline(reason: error.localizedDescription)
        }
        isCheckingHealth = false
    }
}
