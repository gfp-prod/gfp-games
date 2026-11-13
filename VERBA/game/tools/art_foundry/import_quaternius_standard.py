#!/usr/bin/env python3
"""Stage four actual free Quaternius Standard medieval modules from a CC0 mirror.
No proprietary Source/Pro assets, no cookies, paid archives or runtime network.
Original creator: Quaternius, Medieval Village MegaKit Standard (2025-04-22).
Source mirror: github.com/J-Ponzo/gltf-medieval-village-megakit, pinned.
"""
from __future__ import annotations
import hashlib,io,json,sys,time,urllib.parse,urllib.request
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"assets/models/cc0/quaternius/medieval-standard"
REVISION="21104b4045261c28fc312360841ed1a7b0ac8782"
SOURCE="https://raw.githubusercontent.com/J-Ponzo/gltf-medieval-village-megakit/"+REVISION+"/glTF/"
NAMES=("WindowShutters_Wide_Flat_Open","Stairs_Exterior_Straight","Wall_Arch","Prop_Chimney")
LICENSE="https://quaternius.com/packs/medievalvillagemegakit.html"

def fetch(name:str,cap:int=18_000_000)->bytes:
    url=SOURCE+name
    parts=urllib.parse.urlsplit(url)
    if parts.hostname!="raw.githubusercontent.com" or ".." in Path(parts.path).parts:
        raise ValueError("Unverified download path")
    for attempt in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(url,headers={
                "User-Agent":"VERBA-Quaternius-Standard-CC0/1.0"}),timeout=80) as r:
                if urllib.parse.urlsplit(r.geturl()).hostname!="raw.githubusercontent.com":
                    raise ValueError("Unexpected redirected asset host")
                data=r.read(cap+1)
                if len(data)>cap:raise ValueError("Source larger than set budget")
                return data
        except Exception:
            if attempt==3:raise
            time.sleep(min(2**attempt,6))

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    assets=[]
    needed_textures=set()
    for name in NAMES:
        filename=name+".gltf"
        content=fetch(filename,500_000)
        model=json.loads(content)
        if not model.get("meshes") or not model.get("nodes"):
            raise ValueError("Incomplete free Standard geometry: "+name)
        for buffer in model.get("buffers",[]):
            uri=buffer["uri"]
            if "/" in uri or "\\" in uri or not uri.endswith(".bin"):
                raise ValueError("Disallowed external mesh reference "+uri)
            blob=fetch(uri,3_000_000)
            if len(blob)!=int(buffer["byteLength"]):
                raise ValueError("Quaternius mesh size mismatch "+name)
            (OUT/uri).write_bytes(blob)
        for im in model.get("images",[]):
            uri=im.get("uri","")
            if "/" in uri or "\\" in uri or not uri.endswith(".png"):
                raise ValueError("Unverified external glTF texture "+uri)
            needed_textures.add(uri)
        (OUT/filename).write_bytes(content)
        assets.append({"model":filename,"repo_revision":REVISION,
          "file_sha256":hashlib.sha256(content).hexdigest(),
          "meshes":len(model["meshes"]),"materials":len(model.get("materials",[])),
          "animations":len(model.get("animations",[])),
          "images":[i["uri"] for i in model.get("images",[])]})
        print("VERIFIED_QUATERNIUS_STANDARD",name,len(content))
    textures=[]
    for name in sorted(needed_textures):
        raw=fetch(name,18_000_000)
        with Image.open(io.BytesIO(raw)) as source:
            if source.width<128 or source.height<128:
                raise ValueError("Suspiciously tiny official free Standard texture")
            mode="RGBA" if "A" in source.getbands() else "RGB"
            image=source.convert(mode)
        image.thumbnail((1024,1024),Image.Resampling.LANCZOS)
        path=OUT/name
        image.save(path,optimize=True)
        textures.append({"file":name,"original_sha256":hashlib.sha256(raw).hexdigest(),
                         "baked_sha256":hashlib.sha256(path.read_bytes()).hexdigest(),
                         "size":image.size})
        print("VERIFIED_QUATERNIUS_PBR",name,image.size)
    manifest={"schema":"verba-quaternius-standard-v1",
              "original_artist":"Quaternius",
              "original_pack":"Medieval Village MegaKit Standard (the genuinely free subset)",
              "license":"CC0-1.0","original_pack_page":LICENSE,
              "mirror_repo":"J-Ponzo/gltf-medieval-village-megakit",
              "pinned_source_commit":REVISION,
              "note":"Free Standard only, NOT paid Pro/Source. Original exported glTF with reduced 1K surface maps.",
              "models":assets,"textures":textures}
    (OUT/"SOURCE_MANIFEST.json").write_text(json.dumps(manifest,indent=2)+"\n")
    (OUT/"LICENSE-ORIGIN.md").write_text(
        "# Quaternius Medieval Village MegaKit Standard\n\n"
        "Source: "+LICENSE+"\n"
        "License: CC0 1.0 Universal, free Standard distribution\n"
        "Mirror, original-license evidence and pinned revision: "
        "https://github.com/J-Ponzo/gltf-medieval-village-megakit/tree/"+REVISION+"\n"
        "Four assets individually extracted from the public CC0 Standard subset. "
        "No paid Source/Pro files, engine project or source .blend files included.\n")
    print("QUATERNIUS_STANDARD_IMPORT_PASS",len(assets),len(textures))

if __name__=="__main__":
    main()
