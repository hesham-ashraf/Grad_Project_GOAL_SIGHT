# GoalSight Analysis Service — GPU image for AWS EC2 (g4dn/g5, NVIDIA T4/A10).
#
# This image contains the SERVICE code + all heavy ML deps (torch CUDA,
# ultralytics, opencv). The football_ai MODEL (code + weights) is provided at
# runtime by mounting it at /opt/football_ai and setting GOALSIGHT_MODEL_DIR.
# Keeping the model out of the image keeps builds fast and the ~125 MB+ weights
# out of the registry.
#
# Build:
#   docker build -t goalsight-analysis ./analysis_service
# Run (AWS GPU host with nvidia-container-toolkit):
#   docker run --gpus all -p 8000:8000 \
#     -v /home/ubuntu/football_ai:/opt/football_ai \
#     -e GOALSIGHT_DEVICE=cuda:0 \
#     -e SUPABASE_URL=... -e SUPABASE_SERVICE_KEY=... \
#     goalsight-analysis

FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.10 python3-pip python3.10-dev \
        ffmpeg libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*
RUN ln -sf /usr/bin/python3.10 /usr/bin/python

# Torch (CUDA 12.1 wheels) + the model's ML deps. Pin torch to the CUDA build
# so GPU inference works on the EC2 instance.
RUN pip install --upgrade pip && \
    pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
RUN pip install \
        "ultralytics>=8.3.0" \
        "opencv-python-headless>=4.9.0" \
        "numpy>=1.26.0" \
        "PyYAML>=6.0"

# Service deps.
COPY requirements.txt /app/requirements.txt
RUN pip install -r /app/requirements.txt

# Service code.
COPY app /app/app

WORKDIR /app
ENV GOALSIGHT_MODEL_DIR=/opt/football_ai \
    GOALSIGHT_MODEL_CONFIG=config/config.yaml \
    GOALSIGHT_DEVICE=cuda:0 \
    GOALSIGHT_HOST=0.0.0.0 \
    GOALSIGHT_PORT=8000

EXPOSE 8000
# Single worker: the model is GPU-bound and serialized by an internal lock.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
