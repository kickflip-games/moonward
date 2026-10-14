#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import unittest
from PIL import Image

REPO = Path(__file__).resolve().parents[1]
ASSETS = REPO / 'Art/Characters/N3Cloud'
BASELINE = '56dc329'

class CharacterAssets(unittest.TestCase):
    def test_exact_original_and_grid(self):
        manifest = json.loads((ASSETS/'animation_manifest.json').read_text())
        source = ASSETS/'Full-Sheet.png'
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(),manifest['source_sha256'])
        im = Image.open(source)
        self.assertEqual(im.size,(1792,3280))
        self.assertEqual(im.mode,'RGBA')
        self.assertEqual(im.getchannel('A').getextrema(),(0,255))
        self.assertEqual(im.width//128,14)
        self.assertEqual(im.height//80,41)
        self.assertFalse(manifest['padding_required'])

    def test_manifest_has_no_empty_or_out_of_bounds_frames(self):
        manifest = json.loads((ASSETS/'animation_manifest.json').read_text())
        im = Image.open(ASSETS/'Full-Sheet.png')
        self.assertEqual(len(manifest['animations']),52)
        self.assertEqual(len({a['name'] for a in manifest['animations']}),52)
        for a in manifest['animations']:
            self.assertEqual(a['frame_count'],len(a['coordinates']))
            for c,r in a['coordinates']:
                self.assertTrue(0<=c<14 and 0<=r<41)
                self.assertIsNotNone(im.crop((c*128,r*80,(c+1)*128,(r+1)*80)).getbbox())
        roll=next(a for a in manifest['animations'] if a['name']=='roll__roll')
        self.assertEqual(roll['coordinates'],[[c,34] for c in range(9)])

    def test_resource_rebuild_is_identical(self):
        before=(ASSETS/'character_frames.tres').read_bytes()
        subprocess.run([sys.executable,str(ASSETS/'build_frames.py')],check=True,capture_output=True)
        self.assertEqual(before,(ASSETS/'character_frames.tres').read_bytes())

    def test_physics_and_scene_colliders_are_unchanged(self):
        protected=['Player/Player.gd','World/Map/map.tscn','Platforms/MovingPlatform.gd',
                   'Platforms/bouncy/bouncy_platform.gd','Platforms/breakable/breakable_platform.gd',
                   'Globals/CheckpointManager.gd','Globals/HeightTracker.gd']
        for path in protected:
            with self.subTest(path=path):
                baseline=subprocess.check_output(['git','show',f'{BASELINE}:{path}'],cwd=REPO)
                self.assertEqual(baseline,(REPO/path).read_bytes())
        old=subprocess.check_output(['git','show',f'{BASELINE}:Player/Player.tscn'],cwd=REPO,text=True)
        new=(REPO/'Player/Player.tscn').read_text()
        def blocks(text):
            return re.findall(r'\[(?:sub_resource|node)[^\n]+\]\n(?:[^\[]|\[(?!node |sub_resource |ext_resource |connection))*',text)
        old_blocks=blocks(old);new_blocks=blocks(new)
        for block in old_blocks:
            if 'type="RectangleShape2D"' in block or 'type="SeparationRayShape2D"' in block or 'type="CollisionShape2D"' in block or 'type="RayCast2D"' in block or 'type="ShapeCast2D"' in block or 'name="HurtArea"' in block:
                self.assertIn(block,new_blocks)
        def root(text):
            return text.split('[node name="Player" type="CharacterBody2D" groups=["Player"]]')[1].split('[node ')[0]
        self.assertEqual(root(old),root(new))

if __name__=='__main__':unittest.main(verbosity=2)
