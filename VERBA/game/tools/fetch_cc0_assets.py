#!/usr/bin/env python3
"""Fetch selected public-domain game models and PBR photographs into VERBA.

Use before importing/opening project in Godot. Safe to rerun.
Only requests HTTPS URLs from fixed approved domains; no code execution.
"""
from pathlib import Path
from urllib.request import Request, urlopen
import hashlib, json, time, sys
ROOT = Path(__file__).resolve().parents[1]
REAL = ROOT/'assets'/'textures'/'real'
MODELS = ROOT/'assets'/'models'/'cc0'
MANIFEST_FILE = REAL/'VERBA_IMPORTED_CC0.json'
USER_AGENT = 'VERBA/1.2 (+Powered by Poly Haven; https://polyhaven.com)'
# Public-domain material IDs checked on polyhaven.com. For historical typo:
# the Poly Haven ID is forrest_ground_01 (double r).
SURFACES = {
    'meadow_ground': 'forrest_ground_01',
    'woodland_ground': 'forest_floor',
    'amber_ground': 'forest_floor',
    'earth_path': 'forrest_ground_01',
    'bark': 'bark_brown_01',
    'cottage_wood': 'wood_planks',
}
# These exact URLs were verified in the source GitHub repository. All nature
# geometry is from Quaternius' CC0 Stylized Nature MegaKit.
BASE = 'https://raw.githubusercontent.com/anshaneja5/skyline-run/main/public/assets/models/'
GEOMETRY = {n:BASE+n for n in ('tree1.glb','tree2.glb','tree3.glb','bush.glb')}

def get(url):
    request = Request(url, headers={'User-Agent':USER_AGENT})
    with urlopen(request,timeout=45) as response:
        return response.read()

def write_checked(path,data,header):
    if not data.startswith(header): raise ValueError(f'Unexpected format: {path.name}')
    if len(data)<10240: raise ValueError(f'Suspiciously small: {path.name}')
    path.parent.mkdir(parents=True,exist_ok=True)
    tmp=path.with_suffix(path.suffix+'.download')
    tmp.write_bytes(data)
    tmp.replace(path)
    print(' Installed',path.relative_to(ROOT),'(%d KB)'%(len(data)//1024))

def install_models():
    for name,url in GEOMETRY.items():
        target = MODELS/name
        if target.exists() and target.stat().st_size>10240:
            print(' Already present',name); continue
        try: write_checked(target,get(url),b'glTF')
        except Exception as exc: print(' FAILED model',name,':',exc)

def texture_descriptor(asset,channel):
    obj=json.loads(get('https://api.polyhaven.com/files/'+asset).decode('utf-8'))
    maps = ('Diffuse','diffuse') if channel=='diffuse' else ('nor_gl','Normal','normal')
    for key in maps:
        if key not in obj: continue
        for res in ('1k','2k'):
            if res not in obj[key]: continue
            for ext in ('jpg','jpeg'):
                desc=obj[key][res].get(ext)
                if isinstance(desc,dict) and desc.get('url'): return desc
    raise LookupError(f'No jpg map found: {asset}:{channel}')

def install_textures():
    memo={}
    try: installed=json.loads(MANIFEST_FILE.read_text(encoding='utf-8'))
    except (FileNotFoundError, ValueError): installed={}
    for slot,asset in SURFACES.items():
        for channel in ('diffuse','normal'):
            dest = REAL/f'{slot}_{channel}.jpg'
            manifest_key=slot+'_'+channel
            # Bundled v1.1 images are placeholders. Replace them on the first
            # successful external install; subsequent runs are idempotent.
            if installed.get(manifest_key)==asset and dest.exists() and dest.stat().st_size>10240:
                print(' Already installed from Poly Haven',dest.name); continue
            try:
                key=(asset,channel)
                if key not in memo:
                    desc=texture_descriptor(asset,channel)
                    data=get(desc['url'])
                    if desc.get('md5') and hashlib.md5(data).hexdigest().lower() != desc['md5'].lower():
                        raise ValueError('MD5 digest mismatch')
                    memo[key]=data
                write_checked(dest,memo[key],b'\xff\xd8\xff')
                installed[manifest_key]=asset
                MANIFEST_FILE.write_text(json.dumps(installed, indent=2), encoding='utf-8')
            except Exception as exc:
                print(' FAILED texture',slot,channel,':',exc)

if __name__=='__main__':
    print('VERBA CC0 asset installer. All downloaded files remain local.')
    print('Geometry by Quaternius; textures by Poly Haven. No login required.')
    install_models()
    install_textures()
    print('Completed. Open the project in Godot editor so it imports new GLBs/JPGs.')
