# Device scaling and gameplay fairness

Every device uses the released reference world: **1080 × 1857 simulation units**, with the original **1080 × 1794 visible Canvas**. The 63-unit difference preserves the original Android display-origin behavior. Gameplay fits this portrait frame uniformly inside the window's safe area; unused space stays black. A tablet, taller phone or landscape window therefore reveals no additional world area or earlier photon warning. The menu and results screen adapt to the actual safe window instead of shrinking into the gameplay frame.

Physics, collision boxes, spawn timing and hold acceleration use the same world coordinates and 60 updates per second. Device pixels, pixel ratio and window dimensions change presentation only. Resizing preserves the active run, including entities, score, health and time. A resize or focus loss cancels held input so an old pointer cannot remain stuck.

Touch anywhere in the safe window, including the black bars, supplies the same binary hold/release input. Drag distance does not change speed. Space/Enter provide the same hold control once ready; releasing a key does not release another active finger. Game art and HUD text scale with the frame. Menus, external snackbars and system dialogs retain the user's text settings. Accessible labels remain available.

## Automated matrix

The independent [device scaling tests](../test/device_scaling_test.dart) exercise these logical window sizes. Insets are top/right/bottom/left logical units; they are representative test constraints rather than a hardware specification catalog.

| Case | Logical window | DPR | Insets | Text scale |
| --- | --- | --- | --- | --- |
| Released Android reference | 411.43 × 731.43 | 2.625 | 24 / 0 / 24 / 0 | 1 |
| Narrow phone | 320 × 568 | 2 | 20 / 0 / 0 / 0 | 1 |
| Tall Android phone | 360 × 800 | 3 | 24 / 0 / 24 / 0 | 1 |
| iPhone cutout | 393 × 852 | 3 | 59 / 0 / 34 / 0 | 1 |
| Wide phone | 430 × 932 | 3 | 59 / 0 / 34 / 0 | 1 |
| 4:3 tablet | 768 × 1024 | 2 | 24 / 0 / 20 / 0 | 1 |
| Tall tablet | 834 × 1194 | 2 | 24 / 0 / 20 / 0 | 1 |
| Large tablet | 1024 × 1366 | 2 | 24 / 0 / 20 / 0 | 1 |
| Landscape tablet | 1366 × 1024 | 2 | 24 / 0 / 20 / 0 | 1 |
| Landscape cutout window | 852 × 393 | 3 | 0 / 59 / 21 / 59 | 1 |
| Narrow split screen | 256 × 1024 | 2 | 24 / 0 / 20 / 0 | 1 |
| Square split screen | 600 × 600 | 2 | 24 / 0 / 20 / 0 | 1 |
| Enlarged-text narrow phone | 320 × 568 | 2 | 20 / 0 / 0 / 0 | 3.2 |

Each matrix case checks adaptive menu/result controls against the safe-area bounds, scrolling them into view when needed, and runs mode selection → ready → a real hardcore collision → game over → replay → home without layout errors. Ready/playing still use the same transformed gameplay frame. Additional checks compare identical timed hold/drag/release traces across all 13 sizes, preserve a damaged run with a pickup and live photons across resizing/DPR changes, and combine keyboard/touch input. Ten elapsed 100 ms resize intervals produce the same time and world state as an unchanged window. A rendered-pixel test first confirms a real photon is visible inside the frame, then verifies that moving it beyond the reference boundary leaves the tablet's black bar black.

The Apple UI test checks Sound/Share controls, absence of Google Play buttons, and native share requests for the selected mode's best score in the menu and the actual run score after a hardcore death. It records the native channel request without opening a chooser or selecting a recipient.

Run: `flutter test test/device_scaling_test.dart`.
All 20 tests pass; focused static analysis is clean. Tab/Shift-Tab and Space activate focused menu controls without starting a run until the primary button is activated. The released-Java oracle and refresh-rate checks remain in the existing parity suites; the device matrix adds UI/input/resize coverage. The separate [menu design tests and rendered evidence](menu-design.md) cover text scaling and the adaptive components in more detail.

## Runtime and distribution limits

These tests use Flutter's widget renderer with native gameplay text disabled; they establish layout/input/world fairness, not identical native glyph rasterization on every OS. Landscape and split-screen cases exercise constraints the OS may supply; supported rotations are also controlled by the platform manifests. Very short windows make the fixed portrait gameplay art smaller, while menus retain touch targets and scroll when needed. Gameplay hold input still covers the full safe window.

The locally installed simulator runtimes are iOS 18.5 and 26.2. The existing iPhone 16 and available iPad (A16) device type are suitable smoke-test targets; runtime launch/cutout/rotation results are recorded separately from these widget tests. This test task did not boot or operate a simulator.

Before distribution, verify a signed physical iPhone/iPad build, touch-to-display and audible latency, interruption recovery and comfortable control sizes. Configure production signing/identities and preserve legacy Android preferences before replacing the original app. Simulator builds and this matrix do not establish those hardware or store-release gates.

## Platform preparation

Android supports user rotation and resizable windows. iOS targets iPhone and iPad, supports phone portrait/landscapes and all four iPad orientations, and uses the current Flutter scene lifecycle. Native share presentation is anchored safely on iPad. Apple builds include the original atom icon in every required size, a black launch screen, and the reference Roboto regular/medium fonts with their Apache license.

Apple audio has a single native owner: prepared, reusable AVAudioPlayer effect voices with at most 10 simultaneous streams, plus one looping music player. Music pauses therefore cannot deactivate a separate plugin’s audio session underneath an active hit sound. WAV effect samples are identical to the decoded originals; the music uses AAC-LC. The audio session uses ambient mode to respect silent mode and mix with other audio. Music is requested again when an active run resumes after suspension. Physical onset latency remains unmeasured.

Current local iOS bundle identifier: `de.numpy.orbital.atomic-orbital`. Google Play Games continues to use the authorized Android comparison identity. No Apple account records, Game Center project, production credentials or store submissions were created. Apple ratings and Google-only social buttons are hidden until the corresponding service exists.

Platform references: [Flutter safe areas](https://docs.flutter.dev/ui/adaptive-responsive/safearea-mediaquery), [Apple scene lifecycle](https://developer.apple.com/documentation/technotes/tn3187-migrating-to-the-uikit-scene-based-life-cycle), [iPad fullscreen/resizing](https://developer.apple.com/documentation/bundleresources/information-property-list/uirequiresfullscreen), [Android game resizing](https://developer.android.com/games/develop/multiplatform/support-large-screen-resizability).

## Local scaling baseline before menu redesign — 2026-10-21

- `flutter analyze`: no issues.
- `flutter test`: all **126 tests pass**, including the 19 device-scaling checks.
- Android arm64 profile APK: `build/app/outputs/flutter-apk/app-profile.apk`, about 35.1 MB; SHA-256 `a8c3936581d31c798a4fdf23e3f1450aedbd7c2e4d41faad82b2f95e52781bae`.
- iOS simulator build: `build/ios/iphonesimulator/Runner.app`, includes current production code.
- iPhone/iPad device arm64 release build: `flutter build ios --release --no-codesign` passed; `build/ios/iphoneos/Runner.app`, about 25.3 MB. This unsigned app is a compile artifact, not an installable signed distribution.
- Native XCTest `RunnerTests/testAppleAudioPreparesAssetsValidatesRequestsAndDisposes` passed on the dedicated iPad. It verifies real WAV/M4A preparation, ambient audio category, repeat loading, pause/rewind, invalid/unloaded requests and disposal.
- Full native playback remains unpassed. The simulator reported CoreAudio/HAL output-device creation failures and timed-out audio queue startup. The strict playback test remains in the test suite; this environment failure is not counted as a pass.
- iPhone 16 / iOS 26.2 menu, mute control, ready state and landscape fit were observed before the Mac locked. Layout captures: [portrait ready](evidence/device-scaling/iphone-ready-portrait.png), [landscape menu](evidence/device-scaling/iphone-menu-landscape.png). They predate the native-audio ownership change; the layout code is unchanged.
- Further interactive iPad rotation/share and current-device smoke checks await the Mac being unlocked. Android size/density overrides were restored to 1080 × 1920 and 420 dpi. Starting-window captures from the locked-host attempt were discarded.

Re-run strict native playback on a working audio host/device with Xcode’s RunnerTests target, disabling parallel test cloning. Preparation result: `/tmp/atomic-scaling-ios-audio-preparation.xcresult`. Simulator log: `/tmp/atomic-scaling-ios-native-audio.log`; unsigned-device build log: `/tmp/atomic-scaling-ios-device-release.log`.

The previously accepted parity APK remains at `build/reference/atomic-orbital-parity-2026-10-21.apk`. Android scores/settings were preserved. The new Apple identifier has its own local storage; confirm or migrate any data from the former placeholder identifier before distribution. No app was published.

## Unlocked native follow-up — 2026-10-22

The [dated native record](native-checks-2026-10-22.md) supersedes the locked-host blockers in the historical baseline above. The final Android build is installed with its scores retained. Current iPhone/iPad menus, full-field gameplay fits, rotation, replay and native share presentation have been inspected. Both native Apple audio tests passed on the dedicated iPad; the former audio-queue startup failure did not recur. Their scope is successful native request/preparation paths, without physical latency or real-interruption verification.
