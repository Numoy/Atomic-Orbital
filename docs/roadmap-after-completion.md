# Atomic Orbital: work after the completion release

This extends the [completion plan](completion-plan-2026-10-24.md). Implementation and distribution acceptance of that release come first. The stages below are planned work, not claims that these features or releases exist.

## October 25 implementation update

The owner subsequently approved implementing the review recommendations. The current source adds a local daily challenge and explicit save export/import, including confirmation, rollback and the previous save. See the [implementation and validation record](improvements-2026-10-25.md). The daily challenge is offline and uses separate records; it has no online ranking. Newcomer observations and physical-device acceptance still apply before distribution. The current application entry point also enables the collection; the shop-free decision below records the earlier design stage. The owner also requested restoring and expanding the collection; the [six-world design](six-worlds-2026-10-25.md) is now implemented in source.

## Superseded decision: retain the shop-free design

The owner’s later instructions in “Redesign homescreen buttons” hide the shop, cosmetic worlds and currency from the active design without deleting their source or saved data. Version 2.3 therefore shows 16 achievements. Keep that simpler design unless the owner explicitly brings the collection back. Stars/Sterne replaced the earlier Flux wording in the retained feature. The two world achievements remain preserved and hidden until earned in platform catalogs.

Complete device and newcomer acceptance first. Enable the iOS rating destination after the public listing has been verified. The daily challenge prototype and save recovery design are the next candidates for the simpler game; the collection expansion below stays optional.

## Immediate follow-up: make the first run understandable

Owner feedback on October 24 identified the tutorial and generic-looking UI as problems. The revised practice teaches hold/outward, release/inward and two actual pickups with direction reversals. Progress and Settings use plain lists and shorter copy. [Source renders and verification](evidence/tutorial-polish-2026-10-24/README.md) record this pass; build 43 predates it.

The October 25 tutorial revision combines the repeated controls into two pickup steps, explicitly teaches holding anywhere, shows live input feedback and keeps completion reachable at large text sizes. [Updated source renders and verification](evidence/tutorial-anywhere-2026-10-25/README.md) cover this revision.

Observe the revised tutorial with the five newcomers on the acceptance sheet before adding another mode or achievement tier. Watch whether they identify the white player, hold without repeatedly tapping, release deliberately, notice the reversal and collect a square in a real run. Record the particular screen, phrase or artwork they find confusing or generic; adjust that item rather than adding decoration. Target four of five completing a real pickup without coaching. Then make a new signed candidate, refresh the affected store images and complete hardware acceptance. Daily challenges and recovery remain subsequent work.

## Superseded collection proposal

The proposal below predates the owner’s October 25 direction. Cow Abduction, kraken Deep Blue, Web Escape, Dragon’s Hoard, Pollen Patrol and Frost Bite now form the themed catalog. The original proposal was to add two cosmetic stories using the current world renderer and shop. Keep the same simulation, collision sizes, core occlusion, randomness, scoring and competitive eligibility.

| World | Core | Player | Pickup | Hazard | Visual direction |
| --- | --- | --- | --- | --- | --- |
| Honey Heist | Round amber hive | Expressive bee with two clear wings | Gold nectar drop with a bright corner marker | Red warning sting | Warm amber, teal shadows, broad honeycomb shapes; readable at phone size |
| Haunted Orbit | Purple moon with an opaque shaded face | Small white ghost | Pale lost star with a gold marker | Red lantern spark | Quiet violet background accents, soft off-white character and restrained coral hazards |

Deliver each world with its gameplay art, menu scene, featured shop preview, ownership/equipped states, EN/DE copy, reduced-motion rendering and artwork bounds checks. Show the catalog in a responsive grid or rows once five entries no longer fit comfortably in one row. Keep Classic free and preserve existing world/save IDs. Do not introduce a second currency or a gameplay advantage.

Before choosing new prices, observe five new players: their first-run scores, completed-run lengths, number of runs to the first unlock, whether they understand Stars, and whether they use a newly unlocked world. Keep the existing earning rate until those observations justify a specific change. Record observations anonymously in a local playtest sheet; this does not require an analytics SDK or new accounts.

Acceptance: each character and pickup is recognizable at gameplay size; hazards remain conspicuous in every world; the same seeded input produces the same simulation in all worlds; interrupted and repeated purchase actions cannot lose currency or charge twice; every existing wallet still loads.

## Next active candidate: a daily challenge, if playtests support it

Offer one optional daily seeded Normal run. Let ordinary play remain available without dates, streak pressure or rewards for merely opening the app. Use UTC and display the reset time clearly in local time.

First build a local prototype. A challenge identity must include the date, simulation/rules version and PRNG algorithm version. Dart's [`Random(seed)` stream may change between library releases](https://api.dart.dev/dart-math/Random/Random.html) and is not a long-term replay contract; use a small specified deterministic generator with known-answer tests before claiming equal challenges across platforms or versions.

Test pause/resume, offline use, a date change during a run, clock changes, multiple attempts and two app versions generating the same challenge. Give this mode its own score records and eventual platform leaderboard. Keep daily scores out of the established Normal and Hardcore boards. A device clock alone cannot establish a trustworthy global competition; document that limit before enabling online rankings.

Acceptance: participants on supported versions receive identical starting conditions and hazard sequences; the run keeps its original challenge identity after midnight; offline results display honestly; normal-mode records and the Stars wallet cannot be awarded twice.

## Recovery milestone: backup and explicit profile handling

Local progress is currently installation data. Game-service achievements and leaderboards do not back up the wallet, ownership or settings. Do not advertise cloud restoration until it is implemented and tested.

Start with a versioned export/import design or a native save facility after checking platform behavior. The requirements are validation, an explicit preview of what will change, preservation of a previous recoverable snapshot, and a clear conflict policy. Never sum two balances or lifetime counters during a merge: doing so duplicates progress. Paid products would require a separate entitlement/restoration design.

For multiple game-service profiles, offer an explicit choice to keep the installation's local progression or start a separate profile. Bind queues and per-profile records before enabling transfers. Test account changes while a request is in flight, reconnecting an old profile, reinstalling, corrupted backups, unsupported save versions and deletion of pending uploads. Until then, preserve pending cloud updates for their original profile and continue to offer offline play.

Acceptance: recovery survives reinstall and device replacement in the supported scope; imports cannot reduce or duplicate existing progress silently; account changes cannot send the previous player's pending events to a different account; deletion instructions match actual behavior.

## Later polish and retention decisions

- Add cosmetic mastery badges or alternate palettes only when players want goals beyond the initial collection. Reuse achievements and Stars; avoid another progression system.
- Consider friend comparisons and a weekly platform leaderboard before multiplayer. A one-button arcade game can support competition without networking the simulation.
- Improve specific phone-scale artwork or sound cues in response to observed confusion. Keep a recognizable visual style and compare changes using actual gameplay captures.
- Use store reviews, voluntary playtests and existing console diagnostics to choose subsequent work. Do not add telemetry or a crash SDK without a concrete question and a fresh privacy review.

## Release gates for every follow-up

Run the unchanged gameplay oracle and focused new-feature tests. Check EN/DE, large text, reduced motion, safe areas and controller/keyboard behavior where supported. Test a signed in-place upgrade with a populated save. Verify physical-device frame pacing and interruption handling for new effects. Produce new artifacts and store captures from the accepted source, record hashes, and verify distribution through Internal/TestFlight before public release.

No multiplayer, backend accounts, advertising, paid currency, subscriptions or battle pass is scheduled. Reconsider these only in response to a concrete player need and a separate product decision.
