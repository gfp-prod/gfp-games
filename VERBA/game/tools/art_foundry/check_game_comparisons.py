#!/usr/bin/env python3
"""Prove the GLB was actually visible in matched live-game screenshots.

Pixel checks detect accidentally empty exports, changed camera/sky, vanished
cottages and identical A/B frames. Artistic superiority is a human review,
not something that image similarity metrics can establish.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "tests" / "foundry_frames"
VIEWS = ("01_front", "02_west")
CENTER = (350, 160, 860, 630)
SKY = (0, 0, 220, 140)


def fraction_changed(a: Image.Image, b: Image.Image, threshold: int = 24) -> float:
    diff = ImageChops.difference(a, b)
    pixel_total = diff.width * diff.height
    if pixel_total == 0:
        raise AssertionError("An empty comparison crop was supplied")
    return sum(max(rgb) > threshold for rgb in diff.getdata()) / pixel_total


def check() -> None:
    for view in VIEWS:
        captures = {}
        for version in ("old_cottage", "new_blender"):
            path = FRAMES / f"{view}_{version}.png"
            assert path.is_file(), f"Missing real Godot comparison: {path}"
            with Image.open(path) as pic:
                image = pic.convert("RGB")
                assert image.size == (1280, 720), f"Viewport changed: {path}"
                captures[version] = image
        original = captures["old_cottage"]
        candidate = captures["new_blender"]
        background_delta = fraction_changed(
            original.crop(SKY), candidate.crop(SKY), threshold=12)
        assert background_delta < .02, (
            f"{view}: changed lighting/camera/background ({background_delta:.1%})")
        original_center = original.crop(CENTER)
        candidate_center = candidate.crop(CENTER)
        changed = fraction_changed(original_center, candidate_center)
        assert .045 <= changed <= .80, (
            f"{view}: missing or unrelated cottage geometry "
            f"({changed:.1%} changed central pixels)")
        contrast = sum(ImageStat.Stat(candidate_center).stddev) / 3
        assert contrast > 24, f"{view}: new cottage view is blank/flat"
        print(f"FOUNDRY_GAME_PIXEL_PROOF {view}: "
              f"changed={changed:.1%} sky_changed={background_delta:.1%} "
              f"contrast={contrast:.1f}")
    print("PASS: cottage is visible from both live-game camera positions")


if __name__ == "__main__":
    check()
