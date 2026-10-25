# Menu and results design

## Collection restored — 2026-10-25

The owner requested the world designs and shop again. The app entry point now enables the collection, preserving the optional Classic-only `GameScreen` configuration. Eleven themed worlds plus Classic, the minimal swipe selector and current source renders are recorded in [the world review](world-review-2026-10-25.md). The shop-free decision below is historical.

## Shop-free default — 2026-10-24

The active design uses the classic orbital artwork, Play/Try again, the mode
selector and a quiet Progress link. The shop, equipped-world label, currency
balance and reward badge are hidden. Help and practice copy focus on scoring and
controls. Local Progress shows 16 gameplay achievements and omits the two
world-related achievements and the worlds-owned statistic.

The cosmetic implementation, assets, prices, balances, owned worlds and saved
selection are preserved. Currency earnings are paused in this design. Rendering
uses Classic without replacing the saved selection, and run progress records
the world actually shown. `GameScreen(cosmeticsEnabled: true)` retains the shop
design and passes the same setting to Progress; its existing tests opt in.

Current renders of the production screen: [home](evidence/classic-design-2026-10-24/phone-home.png),
[game over](evidence/classic-design-2026-10-24/phone-result.png), and
[progress](evidence/classic-design-2026-10-24/phone-progress.png).
The fixture starts with a purchased and equipped Cow Abduction world, then
completes a five-point Normal run in the default design. The test verifies that
the wallet and saved equipped world remain unchanged.

Validation: all 302 tests pass, including the preserved cosmetic flows and the
shop-free save-preservation test. Analysis of the changed files is clean.
These are headless Flutter renders; physical-device testing was not run.

## Home and game-over navigation — 2026-10-24

Home and game over now share two secondary destinations, World shop and
Progress, in a single row below the main actions. The world shop shows the saved
Stars balance. The links stack on narrow windows or with large text.

The header Menu contains Settings, How to play, available platform leaderboards,
achievements and sign-in/disconnect, sharing, and rating. The sound toggle stays
in the header. Game over uses the same menu, with Share score first, and focuses
on the score, personal best, Try again and Home. A gold star badge distinguishes
saved rewards from pending saves. Its compact artwork leaves the main actions
visible without scrolling in the default landscape layout.

The duplicate Next goal shortcut was removed from both screens; achievements
remain in Progress, newly earned achievements remain in the result summary,
and save failures still show their retry action.

The currency is now Stars in English and Sterne in German, including singular
reward labels, shop prices, help, practice and save messages. The star icon uses
the existing Material font. Wallet keys, balances, ownership, prices and earning
rules are unchanged.

Current Flutter renders: [home](evidence/results-redesign-2026-10-24/phone-normal.png),
[game over](evidence/results-redesign-2026-10-24/phone-result.png),
[result menu](evidence/results-redesign-2026-10-24/phone-result-navigation.png),
[landscape result](evidence/results-redesign-2026-10-24/phone-result-landscape.png),
[tablet result](evidence/results-redesign-2026-10-24/tablet-result.png), and
[pending reward](evidence/results-redesign-2026-10-24/phone-pending-reward.png).
These use production menu widgets with fixture scores and balance, rather than
an installed device build.

Validation: all 296 tests pass, including menu navigation, keyboard activation,
platform sharing/sign-in, reward saving/retry, currency pluralization, and
English/German layouts at 3.2× text scaling.
Analysis of the changed files is clean.
Physical-device checks were not run for this change.

The current [arcade presentation](arcade-menu-2026-10-22.md) replaces the first responsive pass below. It uses a prominent ATOMIC ORBITAL wordmark, an animated concentric arena, compact mode selectors, beveled PLAY/TRY AGAIN buttons and a score inside the nucleus. The new record contains current renders, checks and build details.

## First responsive pass — historical

The first pass used responsive Flutter components with Roboto, an ink background, cyan for Normal and coral for Hardcore. Large mode cards explained the rules and showed each mode's best score. A primary button started or restarted the run, with sound in the header and service actions in the footer.

That layout used the actual safe window, placing the illustration and controls side by side at 840 logical units wide. Smaller windows stacked them vertically and scrolled when needed. The arcade pass now uses a 640-unit breakpoint with a compact layout for short windows, while retaining text scaling, usable touch targets and reduced-motion support.

Ready/playing keep the released game's fixed world, visible field, physics and hold/release controls. These changes intentionally update the surrounding menus. [Device fairness checks](device-scaling.md) continue to verify equal gameplay across sizes and window changes.

## First-pass Flutter renders

These PNGs come from the production `OrbitMenu` and `OrbitGameOver` components, rendered by Flutter with Roboto Regular/Medium and Material Icons explicitly loaded. They use the app's theme and safe-area constraints, with motion frozen for reproducibility. Scores are local test fixtures: Normal best 42, Hardcore best 17 and completed Hardcore run 7. Enabled Android service callbacks expose the real buttons without calling a service or selecting a share recipient.

| Screen | Logical window | PNG pixels | Evidence |
| --- | --- | --- | --- |
| Normal menu | 393 × 852 | 1179 × 2556 | [View](evidence/menu-design/phone-normal.png) |
| Hardcore menu | 393 × 852 | 1179 × 2556 | [View](evidence/menu-design/phone-hardcore.png) |
| Landscape tablet | 1366 × 1024 | 2732 × 2048 | [View](evidence/menu-design/tablet-landscape.png) |
| Hardcore result | 393 × 852 | 1179 × 2556 | [View](evidence/menu-design/phone-game-over.png) |

These preserved renders document the first pass. The current generation command and output directory are in the [arcade record](arcade-menu-2026-10-22.md).

The renders were inspected for text, spacing, selected mode, button visibility and clipping. They are headless Flutter renders, not captures of an operating-system status bar or a physical device.

## Behavioral checks

[Component tests](../test/menu_scene_test.dart) cover 13 window shapes at text scales 1 and 2, both menu modes and both result modes. Controls must remain inside the safe area or be reachable by scrolling without shrinking their touch targets. Additional checks verify selected semantics, score labels, mode/play/replay/home/sound/service callbacks, absent unavailable services, and actual rendered pixels freezing and resuming with reduced motion.

[Screen integration tests](../test/device_scaling_test.dart) preserve the gameplay timing/input/resize checks and exercise menu → ready → death → replay → home across the device matrix. Tab/Shift-Tab navigation and Space on focused mode/sound controls must activate those controls without starting a run. Space on the primary button starts the selected mode. Apple share routing continues to use the selected mode's best score in the menu and the completed run's score in the results.

Local result: **56 component tests and 20 screen integration tests pass**, plus all four opt-in render exports. Focused static analysis is clean.

## Combined verification — 2026-10-21

- Full `flutter test`: **186 passing tests**, including released-Java mechanics, refresh rates, Play Games routing, layout, input, resize and text-cache error recovery. If native gameplay text fails during a run, held input is released and the hidden world stops advancing, including after suspension/resume.
- `flutter analyze` and `git diff --check`: clean.
- Android arm64 profile APK: `build/app/outputs/flutter-apk/app-profile.apk`, 31,044,964 bytes; SHA-256 `a98c3762d137b66730a0411c80df9f9693d9af939b28d3415a48986b120144ed`. The unused historical menu images are absent from the package. The original reference APK remains preserved separately.
- Native Android menu and ready-state launches were inspected at the original 1080 × 1920 / 420 dpi emulator configuration. Existing local bests remained Normal 8 / Hardcore 4. Captures: [menu](evidence/menu-design/android-menu-runtime.png), [ready](evidence/menu-design/android-ready-runtime.png). These captures precede the final invisible-run error-recovery fix; that fix does not change their layout.
- Reinstalling the final APK later timed out after 45 seconds while the Mac was locked; the final artifact is built, but its emulator refresh is not verified. A stalled test input client was stopped without restarting the emulator or adb server. Existing game data was not cleared.
- iOS simulator and unsigned iPhone/iPad arm64 release builds pass. The unsigned device app is approximately 21.2 MB; it still needs production signing for installation/distribution.
- An iPhone simulator launch was attempted, but its capture was entirely black while the Mac was locked. It is not counted as a visual smoke-test pass. The four inspected Flutter renders above remain the cross-size visual evidence. Native Apple audio limitations remain recorded in [device scaling](device-scaling.md).

Build logs: `/tmp/atomic-menu-android-build.log`, `/tmp/atomic-menu-ios-simulator-build.log`, `/tmp/atomic-menu-ios-device-build.log`. Dependency/build-integration warnings about future Android Kotlin plugin support and the existing iOS CocoaPods integration remain maintenance work; neither prevents these builds.

Physical touch comfort, screen-reader traversal and OS dialog presentation still need checks on signed iPhone/iPad and Android builds. Existing audio/device distribution limits remain in the scaling document; these renders do not establish audio latency or store readiness.

## Unlocked native follow-up — 2026-10-22

The [native follow-up](native-checks-2026-10-22.md) closes the Android reinstall and iOS visual-check blockers above. The installed Android APK matches the final artifact and retains the existing scores. iPhone/iPad menus, gameplay framing, rotation and native share presentation were inspected, and both native Apple audio tests pass. Physical latency, real interruptions and signed-device/store validation remain open.
