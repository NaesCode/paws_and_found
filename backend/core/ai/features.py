import logging
import threading
from typing import List, NamedTuple, Union

import numpy as np
import torch
from django.conf import settings

from .detector import detect_and_crop_animal
from .embedder import extract_embedding_from_crop
from .exceptions import AIError, ImageDimensionError, InvalidImageError
from .preprocessor import decode_and_preprocess

logger = logging.getLogger(__name__)

_ai_inference_lock = threading.Lock()
_threads_initialized = False
_threads_lock = threading.Lock()


def _ensure_torch_threads():
    global _threads_initialized
    if not _threads_initialized:
        with _threads_lock:
            if not _threads_initialized:
                num_threads = getattr(settings, "TORCH_THREADS", 4)
                torch.set_num_threads(num_threads)
                _threads_initialized = True
                logger.info("Torch intra-op threads set to %d", num_threads)


class EmbeddingResult(NamedTuple):
    vector: List[float]
    model_version: str
    used_crop: bool
    detector_score: float


def embed_image(image_bytes: bytes, use_detector: bool = True) -> EmbeddingResult:
    """
    End-to-end AI image embedding pipeline:
    1. Decodes and preprocesses image bytes (EXIF correction, RGB conversion, 1024px cap).
    2. Runs SSDLite320 MobileNetV3 to detect cat/dog and crops with 10% padding (if use_detector=True).
    3. Runs ResNet-18 to produce an L2-normalized 512-dimensional vector.

    Thread-safe and guarded by a module-level lock.
    """
    _ensure_torch_threads()

    max_bytes = getattr(settings, "MAX_IMAGE_BYTES", 10 * 1024 * 1024)
    model_version = getattr(settings, "EMBEDDING_MODEL_VERSION", "resnet18-in1k-v1+ssdlite-crop-v1")

    with _ai_inference_lock:
        preprocessed_rgb = decode_and_preprocess(image_bytes, max_bytes=max_bytes)
        if use_detector:
            cropped_rgb, used_crop, detector_score = detect_and_crop_animal(preprocessed_rgb)
        else:
            cropped_rgb = preprocessed_rgb
            used_crop = False
            detector_score = 0.0
        vector = extract_embedding_from_crop(cropped_rgb)

    return EmbeddingResult(
        vector=vector,
        model_version=model_version,
        used_crop=used_crop,
        detector_score=detector_score,
    )


def extract_features(image_bytes: bytes, vector_dim: int = 512) -> List[float]:
    """
    Thin backwards-compatible wrapper returning the 512-dimensional vector.
    """
    if not image_bytes:
        return [0.0] * vector_dim
    result = embed_image(image_bytes)
    return result.vector


def average_embeddings(vectors: List[List[float]]) -> List[float]:
    """
    Averages multiple 512-dimensional normalized vectors and re-normalizes the result (L2).
    Used for multi-photo pet profile representations.
    """
    if not vectors:
        raise ValueError("Cannot average an empty list of vectors.")

    arr = np.asarray(vectors, dtype=np.float32)
    mean_vec = np.mean(arr, axis=0)
    norm = float(np.linalg.norm(mean_vec))

    if norm > 1e-12:
        normalized = mean_vec / norm
    else:
        normalized = mean_vec

    return [float(x) for x in normalized]


def cosine_similarity(v1: Union[List[float], np.ndarray], v2: Union[List[float], np.ndarray]) -> float:
    """
    Computes cosine similarity between two feature vectors.
    Returns float clamped to [0.0, 1.0].
    """
    a = np.asarray(v1, dtype=np.float32)
    b = np.asarray(v2, dtype=np.float32)

    norm_a = np.linalg.norm(a)
    norm_b = np.linalg.norm(b)

    if norm_a == 0.0 or norm_b == 0.0:
        return 0.0

    score = float(np.dot(a, b) / (norm_a * norm_b))
    return max(0.0, min(1.0, score))
