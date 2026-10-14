# Animated character review

Branch: `animated-character-integration`. Baseline: `56dc329` on the existing BlackSpire visual branch. This character change is stacked on that art pass; it does not migrate or redesign the tower.

## Result

- The cube is replaced by Josee / N3Cloud's actual character frames. The unchanged source is 1792×3280 RGBA, with a verified 128×80 grid.
- All 38 named author strips matched source cells exactly. The SpriteFrames resource provides those sequences and 14 gameplay subsets/fallbacks.
- One controller selects poses and owns modest parent squash/lean, source-frame somersaults, particle/audio dispatch and quick retries. The polygon AnimationPlayer was removed.
- Roll eligibility uses speed, air time, a 1.4s cooldown and clear space on both sides. Wall contact and landing preempt it. Narrow shafts remain upright and readable.
- The original collider, controller, tower geometry, platform forces/timing and checkpoint progression remain unchanged. The debug cube uses the new visual owner rather than a second animation system.
- The existing death sound was present but unwired; it now plays through the existing audio node.

## Actual running-game evidence

[Animation comparison sheet](review/animation_comparison_sheet.png) shows all twelve situations at 2× rendered-pixel magnification. Each cell contains the original cube and the new character. [Animated transitions](review/transitions.gif) and [actual main-game view](review/main_gameplay.png) show the character in the BlackSpire environment.

| Situation | Same-camera comparison |
|---|---|
| Idle | [01](review/01_idle_comparison.png) |
| Running | [02](review/02_running_comparison.png) |
| Full speed | [03](review/03_full_speed_comparison.png) |
| Normal jump | [04](review/04_jump_comparison.png) |
| Long airborne jump | [05](review/05_long_jump_comparison.png) |
| Somersault | [06](review/06_somersault_comparison.png) |
| Wall slide | [07](review/07_wall_slide_comparison.png) |
| Wall jump | [08](review/08_wall_jump_comparison.png) |
| Springboard | [09](review/09_springboard_comparison.png) |
| Landing | [10](review/10_landing_comparison.png) |
| Death | [11](review/11_death_comparison.png) |
| Respawn | [12](review/12_respawn_comparison.png) |

All twelve captures have **exactly matching player positions and velocities**, not merely approximate camera placement. They run the same isolated movement scene and scripted inputs on Godot 4.8. Each snapshot pauses the world only after reaching its state; actual source animations and effects are rendered. [Captured states](captured_states.json) record the selected character pose/frame. The comparison is against the original cube controller from Git, not the F8 fallback.

[Animation preview](review/animation_preview.png) shows the independently running selector, frame index, paused roll and two rendering scales. Browser evidence is saved in `review/web_gameplay.png`.

Silent MP4 clips and raw frames remain in ignored `output/`:

- `character_transitions.mp4`: the major test transitions, including retries, sampled at 20fps. Stations are repositioned deliberately between cases.
- `main_gameplay.mp4`: three seconds of ordinary running/jumping with the actual main-game camera.

These are scripted engine captures, not a human feel playtest. The GIF is a smaller review copy of the rendered transition frames. It adds no sprite animation or synthetic motion.

## Completed validation

| Check | Result |
|---|---|
| Godot 4.8-dev6 full project checks | **2,620 checks, zero failures** |
| Godot 4.5 stable isolated-copy checks | **2,620 checks, zero failures** |
| Character checks, included above | 87: frame contracts, fixed anchor, one visual, no old tracks, bounded playback/lean, real jump/roll/wall contacts, once-per-flight/cooldown, spring presentation, death/respawn reset, preview pause/step |
| Character asset tests | Four cases passed: original dimensions/alpha/hash, source bounds/nonempty frames, deterministic resource rebuild, byte-identical physics and collision blocks |
| Existing BlackSpire asset tests | Four cases passed |
| Before/after physics traces | **299 samples in nine segments, byte-identical JSON** |
| Main scene, movement test and preview | Load and render; actual captures inspected |
| Checkpoint / endpoint audit | Existing ordered checkpoints and win-camera trigger pass; not an unassisted tower completion |
| Web | Release export using installed 4.8 templates; browser rendering, running and jumping passed with no console warning/error entries during the smoke test |

[Physics trace](physics_trace.json) includes acceleration, reversal, full and cut jumps, wall jump, moving-platform travel, spring launch and death/retry. It was produced independently with the cube and character implementations. [Verification metadata](verification.json) records the counts and limits.

The working editor was already 4.8; its unrelated local `project.godot`, import changes and development addon remain outside the commits. Godot 4.5 was validated with a temporary self-contained editor and the tracked project configuration. No project upgrade was introduced.

Headless engine logs contain the existing macOS certificate-access diagnostic, interpolation notices and teardown ObjectDB/resource warnings. No script parse errors, missing textures or broken scene references were found. Raw logs are retained under `output/`; engine cleanup diagnostics are not described as an entirely clean log.

## Reproduce

```sh
python3 Tests/character_assets_test.py
GODOT_BIN="/path/to/Godot" bash Tests/run_checks.sh
mkdir -p artifacts/character_animation/output/after
"$GODOT_BIN" --path . --fixed-fps 60 res://Tests/CharacterCapture.tscn -- --output "$PWD/artifacts/character_animation/output/after"
```

For motion, use a separate output directory and add `--motion`; encode `motion_%04d.png` at 20fps. For the source preview capture, add `--preview`. `Tests/CharacterMotionTrace.tscn -- --output /absolute/trace.json` produces deterministic physics samples.

Run `Scenes/CharacterAnimationTest.tscn` with F6 to inspect all 52 animations. Run `Scenes/CharacterMovementTest.tscn` for gaps, slopes, spring, moving platforms and wall contacts. In debug builds: F7 shows visual state/frame/velocity, F8 switches the single cube fallback. The movement test additionally supports R retry, K death test and the existing backslash checkpoint skip.

## Limits and follow-up

- No dedicated source wall-jump, spring, death or respawn strips exist. The manifest and authoring README identify the actual pose fallbacks; no unsupported source animation is claimed.
- The original 26×24 physics box is retained. The humanoid is slimmer in idle/rolling poses; a future hitbox-fitting task would need explicit gameplay review. Roll remains visual and does not shrink the collider.
- Full unassisted tower completion and physical mobile testing were not performed. Desktop browser input was tested; sustained mobile performance remains unmeasured.
- Particle/audio transitions are code-checked and rendered; recorded clips are silent and do not certify listening quality on every device.
- Human tuning of flourish frequency, small-character readability and sound balance is the next useful playtest, rather than adding movement abilities.

See [character authoring documentation](../../Art/Characters/N3Cloud/README.md) and [the source permission notice](../../Art/Characters/N3Cloud/LICENSE-NOTICE.md). Screenshot/GIF artwork retains its respective artist permissions; the character is not relicensed under the terrain's CC BY-SA terms.
