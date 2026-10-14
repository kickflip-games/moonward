#!/usr/bin/env python3
"""Validate native atlas geometry, original-pixel crops and deterministic assembly."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "Art/BlackSpire"


class BlackSpireAssets(unittest.TestCase):
    def setUp(self):
        self.meta = json.loads((ROOT / "catalog.json").read_text())

    def test_source_preservation_and_alpha(self):
        dimensions = {"Medieval_tiles_free_2.0.png": (1024, 824),
                      "Medieval_props_free.png": (512, 200)}
        for name, size in dimensions.items():
            with self.subTest(source=name):
                path = ROOT / "Source" / name
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), self.meta["source_sha256"][name])
                image = Image.open(path)
                self.assertEqual(image.size, size)
                self.assertEqual(image.mode, "RGBA")
                self.assertEqual(image.getchannel("A").getextrema(), (0, 255))

    def test_terrain_cells_and_masks(self):
        atlas = Image.open(ROOT / "Terrain/terrain_atlas.png")
        self.assertEqual(atlas.size, (192, 96))
        self.assertEqual({t["mask"] for t in self.meta["terrain_tiles"] if t["kind"] == "terrain"}, set(range(16)))
        occupied = set()
        for tile in self.meta["terrain_tiles"]:
            with self.subTest(tile=tile["name"]):
                x, y = tile["atlas_coords"]
                self.assertNotIn((x, y), occupied)
                occupied.add((x, y))
                self.assertLessEqual((x+1)*24, atlas.width)
                self.assertLessEqual((y+1)*24, atlas.height)
                self.assertGreaterEqual(x, 0)
                self.assertGreaterEqual(y, 0)
                points = tile["collision"]
                self.assertGreaterEqual(len(points), 3)
                self.assertTrue(all(-12 <= p[0] <= 12 and -12 <= p[1] <= 12 for p in points))
                twice_area = sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(points, points[1:]+points[:1]))
                self.assertGreater(twice_area, 0)
                if tile["kind"] == "slope":
                    cell = atlas.crop((x*24, y*24, (x+1)*24, (y+1)*24))
                    self.assertEqual(cell.getchannel("A").getextrema(), (0, 255))

    def test_props_are_unstretched_nonoverlapping_crops(self):
        source = Image.open(ROOT / "Source/Medieval_props_free.png")
        atlas = Image.open(ROOT / "Props/props_atlas.png")
        occupied = set()
        self.assertEqual(atlas.width % 24, 0)
        self.assertEqual(atlas.height % 24, 0)
        for prop in self.meta["props"]:
            with self.subTest(prop=prop["name"]):
                sx, sy, w, h = prop["source_rect"]
                ax, ay = prop["atlas_coords"]
                sw, sh = prop["size_in_atlas"]
                self.assertLessEqual(sx+w, source.width)
                self.assertLessEqual(sy+h, source.height)
                self.assertLessEqual((ax+sw)*24, atlas.width)
                self.assertLessEqual((ay+sh)*24, atlas.height)
                cells = {(x,y) for x in range(ax, ax+sw) for y in range(ay, ay+sh)}
                self.assertFalse(cells & occupied)
                occupied |= cells
                ox, oy = ax*24+(sw*24-w)//2, ay*24+(sh*24-h)//2
                expected = source.crop((sx, sy, sx+w, sy+h))
                actual = atlas.crop((ox, oy, ox+w, oy+h))
                for y in range(h):
                    for x in range(w):
                        pixel = expected.getpixel((x,y))
                        if pixel[3]:
                            self.assertEqual(pixel, actual.getpixel((x,y)))

    def test_builder_is_deterministic(self):
        with tempfile.TemporaryDirectory(prefix="moonward-assets-") as directory:
            work = Path(directory)
            shutil.copytree(ROOT / "Source", work / "Source")
            (work / "Terrain").mkdir()
            (work / "Props").mkdir()
            shutil.copy(ROOT / "build_assets.py", work / "build_assets.py")
            def build():
                subprocess.run([sys.executable, str(work / "build_assets.py")], check=True, capture_output=True)
                return {p.relative_to(work): hashlib.sha256(p.read_bytes()).hexdigest()
                        for p in work.rglob("*") if p.is_file() and p.suffix in [".png", ".json", ".tres"]}
            first, second = build(), build()
            self.assertEqual(first, second)
            for path, digest in first.items():
                self.assertEqual(digest, hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), str(path))


if __name__ == "__main__":
    unittest.main(verbosity=2)
