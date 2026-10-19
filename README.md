# Clone Voice (iOS 26.0+)
**Native Voice Cloning Application powered by Swift 6, SwiftUI Liquid Glass, and OpenBMB VoxCPM2**

[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![iOS 26.0+](https://img.shields.io/badge/iOS-26.0+-blue.svg)](https://developer.apple.com/ios/)
[![Design System](https://img.shields.io/badge/Design-Apple%20Liquid%20Glass-purple.svg)](https://developer.apple.com/design/)
[![Model](https://img.shields.io/badge/Model-OpenBMB%20VoxCPM2%20(2B)-green.svg)](https://github.com/OpenBMB/VoxCPM)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

---

## 1. Overview & Architectural Philosophy

**Clone Voice** is a native iOS application engineered to clone personalized human voices and synthesize expressive speech using OpenBMB's **VoxCPM2** continuous diffusion-autoregressive foundation model. 

Designed for iOS 26.0+ using **Swift 6 strict concurrency**, the user interface is crafted in Apple's native **Liquid Glass Design System**—a tactile, optical design language pairing real-time chromatic refraction, specular edge lighting, fluid spring gestures, and acoustic-reactive background luminescence.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Clone Voice Architecture                        │
├──────────────────────────────────┬─────────────────────────────────────┤
│        Native iOS Client         │        VoxCPM2 Inference Node       │
│  • Swift 6 Strict Concurrency    │  • Containerized PyTorch & CUDA     │
│  • Liquid Glass Design System    │  • 2B Diffusion-Autoregressive Prior│
│  • AVAudioEngine 48kHz Capture   │  • 48kHz AudioVAE Vocoder / Denoiser│
│  • SwiftData Persistence         │  • HTTP/3 & Chunked Audio Streaming │
│  • 3-Tier Biometric Consent      │  • Ephemeral Zero-Data Retention    │
│  • C2PA Provenance Verification  │  • Cryptographic C2PA Manifests     │
└──────────────────────────────────┴─────────────────────────────────────┘
```

---

## 2. Key Capabilities & System Features

### 🎙️ Studio-Grade 48kHz Audio Pipeline
- Actor-isolated capture with `AVAudioEngine`, recording 48kHz / 16-bit PCM Linear audio.
- Real-time RMS decibel metering streaming via `AsyncStream<Float>` to drive interactive Liquid Glass audio visualizers.
- Seamless chunked streaming audio playback using `AVAudioPlayerNode` for low-latency speech output.

### 💎 Apple Liquid Glass Design System
- Multi-tier optical materials combining `.ultraThinMaterial` with specular reflection rims.
- Dynamic background luminescence (`LiquidGlassMeshGlow`) that breathes and pulses with acoustic speech energy.
- Concentric rounded capsule geometry with continuous curvature (`.continuous`).
- Full automatic accessibility adaptation:
  - Respects `accessibilityReduceTransparency` by substituting frosted glass with solid contrast backdrops.
  - Respects `accessibilityReduceMotion` by disengaging fluid light tracking.

### 🔒 3-Tier Ethical Consent & App Store Compliance
To satisfy App Store Review Guidelines **5.1.1** (Privacy) and **5.2** (Intellectual Property & Deepfake Protection):
1. **Tier 1 (Explicit Legal Consent):** In-app binding agreement disallowing third-party unauthorized cloning.
2. **Tier 2 (Live Dynamic Liveness Verification):** The user must read aloud a randomized verification script containing a timestamp and unique session code.
3. **Tier 3 (Hardware Biometric Lock):** The profile is locked with Apple's **Secure Enclave** (Face ID / Touch ID). No speech generation can occur without biometric authentication.
4. **C2PA Content Credentials:** All generated audio containers embed immutable C2PA cryptographic manifests proving synthetic algorithmic origin.

### 🛡️ Zero-Data Retention Private Inference
- Ephemeral in-memory inference pipeline.
- Reference audio samples uploaded to the GPU inference gateway are retained strictly in RAM and overwritten immediately after latent feature extraction.
- Client-side one-tap local temporary audio scrubber (`EphemeralStorageCleaner`).

---

## 3. Directory Layout

```
.
├── CloneVoice/                         # Native Swift 6 iOS Application
│   ├── Package.swift                   # Swift Package manifest with strict concurrency
│   ├── Sources/CloneVoice/
│   │   ├── App/                        # CloneVoiceApp, AppEnvironment
│   │   ├── Domain/                     # Models, Protocols & Repositories
│   │   │   ├── Models/                 # VoiceProfile, GeneratedUtterance, ConsentContract
│   │   │   └── Services/               # VoiceInference, AudioEngine, BiometricAuth
│   │   ├── Data/                       # Persistence & Networking
│   │   │   ├── Persistence/            # SwiftData schemas & actor repositories
│   │   │   ├── Keychain/               # SecureStorageService (Secure Enclave)
│   │   │   └── Network/                # VoxCPMInferenceClient (HTTP/3 streaming)
│   │   ├── Core/                       # Audio, Security & Design System
│   │   │   ├── Audio/                  # AudioEngineActor, AudioStreamPlayer, AudioConverter
│   │   │   ├── Security/               # BiometricAuthService, C2PAWatermarkService
│   │   │   └── DesignSystem/           # Liquid Glass modifiers, mesh glow, buttons, cards
│   │   └── Presentation/               # SwiftUI Views & ViewModels
│   │       ├── Views/Profiles/         # VoiceDeckView, VoiceProfileCardView
│   │       ├── Views/Enrollment/       # ConsentAgreementView, VoiceRecordingStudioView
│   │       ├── Views/Synthesis/        # SpeechGenerationStudioView, SettingsSheet
│   │       ├── Views/Library/          # UtteranceLibraryView, ProvenanceDetailSheet
│   │       └── Views/Settings/         # SettingsView (Diagnostics & Health)
│   └── Tests/CloneVoiceTests/          # Swift Testing Suites (@Suite, @Test)
├── backend/                            # VoxCPM2 Inference Gateway
│   ├── app/
│   │   ├── main.py                     # FastAPI server with chunked audio streaming
│   │   ├── voxcpm_engine.py            # OpenBMB VoxCPM2 model wrapper & streaming
│   │   ├── c2pa_signer.py              # C2PA manifest builder and injector
│   │   ├── security.py                 # Zero-retention memory wiper & App Attest
│   │   └── config.py                   # Environment settings
│   ├── tests/                          # Backend unit test suite
│   ├── requirements.txt                # Python dependencies
│   ├── Dockerfile                      # Containerized CUDA inference image
│   └── docker-compose.yml              # Multi-GPU orchestrator
└── README.md
```

---

## 4. Setup & Running Guide

### 4.1 Running the VoxCPM2 Inference Backend

#### Quick Start with Local Python:
```bash
cd backend
pip install -r requirements.txt
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

#### Running with Docker & NVIDIA GPU:
```bash
cd backend
docker compose up --build
```
The gateway will start listening on `http://127.0.0.1:8000`. You can inspect the interactive OpenAPI documentation at `http://127.0.0.1:8000/docs` and monitor GPU VRAM via `http://127.0.0.1:8000/v1/health`.

### 4.2 Building the iOS Application in Xcode 26

1. Open Xcode 26.
2. Select **File > Open** and choose the `CloneVoice` folder.
3. Configure your Development Team under **Signing & Capabilities**.
4. Enable required entitlements:
   - **Microphone Access** (`NSMicrophoneUsageDescription`: *"Clone Voice requires microphone access to record clean reference voice samples for authorized voice cloning."*)
   - **Face ID** (`NSFaceIDUsageDescription`: *"Clone Voice requires Face ID to authorize and unlock your enrolled voice profile."*)
5. Select an iOS 26.0+ Simulator or tethered iPhone / iPad device.
6. Press **⌘ + R** to run.

---

## 5. Verification & Testing

### Running Swift Unit Tests
From Xcode, press **⌘ + U**, or via command line:
```bash
swift test --package-path CloneVoice
```
Tests validate:
- Decibel RMS normalization and 44-byte WAV RIFF packaging.
- Bounds clamping and roundtrip JSON encoding for `SynthesisSettings`.
- C2PA manifest creation, binary injection, and extraction.
- SwiftData entity conversions and domain model integrity.

### Running Full Local Verification Suite
```bash
python verify_all.py
```
Executes:
1. File architecture presence validation
2. GitHub Actions YAML syntax and security validation
3. Backend core suite (C2PA signing, security memory wipe, streaming)
4. FastAPI endpoints and validation suite
5. Explicit Khmer speech quality and RTF benchmark

---

## 6. GitHub Actions — CI/CD Automation

Clone Voice includes fully verified GitHub Actions workflows located in `.github/workflows/`:

| Workflow File | Purpose | Runner | Triggers |
| :--- | :--- | :--- | :--- |
| [`.github/workflows/build-iphone-ipa.yml`](.github/workflows/build-iphone-ipa.yml) | **Build & export real iPhone `.ipa` package (`generic/platform=iOS`)** | `macos-15` | `workflow_dispatch`, `push` on tags `v*` |
| [`.github/workflows/ios-ci.yml`](.github/workflows/ios-ci.yml) | iOS 26+ / Swift 6 build & automated test execution | `macos-15` | `push` to `main`, `pull_request` to `main`, `workflow_dispatch` |
| [`.github/workflows/backend-ci.yml`](.github/workflows/backend-ci.yml) | Python 3.12 syntax, API validation, C2PA, and Khmer tests | `ubuntu-latest` | `push` on `backend/**`, `pull_request` on `backend/**`, `workflow_dispatch` |
| [`.github/workflows/release.yml`](.github/workflows/release.yml) | Production release packaging & code signing | `macos-15` | `push` on tags `v*`, `workflow_dispatch` |

### 6.1 Building & Downloading an iPhone IPA for Physical Devices
The workflow [`.github/workflows/build-iphone-ipa.yml`](.github/workflows/build-iphone-ipa.yml) archives the Clone Voice app for a real generic iOS device destination (`generic/platform=iOS`) and exports a verified `.ipa` package.

#### How to Trigger the Workflow:
1. Navigate to the **Actions** tab in your GitHub repository.
2. Select **Build and Export iPhone IPA** from the left sidebar.
3. Click **Run workflow**:
   - **Apple Distribution Method:** Choose `development` (for your registered test iPhone), `ad-hoc`, `app-store`, or `enterprise`.
   - **Build Configuration:** Choose `Release` (recommended) or `Debug`.
4. Click **Run workflow**.

#### Where to Download the Resulting Artifact:
1. When the run finishes, click on the completed workflow run.
2. Scroll down to the **Artifacts** section at the bottom.
3. Download **`CloneVoice-iOS-IPA`**, which contains:
   - `CloneVoice-iphone.ipa` (when signing credentials are configured)
   - Build and codesign verification logs (`codesign-verification.log`, `archive.log`, `export.log`)
   - `SIGNING_DIAGNOSTICS.txt` (when credentials are unconfigured, detailing missing secrets).

#### How to Install on a Physical iPhone:
- **For Development / Ad Hoc IPAs:**
  1. Ensure your iPhone's UDID is registered under **Devices** in your Apple Developer account and included in your Provisioning Profile.
  2. Connect your iPhone via USB or Wi-Fi to a Mac.
  3. Install via **Apple Configurator** (*drag and drop the `.ipa` onto your device*), via **Xcode > Window > Devices and Simulators** (*drag onto Installed Apps*), or via compatible enterprise MDM/sideloading tools.
- **For App Store / TestFlight IPAs:**
  - Distribute via Apple App Store Connect / TestFlight.

### 6.2 Code Signing Secrets Configuration
To enable signed `.ipa` generation, configure these secrets under **Settings > Secrets and variables > Actions**:

| Secret Name | Description | Example Format |
| :--- | :--- | :--- |
| `IOS_CERTIFICATE_BASE64` | Apple iOS Developer/Distribution Certificate (.p12) in Base64 | `base64 -i Certificate.p12` |
| `IOS_CERTIFICATE_PASSWORD` | Password protecting the exported .p12 certificate file | Plaintext string |
| `IOS_PROVISIONING_PROFILE_BASE64` | iOS Provisioning Profile (.mobileprovision) in Base64 | `base64 -i Profile.mobileprovision` |
| `APPLE_TEAM_ID` | 10-character Apple Developer Team ID | e.g. `2X9R4274ND` |
| `IOS_BUNDLE_IDENTIFIER` | App bundle identifier (defaults to `com.clonevoice.app`) | `com.clonevoice.app` |
| `IOS_KEYCHAIN_PASSWORD` | (Optional) Password for ephemeral build keychain | `secure_keychain_pass_123` |

> [!IMPORTANT]
> **Handling Missing Credentials:** If signing secrets are not yet configured in your repository, the workflow executes project and scheme compilation for a real iOS device, generates `CloneVoice-unsigned.zip`, and attaches a detailed `SIGNING_DIAGNOSTICS.txt` report explaining precisely how to obtain and add the missing certificates. It **never** labels an unsigned archive as an installable signed IPA.

### 6.3 Local Workflow & Architecture Validation
Validate all GitHub Actions YAML configurations and test suites locally:
```bash
python verify_all.py
```

---

## 7. Troubleshooting & FAQ

- **Backend Memory Limits (Jetsam):** On consumer iOS hardware, genuine on-device execution of the 2B parameter VoxCPM2 model triggers Jetsam terminations. The app routes inference through the private backend gateway to safeguard responsiveness and battery health.
- **Microphone Permissions:** If audio capture fails on the simulator, ensure permissions are granted in iOS Settings or test on physical hardware.
- **Khmer Font & Script Handling:** For optimal syllable boundary rendering in Khmer, ensure the target system includes system font support for complex Unicode grapheme clusters.
- **IPA Installation Fails (A/B testing):** If an exported Development IPA fails to install on an iPhone, verify that the device UDID is included in the provisioning profile by checking:
  `security cms -D -i profile.mobileprovision | grep -A 20 ProvisionedDevices`

---

## 8. Open Source License

- **Clone Voice iOS Client:** MIT License.
- **VoxCPM2 Model Weights & Architecture:** Apache-2.0 License by OpenBMB (Permits commercial and private deployment).
