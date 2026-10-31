import io
import cv2
import numpy as np
from PIL import Image, ImageOps, UnidentifiedImageError

from .exceptions import ImageDimensionError, InvalidImageError


def decode_and_preprocess(
    image_bytes: bytes,
    max_bytes: int = 10 * 1024 * 1024,
    max_long_side: int = 1024,
    min_side: int = 10,
    max_side: int = 4096,
) -> np.ndarray:
    """
    Decodes raw image bytes, applies EXIF rotation transpose, converts to RGB,
    enforces byte/pixel bounds, and resizes so the long side is at most max_long_side.

    Returns:
        np.ndarray: uint8 RGB image of shape (H, W, 3).
    """
    if not image_bytes:
        raise InvalidImageError("Image bytes payload is empty.")

    if len(image_bytes) > max_bytes:
        raise ImageDimensionError(f"Image size ({len(image_bytes)} bytes) exceeds maximum limit ({max_bytes} bytes).")

    try:
        with Image.open(io.BytesIO(image_bytes)) as pil_img:
            # Transpose according to EXIF orientation tag if present
            transposed = ImageOps.exif_transpose(pil_img)
            # Ensure 3-channel RGB format (stripping alpha or grayscale)
            rgb_img = transposed.convert("RGB")
            arr = np.asarray(rgb_img)
    except (UnidentifiedImageError, OSError, ValueError) as err:
        raise InvalidImageError(f"Corrupt or unsupported image format: {err}") from err

    if arr.ndim != 3 or arr.shape[2] != 3:
        raise InvalidImageError("Invalid decoded image channel structure; expected RGB 3-channel.")

    h, w = arr.shape[:2]
    if h < min_side or w < min_side:
        raise ImageDimensionError(f"Image dimensions ({w}x{h}) are below minimum threshold ({min_side}px).")

    if h > max_side or w > max_side:
        raise ImageDimensionError(f"Image dimensions ({w}x{h}) exceed maximum threshold ({max_side}px).")

    # Downscale long side if it exceeds max_long_side
    long_side = max(h, w)
    if long_side > max_long_side:
        scale = float(max_long_side) / float(long_side)
        new_w = max(1, int(round(w * scale)))
        new_h = max(1, int(round(h * scale)))
        # OpenCV resize expects (width, height)
        arr = cv2.resize(arr, (new_w, new_h), interpolation=cv2.INTER_AREA)

    return arr

