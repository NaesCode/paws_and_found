class AIError(Exception):
    """Base exception for AI module errors."""
    pass


class InvalidImageError(AIError):
    """Raised when an image payload is corrupted, empty, or not a valid image format."""
    pass


class ImageDimensionError(AIError):
    """Raised when an image fails dimension or size bounds checks."""
    pass

