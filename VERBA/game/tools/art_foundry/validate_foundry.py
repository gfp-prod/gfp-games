#!/usr/bin/env python3
"""Strict check on exported, reusable Blender -> Godot artwork."""
from __future__ import annotations
import argparse
import json
import hashlib
from pathlib import Path
from struct import unpack_from
from PIL import Image, ImageStat

def check(out: Path):
    filename=out/"hermit_cottage_v2.glb"
    blob=filename.read_bytes()
    assert len(blob)>20000, "Asset GLB unexpectedly empty"
    magic,version,length=unpack_from("<III",blob,0)
    assert (magic,version,length)==(0x46546C67,2,len(blob)), "Broken glTF 2.0 container"
    size,tag=unpack_from("<II",blob,12)
    assert tag==0x4E4F534A, "glb JSON chunk missing"
    data=json.loads(blob[20:20+size].decode("utf-8").rstrip("\0 "))
    meshes=data.get("meshes",[])
    materials=data.get("materials",[])
    assert len(meshes)>=7, f"Only {len(meshes)} mesh sections"
    assert len(materials)>=7, f"Only {len(materials)} authored PBR materials"
    assert len(data.get("images",[]))>=5, "PBR textures were not embedded"
    accessors=data["accessors"]
    bound_min=[float("inf")]*3
    bound_max=[float("-inf")]*3
    triangles=0
    for mesh in meshes:
        for prim in mesh["primitives"]:
            attr=prim["attributes"]
            assert "TEXCOORD_0" in attr, f"Missing UVs: {mesh['name']}"
            assert "NORMAL" in attr, f"Missing surface normals: {mesh['name']}"
            aa=accessors[attr["POSITION"]]
            for axis in range(3):
                bound_min[axis]=min(bound_min[axis],aa["min"][axis])
                bound_max[axis]=max(bound_max[axis],aa["max"][axis])
            if "indices" in prim:
                triangles+=accessors[prim["indices"]]["count"]//3
            else:
                triangles+=aa["count"]//3
    dims=[b-a for a,b in zip(bound_min,bound_max)]
    assert 5.3<dims[0]<10.0 and 5.0<dims[1]<9.0 and 4.8<dims[2]<9.0, (
        f"Scale/orientation changed. Model extent must be meters; got {dims}")
    assert triangles>1500, f"Slates, stone courses or joinery lost: {triangles} triangles"
    cameras=["01_front_entry","02_riverside_side",
             "03_moss_slate_roof","04_back_and_chimney"]
    for name in cameras:
        pic=out/f"{name}.png"
        assert pic.exists(), f"No Blender camera evidence: {pic}"
        with Image.open(pic) as img:
            assert img.size==(760,570), f"Wrong art review resolution: {pic}: {img.size}"
            contrast=sum(ImageStat.Stat(img.convert("RGB")).stddev)/3
            assert contrast>13, f"Render is blank or dark: {pic} contrast={contrast}"
    assert (out/"hermit_cottage_v2.blend").stat().st_size>15000, (
        "Editable Blender source was not saved")
    manifest=json.loads((out/"provenance.json").read_text())
    assert manifest["glb_sha256"]==hashlib.sha256(blob).hexdigest()
    assert manifest["asset_id"]=="hermit_cottage_v2"
    assert len(manifest["textures"])>=5
    print("FOUNDRY VALIDATED",json.dumps({
        "mesh_count":len(meshes),"materials":len(materials),
        "packed_images":len(data.get("images",[])),
        "triangles":triangles,"extent_m":[round(a,2) for a in dims],
        "camera_frames":len(cameras)},sort_keys=True))
    return 0

if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--out",type=Path,required=True)
    args=parser.parse_args()
    check(args.out.resolve())
