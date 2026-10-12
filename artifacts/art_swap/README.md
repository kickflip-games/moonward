# Dungeon art integration

The supplied spritesheet is applied to the existing tower. Stone/moss/ivy terrain, wooden platforms and springboards, warm metal spikes/projectiles, stone turrets, and moon-shrine checkpoints replace the old surface art. The cube, title, moon, music, UI, progression and movement tuning are preserved.

## Verification

- Godot 4.8 dev6: fresh import, 52 controller checks, 53 tower checks, and main-scene startup passed. The tower audit traverses checkpoints; it does not establish an unassisted completion.
- `after/physics_parity.json` records equality against `786cc57`: player/platform/checkpoint-manager physics scripts, tile cells and collision contours, scene collision shapes, and the source PNG are unchanged.
- Six fixed-camera views rendered and were visually inspected: start/checkpoint, moving-spike shaft, moving-hazard corridor, turret chamber, rotating/moving platforms, and springboard.
- Native game: walked to the first checkpoint and observed shrine activation and the existing fire/particle effects. No current-run script errors were reported.
- Web release exported successfully. The actual local browser build rendered the new materials and accepted movement/jump input; its captured console had no warnings or errors.
- Full unassisted tower completion and a subjective playtest of every obstacle were not performed for this art pass.

The headless macOS runs still print certificate-access and shutdown resource warnings. The editor also retains a `VirtualJoystick` class-name conflict entry; fresh import/startup and the browser run did not reproduce that parser error. The art shaders did not report compilation failures.

## Matching views

The left column uses the gameplay-polish captures taken before the dungeon art was applied. The right column uses the same camera positions, viewport, player positions and frozen physics conditions after integration. These are visual comparisons, not live gameplay recordings.

| Location | Before | After |
| --- | --- | --- |
| Start and checkpoint | [Before](before/08_tower_start.png) | [After](after/08_tower_start.png) |
| Moving-spike shaft | [Before](before/09_tower_moving_shaft.png) | [After](after/09_tower_moving_shaft.png) |
| Moving-hazard corridor | [Before](before/10_tower_moving_hazards.png) | [After](after/10_tower_moving_hazards.png) |
| Turret chamber | [Before](before/11_tower_turrets.png) | [After](after/11_tower_turrets.png) |

Additional views: [Platforms](after/12_tower_platforms.png), [Springboard](after/13_tower_springboard.png). Images, logs and the Web export are ignored local review output.

Side-by-side sheets place the original on the left: [Start](after/start_comparison.png), [Shaft](after/shaft_comparison.png).

## Reproduce

Set `GODOT_BIN` to the installed Godot executable, then run from the repository root:

```sh
GODOT_BIN="$GODOT_BIN" Tests/run_checks.sh
mkdir -p artifacts/art_swap/after artifacts/art_swap/web
"$GODOT_BIN" --path . --fixed-fps 60 --resolution 1152x648 Tests/TowerCapture.tscn -- --output artifacts/art_swap/after --art-details
"$GODOT_BIN" --headless --path . --export-release html5 artifacts/art_swap/web/index.html
python3 -m http.server 8766 --bind 127.0.0.1 --directory artifacts/art_swap/web
```

Open `http://127.0.0.1:8766/index.html` to try the exported game. In Godot, F5 runs the tower and F6 on `Art/Dungeon/Preview.tscn` runs the asset gallery.

For a focused visual check, activate a shrine, ride the wooden moving/rotating platforms, trigger a springboard, and approach a turret to observe its charging ring and metal projectile. Check platform edges and spike tips against their colliders with Godot's visible-collision-shapes debug option.
