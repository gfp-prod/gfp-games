#!/usr/bin/env python3
"""VERBA licensed-asset scout: inventory *official* CC0 downloads for art review.

A scouting tool, NOT a gameplay auto-importer. It must not silently replace
collision-bearing scene objects, overwrite character art, or connect at runtime.
Use from the repo's VERBA/game directory:
  python3 tools/art_foundry/scout_cc0_sources.py --out ../cc0_scout_output

All HTTP requests happen during an optional developer/build step. Kenney ZIP
archives are inventoried without extraction. Poly Haven 1K PBR thumbnails are
transformed to small offline PNG review materials. Original URLs, checksums,
license page and failed links are recorded for reproducibility. See the official
Poly Haven live-API attribution requirement:
  https://polyhaven.com/our-api
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from collections import Counter
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REGISTER = Path(__file__).with_name("cc0_source_register.json")
USER_AGENT = "VERBA-Free-CC0-ArtScout/0.1 (github.com/gfp-prod/gfp-games; Powered by Poly Haven)"
INVENTORY_SUFFIX = {".glb", ".gltf", ".fbx", ".obj", ".png", ".jpg", ".jpeg", ".mtl", ".blend"}
ALLOWED_DOWNLOAD_HOSTS = {"kenney.nl", "api.polyhaven.com", "dl.polyhaven.org", "cdn.polyhaven.com"}
HEADERS = {"User-Agent": USER_AGENT, "Accept": "*/*"}

def fetch(url: str, limit: int = 18_000_000) -> bytes:
    origin = urllib.parse.urlsplit(url)
    if origin.scheme != "https" or origin.hostname not in ALLOWED_DOWNLOAD_HOSTS:
        raise ValueError("Asset source outside allowlisted official hosts: " + url)
    request = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(request, timeout=35) as response:
        final = urllib.parse.urlsplit(response.geturl())
        if final.scheme != "https" or final.hostname not in ALLOWED_DOWNLOAD_HOSTS:
            raise ValueError("Untrusted download redirect: " + response.geturl())
        declared = response.headers.get("Content-Length")
        if declared and int(declared) > limit:
            raise ValueError("Asset exceeds scout size limit")
        data = response.read(limit + 1)
        if len(data) > limit:
            raise ValueError("Asset exceeded scout size limit during download")
        return data

def audit_archive(entry: dict, output: Path) -> tuple[dict, Image.Image | None]:
    raw = fetch(entry["url"], int(entry.get("max_zip_mb", 12)) * 1024 * 1024)
    sha = hashlib.sha256(raw).hexdigest()
    expected = entry.get("sha256")
    if expected and sha != expected:
        raise ValueError("Pinned author download checksum mismatch for " + entry["id"])
    if not zipfile.is_zipfile(io.BytesIO(raw)):
        raise ValueError("Official download was not a valid ZIP: " + entry["id"])
    with zipfile.ZipFile(io.BytesIO(raw)) as archive:
        files = [f for f in archive.infolist() if not f.is_dir()]
        if len(files) > 1800 or sum(f.file_size for f in files) > 280_000_000:
            raise ValueError("Archive count or uncompressed size exceeds budget")
        bad = [f.filename for f in files if f.filename.startswith("/")
               or ".." in Path(f.filename).parts or "\\" in f.filename]
        if bad:
            raise ValueError("Unsafe path in ZIP archive: " + str(bad[:3]))
        counts = Counter(Path(f.filename).suffix.lower() for f in files)
        models = sorted(f.filename for f in files
                        if Path(f.filename).suffix.lower() in {".glb", ".gltf", ".obj", ".fbx"})
        photos = [f for f in files if Path(f.filename).suffix.lower() in {".png",".jpg",".jpeg"}
                  and f.file_size <= 4_500_000]
        licenses = [f.filename for f in files if re.search(r"licen[cs]e|cc0|attribution",f.filename,re.I)]
        sample = None
        # Choose a built-in thumbnail/palette instead of rasterizing entire
        # packs. The full set of models still gets a searchable name index.
        for item in sorted(photos,key=lambda f:(0 if re.search(r"preview|render|sample|thumb|color", f.filename,re.I) else 1,f.file_size)):
            try:
                with archive.open(item) as handle:
                    blob = handle.read(4_500_001)
                if len(blob) > 4_500_000: continue
                with Image.open(io.BytesIO(blob)) as img:
                    if img.width < 64 or img.height < 64: continue
                    sample = img.convert("RGB")
                    break
            except (OSError,ValueError,Image.DecompressionBombError):
                continue
    # ZIPs are not silently injected into the game. Source binaries stay
    # in a separate review artifact until the asset is individually approved.
    (output / "raw_packs").mkdir(exist_ok=True,parents=True)
    (output / "raw_packs" / (entry["id"] + ".zip")).write_bytes(raw)
    result = {
        "id": entry["id"],"title": entry["title"],"status":"audited",
        "license":entry["license"],"license_source":entry["page"],
        "official_url":entry["url"],"bytes":len(raw),"sha256":sha,
        "archive_members":len(files),"license_files":licenses[:12],
        "format_counts":{k:v for k,v in sorted(counts.items()) if k in INVENTORY_SUFFIX},
        "model_files":models,"target":entry["target"],
        "approval":"review_only; no game models automatically replaced"
    }
    return result, sample

def _select_variant(matrix: dict, pref: tuple[str,...]) -> dict:
    if not isinstance(matrix,dict):
        raise ValueError("Poly Haven file variant isn't a map")
    size = next((matrix[k] for k in ("1k","1K","1024") if k in matrix),None)
    if not isinstance(size,dict):
        raise ValueError("1K game-resolution texture not offered")
    for ext in pref:
        candidate = size.get(ext)
        if isinstance(candidate,dict) and candidate.get("url"):
            return candidate
    raise ValueError("Preferred image format not provided at 1K")

def material_review(entry: dict, output: Path) -> tuple[dict, Image.Image | None]:
    metadata_bytes = fetch(entry["api"],limit=1_500_000)
    metadata = json.loads(metadata_bytes)
    if not isinstance(metadata,dict):
        raise ValueError("Malformed Poly Haven file metadata")
    channels = {}
    thumbs = None
    base = output / "pbr_preview" / entry["id"]
    base.mkdir(parents=True,exist_ok=True)
    for request_name in ("Diffuse","nor_gl","Rough"):
        # The public API has historically used mixed case key spellings.
        available = next((v for k,v in metadata.items() if k.lower().replace("_","")==
                          request_name.lower().replace("_","")),None)
        if not isinstance(available,dict):
            if request_name == "Diffuse":
                raise ValueError("Missing Diffuse for "+entry["id"])
            continue
        choice = _select_variant(available,("jpg","png") if request_name=="Diffuse" else ("png","jpg"))
        if int(choice.get("size",0)) > 12_000_000:
            raise ValueError("Poly Haven 1K channel too large")
        raw=fetch(choice["url"],limit=12_000_000)
        expected_md5=choice.get("md5")
        if expected_md5 and hashlib.md5(raw).hexdigest()!=expected_md5:
            raise ValueError("Poly Haven checksum mismatch: "+entry["id"]+"/"+request_name)
        with Image.open(io.BytesIO(raw)) as decoded:
            image=decoded.convert("RGB")
        image.thumbnail((512,512),Image.Resampling.LANCZOS)
        if image.width < 128 or image.height < 128:
            raise ValueError("Suspicious tiny source texture")
        destination = base / (request_name.lower()+".png")
        image.save(destination,optimize=True)
        channels[request_name]={
            "source_url":choice["url"],"source_md5":expected_md5,
            "sha256":hashlib.sha256(raw).hexdigest(),
            "processed_path":str(destination.relative_to(output)),"pixels":[image.width,image.height]
        }
        if request_name=="Diffuse":
            thumbs=image.copy()
    return {
        "id":entry["id"],"title":entry["id"].replace("_"," ").title(),
        "status":"audited","license":"CC0-1.0","license_source":entry["page"],
        "provider":"Poly Haven","source_api":entry["api"],
        "channels":channels,"target":entry["target"],
        "attribution_note":"Powered by Poly Haven (live API credit); asset license CC0",
        "approval":"review_only; baked 512px preview is not a final game texture"
    }, thumbs

def contact_sheet(tiles:list[tuple[str,Image.Image|None]],output:Path)->None:
    if not tiles:return
    cols=3
    tile_w,tile_h=400,315
    rows=(len(tiles)+cols-1)//cols
    sheet=Image.new("RGB",(cols*tile_w,rows*tile_h),(37,43,43))
    draw=ImageDraw.Draw(sheet)
    for i,(name,image) in enumerate(tiles):
        x=(i%cols)*tile_w;y=(i//cols)*tile_h
        draw.rectangle((x+4,y+4,x+tile_w-4,y+tile_h-4),fill=(56,63,62))
        if image is not None:
            image.thumbnail((tile_w-20,tile_h-68),Image.Resampling.LANCZOS)
            sx=x+(tile_w-image.width)//2
            sy=y+10+(tile_h-68-image.height)//2
            sheet.paste(image,(sx,sy))
        else:
            draw.text((x+16,y+110),"3D models: geometry preview pending",fill=(191,183,165))
        draw.text((x+14,y+tile_h-47),name[:47],fill=(222,209,183))
        draw.text((x+14,y+tile_h-28),"CC0 | VERBA art scout | review only",fill=(144,162,154))
    sheet.save(output/"cc0_materials_and_pack_previews.jpg",quality=87)

def main()->int:
    parser=argparse.ArgumentParser()
    parser.add_argument("--out",required=True)
    parser.add_argument("--no-network",action="store_true",
                        help="Validate register structure without downloading")
    args=parser.parse_args()
    manifest=json.loads(REGISTER.read_text())
    assert manifest["schema"]=="verba-cc0-source-register-v1"
    for family in ("packs","materials"):
        for entry in manifest[family]:
            assert entry["license"]=="CC0-1.0"
            assert entry["id"] and entry["page"].startswith("https://")
    if args.no_network:
        print("PASS: VERBA official CC0 source register",len(manifest["packs"]),
              "Kenney ZIPs,",len(manifest["materials"]),"Poly Haven PBR sources")
        return 0
    output=Path(args.out).resolve()
    output.mkdir(parents=True,exist_ok=True)
    records={"origin":"VERBA independent source audit",
             "license":"All automatically fetched materials are sourced as CC0-1.0",
             "powered_by":"Poly Haven live API",
             "warning":"No art accepted or imported into active playable scenes",
             "packs":[],"materials":[],"errors":[]}
    tiles=[]
    for family,callback in (("packs",audit_archive),("materials",material_review)):
        for entry in manifest[family]:
            try:
                result,sample=callback(entry,output)
                records[family].append(result)
                tiles.append((entry["id"],sample))
                print("SCOUT_PASS",entry["id"])
            except Exception as exc:
                print("SCOUT_ERROR",entry["id"],str(exc),file=sys.stderr)
                records["errors"].append({"id":entry["id"],"error":str(exc)[:500]})
                tiles.append((entry["id"],None))
    contact_sheet(tiles,output)
    (output/"source_audit.json").write_text(json.dumps(records,indent=2)+"\n")
    audited=sum(len(records[family]) for family in ("packs","materials"))
    print("SCOUT SUMMARY:",audited,"audited of",
          len(manifest["packs"])+len(manifest["materials"]),
          "sources;",len(records["errors"]),"errors")
    return 1 if audited==0 else 0

if __name__=="__main__":
    raise SystemExit(main())
