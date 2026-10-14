# BlackSpire visual direction

Moonward now uses **BlackSpire Studio's Medieval pixel art asset FREE** for its active tower presentation. The former Dungeon, Cavern and Gothic experiments remain available for compatibility, but do not render the main tower.

## Source and construction

- Original terrain: `Source/Medieval_tiles_free_2.0.png`, 1024×824 RGBA.
- Original props: `Source/Medieval_props_free.png`, 512×200 RGBA.
- Both files are unchanged copies of the supplied originals. SHA-256 hashes and exact crop rectangles are in [catalog.json](catalog.json).
- The sheet is a construction reference, not a uniform grid. Repeated stone caps are approximately 24 source pixels wide; doors, roof spans and props have independent dimensions. No local Unity package or packaged licence accompanied these PNGs.
- Foreground source pixels occupy **two world pixels**. Crops are padded, repeated or assembled at their original density, never stretched to fit a cell. Large distant architecture uses uniform larger scales and darker modulation to communicate depth.
- `Terrain/terrain_atlas.png`: 192×96, 24×24 cells. Sixteen side configurations, eight manual slope pieces, four manual corner accents, two thin ledges.
- `Props/props_atlas.png`: 288×288, 24×24 logical cells, multi-cell padded props. Twenty-one exact-size `AtlasTexture` crops are also available in `Props/regions/`.

The structural fill is the artist's quiet blue-violet patch at `(640,400,24,16)`. Exposed edges use shallow crops of the artist's dusty red caps. Original roof masonry marks form sparse, non-colliding overlays; they are not repeated in every interior tile. The slope strokes retain the source's 45° and **1:3** gradients.

## Paint terrain in Godot 4.8

1. Add a `TileMapLayer`, assign [Terrain/medieval_terrain.tres](Terrain/medieval_terrain.tres), set **Texture Filter: Nearest**, and scale the layer uniformly to `(2,2)`.
2. Choose the **Terrains** palette: set **0**, terrain **0 — BlackSpire stone**, **Connect** mode. Paint walls, floors, pillars and ledges; interior cells have no ornamental frame.
3. Erase cells with terrain painting so neighbouring exposed sides update.
4. Use the ordinary **Tiles** palette for slopes and special pieces. The `asset_name` custom data identifies each entry; [catalog.json](catalog.json) records its atlas coordinates.

This is native **Match Sides** coverage (16 configurations), not a complete 47-tile corner set. Diagonal-only adjacency, ornate concave joins, roofs and stone-to-wood joins need manual selection or separate props. Do not terrain-connect over a finished manual slope: automatic side painting can replace it.

### Slope placement

- `up_45` / `down_45`: one cell of rise per cell of run. Raise/lower the next slope cell's row accordingly.
- Gentle ascent: `up_gentle_low`, `up_gentle_middle`, `up_gentle_high`, in that order on the **same row**. The surface rises a full cell over three cells. Descent uses `down_gentle_high`, `down_gentle_middle`, `down_gentle_low`.
- Back slopes with solid fill where the structure continues underneath. Match the next flat tile's surface to the slope endpoint. The isolated test scene demonstrates both grades.
- Full terrain and slope polygons use Ground layer **2**, mask **5**. Thin ledges occupy the upper half of a cell; `one_way_ledge` has a one-way polygon. Decoration is excluded from collision.

## Place props

Use [Props/medieval_props.tres](Props/medieval_props.tres) on a separate non-colliding `TileMapLayer`, or place a `Sprite2D` with an exact crop from `Props/regions/`. Keep foreground scale `(2,2)` and nearest filtering. Put free-standing props behind the player; embedded windows can sit above solid wall artwork. Doors, torches and checkpoints are deliberate landmarks. Ladders are decorative, not climbable.

## Existing tower integration

The old tower uses 256-pixel TileSet cells at scale 0.125: **32 world pixels** per cell. Replacing those cells with 48-world-pixel authoring tiles would change the route. Instead:

- `World/Map/map.tscn` and its cells/polygons remain unchanged.
- `World/Map/dungeon_skin.gd` delegates to `tower_style.gd`.
- `tower_terrain.gd` hides the old terrain art, aligns a collision-free 16-source-pixel structural layer at scale 2, and draws source-art caps only on exposed original polygon boundaries. Shared boundaries disappear. Original triangular slopes and hazard polygons remain authoritative.
- The original `GameLayer` is the **only tower terrain collider**. Do not add the colliding authoring TileSet on top of it. The isolated test scene instead uses the new native colliding TileSet alone.
- All tower regions receive this presentation. Sparse windows, checkpoint architecture, two parallax layers and an altitude-dependent sky add depth. This is not a room-by-room level redesign.
- Moving, fragile and spring platforms retain their shapes, motion, delays and launch forces. Their art is cropped/repeated at source density. The rotor gets a simpler palette-matched visual while its colliding body remains unchanged.
- Danger silhouettes stay warm coral; turret charge cues remain functional. The cube stays bright and unchanged. Bloom is disabled, height text is restrained, and checkpoint notices last 1.8 seconds.

In the editor, the main map's tool script previews the foreground replacement. Generated overlay nodes are rebuilt from `GameLayer`; edit the original cells for existing geometry. Use the native authoring TileSet for new independent sections. Backgrounds are generated during play.

## Play and regenerate

Run [../../Scenes/VisualDirectionTest.tscn](../../Scenes/VisualDirectionTest.tscn) with F6. It contains an entrance with a 20×20 structural mass, a wall-jump shaft and wooden lift, a spike, three checkpoints, gentle/45° slopes and open traversal. It reuses the real controller and PhantomCamera setup. Normal controls apply; the existing debug checkpoint key `\\` visits the next test section in a debug build.

From the repository root, with Pillow and an existing Godot binary:

```sh
python3 Art/BlackSpire/build_assets.py
"$GODOT_BIN" --headless --path . --editor --import --quit
"$GODOT_BIN" --headless --path . res://Art/BlackSpire/BuildResources.tscn
"$GODOT_BIN" --headless --path . res://Scenes/BuildVisualDirection.tscn
python3 Tests/blackspire_assets_test.py
GODOT_BIN="$GODOT_BIN" bash Tests/run_checks.sh
```

The Python crops/atlases are deterministic. Builders do not overwrite the originals. No extra Godot plugin is required. Godot 4.5 and 4.8 runtime checks and review captures are documented in [../../artifacts/blackspire/README.md](../../artifacts/blackspire/README.md).

## Remaining art limits

- This free pack supplies no suitable player animation set. The white cube remains a visible placeholder.
- Turrets, moving hazard silhouettes, support cables and the rotor use the pack's palette with existing shapes; dedicated matching mechanism sprites would improve them further.
- Automatic painting covers sides, not every diagonal/corner or mixed material arrangement. Uncommon joins are manual.
- Background architecture is deliberately sparse. A later art pass can hand-place distinctive landmarks in individual upper rooms without changing geometry.
- Pixel snapping and interpolation retain the existing project configuration. Dynamic motion can move art between source-pixel positions; no physics rounding was introduced.

## Licence and credits

Artist: **BlackSpire Studio**. Asset: **Medieval pixel art asset FREE**. [Official source](https://blackspirestudio.itch.io/medieval-pixel-art-asset-free). The artist's comment on that page links [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/); no separate licence file accompanied the supplied PNGs. A copy of the licence text is in [LICENSE-CC-BY-SA-4.0.txt](LICENSE-CC-BY-SA-4.0.txt).

Changes: cropping, transparent padding, shallow edge crops, quiet-fill assembly, masonry-mark extraction, slope masks, spring deck/stem assembly, and in-game colour modulation. The original artwork and these adapted art images are distributed under CC BY-SA 4.0. Preserve attribution, source/licence links and the modification notice when redistributing them. This attribution does not assign that licence to unrelated Moonward code or audio. See [../../CREDITS.md](../../CREDITS.md); a brief credit is also visible in-game.
