# Living worlds — 2026-10-25

The owner requested more value from each world: distinct scenery, recognizable projectiles and animated central characters, followed by themed orbit paths that preserve expansion. The existing minimal swipe shop is retained. Shared Canvas artwork supplies these changes in the shop, home, results and gameplay.

| World | Background | Character motion | Projectile |
| --- | --- | --- | --- |
| Cow Abduction | Planet rim and stars | Drifting clouds | Mint plasma bolt |
| Deep Blue | Light shafts, bubbles and kelp | Tentacles and looking eyes | Purple ink drop |
| Web Escape | Corner cobwebs | Moving legs and eyes | Spinning pale web |
| Dragon’s Hoard | Cave walls and embers | Wings, breathing and blinking | Orange flame |
| Pollen Patrol | Meadow, grasses and petals | Swaying petals and blinking | Striped seed |
| Frost Bite | Aurora, snowbanks and flakes | Breathing and blinking | Blue-white ice |
| Haunted Harvest | Crescent moon, branches and mist | Glowing face | Flapping lavender bat |
| Junkyard Dash | Circuit traces and lights | Blinking eyes and beacon | Yellow spark |
| Volcano Hop | Lava cracks and embers | Rising smoke, looking and blinking eyes | Rotating lava rock |
| Cheese Chase | Pantry shelves and jars | Blinking eyes and twitching whiskers | Teal yarn |
| Jungle Jam | Vines, leaves and ferns | Blinking eyes and moving ears | Cracked brown coconut |

The former coral projectile discs are replaced by faint boundaries in each projectile’s own color. Background decorations remain near the edges. Deep Blue still collects treasure chests. Classic retains its original rendering. Cosmetic motion changes no physics, hitboxes, rewards, ownership or save data.

Menu and shop use paint-driven eight-second loops. Gameplay uses its simulation clock, so pausing freezes the scenery and characters. Reduced motion freezes all new decoration at its initial frame; necessary gameplay movement continues.

## Themed paths and chest repair

The orbit paths now use dust and asteroid flecks, water currents and bubbles, paired silk, engraved stone, leafy stems, fractured ice, mist, circuits, cracked basalt, braided yarn, or jungle vines. The moving player path uses a simpler version of the same material. Ten character backings also become their world’s setting: a whirlpool, web, stone, foliage, ice, mist, metal, crater or woven yarn. Earth keeps its globe.

Paths consume each live engine radius on every paint. Holding/releasing still expands/contracts the player path, while scores 5, 10 and 20 preserve the original 60-tick orbit transitions and add the next orbit. Reduced motion freezes decorative time and rotation without freezing these gameplay changes. Decorations remain in a narrow band around each path and render behind hazards and pickups.

Deep Blue’s chest had a detached-looking rear lid and a lower corner touching its circular clip. Its connected barrel roof, front and side now share aligned straps and a continuous seam. The complete gold outline fits inside the same pickup bounds; the lock remains readable at phone size.

## Readability and reactions

The expanding player path now has a brighter continuous trace. Stationary path decorations are dimmed by 30%, keeping the player’s route clear in dense scenes. Pollen Patrol uses small flowers and pollen clusters; Jungle Jam uses broader, veined leaves; Haunted Harvest uses tapered drifting mist ribbons. All still follow the live engine radii.

Each center anticipates a shot during the last 15 simulation ticks before release and reacts for 0.3 seconds afterward. These poses follow the existing projectile release clock: tentacles tuck and recoil, spider legs pull and release, dragon wings and breath respond, petals flinch, frost breath appears, the pumpkin glows, the robot discharges, volcano smoke puffs, cat whiskers twitch, monkey cheeks move, and Earth’s atmosphere pulses. Delayed display frames preserve the release time. Pausing freezes reactions, replay clears them, and practice without projectiles does not trigger them.

Collections now use seven small theme-specific particles over the existing 0.55-second feedback window: tractor glints, gold coins, sugar, gems, pollen, snow crystals, candy, sparks, eggshell flecks, cheese crumbs, or leaves and banana flecks. The readable +1 remains. Effects render above scenic paths and below hazards. Reduced motion suppresses these effects and firing poses; Classic, projectile timing, collisions, rewards and saved progress are unchanged.

## Full-screen background follow-up

The owner reported black bars above and below gameplay and the home screen in build 45. The home background was inside `SafeArea`; gameplay painted its background only inside the fixed, fitted arena. Both exposed the dark scaffold around the artwork.

Backgrounds now fill the complete window. Home and results keep their controls inside an internal safe area; gameplay paints one continuous backdrop behind its original fitted arena. Pause shading and damage flashes also cover the complete window. System bars are transparent with light icons. The 1080 × 1794 visible gameplay area, scaling, input boundaries and collision clipping are unchanged. Decorative motion still respects reduced-motion settings and the paused simulation clock.

- [Portrait home](evidence/fullscreen-backgrounds-2026-10-25/portrait-volcano_hop-home.png)
- [Portrait gameplay](evidence/fullscreen-backgrounds-2026-10-25/portrait-volcano_hop-game.png)
- [Landscape gameplay](evidence/fullscreen-backgrounds-2026-10-25/landscape-deep_blue-game.png)

These are Flutter widget captures. Pixel checks compare the former safe-area and fitted-arena borders against a continuous full-window backdrop for all eleven worlds in portrait and landscape; gameplay dimensions are checked at the same time.

After the owner reconnected the Pixel 9 Pro, the background fix was installed in place. The saved preferences matched byte-for-byte after installation, retaining all twelve themes and the owner's current Deep Blue selection. Physical captures confirm the background fills both the [home screen](evidence/fullscreen-backgrounds-2026-10-25/pixel-deep-blue-home.png) and [game-ready screen](evidence/fullscreen-backgrounds-2026-10-25/pixel-deep-blue-ready.png), including the status/navigation areas and fitted-arena margins. [Installation record](evidence/fullscreen-backgrounds-2026-10-25/pixel-installation.json).

## Preview and validation

- [All eleven themed paths after readability improvements](evidence/reactive-worlds-2026-10-25/all-world-orbits.png)
- [Firing reactions, collections and expansion at all three milestones](evidence/reactive-worlds-2026-10-25/reactive-worlds.mp4)
- [Every center’s idle, preparation and release poses](evidence/reactive-worlds-2026-10-25/core-reactions.png)
- [All eleven collection effects](evidence/reactive-worlds-2026-10-25/pickup-effects.png)
- [Phone shop renders from the preceding path pass](evidence/themed-paths-2026-10-25/shop-overview.jpg)
- [Complete treasure chest](evidence/themed-paths-2026-10-25/treasure-chest.png)
- Full Flutter suite: **451 tests pass**. `dart analyze`: no issues.
- Checks cover local animation, seamless loops, bounds, opaque core occlusion, reduced-motion changes at runtime, shop purchases and seeded simulation parity. All eleven themes preserve every tick of the expansion milestones, matching the original released Java radius fixtures. Chest checks cover connected surfaces and unclipped outlines at preview and gameplay sizes.
- Additional checks cover active-path contrast in dense scenes, distinct material silhouettes, all eleven reaction poses and collection effects, particle bounds/fading, actual release timing, skipped display frames, pause/replay behavior and reduced-motion rendering.
- Phone artwork and dense five-orbit scenes were visually inspected. Phone/tablet, English/German and large-text layout checks pass. The animation clip uses real engine updates with controlled collections and photon collisions disabled; its [frame data](evidence/reactive-worlds-2026-10-25/frames.json) records live radii and firing strengths. These are Flutter renders, not hardware captures.
- Android arm64 comparison/profile APK builds successfully at `build/app/outputs/flutter-apk/app-comparison-profile.apk`. The existing Kotlin plugin migration advisory remains; no dependency change was needed for this work.

Reproduce the evidence:

```sh
flutter test test/world_animation_test.dart --dart-define=GENERATE_LIVING_WORLD_EVIDENCE=true
flutter test test/themed_orbits_test.dart test/treasure_chest_test.dart --dart-define=GENERATE_ORBIT_EVIDENCE=true --dart-define=GENERATE_TREASURE_CHEST_EVIDENCE=true
flutter test test/skin_shop_test.dart --dart-define=GENERATE_SKIN_UI_EVIDENCE=true --dart-define=SKIN_EVIDENCE_DIRECTORY=build/themed-orbits-preview
flutter test test/themed_orbits_test.dart --dart-define=GENERATE_ORBIT_EVIDENCE=true --dart-define=ORBIT_EVIDENCE_DIRECTORY=build/reactive-worlds-preview
flutter test test/core_reactions_test.dart --dart-define=GENERATE_CORE_REACTION_EVIDENCE=true
flutter test test/collection_art_test.dart --dart-define=GENERATE_COLLECTION_EVIDENCE=true --dart-define=COLLECTION_EVIDENCE_DIRECTORY=build/reactive-worlds-preview/collection
flutter test test/full_screen_background_test.dart --dart-define=GENERATE_FULLSCREEN_EVIDENCE=true
ffmpeg -y -framerate 10 -i build/reactive-worlds-preview/frame-%03d.png -c:v libx264 -crf 18 -pix_fmt yuv420p -movflags +faststart build/reactive-worlds-preview/reactive-worlds.mp4
```

The living-worlds design pass was packaged as [build 45](releases/2.3.0-build45.md), uploaded to App Store Connect and installed on the owner's Pixel with all themes and preferences preserved. The subsequent full-screen background fix is installed on the Pixel as an updated local comparison/profile APK with the same 2.3.0 (45) version; its checksum is in the installation record above. The fix is also uploaded as iOS [build 46](releases/2.3.0-build46.md), processed as valid, in internal TestFlight testing and selected in the 2.3.0 draft. Physical-iPhone verification and sustained performance testing remain pending.
