# Optional spritesheet import review

- Preserved the supplied transparent 1448 × 1086 PNG byte-for-byte in `Art/Dungeon/dungeon_spritesheet.png`.
- Added 45 named AtlasTexture resources and an irregular-region visual TileSet.
- Added a browsable five-tab preview: terrain, structures, props, hazards, water and shrines.
- Corrected neighbouring-art bleed in the waterfall and barrel atlas regions after rendering the preview.
- Validated all 45 TileSet entries and rendered/inspected all five tabs in Godot.
- These optional resources are separate from the tower/player art. They have no collision or terrain-connectivity rules. Character poses are retained in the original sheet for later use.

[Usage and resource notes](../../Art/Dungeon/README.md)

![Terrain gallery](spritesheet_0.png)

![Structures gallery](spritesheet_1.png)

![Props gallery](spritesheet_2.png)

![Hazard gallery](spritesheet_3.png)

![Water and shrine gallery](spritesheet_4.png)

The screenshots remain local and are ignored by Git. Artist, pack and licence metadata were not supplied. Very transparent crown/glow details were preserved as supplied.
