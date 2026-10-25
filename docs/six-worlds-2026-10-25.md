# Six worlds and collection shop — 2026-10-25

Follow-up: [the complete world review](world-review-2026-10-25.md) adds five more designs, polishes the existing set and records current validation. This document retains the earlier six-world work and shop iterations.

The owner requested keeping the alien/cow theme, replacing Deep Blue’s central globe with a kraken, adding a spider/fly world and three further designs, and revisiting the shop with mobile arcade references. Three agents split the work into kraken/spider and shared rendering, three new art sets, and the shop/reference research; integration, localization and verification were handled together.

## Implemented catalog

| World | Center | Player | Collect | Avoid |
| --- | --- | --- | --- | --- |
| Cow Abduction | Earth | Alien UFO | Cows | Planetary defenses |
| Deep Blue | Kraken | Bathyscout submarine | Treasure chests | Ink drops |
| Web Escape | Spider | Fly | Sugar cubes | Cobwebs |
| Dragon’s Hoard | Dragon | Small knight | Gold gems | Fireballs |
| Pollen Patrol | Sunflower | Bee | Pollen | Thorned seeds |
| Frost Bite | Snow monster | Penguin | Fish | Ice shards |

All six use the existing circular simulation and collision sizes. Core backing stays opaque to hide hazards before they emerge. Hazards retain a coral danger boundary. Classic and the cow artwork are preserved. The same painters supply gameplay, menu/results and shop previews; no bitmap assets or dependencies were added.

Classic stays free. Each themed world costs 150 Stars. Existing IDs, wallet format, balances, purchases, scoring and reward rates are preserved. The original World Tour achievement still refers to Classic, Cow Abduction and Deep Blue. The application enables cosmetics again; practice and daily challenges use Classic.

## Deep Blue pickup follow-up

The owner requested treasure chests instead of pearls. Deep Blue now uses the same gold-trimmed wooden chest painter in gameplay, menu/results and shop previews. English/German descriptions and the artwork sheet were updated. Pickup size, collision behavior and rewards remain unchanged. The phone-size check verifies that the wood and gold remain distinguishable.

Current Deep Blue renders: [character sheet](evidence/treasure-chest-2026-10-25/deep_blue-characters.png), [gameplay](evidence/treasure-chest-2026-10-25/deep_blue-gameplay-phone.png), [shop](evidence/treasure-chest-2026-10-25/deep_blue-shop-phone.png), and [updated world overview](evidence/treasure-chest-2026-10-25/six-worlds.png). All 51 focused tests/render exports pass; analysis is clean. Physical-device testing was not repeated.

## Shop follow-up after feedback

The owner rejected the collection grid and chose a minimal arcade selector: one large scene, swipe between worlds, and a small price/unlock button. The current shop removes the preview card, catalog grid, visible descriptions and repeated pricing. It keeps a plain Stars balance, full-width swipe area, accessible previous/next buttons, compact visual page dots, the world name and one unlock/equip button. Insufficient funds and save errors remain explicit. Screen readers receive the complete world description.

Swipes only browse. Purchases capture the current world, snap the pager to it and disable browsing until the save finishes. Keyboard arrows, large text and English/German layouts remain supported. The redesign reuses the existing art and wallet; it adds no dependency.

Current renders: [phone](evidence/minimal-shop-2026-10-25/cow_abduction-shop-phone.png), [spider](evidence/minimal-shop-2026-10-25/spider_web-shop-phone.png), [tablet](evidence/minimal-shop-2026-10-25/shop-tablet.png), [German](evidence/minimal-shop-2026-10-25/german-shop-phone.png).

Verification: all **55 focused shop, world integration and wallet tests pass**. This includes swipe navigation without spending, correct purchase targets, browsing blocked during delayed saves, keyboard/semantic controls and 48-pixel arrow/action targets. Analysis of the changed files and `git diff --check` pass. Physical-device checks and the full suite were not repeated for this layout-only follow-up. The snapshots below record the earlier grid design.

## First shop pass and references

The initial shop pass had a large tinted preview, previous/next controls, one unlock/equip action, wallet balance and a compact collection grid with ownership and equipped indicators. All seven choices fit on the tested notched 393 × 852 phone at default text size. Tablet uses a side-by-side layout; large accessibility text switches to readable rows with scrolling. Previewing never spends Stars or changes the equipped world.

The supplied Uptodown URL was unavailable through the web fetcher. We inspected the correct Ketchapp [Arrow App Store screenshots and description](https://apps.apple.com/us/app/arrow/id988476572): the same movement is represented by recognizable arrow, snake and duck forms, with sparse UI and cosmetic unlocks. The [official Crossy Road press kit](https://www.crossyroad.com/crossy-road-classic-press-kit) informed the focus on collectible character identities. The preview/grid/action arrangement is our design interpretation of those references; their artwork was not copied.

## Source renders

- [Six-world overview](evidence/six-worlds-2026-10-25/six-worlds.png)
- [Phone shop](evidence/six-worlds-2026-10-25/spider_web-shop-phone.png) and [tablet shop](evidence/six-worlds-2026-10-25/shop-tablet.png)
- Gameplay: [kraken](evidence/six-worlds-2026-10-25/deep_blue-gameplay-phone.png), [spider](evidence/six-worlds-2026-10-25/spider_web-gameplay-phone.png), [dragon](evidence/six-worlds-2026-10-25/dragon_hoard-gameplay-phone.png), [sunflower](evidence/six-worlds-2026-10-25/sunflower-gameplay-phone.png), [snow monster](evidence/six-worlds-2026-10-25/frost_bite-gameplay-phone.png)

These are Flutter renders of production widgets and painters using isolated fixture balances, scores and positions. They are not physical-device screenshots or public release evidence.

## Verification

Rendering checks cover bounds, opaque core occlusion, actual hazard artwork, zero-radius drawing and identical seeded simulation for 360 frames in every design. Widget checks cover starting every world in both modes, the production shop entry, all-world preview/unlock/equip/persistence, keyboard navigation, selected semantics, insufficient funds, failed saves and responsive layouts through 3.2× text scaling. English and German names/descriptions are generated from ARB sources; German long-copy layout is covered separately.

Validation result for this pass: **106 focused design tests passed**, plus the updated production-language regression test and both German layout tests after the final wrapping adjustment. `flutter analyze --no-pub` and `git diff --check` passed. The latest full-suite snapshot passed **393 tests with one failure** in `daily_challenge_widget_test.dart` (paused daily-run save import: an ambiguous `scrollUntilVisible` finder, “Too many elements”). That test constructs the Classic-only screen; daily/backup sources and tests were also changing concurrently. This is not a full-suite pass or a release sign-off.

Reproduce renders:

```sh
flutter test test/game_skin_test.dart --dart-define=GENERATE_SKIN_EVIDENCE=true --dart-define=SKIN_EVIDENCE_DIRECTORY=docs/evidence/six-worlds-2026-10-25
flutter test test/skin_shop_test.dart --dart-define=GENERATE_SKIN_UI_EVIDENCE=true --dart-define=SKIN_EVIDENCE_DIRECTORY=docs/evidence/six-worlds-2026-10-25
```

Physical touch/readability and sustained frame-pacing checks are still pending. This pass does not upload or publish a build.
