# Atomic Orbital store assets — 22 October 2026

Upload the PNGs under `screenshots/` and `graphics/`. The contact sheet is for review only.

## Screenshot sets

Each directory contains these five ordered screenshots:

1. `01-normal.png`: an actual Normal run at score 8, with active hazards.
2. `02-hardcore.png`: an actual Hardcore run at score 8.
3. `03-normal-later.png`: an actual Normal run at score 14, with additional orbits.
4. `04-menu.png`: the current arcade menu and mode selector.
5. `05-results.png`: the actual Normal run's game-over screen at score 32.

| Directory | Pixel dimensions | Rendered logical window | Capture scale |
| --- | --- | --- | --- |
| `screenshots/google-play-phone` | 1080 × 1920 | 411.43 × 731.43 | 2.625 |
| `screenshots/google-play-tablet` | 1920 × 1080 | 960 × 540 | 2 |
| `screenshots/app-store-iphone-medium` | 1179 × 2556 | 393 × 852 | 3 |
| `screenshots/app-store-iphone-large` | 1320 × 2868 | 440 × 956 | 3 |
| `screenshots/app-store-ipad-13` | 2732 × 2048 | 1366 × 1024 | 2 |

The Android tablet set can be used for both the 7-inch and 10-inch listing slots. It shows the actual responsive landscape interface and the uniformly fitted gameplay world. Apple screenshots show local play and Share, with unavailable Google Play Games controls absent. Android screenshots include the available Play Games controls. Both Roboto and MaterialIcons are explicitly loaded.

The Apple dimensions match its accepted Dynamic Island medium/large and iPad 13-inch specifications. The Android sets use 9:16 phone and 16:9 tablet frames, with three gameplay screenshots before menu/results. Requirements checked against [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) and [Google Play preview-asset guidance](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en) on 22 October 2026. Actual store upload acceptance remains a separate check.

## Graphic assets

- `graphics/feature-1024x500.png`: title artwork using the current typography/palette beside the actual score-8 game renderer. This is a composed Play feature graphic, rather than a full-screen app capture.
- `graphics/icon-512x512.png`: the original `app/src/main/res/launcher_web.png` artwork at its original 512 × 512 resolution, composited onto its original blue background. No new icon identity or AI-generated artwork is introduced.

## Provenance and limits

All screenshots render the current production `GameScreen` and its menu/results components with the bundled fonts. Gameplay comes from the unmodified production `GameEngine`, seeded with `Random(1)` and controlled exclusively through ordinary hold/release input. Entity positions, collision settings, sizes, scores and health are never assigned by the fixture. `fixtures.json` records the selected frames and actual resulting scores. The Normal run ends at 32; the Hardcore run ends at 24, which supply the menu's representative local best values.

These are deterministic Flutter widget renders, not native device screenshots. They include the app's safe-area layout but no fabricated OS status-bar content, device frames, store badges or marketing captions. The software renderer uses the app's Flutter text fallback; native Android Canvas text may differ at a few antialiased edge pixels. The screenshots establish the current in-app visuals, not hardware frame pacing, physical input latency, audio latency or live service availability.

## Reproduce and validate

```sh
flutter test test/store_screenshots_test.dart --dart-define=GENERATE_STORE_SCREENSHOTS=true --reporter expanded
python3 scripts/prepare_store_assets.py
```

The export passed **26 checks**. The packaging script verifies all 25 screenshots and both graphics have exact expected dimensions and fully opaque source pixels, converts them to RGB PNGs without resizing, reopens them and asserts their RGB pixels are unchanged. `manifest.json` records dimensions, sizes and SHA-256 hashes for all 27 final upload assets. The script removes the generated `raw/` duplicates after successful packaging. `review-contact-sheet.jpg` and full-size menu/gameplay/results/feature/icon images were visually inspected for missing glyphs, clipping, palette and platform controls.

Focused static analysis of the screenshot generator passed. No gameplay, native platform or signing code was changed to create these assets.
