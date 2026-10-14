# Source inspection

The attached Gothic Moss / Snow sheet is byte-identical to `Art/StoneSheet/stone_sheet.png` (1448×1086 RGBA, SHA-256 582f7d7c201dc8d1164e114c71f3a90ab266ec9eae0e54f6df1684474edb0b8a).
`Art/Dungeon/dungeon_spritesheet.png` is a different, older pack (SHA-256 dd0ec8b658f5ed80b89e61a2762f88f34640ecc3041960b82a120c9010c7f8b8). Both originals and their catalogues stay unchanged.

The newer image contains approximately 80-pixel blocks with irregular 5–14-pixel gutters. A 72-pixel logical masonry cell keeps the usable stone at its original pixel density, trimming padded rims rather than stretching to 128. Larger objects remain multiple atlas units. There is no Kenney terrain SVG in Moonward; template alignment cannot be asserted.

## Reuse decisions

- **Direct crops:** lanterns, banners, windows, pillars, shrines, chains, wood braces; decorations only.
- **Boundary cleanup:** all square masonry candidates have top highlights and/or outer rims. Interior candidates (1136,122,72,72), (201,286,72,72), (286,286,72,72) contain snow or moss at one corner. Local donor patches remove these surface markings, and narrow shared boundary bands align adjacent interior variants.
- **Exposed surfaces:** moss top and side strips and snow caps/icicles are reused from the matching source sheet. No whole-tile frame is placed on a buried face.
- **Missing connectivity:** the image does not supply 47 aligned blob tiles, four concave corners, T-junctions, or clean isolated ledges. These are assembled locally from cleaned masonry and source edge strips.
- **45-degree slopes:** intact left/right moss and snow slopes exist. Their diagonal pixels need alignment to the common grid and removal of gutters. Ceiling pieces exist, but the snow right ceiling piece is truncated at the sheet edge; use its intact counterpart mirrored.
- **Gentle slopes:** no complete matching 2:1 stone slope pair exists in this source. New constituent shapes must be cut from the existing masonry and edged with original surface pixels. These are reconstructed terrain variants, not claimed as original crops.
- **Curves:** round/arched fragments exist, but do not provide a complete usable curved collision set. They stay decorative in this pass.
- **Separate:** lanterns, chains, banners, pillars, windows, shrines, vines, grass, snow overhangs and cracks. Spike artwork does not gain damage behaviour or solid collision.

The existing StoneSheet catalogue records all 182 arbitrary extraction regions, including padding and fragments. The builder emits an inventory linking those rectangles to terrain, slopes, architectural pieces, hazards and raw fragments; it does not silently treat every crop as a valid tile.

Checked-in project features: Godot 4.5. Local dirty editor settings say 4.8. Installed engines: 4.6 stable, 4.7 stable, 4.7.1 RC2, 4.8 dev6. The new resources use Godot 4.5 TileSet / TileMapLayer APIs; actual engine test results are recorded separately.
