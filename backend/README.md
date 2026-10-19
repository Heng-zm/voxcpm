# VoxCPM2 Private Inference Gateway — Backend

The backend gateway provides zero-shot 48kHz voice synthesis and real-time audio chunk streaming using OpenBMB VoxCPM2.

---

## Architecture & Features

- **Model:** OpenBMB/VoxCPM2 (Tokenizer-free diffusion autoregressive architecture)
- **Audio Output:** 48kHz mono PCM WAV streaming in real-time
- **Security:** App Attest device assertion validation, C2PA cryptographic provenance watermark
- **Privacy:** In-memory audio processing with zero disk retention
- **Hardware Acceleration:** Native NVIDIA CUDA with automatic fallback to lightweight CPU synthesizer for standard cloud tiers

---

## Deployment Options

### 1. Render.com Deployment (Recommended for Cloud)

A `render.yaml` blueprint is included in the repository root.

#### Option A: One-Click Blueprint
1. In Render Dashboard, click **New +** -> **Blueprint**.
2. Connect your `voxcpm` repository.
3. Render automatically reads `render.yaml` and provisions the web service.

#### Option B: Manual Web Service Setup
1. Create a **New Web Service** from your Git repository.
2. Select **Docker** runtime.
3. Set **Docker Command / Context**:
   - Docker Build Context: `backend`
   - Dockerfile Path: `backend/Dockerfile` (or `backend/Dockerfile.cpu` for fast CPU build)
4. Environment Variables:
   - `PORT`: `10000` (Render binds this port automatically)
   - `DEVICE`: `cpu` (or `cuda` if on a GPU instance)
   - `USE_CUDA`: `false` (or `true` on GPU)
   - `VOXCPM_MODEL_NAME`: `openbmb/VoxCPM2`
5. Health Check Path: `/v1/health`

---

### 2. Docker & Docker Compose (Local & Self-Hosted GPU)

Run with NVIDIA GPU acceleration:

```bash
cd backend
docker-compose up --build
```

Test endpoint:
```bash
curl http://localhost:8000/v1/health
```

---

### 3. CPU vs GPU Image Comparison

| Configuration | Base Image | Size | Recommended For |
| :--- | :--- | :--- | :--- |
| `Dockerfile` | `nvidia/cuda:12.4.1` | ~3.5 GB | NVIDIA GPU nodes, RunPod, AWS EC2 G4/G5, Render GPU |
| `Dockerfile.cpu` | `python:3.11-slim` | ~800 MB | Render Free/Starter, Heroku, Cloud Run, Local CPU |

---

## Common Gotchas & Troubleshooting

### Error: `/usr/bin/python3.11: No module named uvicorn`
- **Cause:** In Ubuntu 22.04 base images, installing `python3-pip` connects `pip3` to system Python 3.10 instead of Python 3.11.
- **Fix:** Both `Dockerfile` and `Dockerfile.cpu` now use an isolated Python 3.11 virtual environment (`/opt/venv`), guaranteeing that all dependencies (including `uvicorn`) are installed under Python 3.11.

### Warning: `The NVIDIA Driver was not detected. GPU functionality will not be available.`
- **Cause:** Deploying a CUDA image onto a cloud instance without an attached GPU (e.g., standard Render instance).
- **Behavior:** The gateway safely falls back to CPU mode, preventing crashes and allowing health checks to pass. To reduce image size and build times on CPU-only hosts, use `Dockerfile.cpu`.

### Error: `No open ports detected, continuing to scan...`
- **Cause:** Application hardcoded to port 8000 while Render expects listening on dynamic `$PORT` (typically 10000).
- **Fix:** The container entrypoint executes `uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}`, dynamically honoring the hosting platform's assigned port.
