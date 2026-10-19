import os
from pydantic import BaseModel

class Settings(BaseModel):
    app_name: str = "VoxCPM2 Private Inference Gateway"
    version: str = "1.0.0"
    model_name: str = os.getenv("VOXCPM_MODEL_NAME", "openbmb/VoxCPM2")
    device: str = os.getenv("DEVICE", "cuda" if os.getenv("USE_CUDA", "true").lower() == "true" else "cpu")
    zero_retention_default: bool = True
    c2pa_watermark_enabled: bool = True
    port: int = int(os.getenv("PORT", "8000"))
    host: str = os.getenv("HOST", "0.0.0.0")

settings = Settings()
