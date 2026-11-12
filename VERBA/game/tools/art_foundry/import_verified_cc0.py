#!/usr/bin/env python3
"""Reproducibly import selected *actual* CC0 retro models and Poly Haven textures.

Run in GitHub Actions, never at game runtime. Import from an immutable git
commit of a Kenney CC0 mirror, with individual Git blob SHA-1 checks. Import
Poly Haven 1k source channels with upstream MD5 verified and bake to
512px review-ready PNG. No paid asset or cookie-gated itch download needed.

The download manifest is deliberately a small set of actual authored props,
not an indiscriminate 100-piece kit. Do not turn the art style into a collage.
"""
from __future__ import annotations
import hashlib
import io
import json
import shutil
import struct
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"assets"
PIN="3694c6879e487c108f55677be7dd2ca75b07cc3b"
SOURCE="https://raw.githubusercontent.com/shorepine/kenney/"+PIN+"/3d"
USER_AGENT="VERBA-CC0-Importer/1.0 (gfp-prod/gfp-games, free CC0 game project)"
# The SHA identifiers are the git objects from the immutable mirror revision.
MODELS={
    "retro-fantasy":{
        "barrels.glb":"08d0e7c637f2a9c5dd52e42b3255bd70b8ebb3ab",
        "column-damaged.glb":"bf911a325517aab3343ad9ba52bebd0e66d4d0b3",
        "detail-crate-ropes.glb":"38153f8f5e920a02b9e2c60b7a64a2d91d333df8",
        "detail-crate.glb":"6d5d96e5d11c6b5aa5fee4c54242678ce596534e",
        "ladder.glb":"6dd4968d0d38b836785c2e2591a577245246adfa",
        "stairs-stone.glb":"0ea750ccf55605b3a11c8a8958858ea34116c936",
    },
    "retro-urban":{
        "detail-barrier-strong-damaged.glb":"babd1171f3152d61987921cad2c0a80f7db6f61f",
        "detail-bricks-type-a.glb":"7e39b4d567780ba400d155dbf3c5bd2ddc4c4522",
        "detail-cables-type-a.glb":"211524e37cf9fab3258381e7cb9b1d9018b0cbd8",
        "detail-dumpster-closed.glb":"12db8e174cd3f0da9e101433502d7955c228f7be",
        "pallet.glb":"69db3352973a45a9c189e134afd0c449c9a6be6f",
    },
    "furniture":{
        "bedSingle.glb":"eb79d7ae7cb9a69dc8e27c5c37db72e6759ce0a0",
        "bookcaseOpen.glb":"9a0cce7691e94277f3409719e9e68c910c25aa2c",
        "books.glb":"615aaa9632cf1b262c257f2cb7c208a6f199ab84",
        "chair.glb":"2d57af4fef2a32910e3af9283d1e45f177068d63",
        "table.glb":"8add1baf8a97bd813524a441c947a9e1457f4b13"
    },
}
SHARED={
    "retro-fantasy":("barrel","cobblestone","cobblestoneAlternative",
         "cobblestonePainted","details","fence","planks","roof","tree","water"),
    "retro-urban":("asphalt","bars","concrete","dirt","doors","grass",
         "metal","metal_wall","planks","rock","roof","roof_plates","signs",
         "tiles","treeA","treeB","truck","truck_alien","wall","wall_garage",
         "wall_lines","windows"),
}
# Successfully audited official Poly Haven metadata by the independent scout.
PBR=("weathered_planks","mossy_cobblestone","damaged_plaster","mossy_rock")

def download(url:str,limit:int=25_000_000)->bytes:
    p=urllib.parse.urlsplit(url)
    if p.scheme!="https" or p.hostname not in {
        "raw.githubusercontent.com","api.polyhaven.com",
        "dl.polyhaven.org","cdn.polyhaven.com"
    }:
        raise ValueError("Untrusted source origin: "+url)
    for attempt in range(4):
        try:
            req=urllib.request.Request(url,headers={"User-Agent":USER_AGENT})
            with urllib.request.urlopen(req,timeout=65) as resp:
                actual=urllib.parse.urlsplit(resp.geturl())
                if actual.scheme!="https" or actual.hostname not in {
                    "raw.githubusercontent.com","api.polyhaven.com",
                    "dl.polyhaven.org","cdn.polyhaven.com"
                }:
                    raise ValueError("Untrusted download redirect "+resp.geturl())
                length=resp.headers.get("Content-Length")
                if length and int(length)>limit:
                    raise ValueError("Asset exceeds budget: "+url)
                data=resp.read(limit+1)
                if len(data)>limit:raise ValueError("Download limit exceeded")
                return data
        except Exception:
            if attempt==3:raise
            time.sleep(min(2**attempt,6))

def git_blob_sha(data:bytes)->str:
    prefix=b"blob "+str(len(data)).encode()+b"\x00"
    return hashlib.sha1(prefix+data).hexdigest()

def verify_glb(data:bytes,filename:str)->dict:
    if len(data)<24:raise ValueError("Truncated GLB "+filename)
    magic,version,length=struct.unpack("<4sII",data[:12])
    if (magic,version,length)!=(b"glTF",2,len(data)):
        raise ValueError("Not a valid GLB 2.0 "+filename)
    size,kind=struct.unpack("<II",data[12:20])
    if kind!=0x4e4f534a or size>len(data)-20:
        raise ValueError("Missing GLB 2.0 JSON chunk")
    meta=json.loads(data[20:20+size])
    if not meta.get("meshes") or not meta.get("nodes"):
        raise ValueError("GLB has no geometry "+filename)
    refs=[]
    for image in meta.get("images",[]):
        path=image.get("uri")
        if path and not path.startswith("data:"):
            parts=Path(path).parts
            if path.startswith("/") or ".." in parts or "\\" in path:
                raise ValueError("Unsafe GLB texture reference "+path)
            refs.append(path)
    return {"meshes":len(meta["meshes"]),"nodes":len(meta["nodes"]),
            "images":len(meta.get("images",[])),"external_images":refs}

def _poly_variant(metadata:dict,keys:tuple[str,...],extensions:tuple[str,...]):
    channel=next((v for k,v in metadata.items()
           if k.lower().replace("_","") in
              {q.lower().replace("_","") for q in keys}),None)
    if not isinstance(channel,dict):raise KeyError(str(keys))
    variants=next((channel[k] for k in ("1k","1K","1024") if k in channel),None)
    if not isinstance(variants,dict):raise ValueError("No 1K source")
    for ext in extensions:
        item=variants.get(ext)
        if item and item.get("url"):return item
    raise ValueError("No supported PBR 1K image")

def import_models(records:list):
    for kit,members in MODELS.items():
        folder=OUT/"models"/"cc0"/"kenney"/kit
        folder.mkdir(exist_ok=True,parents=True)
        for filename,expected in members.items():
            url=SOURCE+"/"+kit+"/"+filename
            data=download(url,2_000_000)
            if git_blob_sha(data)!=expected:
                raise ValueError("Unpinned geometry: "+url)
            info=verify_glb(data,filename)
            (folder/filename).write_bytes(data)
            records.append({"kind":"model","family":kit,"filename":filename,
              "repo_revision":PIN,"git_blob_sha":expected,
              "sha256":hashlib.sha256(data).hexdigest(),"size":len(data),
              "original_publisher":"Kenney","original_license":"CC0-1.0",
              "publisher_page":"https://kenney.nl/assets/retro-fantasy-kit"
                 if kit=="retro-fantasy" else
                 "https://kenney.nl/assets/retro-urban-kit"
                 if kit=="retro-urban" else "https://kenney.nl/assets/furniture-kit",
              "mirror_url":url,"geometry":info})
            print("IMPORTED_GLTF",kit,filename,info)
        for image_name in SHARED.get(kit,()):
            filename=image_name+".png"
            data=download(SOURCE+"/"+kit+"/Textures/"+filename,500000)
            with Image.open(io.BytesIO(data)) as im:
                if im.width<16 or im.height<16 or im.width>4096:
                    raise ValueError("Bad shared texture size")
                im.verify()
            target=folder/"Textures"
            target.mkdir(exist_ok=True)
            (target/filename).write_bytes(data)
            records.append({"kind":"texture","family":kit,"filename":filename,
                "origin":"Kenney CC0 via immutable mirror "+PIN,
                "sha256":hashlib.sha256(data).hexdigest(),"size":len(data)})
    # We downloaded the complete texture subdirectories, so all relative
    # image names in glTF/GLB resolve on the destination under Textures/.
    for rec in records:
        if rec["kind"]=="model":
            folder=OUT/"models"/"cc0"/"kenney"/rec["family"]
            for rel in rec["geometry"]["external_images"]:
                if not (folder/rel).is_file():
                    raise ValueError("Missing packed retro material "+rel)

def import_pbr(records:list):
    parent=OUT/"textures"/"cc0"/"polyhaven"
    parent.mkdir(exist_ok=True,parents=True)
    for material_id in PBR:
        api="https://api.polyhaven.com/files/"+material_id
        metadata=json.loads(download(api,3_000_000))
        for channel,aliases,prefs in [
            ("diffuse",("Diffuse",),("jpg","png")),
            ("normal",("nor_gl","normal_gl"),("png","jpg")),
            ("rough",("Rough","roughness"),("png","jpg"))
        ]:
            try:
                info=_poly_variant(metadata,aliases,prefs)
            except (KeyError,ValueError):
                if channel=="diffuse":raise
                continue
            raw=download(info["url"],14_000_000)
            if info.get("md5") and hashlib.md5(raw).hexdigest()!=info["md5"]:
                raise ValueError("Poly Haven MD5 mismatch "+material_id+":"+channel)
            with Image.open(io.BytesIO(raw)) as im:
                if im.width<512 or im.height<512:
                    raise ValueError("PBR texture unexpectedly tiny")
                image=im.convert("RGB")
            image.thumbnail((1024,1024),Image.Resampling.LANCZOS)
            dest=parent/(material_id+"_"+channel+".png")
            image.save(dest,optimize=True)
            records.append({"kind":"pbr","family":"polyhaven","id":material_id,
                "channel":channel,"author":"Poly Haven","license":"CC0-1.0",
                "api":api,"source":info["url"],
                "raw_sha256":hashlib.sha256(raw).hexdigest(),
                "saved_sha256":hashlib.sha256(dest.read_bytes()).hexdigest(),
                "resolution":image.size,
                "saved_path":str(dest.relative_to(ROOT))})
            print("IMPORTED_PBR",material_id,channel,dest.stat().st_size)

def main():
    records=[]
    import_models(records)
    import_pbr(records)
    meta={"schema":"verba-cc0-import-v1","original_creator":"Kenney / Poly Haven",
          "license":"All items CC0-1.0, see specific original source pages",
          "mirror_immutable_commit":PIN,"data":records,
          "warning":"No material/mesh silently replaces a hero asset; Godot scene review required."}
    dest=OUT/"models"/"cc0"/"kenney"/"SOURCE_MANIFEST.json"
    dest.write_text(json.dumps(meta,indent=2)+"\n")
    print("CC0_IMPORT_SUCCESS",len(MODELS),len(records),
          sum(x["kind"]=="model" for x in records),
          sum(x["kind"]=="pbr" for x in records))

if __name__=="__main__":
    main()
