#!/usr/bin/env python3
"""Technical acceptance for REAL Godot village original/new comparisons.

This cannot rank artistic beauty. It catches missing new geometry, changed
cameras, flat colors, and bogus comparison frames. Final visual judgement
remains a human-readable paired screenshot review.
"""
from __future__ import annotations
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageStat

ROOT=Path(__file__).resolve().parents[2]
FRAMES=ROOT/"tests"/"village_frames"
NAMES=("01_bakery","02_forge","03_market")
REGION=(300,170,980,685)
SKY=(0,0,180,100)

def difference(a:Image.Image,b:Image.Image,threshold:int=22)->float:
    delta=ImageChops.difference(a,b)
    changed=sum(max(rgb)>threshold for rgb in delta.getdata())
    return changed/(delta.width*delta.height)

def check():
    metrics=[]
    for name in NAMES:
        pair={}
        for state in ("original","new"):
            path=FRAMES/f"{name}_{state}.png"
            assert path.is_file(),f"Missing real matched engine screenshot: {path}"
            with Image.open(path) as f:
                img=f.convert("RGB")
            assert img.size==(1280,720),f"Viewport unexpectedly changed: {path}"
            pair[state]=img
        old,new=pair["original"],pair["new"]
        sky_change=difference(old.crop(SKY),new.crop(SKY),threshold=16)
        change=difference(old.crop(REGION),new.crop(REGION))
        variation=sum(ImageStat.Stat(new.crop(REGION)).stddev)/3
        assert sky_change < .035, f"{name}: different camera, weather or time ({sky_change:.1%})"
        assert .035<=change<=.89, f"{name}: likely missing/improperly aligned model ({change:.1%})"
        assert variation>13.5, f"{name}: new asset is blank or washed out ({variation:.1f})"
        metrics.append({"model":name,"changed_subject_pixels":round(change,4),
                        "changed_background_pixels":round(sky_change,4),
                        "new_frame_rgb_variation":round(variation,2)})
        print(f"VILLAGE_MATCHED_GAME_PROOF {name}: changed={change:.1%}, "
              f"sky={sky_change:.2%}, variation={variation:.1f}")
    out=FRAMES/"technical_comparison_report.json"
    out.write_text(json.dumps({"nature":"pixel QA, not artistic approval",
                               "views":metrics},indent=2)+"\n")
    print("PASS: all three village old/new pairs show actual new geometry under a fixed in-game lens")

if __name__=="__main__":
    check()
