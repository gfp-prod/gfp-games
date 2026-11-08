"""Rebuild offline photographed CC0 ground and masonry maps from scikit-image's
bundled original CC0 images. No network or extra tooling needed for users.
Sources: skimage.data.grass, gravel, brick. RGB coloration varies naturally
with tonal response; original high-frequency photographic detail is preserved.
"""
from pathlib import Path
from skimage import data
from scipy.ndimage import gaussian_filter
from PIL import Image
import numpy as np

root=Path(__file__).resolve().parents[1]
out=root/'assets/textures/real';out.mkdir(exist_ok=True,parents=True)
photo={'grass':data.grass(),'gravel':data.gravel(),'brick':data.brick()}
# Neutral base, adjusted subtly to the vale's palette. Original photo intensity drives texture.
styles={
 'meadow_ground': ('grass',(101,116,75),.58,13),
 'woodland_ground': ('grass',(92,83,60),.57,16),
 'amber_ground': ('grass',(119,91,60),.63,15),
 'river_silt': ('gravel',(78,88,82),.74,9),
 'earth_path': ('gravel',(122,96,65),.70,12),
 'stone': ('gravel',(120,126,119),.79,8),
 'moss': ('grass',(75,96,63),.55,10),
 'cottage_plaster': ('brick',(180,164,137),.46,8),
 'cottage_roof': ('brick',(83,89,98),.64,8),
}
for slot,(sample,bgr,contrast,mottle) in styles.items():
 a=photo[sample].astype('float32')
 a=np.concatenate([a,np.fliplr(a)],axis=1)
 a=np.concatenate([a,np.flipud(a)],axis=0)
 a=(a-np.mean(a))/max(1.,np.std(a))
 detail=np.clip(a,-2.4,2.4)
 # Low frequency composition comes from real photographic image as well.
 low=gaussian_filter(detail,19)
 base=np.array(bgr,dtype='float32')
 image=base[None,None,:] + detail[:,:,None]*np.array([34,34,31])[None,None,:]*contrast + low[:,:,None]*mottle
 image=np.clip(image,4,248).astype('uint8')
 Image.fromarray(image,'RGB').save(out/(slot+'_diffuse.jpg'),quality=91,subsampling=0)
 # OpenGL tangent normal: source height is the actual photographed surface value.
 gy,gx=np.gradient(gaussian_filter(detail,0.8))
 strength=.12 if sample=='grass' else .16
 nx=np.clip(-gx*strength,-.65,.65);ny=np.clip(-gy*strength,-.65,.65)
 nz=np.ones_like(nx)
 norm=np.sqrt(nx*nx+ny*ny+nz*nz)
 rgb=(np.stack([nx/norm,ny/norm,nz/norm],axis=2)*.5+.5)*255
 Image.fromarray(np.clip(rgb,0,255).astype('uint8'),'RGB').save(out/(slot+'_normal.jpg'),quality=93,subsampling=0)
 print(slot,sample)
