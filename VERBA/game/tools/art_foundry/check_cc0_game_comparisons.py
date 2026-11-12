#!/usr/bin/env python3
"""Compare real, fixed-camera Godot CC0 pack integration before/after shots."""
from __future__ import annotations
import json
from pathlib import Path
from PIL import Image,ImageChops,ImageStat
ROOT=Path(__file__).resolve().parents[2]
FOLDER=ROOT/"tests"/"cc0_pack_frames"
NAMES=("01_market_props","02_station_service_yard","03_millward_yard","04_stonecutter_home")

def count_delta(a,b,t=13):
    diff=ImageChops.difference(a,b)
    return sum(1 for pix in diff.getdata() if max(pix)>t)/(diff.width*diff.height)

results=[]
for name in NAMES:
    a_path=FOLDER/(name+"_before.png")
    b_path=FOLDER/(name+"_new.png")
    assert a_path.exists() and b_path.exists(),name+" missing real Godot PNG"
    with Image.open(a_path) as ia: a=ia.convert("RGB")
    with Image.open(b_path) as ib: b=ib.convert("RGB")
    assert a.size==b.size==(1280,720),name+" wrong camera viewport"
    changed=count_delta(a.crop((120,160,1160,710)),b.crop((120,160,1160,710)))
    sky_changed=count_delta(a.crop((0,0,1280,105)),b.crop((0,0,1280,105)))
    image_var=sum(ImageStat.Stat(b).stddev)/3.0
    # Imported CC0 meshes must actually affect the game at each authored site,
    # while camera, sun and sky remain the same. Pixel tests aren't an art review.
    assert changed>.0012,f"{name}: no visible imported prop at camera target ({changed:.2%})"
    assert sky_changed<.03,f"{name}: non-matching sky/camera ({sky_changed:.2%})"
    assert image_var>12,f"{name}: image is blank or uniformly washed out"
    results.append({"site":name,"subject_changed_pct":round(changed*100,3),
                    "sky_changed_pct":round(sky_changed*100,3),
                    "rgb_variation":round(image_var,3)})
    print("PASS CC0_SCREENSHOT",name,results[-1])
(FOLDER/"cc0_source_game_review.json").write_text(json.dumps({
  "method":"real Godot software rendering, identical first-person camera",
  "warning":"Proves visible geometry and stable camera; NOT artistic acceptance",
  "sites":results},indent=2)+"\n")
print("CC0_VISUAL_REVIEW_PASS: four matched 1280x720 original-versus-imported site pairs")
