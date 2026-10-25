# Parity verification — 2026-10-21

Reference: the owner's original Google Play APK, Atomic Orbital 2.1.6 / code 41. Its fingerprint and recovery process are in [the plan](PLAN.md).

## Verified

| Check | Result |
| --- | --- |
| Independent released-Java controller oracle | 27 cases pass |
| Integrated engine behavior | 11 cases pass |
| Original-derived Play Games event oracle | 37 cases pass |
| Widget, rendering, native glyph cache, lifecycle, persistence, Android audio and Play Games routing | Pass |
| Complete Flutter test suite | 103 tests pass |
| Flutter analysis, including strict casts/inference/raw types | No issues |
| Android profile build, arm64 | Compiles; about 36.0 MB |
| iOS simulator build | Compiles; runtime parity not assessed |
| Original APK | Installed and launched unmodified on Android 16 emulator |
| Flutter port | Installed and launched alongside original under a separate application ID |
| Menu, ready state, and hardcore death screenshots | Paired captures in [evidence](evidence/) |

This is the accepted parity baseline, before the subsequent fair-scaling work. The preserved comparison APK is `build/reference/atomic-orbital-parity-2026-10-21.apk`, installed as `de.numpy.orbital.atomic_orbital` alongside the original. The installed APK and final local artifact have identical hashes. SHA-256: `26b10053624525a01fc8f8842ded0c87400d53e79f1a1bf20d765e256354d293`.

The oracle compiles 13 unmodified controllers/models recovered from the APK. Android rendering dependencies are stubbed. The fixture includes its source hashes and APK fingerprint; regenerating it produced byte-identical output. This is independent evidence of the motion calculations, rather than a test that restates the Dart implementation.

The traces cover player input, reversal and float32 rounding at physical widths 360, 1080 and 1440; all three photon trajectories in both directions; exact integer photon coordinates; 5/10/20-point orbit expansion; normal/hardcore health through regeneration and death; and 203 updates of wave growth/count behavior. Engine tests also check immediate energy respawn, strict box collisions, collision-removal ordering, restart, and equal simulated outcomes under 30/60/90/120 Hz callbacks and a delayed callback.

The user identified the original Samsung Galaxy S10 and 60 FPS target and explicitly chose simulator verification because the phone is unavailable. Simulation is therefore fixed at 60 updates per second. Faster displays do not accelerate it. The original Java loop depends on SurfaceView presentation; its observed emulator presentation rate under concurrent host load is not a calibration target.

## Rendering and flow

The comparison uses 1080 × 1920 physical pixels, density 420 / DPR 2.625, a 63-pixel status bar, and gesture navigation. The isolated AVD is named `atomic_orbital_parity`; it uses the installed Android 16 / API 36 arm64 image. Networking is enabled for live Play Games checks. The owner signed into the emulator. Hardware keyboard input was enabled and verified. The same AVD was restarted with 4096 MB RAM after the signed-in Google services caused heavy swapping at 2048 MB; app data and account were retained. Final captures use the emulator’s swiftshader_indirect backend after the earlier ANGLE backend froze. Both apps were recaptured on the same backend. The pre-existing `flutter_emulator` data was not cleared. The verified toolchain is Flutter 3.47.7 / Dart 3.13.5.

The original `Display.getSize()` includes the status bar while the Canvas surface excludes it. The port preserves this offset: ready-state atom center is at screen pixel (540, 991), atom radius 135, player radius 30, and initial player orbit radius 351. The minimum/maximum dashed orbit radii are 216/486. Source draw order, 5-pixel rings, 4-pixel energy edges, native score position, health bar, and start instruction are restored.

The paired ready captures were sampled at fixed screen coordinates. These checks exclude the random energy square, pulsing instruction, menu-video phase and status icons. “White” below means every RGB channel is greater than 240; bounds are inclusive.

| Static measurement | Original release | Flutter port |
| --- | --- | --- |
| Atom white bounding box within its isolated center crop | x 405–674, y 856–1125 | Identical |
| Initial player vertical white span at x 540 | y 1312–1371 | Identical |
| Selected orbit top white span at x 540 | y 638–641 | Identical |
| Selected orbit left white span at y 991 | x 187–190 | Identical |
| Game status background at (20, 20) | RGB (2, 48, 67) | Identical |
| Health fill at (200, 80) | RGB (74, 174, 82) | Identical |
| Solid dashed-orbit color | RGB (140, 138, 140) | Identical |
| Inner/outer dashed-orbit full-color top bands near x 540 | y 773–776 / 503–506 | Identical with Skia |
| Health-frame white span at x 20 | y 66–139 | Identical with Skia |

Android uses Flutter's Skia renderer explicitly. Impeller/GLES produced an extra full-color boundary row for the last two measured anchors; Skia reproduces the original rows. The original source geometry is unchanged. A rendering regression checks the clipped surface, status inset, shape colors, black score ink and white instruction/FPS ink.

The screenshot preview intermittently omitted static text/icons even when the saved PNG contained them. Independent raw-pixel checks found byte-identical NORMAL, HARDCORE, START and score crops before/after native Play Games overlays and Home/resume. Surface-recreation and image-cache recovery experiments were removed because the saved pixel data showed no app defect. Final visual checks use saved pixels and isolated crops, not preview appearance alone.

Flutter 3.47.7 warns that the Skia opt-out may be removed in a future release. Recheck both rendering backends and these captures before upgrading Flutter; the manifest records this limit. This is an actual toolchain compatibility risk, not a claim that every future renderer is equivalent.

Actual hardcore deaths were captured in both apps. The final layout regression checks the original physical bounds independently of the random gameplay state:

| Hardcore death layout | Original capture | Flutter widget bounds |
| --- | --- | --- |
| Score panel vertical span | y 352–614 | y 352–614 |
| First action-row top | y 878 | y 878 |
| Restart button origin | (159, 1062) | (159, 1062) |
| Restart button dimensions | 761 × 170 | 761 × 170 |
| Bottom action-row top | y 1245 | y 1245 |

The release replaces the hardcore restart button's XML layout parameters using truncated dp conversions. Normal mode keeps the XML rounding, producing a 171-pixel restart height and bottom row at y 1246; both branches are checked. Tests cause real engine collisions (three normal hits or one hardcore hit), then exercise mute, restart, home and native NO ADS routing in both modes.

Android text now uses cached native raster stamps: `TextView.draw` through native HWUI/RenderNode for XML labels on API29+, and `Paint.drawText` on software Canvas for gameplay text. Full strings preserve native hinting, kerning, wrapping, font padding and advances. Cache misses are batched/prewarmed outside the rendering loop; bounded storage releases evicted images. Scores are prepared ahead of use. Other platforms keep the existing Flutter fallback.

The released XML sizes use Android's `getDimensionPixelSize`, which rounds physical font size; fractional `setTextSize(SP)` alone does not reproduce it. At DPR 2.625, 8/9/13/14/15/25/30/60/70 sp becomes 21/24/34/37/39/66/79/158/184 px. The native helper also disables API 35's bounds-based wrap width, preserving the release's target-26 behavior. Menu rows use the original sequential integer weight allocation and rounded spacers, rather than fractional Expanded layouts. Opaque menu stamps are rendered over the original solid background, retaining the antialiased ink while leaving the START panel’s curved corners exposed. This reduces START edge-color differences without adding per-frame native work. The earlier [android-text-metrics.txt](evidence/android-text-metrics.txt) records the fractional-size exploratory harness and is not the final XML-size ground truth.

The final menu captures have identical NORMAL/HARDCORE/START ink bounds and advances. Their eroded solid interiors are byte-identical. Remaining edge-color differences are limited to 1,757 / 2,280 / 2,651 pixels respectively, with a maximum RGB-channel difference of 7 / 6 / 5 out of 255. These are antialias coverage/compositing differences, not shifted or differently sized glyphs. Full isolated-crop measurements are recorded in [glyph-comparison.txt](evidence/glyph-comparison.txt); menu video, scores and status icons are excluded from those glyph crops.

The final GAME OVER title crop is RGB byte-identical to the original. Independent post-rounding screenshot comparisons find identical ink masks and absolute positions for RATE, HOME, MUTED, ACHIEVEMENTS, SCORE, NO ADS, SHARE, and the Score/Highscore prefixes. ACHIEVEMENTS is compared with a background-independent cyan mask because different final orbit positions remain visible behind the translucent panel. The start instruction has identical ink bounds; its time-varying pulse makes edge thresholds phase-sensitive. Ready score zero has identical bounds; four threshold boundary pixels differ between original RGB565 and ARGB rasterization. Dynamic scores, player/energy position and animation phase are excluded explicitly.

Menus reuse the exact original video frames and drawable paths. The two-second, 30 FPS video loops were converted to lossless animated WebP so no video dependency was needed. Mode switching retains animation phase. The Android launcher uses the exact original xxxhdpi icon and resource density selection. Original vector icons were rasterized from their existing paths; original PNGs and OGG bytes are reused. The original rating-stars image is no longer stretched across the game background.

Android effects use native SoundPool with 10 streams and the original samples, matching the released Android backend. Music uses the existing plugin's MediaPlayer. The first launch is muted, as in the release. Runtime mute toggling and restart were exercised; Android AudioFlinger reported an active music track and a separate SoundPool effect track for the port after enabling sound. Host audio output was disabled, so this verifies routing rather than audible latency. The native Android share chooser was opened and dismissed without choosing a recipient. NO ADS displays the original [Android toast](evidence/flutter-no-ads-toast-1080x1920.png). Rate/share actions use the original destinations without automatically sending a message. Original COMING SOON remains unimplemented because its released handler is empty.


## Play Games configuration and live checks

The owner approved creation/linking of an Android OAuth client restricted to `de.numpy.orbital.atomic_orbital` and debug signing SHA-1 `83:8F:3E:F2:F5:DB:03:1E:30:D7:92:7E:56:D5:DE:28:2A:EA:FF:7B`. The actual installed APK's certificate was independently verified.

- Original project: `239790895284` / Cloud `atomic-orbital-7008314`.
- OAuth client: `239790895284-rjrlu85u18ufkv8265n5dtmr0gpiu242.apps.googleusercontent.com`.
- Linked credential: `CgkItOGapf0GEAIQEw`, draft, available to the existing authorized tester account. Original default credential and existing clients are preserved.
- Native SDK: `play-services-games-v2:22.1.0`; genuine authentication, native achievement and selected leaderboard intents, immediate server-acknowledged score/unlock calls.
- Live achievements show the original account's 9/12 earned progress, including 2018 entries. Both mode buttons open the correct original live board with the account's old Normal 61 / Hardcore 36 scores. Proof: [achievements](evidence/play-games-live-achievements.png), [Normal](evidence/play-games-live-normal.png), [Hardcore](evidence/play-games-live-hardcore.png), [linked credential](evidence/play-games-credential-linked.png).

Completed-game requests preserve original achievement thresholds and event ordering. Two broken original games-board details are corrected: it passed the literal preference key `gamesPlayed` as the leaderboard ID and submitted the pre-increment count. The independent Java event fixture retains those original results; the comparison tests explicitly normalize only those two corrections.

Published, immutable score limits were read from the original Console: Normal 1–200, Hardcore 1–100, games played at least 1 with no configured maximum. A default zero submission was rejected by the server (`INVALID_ARGUMENT`, surfaced by the SDK as 26506) and blocked queued valid events. Cloud request validation follows these existing limits while preserving local scores and statistics.

Live `submitScoreImmediate` acknowledgments drained the queue for legitimate local Normal 8 / Hardcore 4 / games 12 updates. A final real Hardcore death advanced completed games to 13 and again left an empty queue. Its SCORE button opened the original Hardcore board; all static death-title/action crops were byte-identical after returning from the native screen. An idempotent `unlockImmediate` check against the already-earned 500-point achievement also drained successfully; no new progress was granted. See [live acknowledgment record](evidence/play-games-live-ack.txt).

Offline/canceled/failed updates remain persisted, coalesce maximum scores and idempotent unlocks, and clear only after native immediate-call acknowledgment. App disconnect persists across restart/resume, stops further uploads and restores the original logged-out toast and controller icon; explicit reconnect resumes sync. Modern Play Games v2 manages the Google account at OS level, so the app disconnect does not remove the Android account. The SDK init provider is disabled. A small Application initializes the SDK before the first Activity only when the saved disconnect preference permits it; explicit reconnect initializes lazily when needed. This preserves automatic sign-in while preventing an explicitly disconnected cold start from reconnecting. Initializing only from Dart missed the SDK’s onActivityCreated hook and caused status10; the early native initialization fixes that observed error.

## Explicit remaining differences and limits

- The original software Canvas uses RGB565 color quantization and dithering; Flutter uses GPU Skia. All listed geometry/color/edge anchors match, but complete boundary pixels are not byte-identical. Screenshot comparisons must not claim perfect pixel equality or hide these differences with a whole-screen percentage.
- Random energy positions and menu-video phase differ between screenshots. The original seeds from wall-clock nanoseconds, so two original sessions also differ. Tests compare deterministic input traces and distributions, not an invented reproducible original random stream.
- The simulator checks input delivery and sound routing, not physical touchscreen-to-photon or speaker latency. The emulator was started without host audio output; audible balance/latency was not measured.
- Old Java preference migration is unnecessary while the two apps have separate IDs. Before an in-place production replacement, import the original `settings` preferences (`highscore`, `hardcorehighscore`, `MUTE`) and preserve the original signing identity. No production rollout was performed. Only the specifically approved comparison OAuth client and linked draft Play Games credential were created; the existing original credentials/default remain unchanged.
- iOS compiled successfully, but its audio, native share sheet, lifecycle and visual behavior have not been compared at runtime. Android is the accepted reference platform for this pass.

The source-derived traces verify mechanics at the agreed 60 Hz target. The screenshot measurements verify the listed Android layout and glyph properties. Neither claims byte-identical rendering across all rasterizers or physical-device latency.
