# Cavern terrain

The 37 tile PNGs in `Tiles/` were copied unchanged from the supplied `Desktop/Main/Tiles` folder. Most are 24×24 pixels; four paired slope images are 48×24. The character, enemy, NPC and background assets from that pack are not used.

## Terrain painting

- Assign `cavern_tileset.tres` to a `TileMapLayer` with nearest filtering.
- In the Terrains paint tab, choose Bare rock, Green grass, or Purple grass. Each style has its own terrain set using **Match Sides**.
- All 16 combinations of the four side neighbours are supported, including isolated blocks, one-cell ledges, narrow columns and junctions. Painting or erasing updates the neighbouring edges.
- The source pack does not contain a separate image for every combined edge. `terrain_quarters.gdshader` combines quarters of the supplied edge/corner images, without changing their pixels. Interior rock details provide a second full-tile variant.
- Tiles 14, 25, 36 and 37 provide four manual 45-degree slopes with triangular collision. Slopes are placed explicitly; the terrain brush cannot infer a slope from occupied cells.
- The wider paired slopes and other raw tiles remain available in the inventory. They are not included in automatic slope selection.

The reusable terrain has 24-pixel square collisions on layer 2 and mask 5. Disable `collision_enabled` when using it as decoration. These are side-matching rules rather than a full eight-neighbour blob terrain or mixed-style transition set. See [Godot's terrain documentation](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html#creating-terrain-sets-autotiling).

## Tower integration

`tower_terrain.gd` derives decorative terrain from the tower's existing `GameLayer`. Its 24-pixel tiles are scaled to the existing 32-pixel world grid. Original tile cells, damage tiles, slopes and colliders remain authoritative; the new layer adds no physics or navigation.

`World/Map/dungeon_skin.gd` exposes the terrain style and brightness. Moss stone from ../StoneSheet/ is now the default; these three cavern styles remain selectable. The old terrain silhouette clips the new art so transparent pixels never hide a collidable surface. Edges next to slopes use the slope's actual solid faces. Editing the original geometry layer or changing style refreshes the preview in the editor.

Keep editing the existing tower's geometry on `GameLayer`. The generated `CavernTerrain` display is rebuilt from it; direct edits to that display are temporary. For new levels, the reusable TileSet can be painted directly on a new layer.

Platforms, hazards, turrets, checkpoints, the cube, UI and audio retain their current assets.

## Preview and rebuild

Run `Preview.tscn` with F6. Click/drag to paint, right-click to erase, R to reset, and I to browse all supplied tiles. The three panels demonstrate platforms, thin ledges, columns, a shaft, a corner and manual slopes.

`Tests/BuildCavernTileSet.tscn` rebuilds the saved TileSet from `terrain_factory.gd`. `Tests/run_checks.sh` runs the terrain tests alongside the existing gameplay checks. See `artifacts/autotile_review/README.md` for captures and validation.

Source: folder supplied in this conversation; no artist or pack metadata was included.
