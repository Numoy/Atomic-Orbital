# World artwork and shop polish — 2026-10-24

Follow-up: the user identified artwork and characters as the priority; the [character-art pass](character-art-2026-10-24.md) further improves the shared artwork. The verification below records this earlier polish pass.

Continues the smooth orbital direction after the user said the game still needed refinement. This pass refines the existing worlds rather than adding currencies or changing gameplay.

- The shop uses a compact Worlds heading and Stardust balance pill, title-case world names, a faint scene backdrop, full world descriptions and quieter purchase controls. Thumbnails use the scene composition rather than a miniature copy of the game HUD.
- A locked world shows the current balance toward its price and the remaining Stardust. Progress is hidden when the wallet is unavailable; buying, ownership and equipped state continue to come from the existing settings service.
- The menu labels the active world beneath the arena, and themed menu planets/actors are slightly larger. Classic gameplay rendering remains intact.
- The shared Canvas artwork refines globe coastlines, lighting, clouds, vehicles and scene depth. The same artwork renders in gameplay, the menu and shop.

Wallet IDs, format, prices, ownership and earnings are unchanged. So are simulation/controller code, collision geometry, visible field, timing, difficulty and leaderboard submissions.

## Validation

- All **250 tests pass**, including the Java oracle, Classic rendering, seeded simulation equality, core occlusion/artwork bounds, globe lighting and UFO silhouette checks, wallet save/retry/concurrency, purchase/equip flows and unavailable-wallet handling.
- `flutter analyze`, formatting and `git diff --check` pass. The focused menu/shop run passes 102 checks including evidence; 19 final evidence tests refresh the current scenes and purchase states.
- Layout checks cover the existing 13-device matrix, a 256-pixel-wide shop, landscape, notches and text scaling through 3.2×. The shop retains compact chooser rows at large text sizes and enough space below its fixed header to browse.
- Android comparison profile and iOS debug simulator builds pass. Android's AOT package is verified without a debug kernel. Neither native bundle reintroduces retired pixel sprites/font files.

Inspected production-widget previews:

- [Locked world progress](evidence/world-polish-2026-10-24/shop-progress-phone.png), [affordable world](evidence/world-polish-2026-10-24/shop-phone.png) and [equipped world](evidence/world-polish-2026-10-24/shop-equipped-phone.png).
- [Deep Blue](evidence/world-polish-2026-10-24/deep_blue-shop-phone.png) and [tablet shop](evidence/world-polish-2026-10-24/shop-tablet.png).
- [Cow gameplay](evidence/world-polish-2026-10-24/cow_abduction-gameplay-phone.png), [Deep Blue gameplay](evidence/world-polish-2026-10-24/deep_blue-gameplay-phone.png) and [menu](evidence/world-polish-2026-10-24/phone-cow-menu.png).

Captures use isolated fixture positions/scores and mock preferences. No real wallet or leaderboard data is modified. No device was visible to adb; neither build was installed or published. Phone readability, native UI interaction and sustained frame pacing remain unverified. Existing Kotlin/CocoaPods migration notices remain build warnings.
