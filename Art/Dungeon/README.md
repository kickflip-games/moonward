# Dungeon spritesheet

The newer Gothic Moss / Snow **connected terrain system** is in [Terrain/README.md](Terrain/README.md). It uses the matching source in Art/StoneSheet and provides native corner/side painting, collision slopes, and separate decorations. This older Dungeon image and its resources remain compatible; the new system has not been applied to the main tower.

- `dungeon_spritesheet.png` is the user-supplied 1448 × 1086 transparent PNG, preserved unchanged.
- `regions/*.tres` contains 45 gallery assets and three platform detail `AtlasTexture` resources. Drag one onto a `Sprite2D` texture property.
- `dungeon_tileset.tres` is a visual `TileSet` for a `TileMapLayer`. It uses explicit regions because the sheet is not a regular grid. Use nearest texture filtering on the layer; its nominal tile size is 128 pixels.
- `Preview.tscn` browses the terrain, structures, props, hazards, water and shrine assets. Run this scene with F6.
- `catalog.json` records every source rectangle and texture path.

The tower uses this art alongside the cavern terrain in `Art/Cavern`:

- Stone, moss and ivy remain reusable materials. The tower terrain now uses the cavern autotiles; the dungeon terrain shader still renders its spike tiles.
- Wooden planks cover moving, rotating and breakable platforms. Springboards use the planks and the supplied shrine pedestal as their spring base.
- Spike shapes and projectiles use warm metal, keeping dangerous surfaces distinct from blue stone.
- Turrets have stone bodies and metal barrels; their charging ring remains visible.
- Checkpoints use moon shrines and banners, retaining their activation sound, particles and fire.

`World/Map/dungeon_skin.gd` applies the shared `surface_material.gd` helper and delegates terrain to the cavern renderer. The shaders sample the supplied sheet through the original geometry and silhouette masks. Solid backing fills transparent parts of source rectangles, keeping collidable surfaces visible. Tile cells, slopes, hazard tips and collision polygons remain authoritative; the art passes do not change their dimensions or physics.

The gallery `TileSet` remains visual-only, with no collision, navigation or terrain-connectivity rules. The cube, title, moon, UI and audio retain their original assets. Character poses are available in the source image but are not connected to the player.

See `artifacts/art_swap/README.md` for verification and matching screenshots.

Source: image supplied in this conversation. Artist, pack name and licence metadata were not supplied.
