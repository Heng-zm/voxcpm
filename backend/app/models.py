from pydantic import BaseModel, Field
from typing import Optional

class SynthesisSettingsModel(BaseModel):
    cfg_value: float = Field(default=2.0, ge=1.0, le=3.0)
    inference_timesteps: int = Field(default=10, ge=4, le=30)
    denoise: bool = True
    seed: Optional[int] = None
    zero_retention: bool = True

class HealthResponse(BaseModel):
    status: str
    engine: str
    gpu_model: Optional[str] = None
    vram_available_gb: Optional[float] = None
    cuda_available: bool
