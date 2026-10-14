# BlackSpire overhaul review

Baseline: `e11efb8`. Working branch: `blackspire-visual-overhaul`. Captured and checked on 15 October 2026.

## Implemented scope

- The **entire existing tower** now renders quiet violet structures, dusty red exposed edges, source-art windows/checkpoint architecture and two subdued parallax layers. The sky opens gradually toward the existing moon.
- Moving platforms, fragile platforms, springboards, the rotor, turret/projectile presentation and hazard colours follow the same palette. Bloom is disabled. The entrance title and height HUD are smaller; checkpoint messages disappear quickly.
- Native authoring resources: 24px terrain TileSet, 16 side configurations, eight manual slopes (45° and 1:3), thin/one-way ledges, and 21 non-colliding props.
- [Playable test scene](../../Scenes/VisualDirectionTest.tscn): entrance and large mass, vertical shaft/wooden lift/spike, and open traversal with connected slopes.
- The original source PNGs, `World/Map/map.tscn`, controller, checkpoint manager, platform scripts, turret behaviour and progression are preserved. A visual overlay replaces the old tower art; its collision is disabled. The original map remains the only terrain collider.

This is a complete shared presentation conversion, not hand-authored architectural redesign of every room. No original terrain region remains on the active old Gothic renderer. Legacy resources remain available for their separate previews/tests.

## Matching actual-game screenshots

Left: baseline. Right: new presentation. Both sides run Godot 4.8-dev6, with the same camera position/zoom, player pose and ten initial physics ticks. The world is then frozen for reproducibility. Static player poses are placed by the capture harness; these images do not demonstrate successful traversal. The spawn animation still gives the cube a stretched silhouette in these early fixed-view frames.

| Location | Comparison |
|---|---|
| Entrance, title and checkpoint | [08](review/08_tower_start_comparison.png) |
| Wall-jump shaft and moving hazard | [09](review/09_tower_moving_shaft_comparison.png) |
| Late moving-spike room | [10](review/10_tower_moving_hazards_comparison.png) |
| Turret room | [11](review/11_tower_turrets_comparison.png) |
| Slope and moving-platform sequence | [12](review/12_tower_platforms_comparison.png) |
| Springboard | [13](review/13_tower_springboard_comparison.png) |
| Rotating mechanism | [14](review/14_rotating_mechanism_comparison.png) |
| Breakable platforms | [15](review/15_breakable_section_comparison.png) |
| Moonlit summit | [16](review/16_summit_comparison.png) |

Test-section views: [entrance](review/test_entrance.png), [vertical challenge](review/test_vertical.png), [open traversal](review/test_open.png). [Browser gameplay](review/web_gameplay.png) shows the actual web export. [Movement frames](review/main_motion_contact_sheet.png) show the real controller and camera running through the entrance; [shaft frames](review/shaft_motion_contact_sheet.png) show wall-jump attempts.

Raw frames, logs, local web build and **silent scripted movement clips** remain under ignored `output/`:

- `main_traversal.mp4`
- `test_section_traversal.mp4`
- `wall_jump_shaft.mp4`

Clips contain three simulated seconds, sampled every three physics ticks at 20fps. They use ordinary input actions, the real controller and its normal PhantomCamera, without altered movement parameters. They are scripted movement evidence, not human playtesting. Large recordings and engine output are not committed.

## Verification actually completed

| Check | Result |
|---|---|
| Godot **4.5 stable** fresh import and full checks | **2,533 checks, zero failures** |
| Godot **4.8-dev6** import and full checks | **2,533 checks, zero failures** |
| BlackSpire-specific checks (included above) | 113: source hashes, native side painting, bounds, overlay alignment, unchanged map collision signature, HUD bounds, floor/ceiling outline orientation, checkpoints, actual floating-ledge landing, both wall-jump directions, slope raycasts, running over uphill/downhill/flat joins in both directions |
| Python asset suite | Four test cases passed: source dimensions/alpha/hashes, terrain masks/polygons, unscaled non-overlapping prop crops, deterministic rebuild |
| Protected gameplay files | Ten baseline hashes match; main map is byte-identical |
| Main game and new test scene | Load and run in 4.5 and 4.8 |
| Tower audit | Original checkpoint traversal and win-camera trigger pass; **not an unassisted tower completion** |
| Web | Release export with installed **4.8** templates; browser renders, runs and jumps; no warning/error console entries during the smoke test |
| Visual review | Nine paired tower views, three test-section views, rendered movement frames and browser play inspected |
| Git checks | No whitespace errors in this branch's changes |

The installed desktop editor/configuration was already 4.8 with unrelated local changes. Those changes were preserved. An official 4.5 binary in a temporary directory tested an isolated copy with the tracked 4.5 project configuration; the editor was not upgraded. One intermediate 4.5 editor shutdown aborted after denied cache writes; the final complete run passed using a temporary self-contained editor cache. No 4.5 web templates were installed, so the web result concerns the available 4.8 templates.

Headless logs include macOS certificate-access diagnostics, interpolation notices and test teardown ObjectDB/resource warnings. No script parse errors, missing resources or broken scene references were found. The warnings are retained in raw logs rather than described as a completely clean engine log.

## Reproduce and review manually

From the project root:

```sh
python3 Tests/blackspire_assets_test.py
GODOT_BIN="/path/to/Godot" bash Tests/run_checks.sh
mkdir -p artifacts/blackspire/output/after artifacts/blackspire/output/demo
"$GODOT_BIN" --path . --fixed-fps 60 res://Tests/TowerCapture.tscn -- --art-details --blackspire-review --output "$PWD/artifacts/blackspire/output/after"
"$GODOT_BIN" --path . --fixed-fps 60 res://Tests/BlackSpireCapture.tscn -- --demo --output "$PWD/artifacts/blackspire/output/demo"
```

For clips, create an output folder and add `--motion` to the BlackSpire capture command; `--demo --motion --shaft` captures alternating wall-jump attempts. Encode saved `motion_%03d.png` frames with `ffmpeg -framerate 20`.

Human review still needed:

1. Run `Scenes/VisualDirectionTest.tscn` with F6. Cross the gentle ramp, jump to the floating ledge, climb the shaft around the wooden lift and inspect the spike. Visit the open traversal bay (the existing debug `\\` checkpoint key can position you there).
2. Paint/erase irregular shapes directly in the editor with terrain set 0 / terrain 0, then manually add slope constituents. Native painting rules were exercised through the engine API; interactive editor painting was not performed.
3. Play the actual tower from bottom to summit without debug checkpoint skips. Check fast-motion readability, turret warning visibility, fragile-platform recognition and springboard direction at normal viewing distance.
4. Test web play on physical mobile hardware. The browser smoke test was desktop only; sustained web performance and touch readability were not measured.

## Remaining visual work

- The bright cube is deliberately retained; the free pack has no suitable character set. A matching protagonist is a separate art decision.
- Turrets, danger silhouettes, cables and the rotor still use original/simple shapes with the new palette. Dedicated mechanism sprites would unify these further.
- Some original shafts and floating geometry remain austere because topology is preserved. Add distinctive architectural supports and landmarks room by room, without obscuring hazards or narrowing clearance.
- Automatic terrain matching covers sides. Diagonal-only joins, ornate concave details, wood/stone transitions and unusual roof arrangements require manual pieces.
- Existing music, moon and particle assets remain. The moon's painterly appearance differs from the small pixel-art props, but preserves the game's destination and identity.

See [authoring and licence documentation](../../Art/BlackSpire/README.md) and [game credits](../../CREDITS.md). Review images contain BlackSpire artwork; attribution and the applicable CC BY-SA 4.0 terms accompany the source/adapted art.
