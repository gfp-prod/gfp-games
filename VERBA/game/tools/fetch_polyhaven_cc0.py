"""Download verified Poly Haven CC0 materials directly into VERBA (build-time only).

Runs once in GitHub Actions. Every source URL, asset ID and SHA256 is recorded.
Never asks the player to install textures and never downloads at game runtime.
"""
from __future__ import annotations
import hashlib
import json
import sys
import time
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import quote
from io import BytesIO
from PIL import Image

BASE = "https://api.polyhaven.com"
ROOT = Path(__file__).resolve().parents[1] / "assets/textures/real"
ROOT.mkdir(parents=True, exist_ok=True)

# Exact source names, from the Poly Haven material catalog, are checked in the API.
SOURCES = {
    "meadow_ground": "sparse_grass",
    "woodland_ground": "forrest_ground_01",
    "amber_ground": "forest_leaves_04",
    "river_silt": "rocks_ground_01",
    "earth_path": "dirt_floor",
    "stone": "rock_surface",
    "moss": "concrete_moss",
    "cottage_plaster": "plastered_wall",
    "cottage_wood": "wood_planks",
    "cottage_roof": "roof_slates_02",
}
MAPS = {
    "diffuse": ("Diffuse", "jpg", "png"),
    "normal": ("nor_gl", "jpg", "png"),
}


def get(url: str) -> bytes:
    last = None
    for attempt in range(4):
        try:
            with urlopen(
                Request(url, headers={"User-Agent": "VERBA-SourcedArt-1.0 (CC0 offline assets)", "Accept": "*/*"}),
                timeout=90
            ) as response:
                return response.read()
        except Exception as error:
            last = error
            time.sleep(2 ** attempt)
    raise RuntimeError(f"Failed: {url}: {last}")


def find_file(files: dict, channel: str) -> dict | None:
    # Poly Haven /files/{id} returns a map family -> resolution -> extension.
    candidate: dict | None = None
    keys = [channel, channel.lower(), channel.upper()]
    if channel == "nor_gl":
        keys += ["Normal", "normal", "normal_gl", "NormalGL"]
    for key in keys:
        value = files.get(key)
        if not isinstance(value, dict):
            continue
        for resolution in ("1k", "2k"):
            sized = value.get(resolution)
            if not isinstance(sized, dict):
                continue
            for extension in ("jpg", "png"):
                descriptor = sized.get(extension)
                if isinstance(descriptor, dict) and descriptor.get("url"):
                    return descriptor
    return candidate


def main() -> None:
    manifest = {"source": "Poly Haven https://polyhaven.com", "license": "CC0-1.0",
                "api": BASE, "downloaded": []}
    missing = []
    for local, asset_id in SOURCES.items():
        files = json.loads(get(f"{BASE}/files/{quote(asset_id)}"))
        if not isinstance(files, dict):
            missing.append((asset_id, "invalid response"))
            continue
        for local_type, (api_channel, _, _) in MAPS.items():
            descriptor = find_file(files, api_channel)
            if descriptor is None:
                if local_type == "diffuse":
                    missing.append((asset_id, "no albedo file"))
                continue
            url = descriptor["url"]
            raw = get(url)
            if len(raw) < 8000 or raw[:2] not in (b"\xff\xd8", b"\x89P"):
                raise RuntimeError(f"Invalid downloaded image {asset_id}/{api_channel}: {url}")
            # Keep the existing Godot file paths stable whether a pack ships
            # source PNG or JPEG, and avoid giant 8K material dependencies.
            img = Image.open(BytesIO(raw)).convert("RGB")
            img.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
            output = ROOT / f"{local}_{local_type}.jpg"
            img.save(output, "JPEG", quality=92, subsampling=0, optimize=True)
            saved = output.read_bytes()
            info = {"material": local, "asset_id": asset_id, "map": api_channel,
                    "path": str(output.relative_to(ROOT.parent.parent)),
                    "url": url, "sha256": hashlib.sha256(saved).hexdigest(), "bytes": len(saved)}
            manifest["downloaded"].append(info)
            print(f"VERBA_POLYHAVEN: {local} {local_type} {len(raw)} bytes", flush=True)
    if missing:
        raise RuntimeError("Unresolved source materials: " + str(missing))
    (ROOT / "SOURCES_MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"VERBA_POLYHAVEN_COMPLETE maps={len(manifest['downloaded'])}", flush=True)


if __name__ == "__main__":
    main()
