# Moonward gameplay polish review

Implemented on `gameplay-feel-fairness`, starting from `177067b`.

- Wall jumps now launch upward and away from the current wall with the same initial push for left, right, or neutral input. Protection lasts 0.12 s, followed by 0.10 s of gradually restored steering. Short taps get a 0.12 s minimum rise period and a gentler wall-specific cut. Fresh opposite-wall contacts can immediately initiate another jump.
- Ground turning uses its configured acceleration. Running speed and normal jump reach are preserved; air braking, coyote time, buffering, variable-height jumps, ceiling handling and landing resets are consistent.
- Moving platforms use physics-frame tweens and Godot's transport rather than adding their velocity repeatedly. The group belongs to the colliding body. Leaving a descending platform retains full jump height. See the [Godot platform handling reference](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html#class-characterbody2d-property-platform-on-leave).
- Springs keep their 2500 px/s launch, use their transformed visible up direction, reject back-face/ascending retriggers, clear stale jump-cut state, and replace overlapping bounce-animation tweens. Their body now uses the terrain collision layer.
- PhantomCamera retains its host and end-game camera. Bounded velocity lookahead, faster vertical damping, and one smooth 0.8 zoom zone in the horizontal hazard room improve anticipation.
- Standalone, rotated, scaled, moving and tile-atlas spikes are coral. Inset triangular/visual-derived collision polygons replace broad rectangles over empty tip gaps. Projectile collision is swept and inset to its triangle.
- Turrets charge visibly and play an existing sound for 0.5 s before firing. A lost or offscreen target cancels charging, so warnings must be visible before firing. Projectiles steer for at most 0.6 s, at a bounded angular rate, then commit to their trajectory.
- Death is single-entry, returns control after about 0.35 s, and clears all temporary movement/input/contact state. A short 0.15 s respawn grace avoids stale hazards. Animation callbacks cannot hide the new player. Uncommunicated fall-height deaths are removed.
- Ten checkpoints have explicit ascending progression indexes, refuse backward activation, register without duplicates, and survive scene initialization/reload correctly. Existing flags, particles, sound, music and ending are retained.
- Level geometry and route are unchanged. The only obstacle timing adjustment is a 0.6 s endpoint pause, previously 0.4 s, for the first vertical moving-spike shaft.
- The bundled joystick class is renamed to avoid Godot 4.8's native class collision. Mouse-to-touch emulation remains optional and disabled; touch-to-mouse emulation is disabled to avoid duplicate input. Review/test resources are excluded from Web exports.

## Parameters

Values below compare the **actual original World player**, including Player.tscn overrides, with the shared new script defaults. The original standalone scene's separate 9000 px/s wall-jump vertical override was erroneous and is removed.

| Parameter | Original | Polished | Reason |
|---|---:|---:|---|
| Maximum run speed | 560 px/s | 560 px/s | Preserve fast traversal |
| Ground acceleration | 4032 px/s² | 4032 px/s² | Already reached speed in about 0.15 s |
| Ground turning acceleration | 13440, unused | 13440 px/s², applied | Responsive reversal |
| Ground braking | 4480 px/s² | 4480 px/s² | Predictable stops |
| Air acceleration | 0.6 × ground | 0.65 × ground | Responsive steering |
| Air turning acceleration | Ground acceleration × 0.6 | 5600 px/s² | Controlled reversal after protection |
| Air braking with no input | 4480 px/s² despite 0.6 setting | 1568 px/s² (0.35 × ground) | Retain airborne momentum |
| Ground jump force | 1200 px/s | 1200 px/s | Preserve jump reach |
| Ground coyote | 0.08 s | 0.12 s | Late ledge presses |
| Jump buffer | 0.10 s | 0.12 s | Early landing/wall presses |
| Wall coyote | Shared 0.08 s ground timer | Separate 0.10 s | Predictable recent-wall fallback |
| Wall jump velocity | ±1200, −1100 px/s | ±620, −1100 px/s | Consistent separation without an uncontrolled horizontal launch |
| Wall steering | 0.15 s at 0.65 interpolation; input-dependent | 0.12 s protected + 0.10 s ramp | Repeatable push, then smooth control |
| Wall short-tap assistance | No minimum rise; 25% cut | 0.12 s minimum rise; 15% cut | Useful, easy-to-initiate bounces |
| Wall slide limit | 80 px/s target; slow convergence from fast falls | 100 px/s hard falling limit | Predictable slide on current contact |
| Jump cut | Remove 25% of upward velocity | Remove 45% | More distinct short jumps; buffered taps also cut |
| Apex velocity threshold | 2 px/s | 120 px/s | Assistance can actually span physics ticks |
| Apex gravity multiplier | 0.05 | 0.5 | Mild assistance over a wider interval |
| Gravity / fall limit | 3840 px/s² / 1020 px/s | Same | Preserve base trajectory |
| Fall gravity multiplier | 1.2, unused | 1.2, applied | Brisk descent |
| Spring launch | 2500 px/s | 2500 px/s | Keep powerful launch |
| Floor snap | 16 px | 8 px | Avoid reaching too far across ledge gaps |
| Camera | Framed dead zone 0.278 × 0.227, damping 0.1 × 0.1 | Simple follow, damping 0.09 × 0.06 | Keep up with climbing |
| Camera anticipation | None | 70 px up bias; up to 150 px vertical and 55 px horizontal lookahead | Show the route ahead; suppress horizontal wall-jump oscillation |
| Turret warning | Immediate fire | 0.50 s charge | Time to recognize the threat |
| Projectile homing | Per-tick interpolation indefinitely | ≤1.2 rad/s for ≤0.6 s | Readable, frame-rate-independent trajectories |
| Death-to-control | 0.8 + 0.5 s | 0.35 s | Fast retries |
| Fall-height death | Safe landings can kill after >500 px | Removed | Safe terrain is safe |

## Measured before/after

Godot 4.6 stable, 60 Hz, identical practice geometry and input schedules, using the original archived controller and the improved controller respectively. The original practice instance uses the World override (1200, 1100), not the broken standalone override.

| Measurement | Original | Polished |
|---|---:|---:|
| Ticks to reach 560 px/s | 9 | 9 |
| Ticks to reverse a 560 px/s ground run | 9 | 3 |
| Held-jump rise | 177.7 px | 179.3 px |
| One-tick tapped jump rise | 59.4 px | 39.3 px |
| Wall push with held directional input | ±1200 px/s | ±620 px/s |
| Wall push with neutral input at 100 ms | ±752 px/s | ±620 px/s |
| One-tick tapped wall-jump rise | 50.2 px | 120.5 px |
| Death signals from three simultaneous calls | 3 | 1 |
| Ticks from death to unlocked control | 79 (1.32 s) | 22 (0.37 s) |

Raw [combined metrics](metrics.json), [original benchmark](before/benchmark.json), [polished benchmark](after/benchmark.json), and [input/position traces](after/replay.json) are local, ignored review assets.

## Verification completed

- Godot 4.8 dev6: headless import, **52 controller/camera/hazard checks**, **53 tower checks**, and main-scene startup passed. No GDScript parse/runtime errors, missing resources or broken scene references in those checks.
- The 52 checks cover both wall sides with all horizontal inputs, protected steering/reversal, contact precedence, short-tap wall rise, simultaneous wall probes, repeated shaft climbing, ground/wall coyote, ground/wall buffers, one press/one jump, jump-cut reset, ceiling contact, actual platform carry/leave/respawn, vertical/rotated springs, camera bounds, rotated/scaled tip gaps, single death, retry/reset/visibility, safe long falls, checkpoint activation, visible/offscreen turret warning and finite homing.
- Tower checks instantiate and unload the full world twice, validate all ten ascending checkpoints, respawn at each, check composite moving-spike colliders, verify room framing/zoom reset, and exercise the original ending camera.
- Godot 4.6 stable: matching graphical replays and benchmarks, clean-copy import, and Web release export completed. Earlier 4.6 controller/tower runs also passed; the final 4.8 run adds framing-zone checks.
- Actual rendered screenshots inspected: original and improved shaft/corridor, normal play and hazard examples. Seven matching input-replay clips were captured. These are automated graphical tests, not subjective human playtests.
- Actual browser test: the exported main game rendered and responded to keyboard running/jumping. Final export was rebuilt from a clean project copy without the pre-existing editor integration.
- `git diff --check` passed.

**Limits:** No unassisted full-tower completion, novice-player playtest, physical touchscreen/controller playtest, or public itch.io upload was performed. Checkpoint traversal and ending checks do not establish that every route segment is completable with the new movement. Godot 4.6 produced existing PagedAllocator/ObjectDB/resource cleanup diagnostics at exit in some original/main-world capture runs; these are kept in logs and are separate from successful script checks. Sandbox certificate/editor-settings-write diagnostics also appeared in headless tooling. No claim of completely clean engine teardown is made.

## Comparisons

Original is on the **left**, polished on the **right**. Clips replay the same input schedule at 60 Hz, with framebuffer samples every six physics ticks encoded at 10 fps. They have no recorded audio. Fixed tower screenshots use the same camera positions and paused geometry; player spawn animation and decorative particles can differ. The fixed screenshots demonstrate readability, not the new follow camera. Live camera behaviour is covered by replay and framing tests.

1. [Ordinary jumping](01_jump_comparison.mp4)
2. [Alternating wall jumps](02_alternating_walls_comparison.mp4)
3. [Narrow wall-jump shaft](03_narrow_shaft_comparison.mp4)
4. [Moving-platform carry and jump](04_moving_platform_comparison.mp4)
5. [Spring launch](05_spring_comparison.mp4)
6. [Spikes, death and retry](06_spikes_retry_comparison.mp4)
7. [Turret encounter](07_turret_comparison.mp4)
8. [Tower start](08_tower_start_comparison.png)
9. [Moving-spike shaft](09_tower_moving_shaft_comparison.png)
10. [Static and moving hazard corridor](10_tower_moving_hazards_comparison.png)
11. [Tower turret room](11_tower_turrets_comparison.png)

## Reproduce and playtest

Set `GODOT_BIN` to your Godot executable, then:

```sh
GODOT_BIN='/path/to/Godot' Tests/run_checks.sh
GODOT_BIN='/path/to/Godot-4.6' Tests/capture_comparison.sh
```

The capture script preserves a temporary checkout of `177067b` and copies only the shared replay harness into it. Use Godot 4.6 for the original comparison because its bundled joystick class conflicts with a new native class in 4.8. `ffmpeg` is only needed to encode review media; the game and tests need no new plugin or package.

Open `Tests/MovementTest.tscn` and run it. Keys **1–9** select runway/wide gap, single wall, alternating walls, narrow shaft, low ceiling, moving platform, springs, spikes and turret. **R** retries the station. Use arrows/A/D and Space/C/Up as in the main game.

Manual acceptance pass still required:

- Hold and tap jump over the runway gap; run/reverse/brake on ground, then in the air.
- On each wall, press jump with neutral, toward-wall and away-wall input. Repeat in the shaft, intentionally late and early; reverse after the push. Check ceiling contact.
- Wait on a horizontal/vertical platform; jump from both travel directions. Die while riding and retry on safe ground.
- Drop onto both springs with no input and while steering. Check launch direction, full force and no back-face retrigger.
- Inspect camera during open running, alternating walls and full-force spring launches, and transition into/out of the tower's horizontal hazard-room frame.
- Approach turrets slowly, wait through charging, break line of sight, dodge, and retry. Listen to the warning cue; the silent recordings cannot validate audio mixing.
- Climb the original tower from the start without checkpoint skipping, recording any route that is no longer reachable or any obscured/unclear death. Repeat on a touchscreen device before release.

## Remaining concerns and later level work

- The moving-spike shaft remains a timing challenge. Novice playtesting should decide whether a small waiting ledge or wider passage is warranted; no widening or hazard removal was made here.
- The long section between checkpoints 5 and 6 remains potentially punishing. Evaluate an additional safe waiting location/checkpoint during the later level-design pass.
- The horizontal moving-hazard corridor now has clear colour, honest hitboxes, symmetric reversals and wider framing, but still needs human evaluation of observation time and spacing.
- Short jump taps now rise less than before. Tune `jump_cut` if novice players consistently undershoot; held jump reach is preserved.
- Wall impulse is intentionally lower and consistent. Confirm distant wall transfers across the entire tower before release; use the exposed parameters to tune if a specific route proves unreachable.
- Evaluate warning-audio clarity against the music in a real play session. Preserve existing audio while tuning volumes if needed.
