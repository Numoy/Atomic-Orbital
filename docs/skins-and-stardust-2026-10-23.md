# World skins and Stardust — 2026-10-23

Current implementation: the [October 25 collection](six-worlds-2026-10-25.md) has six themed worlds, free Classic and the displayed currency **Stars/Sterne**. This document records the original implementation and earlier naming.

Follow-up: the [2026-10-24 orbital style](orbital-style-2026-10-24.md) replaces this first slice's artwork and shop layout, following an intermediate pixel-art pass. It retains the wallet rules and IDs; Deep Blue now depicts an ocean world. The evidence and 240-test results below record the original October 23 implementation.

The requested direction is a cosmetic collection system: the same orbital game can tell different little stories. The first example comes directly from the player: Earth is the core, a UFO circles it collecting cows, and Earth sends defenses after the UFO. A world skin changes the core, player, collectible and hazards together, so it feels like a complete scene.

This first slice adds a small local shop and one earned currency, **Stardust**. It does not add real-money purchases, advertising, loot boxes, consumable advantages or a backend.

## First catalog

| World | Price | Theme |
| --- | ---: | --- |
| Classic | Free | The existing abstract atom, player, energy and photons. |
| Cow Abduction | 150 Stardust | Earth, a UFO and cows, with clearly visible planetary defenses. |
| Deep Blue | 150 Stardust | Pufferfish core, submarine pilot, pearl pickups and red stinging orbs. |

Classic is owned and equipped by default. Players can preview locked worlds before buying them, and switch between owned worlds without paying again. Each complete world costs the same amount; their difference is the artwork.

The renderer must preserve readable silhouettes, hazard contrast and the visible scale of collision boundaries. Skins must not change movement, hitboxes, health, difficulty, scoring, random draws, timing or leaderboard eligibility. In particular, a cow replaces the energy collectible visually; collecting it still scores one point and reverses the player's direction.

## Earning and spending

- A new wallet receives **100 Stardust once**.
- Every collected pickup earns **1 Stardust**, in both Normal and Hardcore.
- Pickups are banked as they are collected. Death, choosing End run, replaying or returning to the menu must not award them again. If saving fails, pending earnings stay in memory and the game offers a retry; closing the app before they save can lose those pending earnings.
- There are no rewards for elapsed time, starting attempts, daily streaks or changing a personal best. Pausing and repeatedly restarting an empty run earn nothing.
- A purchase deducts its displayed price and permanently unlocks that world in the local save. Equipping an owned world is free.

For an illustrative player collecting 10 pickups per run, the first 150-Stardust world requires five runs after the welcome grant. Another world then takes 15 such runs. These are arithmetic examples, not measured player retention or run-length data; prices should be revisited after real playtesting.

Existing highscores, games played and lifetime points retain their meanings. The new wallet starts separately; it does not convert or spend historical lifetime points. Existing players receive the same one-time welcome grant.

## Save and interaction requirements

Balance, ownership and selection belong to the same local save. Purchase handling must reject unknown items and insufficient funds, allow only owned worlds to be equipped, and prevent duplicate taps or repeated purchases from charging twice. A failed save must not be presented as a successful purchase. Restoring the app should validate saved values and fall back to Classic if an equipped world is invalid or unowned.

Earning and purchase persistence must not block the simulation or introduce additional random draws. Shop previews must not start a real run, earn currency or submit scores. The wallet and equipped world should remain consistent after leaving and reopening the shop, replaying, and restarting the app.

The save is local to this app installation. Clearing app data or uninstalling can remove Stardust and unlocked worlds; a different phone or app flavor has its own save. There is no account-backed wallet, cloud sync, paid purchase restoration or promise of recovery in this version. Real-money currency would require a separate product and persistence design before it could be offered.

## Ideas for later

These are suggestions, **not implemented catalog items**:

| World idea | Core | Player | Collectibles | Hazards |
| --- | --- | --- | --- | --- |
| Honey Heist | Hive | Bee | Nectar drops | Bright warning stings |
| Midnight Snack | Cheese moon | Mouse capsule | Cheese bites | Hot pepper sparks |
| Dragon's Hoard | Castle | Tiny dragon | Gems | Glowing magic bolts |
| Junkyard Orbit | Scrap planet | Salvage drone | Useful scrap | Red electrical arcs |
| Candy Cosmos | Candy planet | Candy rocket | Wrapped sweets | Sour candy comets |
| Haunted Orbit | Haunted moon | Little ghost | Lost stars | Glowing lantern wisps |

Additional cosmetic categories could give players smaller goals between complete worlds. Suggested starting prices are **40 Stardust for player paints**, **75 for orbit patterns**, and **100 for results banners**. These categories are not in the first implementation. Any future trail or orbit effect needs a readability and reduced-motion check; visual decoration must not obscure hazards. Independent cosmetic combinations should only be introduced when the art works together without making the shop or gameplay harder to read.

## Release and verification status

Implemented in the local Flutter source. `flutter analyze` is clean and all **240 tests pass**, including the existing Java oracle/gameplay suite, 13 wallet tests, 10 skin/catalog/rendering tests and 18 shop/earning-flow tests. Shop layout checks cover 256-pixel width, phone/tablet portrait and landscape, and text scales through 3.2×. Seeded paired simulations compare each rendered world with an unrendered control for 360 frames, preserving entities, orbits, random draws and game state.

Wallet checks cover concurrent earnings/purchases, repeated buys, insufficient funds, reloading, corrupted data, failed writes, selection fallback and ordered reset. Widget flows cover per-pickup rewards in both modes, End run, death/replay/Home, save retry without duplicate warnings, one shop route during delayed saving, equipping and persisted ownership.

Both builds pass: `flutter build apk --profile --flavor comparison` and `flutter build ios --simulator --debug`. The comparison APK contains AOT code for the new catalog and no debug kernel. Existing Kotlin-plugin and CocoaPods-migration notices remain build warnings. No build was installed on a phone/simulator, uploaded or released during this pass.

Rendered production-widget previews, visually inspected:

- [Tablet shop](evidence/skins-2026-10-23/shop-tablet.png) and [phone shop](evidence/skins-2026-10-23/shop-phone.png).
- [Cow Abduction gameplay](evidence/skins-2026-10-23/cow_abduction-gameplay-phone.png) and [Deep Blue gameplay](evidence/skins-2026-10-23/deep_blue-gameplay-phone.png).

These use isolated local fixture scores/positions and mock preferences; they did not earn real currency or submit scores. Phone-size readability was inspected in widget renders. Physical-device readability, sustained rendering performance and economy pacing still need playtesting. No real-money purchases or cloud recovery were implemented.

The existing [content/privacy audit](store/2.2.0/content-privacy-audit.md) describes an abstract game without animals or weapons. The cow-abduction and planetary-defense theme requires a fresh review of age-rating answers and store content descriptions before publishing. This note does not change published policies or external store declarations.
