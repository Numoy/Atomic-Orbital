# Orbital visual style — 2026-10-24

Follow-up: the [world polish pass](world-polish-2026-10-24.md) further refines the artwork, shop and menu world identity. The checks below record this earlier style implementation.

The user reconsidered the retro direction and asked for a style that fits the game. This follow-up keeps the featured-world shop and cosmetic system while returning to the existing dark navy, off-white and cyan arcade presentation.

## Presentation

- Cow Abduction uses a shaded Earth, metallic UFO and cow silhouette. Deep Blue uses an ocean sphere, submarine and pearl. Planets, vehicles and collectibles share smooth shapes and a consistent light direction.
- The menu, results and shop use bundled Roboto, restrained borders and cyan actions. Gold identifies Stardust. The shop retains its large featured preview, three world thumbnails and explicit unlock/equip action.
- Themed gameplay uses the same background glow and health rail as Classic, quieter orbit guides and a score above the planet. Classic's existing renderer and native Android glyph path remain intact.
- Artwork is drawn synchronously with Canvas. The intermediate pixel sprite loader, artwork loading/error UI and pixel font are removed from the runtime. Earlier PNGs, prompts, font notices and screenshots remain in the repository as unbundled design history.

## Preserved behavior

The wallet format, world IDs, prices and existing ownership are unchanged: 100 welcome Stardust, one per pickup in either mode, 150 for each themed world, and free Classic. Previewing does not equip or purchase. Failed wallet saves retain their existing retry behavior. There are no paid purchases or cloud recovery.

Gameplay controllers, collision bounds, core occlusion, random draws, timing, difficulty and leaderboard scores are unchanged. Drawing a theme does not alter the simulation. The fixed visible playfield and safe-area scaling remain in place.

## Verification

- All **247 tests pass**, including the Java oracle, Classic rendering, wallet serialization/failure/retry, per-pickup banking, paired seeded simulations, entity bounds/core occlusion, hero-preview bounds, keyboard/screen-reader actions, pause/replay and themed HUD/input in both modes.
- Existing device coverage includes 13 configurations, landscape/split windows, a 256-pixel-wide shop, up to 3.2× text and a notched phone. Large text changes the chooser into compact rows and uses a shorter header so the fixed header leaves room to browse. The layout checks also assert that the shop's scrollable content keeps at least 40% of the window height.
- `flutter analyze`, formatting and `git diff --check` pass. Eighteen evidence tests pass, with a further full shop run covering the large-text fix and refreshed captures.
- Android comparison profile APK and iOS debug simulator builds pass. Both bundles exclude the retired pixel artwork/font and contain the unchanged bundled Roboto files. Android contains AOT libraries without a debug kernel.
- Existing Kotlin-plugin and CocoaPods migration notices remain build warnings.

Inspected production-widget renders:

- [Cow shop on phone](evidence/orbital-style-2026-10-24/shop-phone.png) and [tablet](evidence/orbital-style-2026-10-24/shop-tablet.png).
- [Deep Blue shop](evidence/orbital-style-2026-10-24/deep_blue-shop-phone.png).
- [Cow gameplay](evidence/orbital-style-2026-10-24/cow_abduction-gameplay-phone.png) and [Deep Blue gameplay](evidence/orbital-style-2026-10-24/deep_blue-gameplay-phone.png).
- [Menu](evidence/orbital-style-2026-10-24/phone-cow-menu.png), [results](evidence/orbital-style-2026-10-24/phone-cow-result.png) and [256-pixel/3.2× text chooser](evidence/orbital-style-2026-10-24/narrow-large-text-chooser.png).

Evidence uses isolated fixture positions/scores and mock preferences, without altering a real wallet or submitting scores. These builds were not installed or published. Physical-phone readability, native UI interaction and sustained frame pacing remain unverified for this pass. The store-content reassessment noted in the original skins record remains necessary before publishing.
