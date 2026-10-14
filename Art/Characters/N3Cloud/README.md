# N3Cloud character integration

Source: **Josee / N3Cloud — 2D Pixel Art Character Template, Platformer & Metroidvania**. [Official page](https://n3cloud.itch.io/2d-pixel-art-character-template-platformer-metroidvania). See [LICENSE-NOTICE.md](LICENSE-NOTICE.md) for the author's game-use permission and its scope.

## Verified source

- `Full-Sheet.png` is the unchanged original **1792×3280 RGBA** file; its SHA-256 is recorded in [animation_manifest.json](animation_manifest.json).
- The actual grid is **128×80**, 14 columns and 41 rows. The smaller dimensions in the request described a scaled attachment view. No transparent padding or resizing was necessary.
- All **38 named PNG strips** from the supplied pack matched cells in this sheet pixel-for-pixel. The supplied Aseprite file also confirms sequence names and nested jump/wall/ledge subsets.
- `character_frames.tres` contains 38 complete author sequences plus 14 gameplay aliases/subsets, using 198 fixed-size `AtlasTexture` regions. Combat, crouch, dash and ledge sequences are available in the preview only; they introduce no abilities.
- Zero-based row 34 contains the full **nine-frame roll**. Gameplay uses its six tumbling frames, columns 2–7, leaving out the grounded standing/crouch bookends. These frames already contain rotation.
- Jump row 22 contains preparation (columns 0–2), rising (3–5), falling (6–8), and recovery (9–10). Rows 23/24 repeat the up/down subsets; row 25 repeats the full jump. Dash rows and ledge subsets also contain duplicates; the manifest records exact matches.

Every animation entry records source coordinates, rectangles, frame count, FPS, looping, intended use and any fallback. Names follow the author's strip filenames rather than an assumed row catalogue.

## Runtime poses

| State | Frames `(column,row)`, zero-based | FPS / behaviour |
|---|---|---|
| Idle | `(0–4,0)` | 8, loop |
| Walk/run | `(0–5,4)` | 12.5, speed-scaled loop |
| Sprint | `(0–5,8)` | 14, speed-scaled loop |
| Takeoff | `(1–2,22)` | 24, brief preparation |
| Rising | `(3–5,22)` | 10, loop |
| Apex | `(4,22)` | Held neutral airborne frame |
| Falling | `(6–8,22)` | 10, loop |
| Landing | `(9–10,22)` | 20, short recovery |
| Wall slide | `(2–4,26)` | 8, loop; contact hand reaches left before mirroring |
| Wall jump | `(3–5,22)` | 18, rising-pose fallback; no dedicated push-off strip |
| Spring launch | `(6–7,22)` | 18, arms-up fallback; no dedicated spring strip |
| Air roll | `(2–7,34)` | 16, once; no extra parent spin |
| Death | `(6–8,22)` | Falling-pose fallback and quick fade; no death strip |
| Respawn | `(0,0)` | Standing fallback and quick appearance; no spawn strip |

Run playback is based on actual horizontal speed, clamped to 0.65–1.3×; sprint starts at 85% of normal maximum speed. Ordinary animation changes do not lock controls. Takeoff presentation lasts 75ms, wall push-off follows the existing wall-jump state, landing recovery lasts 110ms, and spawn presentation lasts 120ms. Death keeps the existing 350ms retry timing and fades the art over approximately 100ms after an initial 60ms effect.

## One visual owner

`Player/Sprite.gd` reads the unchanged physics controller and owns:

```text
Sprite                 # foot pivot at player origin + (0,8); lean only
└── FacingRoot         # horizontal mirroring, art-only wall contact offset
    └── SquashRoot     # one replaceable scale tween
        ├── Character # AnimatedSprite2D; original frame alignment
        └── CubeFallback # development comparison only
```

The cube's `AnimationPlayer` and polygon tracks were removed. Physics, ground/wall rays, hurt area and collision shapes remain unchanged. The formerly unwired death sound is now connected to the existing `death.ogg` resource.

The fixed source anchor is **(64,64)**. Every frame retains its full 128×80 padding. At uniform scale **0.75**, normal idle art is approximately 27 world pixels high; its feet align with the original collision foot eight pixels below the player's origin. Frames are never re-centred using alpha bounds. Run/jump limb motion comes from the source. Nearest filtering and clipped atlas regions preserve crisp transparent edges.

Effects use the parent hierarchy, never the physics body:

- Run lean: 4°, forward with actual velocity.
- Takeoff: scale `(0.90,1.10)`, recovery 85ms.
- Landing: `(1.12,0.86)`, recovery 130ms; hard falls use `(1.16,0.82)`.
- Wall contact: 4px visual offset toward the wall, no rotation. Wall-jump facing retains the actual launch direction even when opposite input is held.
- Source roll: one flourish per airborne sequence, eligible after 180ms with takeoff speed ≥500px/s or a spring launch, and 64px of clear space on **both** sides. A 1.4s cooldown makes it occasional; eligibility is decided at takeoff, preventing late mid-jump flips when that cooldown expires. Wall contact, landing, death and respawn interrupt it immediately. It adds no dodge, invulnerability or force.
- Existing CPU particles and audio remain. Bursts are smaller; trails are at most seven points, three pixels wide with restrained alpha. Footsteps follow run/sprint frames 0 and 3. Jump particles/sound have one owner: the physics `jumped` signal.
- Death/respawn kill the squash tween, clear locks/trails and restore known transforms. There are no delayed visibility coroutines.

## Preview and play

- Run [../../../Scenes/CharacterAnimationTest.tscn](../../../Scenes/CharacterAnimationTest.tscn) with F6. Use the dropdown or `[` / `]` for all 52 animations, Space to pause, Left/Right to step, `F` to flip, and the speed slider. Large and actual-size previews share the same frame and anchor.
- Run [../../../Scenes/CharacterMovementTest.tscn](../../../Scenes/CharacterMovementTest.tscn) with F6. The independent BlackSpire route adds short/long gaps and a spring, retains slopes, a narrow shaft, a moving lift, a high wall, checkpoints and safe falls. `R` retries, `K` tests death, and the existing debug `\\` key visits the next checkpoint.
- In debug builds, `F7` toggles state/frame/velocity/squash/roll information; `F8` toggles the single cube fallback. These are not release controls.

## Extend and validate

Edit the manifest to select verified source cells, then rebuild:

```sh
python3 Art/Characters/N3Cloud/build_frames.py
python3 Tests/character_assets_test.py
GODOT_BIN="/path/to/Godot" bash Tests/run_checks.sh
```

Add a state alias and its explicit fallback in `Sprite.gd`; keep its fixed anchor and one event owner. Adjust inspector fields on `Player/Sprite` for scale, lean, squash and flourish thresholds. Do not change body scale or collision resources to tune presentation.

Review captures, exact before/after physics traces and limitations are in [../../../artifacts/character_animation/README.md](../../../artifacts/character_animation/README.md). Full human tower completion and physical mobile testing are separate from deterministic animation checks.
