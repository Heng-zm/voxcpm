import sys
import os
import asyncio

# Add backend directory to python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.c2pa_signer import C2PASigner
from app.security import compute_acoustic_hash, secure_ephemeral_wipe
from app.voxcpm_engine import VoxCPMEngine

def test_c2pa_signing():
    print("[TEST] Testing C2PA manifest creation & injection...")
    manifest = C2PASigner.create_manifest("UnitTest Title", "hash-1234")
    assert b"UnitTest Title" in manifest
    assert b"OpenBMB/VoxCPM2" in manifest
    
    # Construct minimal WAV
    riff_header = b"RIFF\x24\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x80>\x00\x00\x00}\x00\x00\x02\x00\x10\x00data\x00\x00\x00\x00"
    signed_wav = C2PASigner.inject_c2pa(riff_header, manifest)
    assert b"c2pa" in signed_wav
    print("  -> Passed C2PA signing test.")

def test_security_hash_and_wipe():
    print("[TEST] Testing security hashing and memory wipe...")
    data = b"Sample acoustic voice data 48000hz"
    voice_hash = compute_acoustic_hash(data)
    assert len(voice_hash) == 64
    
    buf = bytearray(b"sensitive-voice-bytes")
    secure_ephemeral_wipe(buf)
    assert all(b == 0 for b in buf)
    print("  -> Passed Security hash and zero-wipe test.")

async def test_streaming_engine():
    print("[TEST] Testing VoxCPMEngine chunked speech streaming...")
    engine = VoxCPMEngine(device="cpu")
    status = engine.get_status()
    assert status["status"] == "ready"
    
    chunks = []
    async for chunk in engine.stream_cloned_speech(
        text="Hello world from Clone Voice test suite.",
        reference_audio_bytes=b"dummy-ref-audio"
    ):
        chunks.append(chunk)
        if len(chunks) >= 3:
            break
            
    assert len(chunks) >= 3
    assert len(chunks[0]) > 0
    print(f"  -> Successfully streamed {len(chunks)} audio chunks (chunk size: {len(chunks[0])} bytes).")

if __name__ == "__main__":
    test_c2pa_signing()
    test_security_hash_and_wipe()
    asyncio.run(test_streaming_engine())
    print("\n[SUCCESS] ALL BACKEND CORE VERIFICATION TESTS PASSED SUCCESSFULLY!")
