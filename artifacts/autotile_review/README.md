# Cavern autotile review

The tower terrain now uses the supplied 24-pixel cave/grass assets. Its level route and physical geometry are unchanged. The earlier dungeon sheet continues to supply platforms, hazards, turrets and checkpoint props.

## Evidence

- [Terrain styles and painting examples](output/terrain_preview.png)
- [Raw tile inventory](output/inventory.png)
- [Previous stone art beside the new terrain](output/terrain_comparison.png), previous on the left
- Tower captures: [start](output/08_tower_start.png), [shaft](output/09_tower_moving_shaft.png), [moving hazards](output/10_tower_moving_hazards.png), [turrets](output/11_tower_turrets.png), [platforms](output/12_tower_platforms.png), [springboard](output/13_tower_springboard.png)

The six tower views and the terrain preview were rendered and visually inspected. These are frozen captures, not gameplay recordings. Local images, logs and exports are ignored output.

## Verification

- 215 checks passed: 52 controller checks, 53 tower/checkpoint checks, and 110 new terrain checks.
- The terrain checks cover all 16 side-neighbour patterns in all three styles, deletion/reconnection, preview click/erase handlers, world-grid alignment, all slope orientations, unchanged original tile cells, retained hazard tiles, disabled extra collision/navigation, and reusable resource isolation.
- Fresh headless import and main-scene startup passed without script or resource failures.
- The Web release exported. The actual local browser showed the new terrain, accepted running/jump inputs and activated the first checkpoint; its captured console had no warnings or errors.
- The supplied tile files are byte-for-byte copies. No movement values, tile layout or collision contours were edited.
- Full unassisted tower completion was not performed. Interactive painting was checked through the preview input-handler tests; the attempted editor-helper mouse injection did not produce a visible painted tile, so it is not counted as a successful manual painting test.

Headless macOS certificate-access and shutdown resource warnings remain. They are separate from the passing script/resource checks.

## Reproduce

Set `GODOT_BIN` to the installed Godot executable, then run from the project root:

```sh
GODOT_BIN="$GODOT_BIN" Tests/run_checks.sh
mkdir -p artifacts/autotile_review/output/web
"$GODOT_BIN" --path . --fixed-fps 60 --resolution 1152x648 Art/Cavern/Preview.tscn -- --capture artifacts/autotile_review/output/terrain_preview.png
"$GODOT_BIN" --path . --fixed-fps 60 --resolution 1152x648 Tests/TowerCapture.tscn -- --output artifacts/autotile_review/output --art-details
"$GODOT_BIN" --headless --path . --export-release html5 artifacts/autotile_review/output/web/index.html
python3 -m http.server 8767 --bind 127.0.0.1 --directory artifacts/autotile_review/output/web
```

Open `http://127.0.0.1:8767/index.html` to play the local export. In Godot, F5 runs the tower; F6 on `Art/Cavern/Preview.tscn` opens the terrain painting preview. The Map inspector exposes the style and brightness.
