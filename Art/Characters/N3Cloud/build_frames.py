#!/usr/bin/env python3
"""Build SpriteFrames from verified, fixed-origin source cells without image edits."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
manifest = json.loads((ROOT / 'animation_manifest.json').read_text())
source = ROOT / manifest['source']
assert hashlib.sha256(source.read_bytes()).hexdigest() == manifest['source_sha256']
image = Image.open(source)
assert list(image.size) == manifest['source_dimensions'] and image.mode == 'RGBA'
coordinates = sorted({tuple(p) for a in manifest['animations'] for p in a['coordinates']})
lines = [f'[gd_resource type="SpriteFrames" load_steps={len(coordinates)+2} format=3]', '',
         '[ext_resource type="Texture2D" path="res://Art/Characters/N3Cloud/Full-Sheet.png" id="1_sheet"]', '']
for c,r in coordinates:
    assert 0 <= c < 14 and 0 <= r < 41
    assert image.crop((c*128,r*80,(c+1)*128,(r+1)*80)).getbbox()
    lines += [f'[sub_resource type="AtlasTexture" id="Frame_{c}_{r}"]',
              'atlas = ExtResource("1_sheet")', f'region = Rect2({c*128}, {r*80}, 128, 80)', 'filter_clip = true', '']
lines += ['[resource]', 'animations = [']
for i,animation in enumerate(manifest['animations']):
    frames = ', '.join('{"duration": 1.0, "texture": SubResource("Frame_%d_%d")}' % tuple(p) for p in animation['coordinates'])
    lines += ['{', f'"frames": [{frames}],', f'"loop": {str(animation["loop"]).lower()},',
              f'"name": &"{animation["name"]}",', f'"speed": {animation["fps"]}', '}' + (',' if i+1<len(manifest['animations']) else '')]
lines += [']', '']
(ROOT / 'character_frames.tres').write_text('\n'.join(lines))
print(f'Built {len(manifest["animations"])} animations using {len(coordinates)} verified source cells')
