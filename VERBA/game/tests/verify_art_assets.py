"""Self-contained art and resource quality checks; Godot engine needed for runtime QA."""
from pathlib import Path
from PIL import Image
import re
ROOT=Path(__file__).resolve().parents[1]
required=[
  "assets/materials/terrain.gdshader", "assets/materials/stream.gdshader",
  "scripts/foliage.gd", "assets/textures/meadow_ground.png",
  "assets/textures/woodland_ground.png", "assets/textures/amber_ground.png",
  "assets/textures/river_silt.png", "assets/textures/earth_path.png",
  "assets/textures/bark.png", "assets/textures/stone.png",
  "assets/textures/leaf_green.png", "assets/textures/leaf_amber.png",
  "assets/textures/leaf_blue.png", "assets/textures/grass.png",
  "assets/textures/moss.png", "assets/textures/roof_slate.png"
]
for rel in required:
    assert (ROOT/rel).is_file(), f"Missing {rel}"
for p in ROOT.glob("assets/textures/*.png"):
    with Image.open(p) as img:
        img.verify()
missing=[]
for p in list(ROOT.rglob("*.gd"))+list(ROOT.rglob("*.tscn")):
    text=p.read_text()
    for m in re.findall(r'res://([^\"\s]+)',text):
        m=m.rstrip(")')\",;")
        if "$" in m or m.endswith("/"): continue
        # Skip paths assembled by string concatenation.
        if not (ROOT/m).is_file():
            missing.append((str(p.relative_to(ROOT)),m))
assert not missing, missing
w=(ROOT/'scripts/world.gd').read_text()
for m in ['FOLIAGE.populate_grass','FOLIAGE.populate_ferns','FOLIAGE.populate_litter','make_broadleaf_crown','make_conifer_needles']:
    assert m in w,m
assert 'ground_detail.png' not in w
p=(ROOT/'scripts/player.gd').read_text()
assert 'is_physical_key_pressed' in p
print('PASS: art files, PNG integrity, static scene/code references and environment systems.')
print('WARNING: does not compile GDScript or render Godot. Test in native engine before certifying playability.')
