import io
import time

import numpy as np
from django.core.management.base import BaseCommand
from PIL import Image

from core.ai.features import embed_image


class Command(BaseCommand):
    help = "Loads both AI models (SSDLite320 & ResNet-18), runs a dummy inference, and reports timing."

    def handle(self, *args, **options):
        self.stdout.write("Warming up AI models (SSDLite320 animal detector + ResNet-18 embedder)...")

        # Create a synthetic 320x320 RGB dummy image in memory
        arr = np.random.randint(0, 255, (320, 320, 3), dtype=np.uint8)
        img = Image.fromarray(arr)
        buf = io.BytesIO()
        img.save(buf, format="JPEG", quality=85)
        dummy_bytes = buf.getvalue()

        start_time = time.perf_counter()
        result = embed_image(dummy_bytes)
        elapsed_ms = (time.perf_counter() - start_time) * 1000.0

        vector_len = len(result.vector)
        self.stdout.write(
            self.style.SUCCESS(
                f"Models successfully warmed up!\n"
                f"  Vector length:    {vector_len}\n"
                f"  Model version:    {result.model_version}\n"
                f"  Used crop:        {result.used_crop}\n"
                f"  Detector score:   {result.detector_score:.4f}\n"
                f"  Inference time:   {elapsed_ms:.2f} ms"
            )
        )

