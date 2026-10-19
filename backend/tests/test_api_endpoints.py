import sys
import os
import io
import json
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.main import app

def test_api_root_endpoint():
    print("[TEST] Testing GET / endpoint...")
    with TestClient(app) as client:
        response = client.get("/")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        data = response.json()
        assert data["status"] == "online"
        assert "docs_url" in data
        assert data.get("web_ui") == "/index/clonevoice"
        print("  -> Passed root endpoint test.")

def test_api_clonevoice_web_interface():
    print("[TEST] Testing GET /index/clonevoice web interface...")
    with TestClient(app) as client:
        response = client.get("/index/clonevoice")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        assert "text/html" in response.headers.get("content-type", "")
        assert "Clone Voice" in response.text
        assert "VoxCPM2" in response.text
        assert "synthesis-text" in response.text
        print("  -> Passed clonevoice web interface test.")

def test_api_health_endpoint():
    print("[TEST] Testing GET /v1/health endpoint...")
    with TestClient(app) as client:
        response = client.get("/v1/health")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        data = response.json()
        assert data["status"] == "ready"
        assert "engine" in data
        assert "vram_available_gb" in data
        print("  -> Passed health check endpoint test.")

def test_api_synthesis_stream_endpoint():
    print("[TEST] Testing POST /v1/synthesis/stream endpoint...")
    with TestClient(app) as client:
        # Construct synthetic WAV audio buffer
        fake_wav = b"RIFF\x24\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x80>\x00\x00\x00}\x00\x00\x02\x00\x10\x00data\x00\x00\x00\x00"
        files = {
            "reference_audio": ("ref.wav", io.BytesIO(fake_wav), "audio/wav")
        }
        data = {
            "text": "Testing API speech streaming with Clone Voice.",
            "settings": json.dumps({
                "cfg_value": 2.0,
                "inference_timesteps": 10,
                "denoise": True,
                "zero_retention": True
            })
        }
        headers = {
            "X-App-Attest-Assertion": "valid-simulated-app-attest-assertion-token-12345"
        }
        
        response = client.post("/v1/synthesis/stream", data=data, files=files, headers=headers)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        assert response.headers.get("content-type") == "audio/wav"
        assert response.headers.get("x-zero-retention-enforced") == "true"
        assert len(response.content) > 0
        print(f"  -> Passed speech synthesis stream test (received {len(response.content)} bytes).")

def test_api_validation_errors():
    print("[TEST] Testing API validation and unauthorized rejection...")
    with TestClient(app) as client:
        # Missing required text field
        response = client.post("/v1/synthesis/stream")
        assert response.status_code == 422, f"Expected 422, got {response.status_code}"
        
        # Invalid App Attest assertion (too short)
        fake_wav = b"RIFF\x24\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x80>\x00\x00\x00}\x00\x00\x02\x00\x10\x00data\x00\x00\x00\x00"
        files = {"reference_audio": ("ref.wav", io.BytesIO(fake_wav), "audio/wav")}
        data = {"text": "Hello"}
        headers = {"X-App-Attest-Assertion": "short"}
        
        bad_response = client.post("/v1/synthesis/stream", data=data, files=files, headers=headers)
        assert bad_response.status_code == 401, f"Expected 401 for bad attest, got {bad_response.status_code}"
        print("  -> Passed validation error handling tests.")

if __name__ == "__main__":
    test_api_health_endpoint()
    test_api_synthesis_stream_endpoint()
    test_api_validation_errors()
    print("\n[SUCCESS] ALL API ENDPOINT TESTS PASSED SUCCESSFULLY!")
