"""VERBA: bake seamless authored valley terrain from real CC0 photographs.

This OFFLINE authoring step runs in GitHub Actions and commits one 3072px
world-aligned atlas. The game contains NO runtime terrain shader or texture
downloads; its existing HeightMapShape3D physics is preserved. Smooth biomes
replace hard per-triangle material switches.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PHOTO = ROOT / "assets/textures/real"
TARGET = PHOTO / "vale_terrain_blend.jpg"
RES = 3072
WORLD_METERS = 144.0

SOURCE_PATHS = {
    "meadow": PHOTO / "meadow_ground_diffuse.jpg",
    "woodland": PHOTO / "woodland_ground_diffuse.jpg",
    "autumn": PHOTO / "amber_ground_diffuse.jpg",
    "creek": PHOTO / "river_silt_diffuse.jpg",
    "road": PHOTO / "earth_path_diffuse.jpg",
}
TILES = {"meadow": 4.4, "woodland": 3.7, "autumn": 4.6,
         "creek": 3.7, "road": 3.6}
# Slight painterly adaptation of photographs, NOT a uniform paint wash.
TINT = {"meadow": np.array([102, 111, 76]),
        "woodland": np.array([82, 95, 73]),
        "autumn": np.array([126, 108, 79]),
        "creek": np.array([102, 108, 98]),
        "road": np.array([132, 114, 85])}


def smooth(a: float, b: float, value: np.ndarray) -> np.ndarray:
    t = np.clip((value-a)/(b-a), 0, 1)
    return t*t*(3-2*t)


def load_sources() -> dict:
    result = {}
    for name, file in SOURCE_PATHS.items():
        if not file.exists() or file.stat().st_size < 10_000:
            raise RuntimeError(f"CC0 input not yet sourced: {file}")
        img = Image.open(file).convert("RGB")
        # Downsample once; output world-space atlas repeats with gentle warp.
        img = img.resize((768,768), Image.Resampling.LANCZOS)
        result[name] = np.asarray(img, dtype=np.uint8)
        print("VERBA_TERRAIN_INPUT", name, file.stat().st_size, flush=True)
    return result


def sample(texture: np.ndarray, name: str, xx: np.ndarray,
           zz: np.ndarray) -> np.ndarray:
    side = texture.shape[0]
    tile = TILES[name]
    # Curved seams reduce repeated straight seams without distorting the
    # actual biome geography; no source image is stretched over 144 meters.
    warp_u = xx + 0.17*np.sin(zz*.31) + 0.12*np.sin(zz*.09 + xx*.05)
    warp_v = zz + 0.19*np.sin(xx*.26) - 0.09*np.cos(xx*.11)
    u = np.mod(np.floor(warp_u / tile * side).astype(np.int32), side)
    v = np.mod(np.floor(warp_v / tile * side).astype(np.int32), side)
    px = texture[v,u].astype(np.float32)
    # Preserve real stone, leaf, and soil photo features but unify palettes.
    return px*.88 + TINT[name][None,None,:]*.12


def main() -> None:
    # Two upstream compressed normal maps have occasionally arrived as empty
    # files. Never let broken 0-byte JPEGs enter a Godot texture import.
    for normal in PHOTO.glob("*_normal.jpg"):
        if normal.stat().st_size < 4096:
            print("VERBA_REMOVING_BAD_NORMAL", normal.name, flush=True)
            normal.unlink()
    images = load_sources()
    output = np.empty((RES,RES,3),dtype=np.uint8)
    x_axis = ((np.arange(RES,dtype=np.float32)+.5)/RES-.5)*WORLD_METERS
    z_axis = ((np.arange(RES,dtype=np.float32)+.5)/RES-.5)*WORLD_METERS
    xx = x_axis[None,:]
    for start in range(0,RES,96):
        z = z_axis[start:start+96,None]
        xs = np.broadcast_to(xx, (len(z),RES))
        zs = np.broadcast_to(z, (len(z),RES))
        # Interpolated biomes, compatible with the game world's existing
        # terrain_biome()/stream_x(). Gentle 9-15m ecotones are deliberate.
        woody = (1.0 - smooth(-24.0,-4.0,xs))*smooth(-33.0,-13.0,zs)*.93
        amber = smooth(14.0,37.0,xs)*(1.0-smooth(14.0,34.0,zs))*.92
        stream_x = -20.0+4.4*np.sin(zs*.075)+1.7*np.sin(zs*.21)
        damp = (1.0-smooth(4.8,10.4,np.abs(xs-stream_x)))*.92

        out = sample(images["meadow"],"meadow",xs,zs)
        other = sample(images["woodland"],"woodland",xs,zs)
        out = out*(1.0-woody[:,:,None]) + other*woody[:,:,None]
        other = sample(images["autumn"],"autumn",xs,zs)
        out = out*(1.0-amber[:,:,None]) + other*amber[:,:,None]
        other = sample(images["creek"],"creek",xs,zs)
        out = out*(1.0-damp[:,:,None]) + other*damp[:,:,None]

        # Painted, physically flat old road: no hovering road plane, no
        # interlocking physical triangles. Still follows the original trail.
        path_i = (29.0-zs)/.49
        winding = np.sin(path_i*.059)*2.15 + np.sin(path_i*.16)*.47
        width = 1.55 + .20*np.sin(path_i*.18)
        distance = np.abs(xs-winding)
        road = (1.0-smooth(width*.45,width*1.95,distance))
        road *= smooth(-49.0,-38.0,zs)*(1.0-smooth(25.0,32.0,zs))
        road *= .89
        other = sample(images["road"],"road",xs,zs)
        out = out*(1.0-road[:,:,None]) + other*road[:,:,None]
        # Subdued overall contrast/saturation preserves a storybook midtone
        # without bleaching the photographic detail or making it monochrome.
        luma = out[:,:,0]*.25 + out[:,:,1]*.64 + out[:,:,2]*.11
        out = out*.94 + luma[:,:,None]*.06
        # The first real-player-eye render showed dangerously dark (40/255)
        # foreground midtones. A filmic perceptual lift keeps photo texture
        # detail while giving open meadow the storybook daylight it needs.
        out = 255.0*np.power(np.clip(out/255.0,0.0,1.0), .63)
        output[start:start+len(z)] = np.clip(out,0,255).astype(np.uint8)
        if start%768 == 0:
            print(f"VERBA_TERRAIN_BAKE {start}/{RES}", flush=True)

    Image.fromarray(output).save(TARGET, "JPEG", quality=91, subsampling=0,
                                 optimize=True, progressive=True)
    source_checksums = {name:hashlib.sha256(path.read_bytes()).hexdigest()
                        for name,path in SOURCE_PATHS.items()}
    meta = {"resolution":[RES,RES],"extent_meters":WORLD_METERS,
            "license":"Derived exclusively from bundled Poly Haven CC0 source textures",
            "inputs_sha256":source_checksums,"atlas_sha256":hashlib.sha256(TARGET.read_bytes()).hexdigest(),
            "source": "tools/bake_vale_terrain.py", "tiles_meters": TILES}
    (PHOTO/"VALE_TERRAIN_BAKE.json").write_text(json.dumps(meta,indent=2)+"\n")
    print("VERBA_TERRAIN_BAKE_COMPLETE",TARGET.stat().st_size,flush=True)


if __name__ == "__main__":
    main()
