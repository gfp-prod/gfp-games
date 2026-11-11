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


# Actual first-person manuscript gate: a green engine run is not a readable
# book. Catch lighting regressions that plunge the vellum to charcoal or
# wash out ink. Sample the page texture and words *inside the real camera*
# frame, never screenshots painted by a mockup.
from statistics import median

for title in ("latin_book_passage", "latin_book_question"):
    page = Image.open(root / (title + ".png")).convert("RGB")
    w, h = page.size
    if w < 900 or h < 500:
        raise SystemExit(f"FAIL {title}: manuscript capture is too small")
    # This unprinted lower interior is genuinely parchment in the held pose.
    unprinted = page.crop((int(w*.32), int(h*.765), int(w*.445), int(h*.86)))
    samples = list(unprinted.getdata())
    brightness = median(.2126*r + .7152*g + .0722*b for r,g,b in samples)
    print(f"MANUSCRIPT PAPER BRIGHTNESS {title}: {brightness:.1f}")
    if not 110.0 <= brightness <= 230.0:
        raise SystemExit(f"FAIL {title}: vellum is too dark or overexposed to read")
# Passage ink must have local contrast on the paper, not merely exist in 3D.
page = Image.open(root / "latin_book_passage.png").convert("RGB")
w, h = page.size
ink_patch = page.crop((int(w*.31),int(h*.51),int(w*.45),int(h*.64)))
values = sorted(.2126*r+.7152*g+.0722*b for r,g,b in ink_patch.getdata())
contrast = values[int(len(values)*.80)] - values[int(len(values)*.05)]
print(f"MANUSCRIPT INK CONTRAST: {contrast:.1f}")
if contrast < 48.0:
    raise SystemExit("FAIL: in-world Latin ink lost contrast against parchment")
print("FIRST-PERSON BOOK READABILITY GATE PASSED")
