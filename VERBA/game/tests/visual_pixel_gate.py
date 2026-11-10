"""Fail if any Godot-rendered animal fills the camera or is invisible.

This catches bad imported glTF skins, including the former 100x-scale boar
model shipped as a hare. Compare actual GPU pixels to a same-camera empty stage.
"""
from PIL import Image, ImageChops
from pathlib import Path

root = Path("visual-reports")
species = ("deer", "fox", "wolf", "hare", "crow")
poses = ("idle", "walk", "run")
for animal in species:
    baseline = Image.open(root / f"{animal}_baseline.png").convert("RGB")
    for pose in poses:
        file = root / f"{animal}_{pose}.png"
        current = Image.open(file).convert("RGB")
        assert current.size == baseline.size, str(file) + " wrong frame size"
        difference = ImageChops.difference(current, baseline)
        # Threshold filters out one-code-level antialiasing / shadow noise.
        counts = sum(max(px) > 24 for px in difference.getdata())
        occupancy = counts / (current.width * current.height)
        print(f"SCREEN OCCUPANCY {animal} {pose}: {100 * occupancy:.2f}%")
        if occupancy > 0.15:
            raise SystemExit(
                f"FAIL {animal} {pose}: {100*occupancy:.1f}% of viewport obscured by its model."
                " Check skeleton, glTF node scale, mesh orientation and grounding.")
        if occupancy < 0.0001:
            raise SystemExit(f"FAIL {animal} {pose}: appears invisible")
print("VISUAL OCCUPANCY GATE PASSED (all 5 animals, 3 animated poses)")
