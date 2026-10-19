from pydantic import BaseModel, Field
from typing import Optional

class SynthesisSettingsModel(BaseModel):
    cfg_scale: float = Field(default=2.0, ge=1.0, le=5.0)
    timesteps: int = Field(default=10, ge=5, le=30)
    emotion_instruction: Optional[str] = None
    speed_multiplier: float = Field(default=1.0, ge=0.5, le=2.0)
    watermark_enabled: bool = True
    zero_retention: bool = True

class HealthResponse(BaseModel):
    status: str
    engine: str
    gpu_model: Optional[str] = None
    vram_available_gb: Optional[float] = None
    cuda_available: bool
