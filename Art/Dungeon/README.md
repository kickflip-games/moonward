# Optional dungeon spritesheet

- `dungeon_spritesheet.png` is the user-supplied 1448 × 1086 transparent PNG, preserved unchanged.
- `regions/*.tres` contains 45 named `AtlasTexture` resources. Drag one onto a `Sprite2D` texture property.
- `dungeon_tileset.tres` is a visual `TileSet` for a `TileMapLayer`. It uses explicit regions because the sheet is not a regular grid. Use nearest texture filtering on the layer; its nominal tile size is 128 pixels.
- `Preview.tscn` browses the terrain, structures, props, hazards, water and shrine assets. Run this scene with F6.
- `catalog.json` records every source rectangle and texture path.

These are optional visual resources. They have no collision, navigation or terrain-connectivity rules. The existing tower, cube player and gameplay colliders continue to use their original assets. Character poses remain available in the source image but are not assigned animation meanings or connected to the player.

Source: image supplied in this conversation. Artist, pack name and licence metadata were not supplied.
