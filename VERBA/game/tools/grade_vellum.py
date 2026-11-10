"""Art-directed, genuinely textured parchment — offline authoring.

Uses our already-authored vellum image as a texture source. Retains pores,
stains and age variation, but removes the saturated yellow color that made
the real first-person grimoire appear to be two luminous flat screens.
"""
from pathlib import Path
from PIL import Image
import numpy as np

ROOT = Path(__file__).resolve().parents[1] / "assets" / "textures" / "authored"
source = ROOT / "aged_vellum.png"
target = ROOT / "vellum_cream.png"
raw = np.asarray(Image.open(source).convert("RGB"),dtype=np.float32)
# Preserve relative manuscript weathering but unify it under a cream/linen
# palette. Avoid pure white, neon yellow and a screen-filling orange wash.
luma = raw[:,:,0]*.265+raw[:,:,1]*.620+raw[:,:,2]*.115
lo,hi=np.percentile(luma,[5,95])
tone = np.clip((luma-(lo+hi)*.5) / max(hi-lo,1.0),-.9,.9)
# Difference in channel values creates warm paper without gold saturation.
base = np.array([201.,188.,165.],dtype=np.float32)
color = base[None,None,:] + tone[:,:,None]*np.array([44.,40.,35.],dtype=np.float32)
# Slightly darkened vignette at page edge, never hard brown line; the real 3D
# board and leaf edges provide silhouette, this is subtle surface pigment.
h,w=luma.shape
y,x=np.ogrid[:h,:w]
edge=np.minimum.reduce(np.broadcast_arrays(x,y,w-1-x,h-1-y)).astype(np.float32)
warm=np.exp(-edge/max(35.0,min(w,h)*.16)) * -9.0
color[:,:,0] += warm*.80
color[:,:,1] += warm
color[:,:,2] += warm*1.12
Image.fromarray(np.clip(color,0,255).astype(np.uint8)).save(target,optimize=True)
print("VERBA CREAM VELLUM",target,source.stat().st_size,target.stat().st_size)
