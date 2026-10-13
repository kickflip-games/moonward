# Stone sheet TileSet

Assign **stone_tileset.tres** to a TileMapLayer. The supplied transparent PNG is preserved unchanged.

- **Tiles tab:** sources 100–281 expose 182 cropped image regions. Each source is named; select it and paint its single tile. Uneven spacing and overlapping crop boundaries require separate atlas sources sharing the same image.
- **Terrains tab:** choose Moss stone or Ice stone. Both support all 16 side-neighbour patterns. Edge quarters are composed by a shader; these are side-matching brushes, not eight-neighbour blob terrains or moss/ice transitions.
- **Slopes:** sources 14, 25, 36 and 37 provide four triangular colliders. Alternative 0 is moss; alternative 1 is ice. Paint slopes manually. The cropped ice ceiling corner is mirrored from its intact counterpart.
- Native cells are 80×80. Use nearest filtering and scale 0.4 for Moonward's 32-pixel world grid.
- Named terrain regions have square or triangular collisions on layer 2, mask 5. Decorations, raw catalogue regions and spike artwork have no collision or damage behaviour; add those deliberately when building a new level.
- Large decorations occupy one cell and extend beyond it. Some raw crops include padding or partial artwork because the supplied image is not a uniform atlas export; inspect them before using them as standalone pieces.

Run **Preview.tscn** with F6: left-click/drag paints, right-click erases, R resets, I opens the catalogue, and Left/Right changes catalogue pages.

The existing tower uses moss stone by default. Its original GameLayer remains the geometry and hazard authority. Change the Map terrain style to select ice or the previous cavern styles. Edit GameLayer to change the tower; the generated visual layer is rebuilt.

Rebuild the resource with Tests/BuildStoneSheet.tscn after editing terrain_factory.gd or catalog.json. Run Tests/run_checks.sh for validation. The catalogue and regions/ AtlasTextures also support Sprite2D decoration.
