FROM python:3.11-slim

# System libraries required by GeoDjango (GDAL, GEOS, PROJ) and OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
    binutils \
    libproj-dev \
    gdal-bin \
    libgdal-dev \
    libgeos-dev \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── Bake AI model weights into the image ────────────────────────────────────
# Pre-downloading during build means the container starts fully offline.
# torch.hub stores weights at /root/.cache/torch/hub/checkpoints/ by default.
# We set TORCH_HOME to /opt/torch so baked weights are NOT shadowed by the
# volume mount of ./backend to /app during local development.
ENV TORCH_HOME=/opt/torch
RUN python - <<'PYEOF'
import os
os.environ.setdefault("TORCH_HOME", "/opt/torch")
import torchvision
from torchvision.models import ResNet18_Weights, resnet18
from torchvision.models.detection import (
    SSDLite320_MobileNet_V3_Large_Weights,
    ssdlite320_mobilenet_v3_large,
)
print("Downloading ResNet-18 weights...")
resnet18(weights=ResNet18_Weights.IMAGENET1K_V1)
print("Downloading SSDLite320 MobileNetV3 weights...")
ssdlite320_mobilenet_v3_large(weights=SSDLite320_MobileNet_V3_Large_Weights.DEFAULT)
print("All model weights cached successfully.")
PYEOF
# ── End weight bake ──────────────────────────────────────────────────────────

COPY . .

EXPOSE 8000

# Gunicorn multi-worker production server.
# CMD is overridden in docker-compose.yml for development (--reload flag).
CMD ["gunicorn", "config.wsgi:application", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "2", \
     "--threads", "4", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-"]
