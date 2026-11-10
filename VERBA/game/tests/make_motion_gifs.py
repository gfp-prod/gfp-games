"""Assemble real Godot-rendered walk-cycle frames into reviewable GIFs."""
from PIL import Image, ImageChops
from pathlib import Path
root = Path("visual-reports")
for species in ("deer", "wolf", "fox", "hare", "crow"):
    paths = sorted(root.glob(f"motion_{species}_*.png"))
    if len(paths) != 10:
        raise SystemExit(f"Missing 10-frame walking cycle for {species}: {len(paths)}")
    frames = []
    for path in paths:
        rendered = Image.open(path).convert("RGB")
        # Crop the neutral test stage to the animal instead of the 1.75m reference.
        frame = rendered.crop((120, 200, 520, 520)).resize((800, 640))
        frames.append(frame)
    # Reject a model whose walking animation renders the same image every frame.
    delta = ImageChops.difference(frames[0], frames[5])
    changed = sum(max(pixel) > 16 for pixel in delta.getdata()) / (800 * 640)
    print(f"VISIBLE MOTION {species}: {changed * 100:.3f}% changed pixels")
    if changed < 0.002:
        raise SystemExit(f"FAIL: {species} plays an animation that looks frozen")
    file = root / f"motion_{species}.gif"
    frames[0].save(file, format="GIF", save_all=True,
                   append_images=frames[1:], duration=120, loop=0, optimize=False)
    print("ANIMATED GODOT PREVIEW", file, file.stat().st_size)
