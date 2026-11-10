"""Validate real sourced material bytes rather than only scene references.

This prevents GitHub from silently shipping 0-byte normal maps, stale
licensed source URLs, or broken source->bake inputs. No extra dependencies.
"""
from pathlib import Path
import json
import hashlib

ROOT = Path(__file__).resolve().parents[1]
REAL = ROOT / "assets" / "textures" / "real"
manifest = json.loads((REAL / "SOURCES_MANIFEST.json").read_text(encoding="utf-8"))
assert manifest["license"] == "CC0-1.0"
records = manifest["downloaded"]
assert len(records) >= 15, "Most source photo texture maps missing"
for entry in records:
    file = ROOT / "assets" / "textures" / "real" / Path(entry["path"]).name
    assert file.is_file(), f"Missing sourced material {file}"
    data = file.read_bytes()
    assert len(data) > 10_000 and data[:2] == b"\xff\xd8", f"Invalid JPEG: {file}"
    assert hashlib.sha256(data).hexdigest() == entry["sha256"], f"SHA256 mismatch {file}"
    assert "polyhaven.org" in entry["url"], f"Unvetted source: {entry['url']}"
for file in REAL.glob("*.jpg"):
    assert file.stat().st_size > 10_000, f"Broken/zero-byte material: {file}"
baked = json.loads((REAL / "VALE_TERRAIN_BAKE.json").read_text())
texture = REAL / "vale_terrain_blend.jpg"
assert texture.is_file() and texture.stat().st_size > 300_000
assert hashlib.sha256(texture.read_bytes()).hexdigest() == baked["atlas_sha256"]
source_names = {"meadow":"meadow_ground","woodland":"woodland_ground",
                "autumn":"amber_ground","creek":"river_silt","road":"earth_path"}
for name, expected in baked["inputs_sha256"].items():
    src = REAL / f"{source_names[name]}_diffuse.jpg"
    assert src.is_file() and hashlib.sha256(src.read_bytes()).hexdigest() == expected, name
assert baked["extent_meters"] == 144 and min(baked["resolution"]) >= 2048
print(f"PASS: {len(records)} sourced CC0 PBR files, valid originals, durable hashes, and finished blended terrain atlas")
