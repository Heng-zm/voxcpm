# High-performance container for VoxCPM2 inference (supports NVIDIA GPU and CPU fallback)
FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:$PATH" \
    PORT=8000

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-venv \
    ffmpeg \
    libsndfile1 \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create dedicated Python 3.11 virtual environment
RUN python3.11 -m venv $VIRTUAL_ENV

WORKDIR /workspace

# Install dependencies into Python 3.11 virtual environment
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

EXPOSE 8000

# Render, Cloud Run, and container platforms inject dynamic $PORT (default to 8000)
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
