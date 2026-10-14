# Superseded reference-tower prototype — 2026-10-15

**Superseded after play feedback:** the repetitive 30-room stack is now isolated in `World/Tower/PrototypeWorld.tscn`. The [current main tower](../integrated_tower/README.md) restores the original course and integrates redesigned sections. The results below describe the earlier prototype, not the current main game.

- Added all **30 reference-room concepts** to the main climb, with **53 ordered retry shrines** and a quiet Summit Walk finale. Trap rooms precede the final battlements instead of following the summit.
- Each room is an editable Godot scene. [Editing guide](../../World/Tower/README.md) · [Tower assembly](../../World/Tower/ReferenceTower.tscn) · [Authoring source](../../Tools/build_reference_tower.py).
- Reused BlackSpire art and the existing controller, moving/breakable/spring platforms, checkpoint manager, music, character, and win camera. The earlier course remains available as [LegacyWorld.tscn](../../World/LegacyWorld.tscn).
- Tuned the sketches using real controller traces: corrected blocked pillar crossings, excessive recovery climbs, and overlap between adjacent rooms. Connector shelves give each room enough vertical clearance. Render review corrected HUD overlap and the summit moon's scale.

## Verified on Godot 4.8-dev6

| Check | Result |
|---|---:|
| Reference tower: loading twice, shrine order/safety, main and connector jumps, recovery/rejoin paths, live traps, wind, platform carry/collapse, summit | **903 checks, 0 failures** |
| Existing controller, earlier tower, terrain, artwork, and animation suites | **2,620 checks, 0 failures** |
| Import and main-scene startup | Passed |
| Web release export | Passed |
| Browser smoke: movement, jump, first-ledge landing, camera and height HUD | Passed; no browser warning/error logs observed |
| Rendered rooms | All 30 captured and inspected, including the entrance and moon-view finale |
| Whitespace validation | `git diff --check` passed |

Main-route jump checks use the real player and collision geometry with traps disabled and moving platforms held neutral. Live checks separately verify non-lethal warning intervals, lethal trap contact, lift carry, collapsing-platform restoration, and airborne wind movement. Recovery checks allow a jump to rejoin a higher main ledge early.

**Still needed:** a human playthrough of the entire timed climb, difficulty/pacing feedback, and device/audio checks. These results do not establish unassisted completion or long-session memory behavior. Headless runs retain the baseline macOS certificate/audio shutdown warnings; the scripted traversal fixture also reports resource warnings at teardown.

## Review locally

- Raw room screenshots, test output, and the Web build are kept in ignored `output/`.
- [Entrance](output/start.png) · [Moon view](output/summit.png) · [Moon Gate](output/19.png) · [Flame Pipe](output/23.png).
- Run `World/Tower/PrototypeWorld.tscn` to play this experimental stack. In a debug build, `\` advances to the next shrine.
- Re-run validation with `GODOT_BIN='/path/to/Godot' bash Tests/run_checks.sh`.
- Rebuild room screenshots with `Godot --path . --windowed res://Tests/ReferenceTowerCapture.tscn -- --output artifacts/reference_tower/output`.
