# Gameplay presentation — 2026-10-22

The playfield now shares the arcade menu's palette: ink background, off-white nucleus/player/pickup, cyan Normal and coral Hardcore accents, and distinct pink/red hazards. A faint, stationary reactor glow sits behind the arena. The health display becomes a slim beveled rail with the mode and HEALTH/ONE HIT labels. Production FPS text is hidden; native score/start-prompt glyphs remain in use on Android.

The palette is owned by the existing `GameConstants` and reused by both menu and playfield. No assets or dependencies were added. There are no new trails, camera effects, pulsing silhouettes, particle systems, per-hazard blur or independent gameplay animations.

## Preserving the accepted game

- World remains 1080 × 1857, clipped to the same 1080 × 1794 visible field and uniformly fitted inside safe areas. Input still works over the fitted margins.
- Simulation remains 60 Hz. Ticker, input, lifecycle, random sequence, spawning, health regeneration, collisions, scoring and audio paths are unchanged.
- Player and photon cores use their actual existing radii. The pickup retains its hollow diamond, the same vertices and 4-pixel stroke. Orbit radii, dash geometry, rotations and 5-pixel strokes remain unchanged.
- The opaque 135-radius nucleus still draws over photons. Growing or inward hazards are not revealed earlier.
- Ready-prompt alpha and damage timing still come directly from the existing controllers. The red background uses the original quantized flash envelope, recolored for the new palette. The health rail displays the actual health fraction.

An independent read-only review found no timing, geometry, clipping or input regression. [Mechanics fingerprints](evidence/game-visuals-2026-10-22/mechanics.json) confirm engine, components, vector math and entity sources are byte-for-byte unchanged during this pass.

## Verification and renders

The full Flutter suite passes **192 tests**; analysis and `git diff --check` are clean. Existing released-Java oracle, refresh-rate, multi-input and device-scaling tests pass. Added checks cover repeated-paint purity, solid player/photon boundaries, the hollow pickup, nucleus occlusion, actual damaged health and hazard contrast during the maximum flash. The existing renderer test retains surface clipping, score and ready-prompt checks with the intentional new colors.

The five captures below render the actual production `GameScreen` with bundled Roboto. Ready is a fresh run. Active fixtures temporarily disable collisions while populating the field, then restore them before capture. The hit fixture triggers a real controller hit, reaching health 55.1 / flash 125, and positions the surviving hazard for contrast inspection. These isolated exports do not write device scores or leaderboards; they are not recordings of a live run.

| State | Capture |
| --- | --- |
| Normal ready | [View](evidence/game-visuals-2026-10-22/ready.png) |
| Normal active | [View](evidence/game-visuals-2026-10-22/normal.png) |
| Hardcore active | [View](evidence/game-visuals-2026-10-22/hardcore.png) |
| Maximum hit flash / damaged health | [View](evidence/game-visuals-2026-10-22/hit.png) |
| Landscape tablet / same visible field | [View](evidence/game-visuals-2026-10-22/tablet-landscape.png) |

The visual review found no material clarity issue, including the maximum hit flash. Regenerate with `flutter test test/game_visuals_evidence_test.dart --dart-define=GENERATE_GAME_EVIDENCE=true`.

Logs: `/tmp/atomic-game-visuals-{all-tests,render,analysis,ios-build,android-build}.log`.

## Native follow-up and installed artifacts

Both dedicated Apple simulators run iOS 26.2 and received the updated debug simulator build without uninstalling or clearing app data.

- iPad (A16): inspected Normal Ready in portrait and landscape. A real run exercised hold/release input, reached score 2 and showed damaged health followed by recovery. Escape returned to the menu.
- iPhone 16: inspected Hardcore Ready in landscape and upright portrait, including cutout clearance. A real run ended on a collision with score 0; TRY AGAIN returned to Ready. Another live run was captured with visible hazards, then Escape returned to the menu. Existing Normal best 28 / Hardcore best 12 remain intact.
- Native captures retain the Simulator bezel and toolbar. These runs used ordinary keyboard input, without injected scores or altered collision rules.

| Native state | Capture |
| --- | --- |
| iPad Normal Ready portrait | [View](evidence/game-visuals-2026-10-22/native/ipad-normal-ready-portrait.png) |
| iPad Normal Ready landscape | [View](evidence/game-visuals-2026-10-22/native/ipad-normal-ready-landscape.png) |
| iPad Normal live run | [View](evidence/game-visuals-2026-10-22/native/ipad-normal-live-landscape.png) |
| iPhone Hardcore Ready landscape | [View](evidence/game-visuals-2026-10-22/native/iphone-hardcore-ready-landscape.png) |
| iPhone Hardcore Ready portrait | [View](evidence/game-visuals-2026-10-22/native/iphone-hardcore-ready-portrait.png) |
| iPhone Hardcore completed run | [View](evidence/game-visuals-2026-10-22/native/iphone-hardcore-run-portrait.png) |
| iPhone Hardcore live run | [View](evidence/game-visuals-2026-10-22/native/iphone-hardcore-live-portrait.png) |

The Android arm64 profile build passed and is installed on `emulator-5554`: `build/app/outputs/flutter-apk/app-profile.apk`, 36,880,215 bytes, SHA-256 `2d39855b8e92810bfebb82fb43260680c01c25446ae7a8558cfaa332aea11461`. The installed artifact matches, with Normal 8 / Hardcore 4 / games played 13 preserved. [Installation record](evidence/game-visuals-2026-10-22/android-install.json). Its AOT binary contains the new HUD labels and omits production FPS text. The profile app launched successfully with no fatal/Flutter text errors in the inspected process log. [Startup record](evidence/game-visuals-2026-10-22/android-startup.json).

The Android Qt emulator window was not exposed to desktop UI automation, so this pass does not claim an Android native visual check. iPhone/iPad visual and interaction checks passed; physical touch/audio latency and measured native frame pacing remain unverified. Device release signing and publishing were not performed.
