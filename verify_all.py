import os
import sys
import subprocess

def run_step(step_name, command):
    print(f"\n==================================================")
    print(f"RUNNING: {step_name}")
    print(f"==================================================")
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print(result.stderr)
    if result.returncode != 0:
        print(f"[FAIL] {step_name} failed with exit code {result.returncode}")
        return False
    print(f"[PASS] {step_name} succeeded.")
    return True

def verify_file_presence():
    print(f"\n==================================================")
    print(f"CHECKING PROJECT FILE ARCHITECTURE")
    print(f"==================================================")
    required_files = [
        "CloneVoice/Package.swift",
        "CloneVoice/Sources/CloneVoice/App/CloneVoiceApp.swift",
        "CloneVoice/Sources/CloneVoice/App/AppEnvironment.swift",
        "CloneVoice/Sources/CloneVoice/Domain/Models/VoiceProfile.swift",
        "CloneVoice/Sources/CloneVoice/Domain/Models/GeneratedUtterance.swift",
        "CloneVoice/Sources/CloneVoice/Domain/Models/SynthesisSettings.swift",
        "CloneVoice/Sources/CloneVoice/Domain/Models/ConsentContract.swift",
        "CloneVoice/Sources/CloneVoice/Data/Persistence/SwiftDataContainer.swift",
        "CloneVoice/Sources/CloneVoice/Core/Audio/AudioEngineActor.swift",
        "CloneVoice/Sources/CloneVoice/Core/Audio/AudioStreamPlayer.swift",
        "CloneVoice/Sources/CloneVoice/Core/Audio/AudioConverter.swift",
        "CloneVoice/Sources/CloneVoice/Core/DesignSystem/LiquidGlass/LiquidGlassModifier.swift",
        "CloneVoice/Sources/CloneVoice/Core/DesignSystem/Components/DynamicWaveformView.swift",
        "CloneVoice/Sources/CloneVoice/Features/Home/HomeConversationView.swift",
        "CloneVoice/Sources/CloneVoice/Features/VoiceLibrary/VoiceLibraryView.swift",
        "CloneVoice/Sources/CloneVoice/Features/CreateVoice/CreateVoiceSheet.swift",
        "CloneVoice/Sources/CloneVoice/Features/AudioPlayer/AudioPlayerView.swift",
        "CloneVoice/Sources/CloneVoice/Features/History/HistoryView.swift",
        "backend/app/main.py",
        "backend/app/voxcpm_engine.py",
        "backend/app/c2pa_signer.py",
        "backend/app/security.py",
        "backend/Dockerfile",
        "backend/docker-compose.yml",
        "backend/tests/test_backend_core.py",
        "backend/tests/test_khmer_speech.py"
    ]
    
    missing = []
    for f in required_files:
        if not os.path.exists(f):
            missing.append(f)
            print(f"  [X] Missing: {f}")
        else:
            print(f"  [+] Found: {f}")
            
    if missing:
        print(f"\n[FAIL] Missing {len(missing)} required files.")
        return False
        
    print(f"\n[PASS] All {len(required_files)} architectural components verified present.")
    return True

if __name__ == "__main__":
    success = True
    if not verify_file_presence():
        success = False
        
    if not run_step("GitHub Actions Workflows Syntax & Security Validation", f"{sys.executable} validate_workflows.py"):
        success = False
        
    if not run_step("Backend Core Suite (C2PA, Security, Engine)", f"{sys.executable} backend/tests/test_backend_core.py"):
        success = False
        
    if not run_step("Backend API Endpoints & Validation Suite", f"{sys.executable} backend/tests/test_api_endpoints.py"):
        success = False
        
    if not run_step("Explicit Khmer Speech & RTF Quality Suite", f"{sys.executable} backend/tests/test_khmer_speech.py"):
        success = False
        
    if success:
        print("\n[SUCCESS] ALL ARCHITECTURAL AND INFERENCE VERIFICATIONS PASSED SUCCESSFULLY!")
        sys.exit(0)
    else:
        print("\n[FAIL] VERIFICATION ENCOUNTERED FAILURES.")
        sys.exit(1)
