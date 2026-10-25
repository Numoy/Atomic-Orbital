# Compact mode switch — 2026-10-22

The two mode cards competed with PLAY and repeated the best-score header. The selector now sits in one inset, beveled track immediately above PLAY. Its selected segment uses a restrained cyan/coral fill and outline; PLAY keeps the strongest visual emphasis. The mode rule moves below PLAY, keeping selection and starting together.

The selected mode's best remains in the header. Both personal bests remain available in the buttons' accessibility values, along with mutually exclusive selected states. The existing callbacks, mode keys and game rules are unchanged. No dependencies or assets were added.

The switch is capped at 340 logical units, with 48-unit minimum button targets. It stacks in narrow windows or with large text. Selection feedback respects reduced motion.

## Rendered checks

The production widgets were rendered with the bundled fonts. Scores 42 and 17 are fixtures; export callbacks do not write scores or start a run.

| Layout | Normal | Hardcore |
| --- | --- | --- |
| Phone | [View](evidence/mode-picker-2026-10-22/phone-normal.png) | [View](evidence/mode-picker-2026-10-22/phone-hardcore.png) |
| Apple phone | [View](evidence/mode-picker-2026-10-22/phone-apple-normal.png) | — |
| Landscape phone | [View](evidence/mode-picker-2026-10-22/phone-landscape.png) | — |
| Landscape tablet | [View](evidence/mode-picker-2026-10-22/tablet-landscape.png) | — |

Regenerate with `flutter test test/menu_scene_test.dart --dart-define=GENERATE_MENU_EVIDENCE=true --dart-define=MENU_EVIDENCE_DIRECTORY=docs/evidence/mode-picker-2026-10-22`.

- Full Flutter suite: **189 passing tests**. Analysis and `git diff --check` are clean.
- Existing layout coverage checks 13 window shapes at text scales 1 and 2, with both modes reachable and usable. The default phone keeps the switch and PLAY visible without scrolling.
- Interaction checks verify touch and keyboard selection, selected-state semantics, both accessible personal bests, the visible best/rule update, and that choosing a mode does not start a run. Existing gameplay/scaling/service tests pass.
- Test/analysis logs: `/tmp/atomic-mode-picker-all-tests.log`, `/tmp/atomic-mode-picker-analysis.log`.

The preceding [arcade presentation record](arcade-menu-2026-10-22.md) retains its original captures and artifact hashes.

## Native checks and installed builds

The final build was installed without uninstalling or clearing app data on the iPhone 16 and iPad (A16), both on iOS 26.2. Normal/Hardcore selection was exercised in the actual Simulator windows. Both layouts keep the switch and PLAY visible in portrait and landscape. Selection updates the accent, best-score header and mode rule without leaving the menu.

The native accessibility tree exposes each choice as one button containing its title, selected state and personal best. Existing device scores remain iPhone Normal 28 / Hardcore 12, and iPad Normal 0 / Hardcore 3. No new run or score was generated during this refinement.

| Native layout | Capture |
| --- | --- |
| iPhone Normal portrait | [View](evidence/mode-picker-2026-10-22/native/iphone-normal-portrait.png) |
| iPhone Hardcore portrait | [View](evidence/mode-picker-2026-10-22/native/iphone-hardcore-portrait.png) |
| iPhone Hardcore landscape | [View](evidence/mode-picker-2026-10-22/native/iphone-hardcore-landscape.png) |
| iPad Normal landscape | [View](evidence/mode-picker-2026-10-22/native/ipad-normal-landscape.png) |
| iPad Hardcore portrait | [View](evidence/mode-picker-2026-10-22/native/ipad-hardcore-portrait.png) |

- iOS debug simulator build passed; `build/ios/iphonesimulator/Runner.app` is installed on both Apple simulators.
- Android arm64 profile build passed and is installed on `emulator-5554`: `build/app/outputs/flutter-apk/app-profile.apk`, 36,880,215 bytes, SHA-256 `536833760123305c3dc5208aaf3f1dccc5d7e621114e8a6dfd6950cf8335c542`. The installed artifact matches; Normal 8 / Hardcore 4 / games played 13 remain unchanged. [Installation record](evidence/mode-picker-2026-10-22/android-install.json).
- Build logs: `/tmp/atomic-mode-picker-ios-build.log`, `/tmp/atomic-mode-picker-android-build.log`.

Physical-device testing and production signing were not performed in this presentation-only follow-up. The prior audio, sharing and real-run checks remain in the arcade record; those paths were not changed or repeated here. No app was published.
