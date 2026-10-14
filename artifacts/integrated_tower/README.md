# Integrated tower review — 2026-10-15

The main course again uses Moonward's original tower. Three new sections are inserted before the original scaffold grid, adding 2,304px of height. The entire original scaffold climb is retained above them. The earlier 30-room stack is retained as an experimental scene, outside the main route.

- **Collapsing Stair:** four narrow, alternating planks with 0.48-second collapse timers, 144px rises and 224–256px lateral transfers. A missed jump loses height onto the original lower architecture.
- **Counterweight / Relay Lifts:** 224px vertical travel, 320px horizontal travel, narrow moving decks and a single central transfer perch. Boarding and leaving require timing.
- **Needle Court:** alternating buttresses built into the original walls, a saw and pendulum across the gaps, and a collapsing foothold leading to a new rest shrine and then the original scaffold grid. The wall ledges use the existing terrain tiles and renderer.
- **Continuity:** all original terrain cells, the entrance, lower mechanisms, spike shafts, turrets, springs, camera framing and summit remain. The original ten shrines plus three new boundary shrines make thirteen. All upper mechanisms, terrain, checkpoint positions, camera framing, moon and win zone translate upward together.
- Corrected the existing lift-cable origin to account for the Platforms container's offset.

[Editing guide](../../World/Tower/README.md) · [Integration source](../../World/Map/integrated_map.gd)

## Verified

- Godot 4.8-dev6 import and main-scene startup pass.
- Integrated suite: **132 checks, zero failures**. Includes two load/teardown cycles, thirteen safe checkpoint respawns, continuous stair traversal with collapse timers active, boarding/riding/leaving both moving lifts, and a continuous court climb with blades active that connects to the original scaffold climb. The court test retries from its boundary shrine; it does not teleport between landings or disable hazards.
- Every original terrain cell and mechanism is checked at its retained or translated position. Two real-controller jumps verify the seam onto the original scaffolds.
- Original controller, terrain, artwork, checkpoint and character suites pass. The isolated prototype's older suite also passes; those checks do not establish its design quality.
- Eight native captures inspected: entrance, stair, lifts, court, scaffold connection, restored original scaffolds, original upper hazards and summit.
- Debug Web export succeeds. Browser smoke confirmed the restored entrance, checkpoint progression into the new sections, movement/camera/HUD response, and no observed browser warning/error logs. This was not a browser completion of the new sections.
- `git diff --check` passes.

These are bounded scripted checks, not a human full-tower playthrough or a claim that difficulty is perfectly balanced. The existing macOS certificate and resource-at-shutdown warnings remain; the traversal fixture also reports resources at teardown.

## Play and review

Run the normal project. In a debug build, `\` advances to the next checkpoint. The added chapter starts at the sixth checkpoint (around 146m); the following three shrines start the lifts, court, and restored original scaffold climb.

Rebuild a local debug Web export with `Godot --headless --path . --export-debug html5 /tmp/moonward-web/index.html`. No upload or publication was performed.

Screenshots are in ignored `output/`:

- [Restored entrance](output/entrance.png)
- [Collapsing stair](output/collapsing_stair.png)
- [Relay lifts](output/relay_lifts.png)
- [Needle court](output/needle_court.png)
- [Connection into original scaffolds](output/scaffold_connection.png)
- [Retained original scaffold climb](output/original_scaffolds.png)
- [Original upper hazards](output/original_hazards.png)
- [Raised summit](output/summit.png)

Run `GODOT_BIN='/path/to/Godot' bash Tests/run_checks.sh` for all checks, or `Godot --headless --path . --fixed-fps 60 res://Tests/IntegratedTowerTests.tscn` for the new course. Capture with `Godot --path . res://Tests/IntegratedTowerCapture.tscn`.
