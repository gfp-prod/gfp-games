"""Deterministic source generator for all original procedural textures in VERBA.
No third-party assets and no AI images or fonts are required.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import gaussian_filter
out=Path(__file__).parent/'assets'/'textures'
out.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(4082)
n=512

def fractal():
    z=np.zeros((n,n))
    for sigma,strength in [(88,2.0),(45,1.6),(21,1.4),(9,.95),(2,.35)]:
        raw=rng.standard_normal((n,n)); sm=gaussian_filter(raw,sigma,mode='wrap');sm=(sm-sm.mean())/(sm.std()+1e-8)
        z+=sm*strength
    z/=z.std()
    return z

def image(base,tone,struct,grain=0.02):
    z=fractal()*0.11+struct
    noise=rng.standard_normal((n,n))*.036
    array=np.clip((np.array(base).reshape((1,1,3)))*(1+z[...,None]*.17+noise[...,None])+np.array(tone).reshape((1,1,3))*z[...,None]*.08,0,255)
    return Image.fromarray(array.astype('uint8'),'RGB')

# Rough-hewn chapel stone, irregular weathering and mineral deposits.
z=fractal()
y,x=np.indices((n,n))
blocks=np.abs(np.sin((x+17*np.sin(y*.015))*.039))*.09 + np.abs(np.sin((y+12*np.sin(x*.018))*.03))*.06
stone=image([155,152,135],[17,14,9],z*.13-blocks)
d=ImageDraw.Draw(stone,'RGBA')
for _ in range(95):
  x0=int(rng.integers(0,n));y0=int(rng.integers(0,n));
  points=[(x0,y0)]; xx=x0;yy=y0
  for k in range(int(rng.integers(2,7))):
    xx=int(xx+rng.integers(-20,21));yy=int(yy+rng.integers(-8,19));points.append((xx,yy))
  d.line(points,fill=(57,59,52,47),width=int(rng.integers(1,3)))
stone.save(out/'stone.png')
# Vertical soft bark fissures. Substantial relief comes from actual mesh geometry.
y,x=np.indices((n,n))
streak=np.sin(x*.13 + 2.1*np.sin(y*.029)+.7*np.sin(y*.1))*.16
bark=image([117,96,77],[20,17,9],streak+fractal()*.07)
d=ImageDraw.Draw(bark,'RGBA')
for _ in range(205):
  x0=int(rng.integers(0,n));y0=int(rng.integers(0,n)); h=int(rng.integers(20,190))
  d.line([(x0,y0),(x0+int(rng.integers(-4,5)),y0+h)],fill=(25,16,12,int(rng.integers(28,84))),width=int(rng.integers(1,5)))
bark.save(out/'bark.png')
# Hewn timber with grain and non-uniform age.
wood=image([155,129,98],[20,12,5],np.sin(x*.045+np.sin(y*.022))*.12)
d=ImageDraw.Draw(wood,'RGBA')
for _ in range(105):
  px=int(rng.integers(0,n));py=int(rng.integers(0,n))
  d.line([(px,py),(px+int(rng.integers(-3,4)),py+int(rng.integers(30,130)))],fill=(35,29,20,int(rng.integers(14,60))),width=int(rng.integers(1,3)))
wood.save(out/'wood.png')
# Oxblood leather, not plain purple plastic.
leather=image([80,49,43],[5,3,3],fractal()*.06)
d=ImageDraw.Draw(leather,'RGBA')
for _ in range(1100):
  px=int(rng.integers(0,n));py=int(rng.integers(0,n));r=int(rng.integers(1,4))
  d.arc((px,py,px+r*3,py+r*3),0,160,fill=(20,11,10,25))
leather.save(out/'leather.png')
# Dirty vellum with warm edges, subtle watercolor blooms.
y,x=np.indices((n,n)); edge=np.minimum.reduce([x,y,n-x-1,n-y-1]);aging=np.exp(-edge/44.0)*-.15
paper=image([205,189,150],[9,7,4],fractal()*.12+aging)
paper.save(out/'vellum.png')
print('Produced',[(p.name,p.stat().st_size) for p in out.glob('*.png')])
