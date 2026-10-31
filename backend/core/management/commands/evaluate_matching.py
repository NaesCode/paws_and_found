import csv
import os
from pathlib import Path
from typing import Dict, List, Tuple

import numpy as np
from django.core.management.base import BaseCommand, CommandError

from core.ai.features import cosine_similarity, embed_image

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


class Command(BaseCommand):
    help = (
        "Evaluates ResNet-18 + SSDLite320 pet matching on local evaluation images, "
        "calibrating precision, recall, F1, and similarity thresholds."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--data",
            type=str,
            default="backend/eval_data",
            help="Directory containing subdirectories per animal (default: backend/eval_data)",
        )
        parser.add_argument(
            "--target-precision",
            type=float,
            default=0.85,
            help="Target precision threshold to recommend (default: 0.85)",
        )
        parser.add_argument(
            "--output-csv",
            type=str,
            default="matching_eval_results.csv",
            help="Path to write evaluation CSV results (default: matching_eval_results.csv)",
        )

    def handle(self, *args, **options):
        data_dir = Path(options["data"]).resolve()
        target_precision = options["target_precision"]
        output_csv = options["output_csv"]

        self.stdout.write(self.style.MIGRATE_HEADING("=== Paws and Found AI Matching Evaluation ==="))
        self.stdout.write(f"Scanning directory: {data_dir}")

        if not data_dir.exists() or not data_dir.is_dir():
            self._print_empty_scaffolding_help(data_dir)
            return

        # Discover animal classes and photos
        animal_photos: Dict[str, List[Path]] = {}
        for entry in data_dir.iterdir():
            if entry.is_dir():
                photos = [
                    p for p in entry.iterdir()
                    if p.is_file() and p.suffix.lower() in ALLOWED_EXTENSIONS
                ]
                if photos:
                    animal_photos[entry.name] = photos

        total_animals = len(animal_photos)
        total_photos = sum(len(p) for p in animal_photos.values())

        if total_animals < 2 or total_photos < 4:
            self.stdout.write(self.style.WARNING(
                f"\nFound {total_animals} animal folders with {total_photos} total photos.\n"
                "To evaluate matching precision & recall, at least 2 animal folders with multiple photos each are required."
            ))
            self._print_empty_scaffolding_help(data_dir)
            return

        self.stdout.write(f"Loaded {total_photos} photos across {total_animals} animal entities.\n")

        # Compute embeddings for both modes: with detector crop (True) and without detector crop (False)
        self.stdout.write("Extracting embeddings (Mode 1: Detector Crop ON, Mode 2: Full Image)...")

        crop_embeddings: Dict[Path, List[float]] = {}
        nocrop_embeddings: Dict[Path, List[float]] = {}

        for animal, photos in animal_photos.items():
            for photo_path in photos:
                try:
                    with open(photo_path, "rb") as f:
                        img_bytes = f.read()
                    crop_res = embed_image(img_bytes, use_detector=True)
                    crop_embeddings[photo_path] = crop_res.vector

                    nocrop_res = embed_image(img_bytes, use_detector=False)
                    nocrop_embeddings[photo_path] = nocrop_res.vector
                except Exception as e:
                    self.stdout.write(self.style.ERROR(f"Error processing {photo_path.name}: {e}"))

        all_photos = list(crop_embeddings.keys())
        n = len(all_photos)

        # Generate photo pairs (positive: same animal, negative: different animals)
        pairs: List[Tuple[Path, Path, bool]] = []
        for i in range(n):
            for j in range(i + 1, n):
                p1 = all_photos[i]
                p2 = all_photos[j]
                is_same = p1.parent.name == p2.parent.name
                pairs.append((p1, p2, is_same))

        num_positive = sum(1 for _, _, is_same in pairs if is_same)
        num_negative = sum(1 for _, _, is_same in pairs if not is_same)

        self.stdout.write(f"Generated {len(pairs)} evaluation pairs: {num_positive} Positive, {num_negative} Negative.\n")

        if num_positive == 0:
            self.stdout.write(self.style.ERROR(
                "No positive pairs found. Each animal directory must contain at least 2 photos."
            ))
            return

        csv_rows = []

        # Evaluate both modes
        for mode_name, emb_dict in [("Detector Crop ON", crop_embeddings), ("Full Image (No Crop)", nocrop_embeddings)]:
            self.stdout.write(self.style.MIGRATE_LABEL(f"\n--- Results: {mode_name} ---"))
            pos_scores = []
            neg_scores = []

            for p1, p2, is_same in pairs:
                v1 = emb_dict[p1]
                v2 = emb_dict[p2]
                score = cosine_similarity(v1, v2)
                if is_same:
                    pos_scores.append(score)
                else:
                    neg_scores.append(score)

            pos_arr = np.array(pos_scores)
            neg_arr = np.array(neg_scores)

            self.stdout.write("Similarity Distribution:")
            self.stdout.write(
                f"  Positive pairs (Same Animal)  : mean={pos_arr.mean():.4f}, median={np.median(pos_arr):.4f}, "
                f"min={pos_arr.min():.4f}, max={pos_arr.max():.4f}, 25th={np.percentile(pos_arr, 25):.4f}"
            )
            self.stdout.write(
                f"  Negative pairs (Diff Animals) : mean={neg_arr.mean():.4f}, median={np.median(neg_arr):.4f}, "
                f"min={neg_arr.min():.4f}, max={neg_arr.max():.4f}, 75th={np.percentile(neg_arr, 75):.4f}"
            )

            # Evaluate thresholds
            best_threshold_for_target = None
            best_f1 = -1.0
            best_f1_threshold = None

            self.stdout.write("\nThreshold Sweep (0.50 to 0.98):")
            self.stdout.write(f"{'Threshold':>10} | {'Precision':>10} | {'Recall':>10} | {'F1-Score':>10} | {'TP':>4} | {'FP':>4} | {'FN':>4} | {'TN':>4}")
            self.stdout.write("-" * 75)

            for t_int in range(50, 99, 2):
                thresh = t_int / 100.0
                tp = int(np.sum(pos_arr >= thresh))
                fn = int(np.sum(pos_arr < thresh))
                fp = int(np.sum(neg_arr >= thresh))
                tn = int(np.sum(neg_arr < thresh))

                prec = tp / (tp + fp) if (tp + fp) > 0 else 1.0
                rec = tp / (tp + fn) if (tp + fn) > 0 else 0.0
                f1 = (2 * prec * rec / (prec + rec)) if (prec + rec) > 0 else 0.0

                csv_rows.append({
                    "mode": mode_name,
                    "threshold": f"{thresh:.2f}",
                    "tp": tp,
                    "fp": fp,
                    "tn": tn,
                    "fn": fn,
                    "precision": f"{prec:.4f}",
                    "recall": f"{rec:.4f}",
                    "f1": f"{f1:.4f}",
                })

                if f1 > best_f1:
                    best_f1 = f1
                    best_f1_threshold = thresh

                if prec >= target_precision and best_threshold_for_target is None:
                    best_threshold_for_target = thresh

                # Sampled display rows
                if t_int in (60, 70, 75, 80, 82, 85, 88, 90, 92, 95):
                    self.stdout.write(
                        f"{thresh:>10.2f} | {prec:>10.4f} | {rec:>10.4f} | {f1:>10.4f} | {tp:>4} | {fp:>4} | {fn:>4} | {tn:>4}"
                    )

            self.stdout.write("-" * 75)
            self.stdout.write(
                f"Peak F1-score: {best_f1:.4f} at threshold {best_f1_threshold:.2f}"
            )
            if best_threshold_for_target is not None:
                self.stdout.write(self.style.SUCCESS(
                    f"Lowest threshold meeting target precision ({target_precision:.2f}): {best_threshold_for_target:.2f}"
                ))
            else:
                self.stdout.write(self.style.WARNING(
                    f"No threshold reached target precision ({target_precision:.2f})."
                ))

        # Write output CSV
        try:
            with open(output_csv, mode="w", newline="", encoding="utf-8") as f:
                writer = csv.DictWriter(
                    f,
                    fieldnames=["mode", "threshold", "tp", "fp", "tn", "fn", "precision", "recall", "f1"]
                )
                writer.writeheader()
                writer.writerows(csv_rows)
            self.stdout.write(self.style.SUCCESS(f"\nSaved evaluation metrics to CSV: {output_csv}"))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Failed to write CSV: {e}"))

        self.stdout.write(self.style.WARNING(
            "\n[IMPORTANT NOTE] Results and threshold recommendations are strictly reflective "
            "of the current evaluation dataset size and diversity. For academic/capstone defense, "
            "ensure evaluation data comprises varied angles, lighting, and fur patterns."
        ))

    def _print_empty_scaffolding_help(self, data_dir: Path):
        self.stdout.write(
            "\nTo calibrate MATCH_BASE_SIMILARITY using real animal photos, organize your photos as follows:\n\n"
            f"  {data_dir}/\n"
            "    ├── dog_milo/\n"
            "    │   ├── milo_1.jpg\n"
            "    │   ├── milo_2.jpg\n"
            "    │   └── milo_3.jpg\n"
            "    ├── cat_luna/\n"
            "    │   ├── luna_1.jpg\n"
            "    │   └── luna_2.jpg\n"
            "    └── dog_rocky/\n"
            "        ├── rocky_1.jpg\n"
            "        └── rocky_2.jpg\n\n"
            "Then run:\n"
            f"  docker compose exec backend python manage.py evaluate_matching --data {data_dir.name} --target-precision 0.85\n"
        )

