import hashlib
import numpy as np


def extract_features(image_bytes: bytes, vector_dim: int = 512) -> list[float]:
    """
    Extract a normalized visual feature vector from image bytes.

    TODO: Replace this deterministic stub with a trained PyTorch model
    (e.g., MobileNetV3 / ResNet18 backbone using OpenCV image preprocessing).
    Do NOT download large model weights during this initial phase.
    """
    if not image_bytes:
        return [0.0] * vector_dim

    # Deterministic feature generation from image byte chunks
    # Provides repeatable, normalized 512-dimensional vector for tests & offline pipeline
    hasher = hashlib.sha256()
    hasher.update(image_bytes)
    base_hash = hasher.digest()

    rng = np.random.RandomState(int.from_bytes(base_hash[:4], "big"))
    raw_vector = rng.randn(vector_dim).astype(np.float32)

    # L2 normalize
    norm = np.linalg.norm(raw_vector)
    if norm > 0:
        normalized_vector = raw_vector / norm
    else:
        normalized_vector = raw_vector

    return [float(x) for x in normalized_vector]


def cosine_similarity(v1: list[float] | np.ndarray, v2: list[float] | np.ndarray) -> float:
    """
    Calculate the cosine similarity between two feature vectors.
    Returns a float in the range [-1.0, 1.0], clamped to [0.0, 1.0] for matching.
    """
    a = np.asarray(v1, dtype=np.float32)
    b = np.asarray(v2, dtype=np.float32)

    norm_a = np.linalg.norm(a)
    norm_b = np.linalg.norm(b)

    if norm_a == 0.0 or norm_b == 0.0:
        return 0.0

    score = float(np.dot(a, b) / (norm_a * norm_b))
    # Clamp to [0.0, 1.0] for matching thresholds
    return max(0.0, min(1.0, score))

