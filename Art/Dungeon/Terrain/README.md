# Gothic connected terrain

Use **gothic_terrain.tres** for solid terrain and **decorations.tres** for a separate non-colliding decoration layer. Open **Scenes/TerrainTest/GothicTerrainTest.tscn** to inspect the examples or play with the existing Moonward cube.

This system reuses the attached Gothic Moss / Snow image in **Art/StoneSheet/stone_sheet.png**. The older **Art/Dungeon/dungeon_spritesheet.png** is a different pack. Both originals, their region resources, the main level and player parameters are preserved. [Inventory](INVENTORY.md) and [all source rectangles](source_inventory.json) explain the source limitations.

## Atlas and collision

| Resource | Image dimensions | Logical cell / atlas unit | Source ID | Terrain set / terrain |
| --- | --- | --- | --- | --- |
| Moss | 576×1152 | 72×72 | 0 | 0 / 0 |
| Ice | 576×1152 | 72×72 | 1 | 1 / 0 |
| Decorations | 864×576 | 72×72 | 0 | none |

Each solid terrain image occupies **one atlas column and two rows** (72×144). Its 72×72 stone body is centred vertically; transparent padding lets original foliage/snow overhang the solid cell. Keep texture origin at zero and UV clipping off. Use nearest filtering.

The logical cell follows the usable interior of the roughly 80-pixel source blocks. Pixels are cropped, patched and aligned at original density; they are not stretched to 128. The test scene scales layers uniformly by 0.5, producing 36-pixel world cells. A future 32-pixel tower migration must make an explicit grid/scale decision; this task does not migrate the tower.

Collision uses layer 2 / mask 5. Squares are ±36 source pixels. Slope polygons follow exact 45° or 2:1 gradients; no foliage, snow or icicle pixels enter collision. There is no navigation or damage behaviour in either resource. The decoration resource has **no physics layers**.

## Native painting

1. Add a TileMapLayer and assign gothic_terrain.tres.
2. Choose the **Terrains** tab, then Moss Stone (set 0) or Ice Stone (set 1), terrain 0.
3. Use **Connect** to paint connected structures. Erase a hole with the terrain eraser so nearby peering bits update.
4. There are 47 canonical corner/side visuals per material. Legal diagonal-only neighborhood alternatives share those visuals; all 256 eight-neighbor occupancy cases are represented.
5. Interiors have three original-masonry variants with shared boundaries. Exposed strips are selected only on outside faces; buried tiles do not receive a decorative frame.
6. Materials use separate terrain sets. Paint each region explicitly. The visible moss/ice boundary is deliberate; automatic mixed-material blend tiles are not supplied.
7. For exposed stone between moss or snow caps, manually select **bare_top**. flat_transition and wall_transition_left/right are manual boundary pieces.

Ordinary terrain painting uses Godot's native rules and bitmap atlases. No runtime terrain selector or shader is needed.

## Manual slopes

In the **Tiles** tab, select Moss source 0 or Ice source 1. These coordinates are identical in both atlases:

| Piece | Atlas coordinate | Surface endpoints (left y → right y) |
| --- | --- | --- |
| up_45 | (1,12) | 72 → 0 |
| down_45 | (2,12) | 0 → 72 |
| up_gentle_low | (3,12) | 72 → 36 |
| up_gentle_high | (4,12) | 36 → 0 |
| down_gentle_high | (5,12) | 0 → 36 |
| down_gentle_low | (6,12) | 36 → 72 |
| ceiling_up_45 | (7,12) | 72 → 0 |
| ceiling_down_45 | (0,14) | 0 → 72 |
| flat_transition | (1,14) | flat |
| wall_transition_left | (2,14) | vertical trim |
| wall_transition_right | (3,14) | vertical trim |
| bare_top | (4,14) | flat, no surface vegetation |

Both gentle constituents go in the **same map row**, low then high when rising, high then low when descending. A 45° ascending run moves one row up per cell; a descending run moves one row down. Slopes cannot be inferred reliably by the terrain brush and have no terrain peering assignments.

**Build the occupied shape with Connect first**, including slope cells as full cells. Then replace the partial cells using the Tiles tab. This establishes correct buried faces in supporting tiles. Add flat_transition at adjoining flat surfaces as demonstrated in the test scene. Repainting with a terrain brush can replace manual slopes; reinsert them afterward. For a slope ending against a wall, retain the wall's solid cells and choose its exposed vertical trim explicitly.

## Decoration

Assign decorations.tres to a second TileMapLayer, set nearest filtering, and use its named atlas entries. It contains 21 entries: wood trim, lanterns, chains, banners, windows, pillars, shrines, grass/moss and snow overhangs, a vine, masonry cracks, and decorative arch fragments.

Large objects occupy multiple atlas units and retain their proportions with transparent padding. Decorations do not influence solid terrain selection. Lanterns and shrines here are static artwork; interactive versions should remain separate scenes.

## Source corrections and limits

- Interior texture comes from three original masonry crops. Local original-stone donor patches remove surface snow/moss and the former block rim. Four-pixel periodic boundary bands and shared variant margins match neighboring fill pixels.
- Surface strips and diagonal edging retain the original palette and detail. Small concave accents are reconstructed from original boundary pixels.
- **Gentle slopes are reconstructed:** the source lacks a complete consistent 2:1 pair. Their bodies use original masonry; edge pixels from the original 45° slopes are repositioned along exact gradients. They are not rotated rectangular tiles.
- The right snow ceiling crop is truncated in the original image; its intact counterpart is mirrored.
- Some original masonry rows and brick bonds are irregular. Shared fill pixels remove obvious seams and frames, but this is not an artist-authored, perfectly staggered masonry bond across every variant.
- Decorative arches do not constitute a complete curved collision kit. Smooth curved ramps, arbitrary slope concavities, and automatic mixed moss/ice blends remain unsupported. No unsupported combination is presented as seamless.
- No independent loose-stone sprite was reconstructed from an ambiguous raw fragment; cracks and existing architectural trims are available.
- Source artist/licence metadata was not supplied. Existing source records are retained.

## Regeneration and checks

Requires Python 3 + Pillow and a Godot executable. From the repository root:

    python3 Art/Dungeon/Terrain/terrain_builder.py
    "$GODOT_BIN" --headless --path . --editor --import --quit
    "$GODOT_BIN" --headless --path . Art/Dungeon/Terrain/BuildResources.tscn
    "$GODOT_BIN" --headless --path . Scenes/TerrainTest/BuildTestScene.tscn
    GODOT_BIN="$GODOT_BIN" bash Tests/run_checks.sh

The source hash is pinned. PNGs and JSON rebuild byte-identically. Native terrain/decoration resources also use stable resource IDs and were checked for identical rebuilds. Regeneration intentionally replaces generated resources; preserve intentional manual TileSet changes by moving them into the builder.

The resources use Godot 4.5 TileSet and TileMapLayer APIs. Actual import, scene loading and controller tests passed on installed **4.6 stable** and **4.8 dev6**. **4.5 was not installed and is not claimed as tested.**

Run the test scene with F6: arrows + the existing jump input, Esc retries; 1–4 inspect examples, 5 resumes player follow. Automated input tests use the real controller, not reimplemented movement formulas. Manual editor mouse painting and a full human route playthrough are not claimed.

[Review and before/after evidence](../../../artifacts/gothic_terrain/README.md).
