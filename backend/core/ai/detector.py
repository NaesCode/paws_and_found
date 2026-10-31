import logging
import threading
from typing import Optional, Set, Tuple

import numpy as np
import torch
from PIL import Image
from torchvision.models.detection import (
    SSDLite320_MobileNet_V3_Large_Weights,
    ssdlite320_mobilenet_v3_large,
)

logger = logging.getLogger(__name__)

_detector_lock = threading.Lock()
_detector_model: Optional[torch.nn.Module] = None
_detector_transforms = None
_target_categories: Optional[Set[int]] = None

SCORE_THRESHOLD = 0.40
PADDING_RATIO = 0.10


def _load_detector():
    global _detector_model, _detector_transforms, _target_categories
    if _detector_model is not None:
        return

    with _detector_lock:
        if _detector_model is not None:
            return

        logger.info("Loading SSDLite320 MobileNetV3 object detector...")
        weights = SSDLite320_MobileNet_V3_Large_Weights.DEFAULT
        model = ssdlite320_mobilenet_v3_large(weights=weights)
        model.eval()

        # Extract target category indices dynamically by class name from weights metadata
        categories = weights.meta.get("categories", [])
        target_indices = {idx for idx, cat in enumerate(categories) if cat in ("cat", "dog")}
        if not target_indices:
            # Fallback if categories metadata format varies
            target_indices = {16, 17, 18}

        _detector_model = model
        _detector_transforms = weights.transforms()
        _target_categories = target_indices
        logger.info("SSDLite320 detector loaded. Target classes: cat, dog (indices %s)", target_indices)


def detect_and_crop_animal(
    image_rgb: np.ndarray,
    score_threshold: float = SCORE_THRESHOLD,
    padding_ratio: float = PADDING_RATIO,
) -> Tuple[np.ndarray, bool, float]:
    """
    Detects cats or dogs in the RGB image. If found with confidence >= score_threshold,
    crops to the highest scoring bounding box with padding_ratio.
    Otherwise returns the original image.

    Args:
        image_rgb: uint8 numpy array with shape (H, W, 3).
        score_threshold: minimum detector confidence.
        padding_ratio: bounding box padding fraction.

    Returns:
        Tuple of (cropped_or_full_image_rgb, used_crop, detector_score)
    """
    _load_detector()
    h, w = image_rgb.shape[:2]

    # Convert to PIL Image for torchvision detection transforms
    pil_img = Image.fromarray(image_rgb)
    transformed_tensor = _detector_transforms(pil_img)

    with torch.inference_mode():
        predictions = _detector_model([transformed_tensor])[0]

    boxes = predictions["boxes"]
    scores = predictions["scores"]
    labels = predictions["labels"]

    best_box = None
    best_score = 0.0

    for i in range(len(scores)):
        score = float(scores[i].item())
        if score < score_threshold:
            continue
        label = int(labels[i].item())
        if label in _target_categories:
            if score > best_score:
                best_score = score
                best_box = boxes[i].tolist()

    if best_box is not None:
        x1, y1, x2, y2 = best_box
        box_w = x2 - x1
        box_h = y2 - y1

        pad_x = padding_ratio * box_w
        pad_y = padding_ratio * box_h

        crop_x1 = max(0, int(round(x1 - pad_x)))
        crop_y1 = max(0, int(round(y1 - pad_y)))
        crop_x2 = min(w, int(round(x2 + pad_x)))
        crop_y2 = min(h, int(round(y2 + pad_y)))

        if crop_x2 > crop_x1 and crop_y2 > crop_y1:
            cropped = image_rgb[crop_y1:crop_y2, crop_x1:crop_x2]
            return cropped, True, round(best_score, 4)

    return image_rgb, False, 0.0

