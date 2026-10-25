# Arcade presentation — 2026-10-22

The first responsive menu felt more like an editorial app than a game. This pass makes the orbital arena and game identity the main visual elements, with less copy and faster access to play.

The subsequent [compact mode-switch refinement](mode-picker-2026-10-22.md) replaces this pass's two mode cards. The captures and artifacts below document the preceding design.

- Large stacked ATOMIC ORBITAL wordmark, a restrained starfield, and cyan/coral mode colors.
- Decorative arena with concentric segmented rings, a moving player and trail, radial movement, square pickup and red hazards. Its eight-second loop is presentation only: it does not advance the game engine, consume its random sequence, or change scores.
- Compact Normal/Hardcore buttons with separate best scores and one selected-mode rule. PLAY remains visible on the default phone without scrolling.
- Beveled PLAY and TRY AGAIN controls depress on pointer or keyboard activation. Utilities remain labeled with full semantic/tooltips for achievements, leaderboards and Play Games.
- GAME OVER results place the actual earned score inside the white nucleus, with the personal best nearby. Equal scores do not imply a new record.

The menu uses a two-column composition from 640 safe logical units wide, with a compact version below 480 units high. Smaller windows stack the content. Large text can stack the mode buttons and grow utility labels; content scrolls when necessary without shrinking touch targets. The logo and score are fitted display graphics with semantic text. Reduced-motion settings freeze the arena and remove the button's slide animation.

Gameplay, its fixed visible field, 60 Hz mechanics, binary hold/release input and Play Games routing are unchanged by this pass. No runtime dependencies or raster assets were added.

## Rendered evidence

These are actual production Flutter widgets rendered with bundled Roboto and Material Icons. Static captures freeze motion for reproducibility. Scores 42/17, completed run 7 and equal-score/best 42 are fixtures, not writes to a device or leaderboard. Service buttons use no-op callbacks during export.

| Screen | Evidence |
| --- | --- |
| Normal phone | [View](evidence/arcade-menu-2026-10-22/phone-normal.png) |
| Hardcore phone | [View](evidence/arcade-menu-2026-10-22/phone-hardcore.png) |
| Apple phone without unavailable Google actions | [View](evidence/arcade-menu-2026-10-22/phone-apple-normal.png) |
| Short landscape phone | [View](evidence/arcade-menu-2026-10-22/phone-landscape.png) |
| Landscape tablet | [View](evidence/arcade-menu-2026-10-22/tablet-landscape.png) |
| Hardcore game over | [View](evidence/arcade-menu-2026-10-22/phone-game-over.png) |
| Equal score and personal best | [View](evidence/arcade-menu-2026-10-22/phone-result-equal-best.png) |

Regenerate: `flutter test test/menu_scene_test.dart --dart-define=GENERATE_MENU_EVIDENCE=true`.

The [motion preview](evidence/arcade-menu-2026-10-22/menu-motion.gif) samples the actual widgets at 16 fps over the complete eight-second loop, including a half-second PLAY press/release. Its button visibly depresses 5 pixels and returns to idle. This is an isolated widget capture with a no-op play callback, rather than a recording of game performance or a run. Export with `flutter test test/menu_scene_test.dart --dart-define=GENERATE_MENU_MOTION=true --plain-name 'export actual arena loop and PLAY press feedback'`; encoding requires the local `ffmpeg` command, with no app dependency added.

## Verification and artifacts

- Full Flutter suite: **189 passing tests**; `flutter analyze` and `git diff --check` are clean.
- The component matrix covers 13 shapes at text scales 1 and 2, both modes and results, callback/service gating, reduced motion, initial phone visibility and truthful scores. A raster regression compares ordinary motion with the transition across the animation-loop seam; it passes the corrected loop and rejects a temporary copy with the former discontinuous motion. The existing world/input/resize and released-Java suites retain their gameplay checks.
- Android arm64 profile build passed: `build/app/outputs/flutter-apk/app-profile.apk`, 31,110,628 bytes, SHA-256 `16d9c3af84088d2f83b1e61c89182619ddc612c9daf78d48e90c54b6d7d574c0`.
- Installed Android artifact matches that SHA-256. Preferences before/after installation remain Normal 8 / Hardcore 4 / games played 13; [installation evidence](evidence/arcade-menu-2026-10-22/android-install.json).
- iOS simulator and unsigned iPhone/iPad release builds passed. The simulator build was installed on both dedicated Apple simulators. Device release output: `build/ios/iphoneos/Runner.app`, approximately 21.2 MB; production signing remains required.
- Build/test logs: `/tmp/atomic-arcade-{android-build,ios-simulator-build,ios-device-build,all-tests,all-analysis}.log`.

## Native simulator checks

After the Mac was unlocked, the installed arcade build was inspected on the dedicated iPhone 16 and iPad (A16), both running iOS 26.2. These are captures of the actual Simulator windows, including their bezels and toolbars.

- iPhone portrait respects the cutout and home indicator. In landscape, both modes, PLAY and Share fit without scrolling. Switching to Hardcore updates the palette, rule and selected best while preserving the existing Normal best of 28.
- A real iPhone Hardcore run earned 12. Its results retain the score through portrait/landscape rotation, with TRY AGAIN, HOME and Share visible in both layouts. HOME returns to the selected Hardcore mode with best 12 and Normal still 28.
- iPad menus adapt through portrait/landscape rotation with all primary controls visible. Its native share popover stays within the window when rotated and dismisses back to the menu.
- A real iPad Hardcore run ended with an earned score of 2. Results retained that score through rotation, and the native share preview correctly said “I got 2 points in Atomic Orbital.” TRY AGAIN reset the run to Ready with score 0. The replay earned 3; HOME returned to the Hardcore menu showing best 3, with Normal still 0.
- Native sharing was opened and dismissed on both devices; no destination was selected. Scores came from normal gameplay, without clearing preferences or injecting test scores.

| Native screen | Evidence |
| --- | --- |
| iPhone portrait menu | [View](evidence/arcade-menu-2026-10-22/native/iphone-menu-portrait.png) |
| iPhone landscape menu | [View](evidence/arcade-menu-2026-10-22/native/iphone-menu-landscape.png) |
| iPhone native sharing | [View](evidence/arcade-menu-2026-10-22/native/iphone-share-landscape.png) |
| iPhone portrait results | [View](evidence/arcade-menu-2026-10-22/native/iphone-game-over-portrait.png) |
| iPhone landscape results | [View](evidence/arcade-menu-2026-10-22/native/iphone-game-over-landscape.png) |
| iPhone HOME after gameplay | [View](evidence/arcade-menu-2026-10-22/native/iphone-home-portrait.png) |
| iPad portrait menu | [View](evidence/arcade-menu-2026-10-22/native/ipad-menu-portrait.png) |
| iPad landscape menu | [View](evidence/arcade-menu-2026-10-22/native/ipad-menu-landscape.png) |
| iPad sharing in landscape | [View](evidence/arcade-menu-2026-10-22/native/ipad-share-landscape.png) |
| iPad sharing after rotation | [View](evidence/arcade-menu-2026-10-22/native/ipad-share-portrait.png) |
| iPad portrait results | [View](evidence/arcade-menu-2026-10-22/native/ipad-game-over-portrait.png) |
| iPad landscape results | [View](evidence/arcade-menu-2026-10-22/native/ipad-game-over-landscape.png) |
| iPad share earned score | [View](evidence/arcade-menu-2026-10-22/native/ipad-share-result.png) |
| iPad replay ready | [View](evidence/arcade-menu-2026-10-22/native/ipad-replay-ready-landscape.png) |
| iPad completed replay | [View](evidence/arcade-menu-2026-10-22/native/ipad-replay-result-landscape.png) |
| iPad HOME after replay | [View](evidence/arcade-menu-2026-10-22/native/ipad-home-landscape.png) |

The [earlier native checks](native-checks-2026-10-22.md) cover the preceding menu, unchanged platform integration and native audio request paths. No production source changed during this native follow-up. Physical touch/audio latency, actual interruptions and signed-device validation remain unverified. No app was published.
