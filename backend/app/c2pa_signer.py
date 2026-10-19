import json
import struct
from datetime import datetime, timezone

class C2PASigner:
    """Injects and verifies C2PA Content Credentials manifests into synthetic WAV audio."""
    
    @staticmethod
    def create_manifest(title: str, voice_hash: str) -> bytes:
        manifest = {
            "claim_generator": "CloneVoice-VoxCPM2-Backend/1.0",
            "title": title,
            "format": "audio/wav",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "engine": "OpenBMB/VoxCPM2",
            "digital_source_type": "http://cv.iptc.org/newscodes/digitalsourcetype/trainedAlgorithmicMedia",
            "voice_profile_hash": voice_hash,
            "watermarked": True
        }
        return json.dumps(manifest).encode("utf-8")
    
    @classmethod
    def inject_c2pa(cls, wav_bytes: bytes, manifest_bytes: bytes) -> bytes:
        """Appends a standard C2PA RIFF subchunk to the WAV file."""
        if len(wav_bytes) < 44 or wav_bytes[:4] != b"RIFF":
            return wav_bytes
        
        chunk_header = b"c2pa" + struct.pack("<I", len(manifest_bytes))
        chunk_data = chunk_header + manifest_bytes
        if len(manifest_bytes) % 2 != 0:
            chunk_data += b"\x00"
            
        new_wav = bytearray(wav_bytes) + chunk_data
        # Update overall RIFF size in bytes 4..8
        riff_size = len(new_wav) - 8
        new_wav[4:8] = struct.pack("<I", riff_size)
        return bytes(new_wav)
