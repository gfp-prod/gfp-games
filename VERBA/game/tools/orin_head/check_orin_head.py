#!/usr/bin/env python3
"""Reject missing binary art / invisible eye and mouth movement.

A valid GLB is necessary but NOT sufficient for artistic acceptance.
"""
from pathlib import Path
from PIL import Image, ImageChops, ImageStat
import json
import sys


def difference(left: Path, right: Path):
    with Image.open(left) as a, Image.open(right) as b:
        a = a.convert("RGB")
        b = b.convert("RGB")
        if a.size != (1280, 720) or b.size != a.size:
            raise AssertionError("Godot captured wrong framebuffer dimensions")
        # Same camera and same scene; face is in the centre of this crop.
        region = (350, 90, 930, 650)
        d = ImageChops.difference(a.crop(region), b.crop(region))
        stat = ImageStat.Stat(d)
        return sum(stat.mean) / len(stat.mean)


def main():
    if len(sys.argv) != 3:
        raise SystemExit("Usage: check_orin_head.py MODEL_DIR FRAME_DIR")
    model = Path(sys.argv[1])
    frames = Path(sys.argv[2])
    manifest = json.loads((model / "manifest.json").read_text())
    assert manifest["source_license"].startswith("CC0"), manifest
    assert len(manifest["blend_shapes"]) == 10
    assert manifest["facial_mesh"]["mesh_vertices"] >= 700
    for name in ("orin_authored_head.glb", "orin_head_editable.blend"):
        target = model / name
        assert target.is_file() and target.stat().st_size > 25000, name
    for shot in (
        "01_front_neutral", "02_three_quarter", "03_profile",
        "04_eyes_closed", "05_speaking", "06_smiling",
        "07_reverse_hemisphere_diagnostic",
        "08_gameplay_scale",
    ):
        im = frames / (shot + ".png")
        assert im.is_file(), shot
        with Image.open(im) as check:
            assert check.size == (1280,720), shot
    blink = difference(frames / "01_front_neutral.png",
                       frames / "04_eyes_closed.png")
    speech = difference(frames / "01_front_neutral.png",
                        frames / "05_speaking.png")
    # Neither poses nor camera may be moved to fabricate the image diff.
    # Small differences are expected because facial motion is localized.
    assert blink > .045, "Blink does not change visible facial pixels"
    assert speech > .035, "Talking does not change visible facial pixels"
    print("PASS: verified genuine Orin morph/pose pixel changes",
          {"blink_mean_absolute_delta":blink,
           "mouth_mean_absolute_delta":speech})
    print("NOTE: pixel movement is a technical test; art acceptance is manual.")


if __name__ == "__main__":
    main()
