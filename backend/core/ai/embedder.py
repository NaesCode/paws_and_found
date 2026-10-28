import logging
import threading
from typing import List, Optional

import numpy as np
import torch
import torch.nn as nn
from django.conf import settings
from PIL import Image
from torchvision.models import ResNet18_Weights, resnet18

logger = logging.getLogger(__name__)

_embedder_lock = threading.Lock()
_embedder_model: Optional[nn.Module] = None
_embedder_transforms = None


def _load_embedder():
    global _embedder_model, _embedder_transforms
    if _embedder_model is not None:
        return

    with _embedder_lock:
        if _embedder_model is not None:
            return

        logger.info("Loading ResNet-18 feature extraction backbone...")
        weights = ResNet18_Weights.IMAGENET1K_V1
        model = resnet18(weights=weights)
        # Replace the final linear classification layer with Identity to output 512-d pooled features
        model.fc = nn.Identity()
        model.eval()

        _embedder_model = model
        _embedder_transforms = weights.transforms()
        logger.info("ResNet-18 embedder loaded successfully. Output dimension: %d", getattr(settings, "EMBEDDING_DIM", 512))


def extract_embedding_from_crop(
    cropped_rgb: np.ndarray,
    flip_averaging: Optional[bool] = None,
) -> List[float]:
    """
    Extracts an L2-normalized 512-dimensional feature embedding from a cropped RGB image.

    Args:
        cropped_rgb: uint8 numpy array with shape (H, W, 3).
        flip_averaging: whether to average features with the horizontally flipped image.
                        Defaults to settings.AI_HORIZONTAL_FLIP_AVG (False).

    Returns:
        List[float]: L2-normalized 512-dimensional vector.
    """
    _load_embedder()
    expected_dim = getattr(settings, "EMBEDDING_DIM", 512)
    use_flip = getattr(settings, "AI_HORIZONTAL_FLIP_AVG", False) if flip_averaging is None else flip_averaging

    pil_img = Image.fromarray(cropped_rgb)
    t1 = _embedder_transforms(pil_img).unsqueeze(0)

    if use_flip:
        pil_flipped = pil_img.transpose(Image.FLIP_LEFT_RIGHT)
        t2 = _embedder_transforms(pil_flipped).unsqueeze(0)
        batch = torch.cat([t1, t2], dim=0)
    else:
        batch = t1

    with torch.inference_mode():
        raw_features = _embedder_model(batch)

    if use_flip:
        pooled = torch.mean(raw_features, dim=0, keepdim=True)
    else:
        pooled = raw_features

    # L2 normalize
    norm = torch.linalg.norm(pooled, dim=1, keepdim=True)
    normalized = pooled / torch.clamp(norm, min=1e-12)

    vec = [float(x) for x in normalized.squeeze(0).cpu().numpy()]
    assert len(vec) == expected_dim, f"Feature dimension mismatch: expected {expected_dim}, got {len(vec)}"
    return vec

