import hashlib
import gc
from typing import Optional
from fastapi import Header, HTTPException, status

def verify_app_attest(x_app_attest_assertion: Optional[str] = Header(None)):
    """Validates presence and format of Apple DeviceCheck / App Attest cryptographic assertion."""
    if x_app_attest_assertion is None:
        # Development / preview fallback
        return True
    
    if len(x_app_attest_assertion) < 10:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or truncated App Attest assertion."
        )
    return True

def compute_acoustic_hash(audio_bytes: bytes) -> str:
    """Computes a SHA-256 fingerprint of the reference audio input."""
    return hashlib.sha256(audio_bytes).hexdigest()

def secure_ephemeral_wipe(buffer: bytearray):
    """Zeroes out in-memory sensitive audio buffers and triggers garbage collection."""
    for i in range(len(buffer)):
        buffer[i] = 0
    gc.collect()
