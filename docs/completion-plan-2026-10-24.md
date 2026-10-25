# Atomic Orbital completion plan

Prepared on 24 October 2026 from the current Flutter source, tests, artwork captures and release records. This records the original proposed roadmap. The [2.3.0 handoff](releases/2.3.0-internal.md) tracks implementation, the later shop-free design decision, evidence and open acceptance gates.

## Goal and current baseline

Deliver a complete arcade game in which a new player understands the controls, can enjoy repeated runs, sees meaningful progress, trusts their saved rewards, and can use the available platform services without losing offline play.

The existing game already has Normal and Hardcore, the original simulation, fair fixed-world scaling, pause/resume, interruption handling, help, audio, local records, sharing, three cosmetic worlds, and an earned-currency shop. The source now calls the currency **Flux**; older documentation and captures still call it Stardust. Existing wallet keys and world IDs must remain stable.

There are already **12 Google Play achievements**:

| Existing category | Thresholds |
| --- | --- |
| Normal score in one run | 20, 35, 50 |
| Hardcore score in one run | 20, 35, 50 |
| Total points from completed games | 500, 1,000, 10,000 |
| Completed games | 50, 150, 500 |

They are currently implemented inside the Android Play Games service. iOS and signed-out players have no equivalent in-game trophy collection. Games played, total points and playtime are saved but have no player-facing statistics screen. The service exposes pending-sync and error state that the game screen does not currently display.

Fresh baseline verification for this plan: `flutter analyze` passes and **265 tests pass**. Historical records also show Pixel 9 Pro checks, including real pickup persistence and later themed-world access. Those records do not establish sustained performance, iPhone acceptance, or current store availability. Some screenshots predate the Flux rename.

## 1. Finish reliability and essential settings

**Priority: release essential.**

- Add one Settings/About sheet with the existing sound control, help, privacy, support, deletion instructions, version/build and an explanation that Flux/world ownership are saved on this installation. Use the existing native platform channel for external links.
- Use Flux consistently in player-facing copy, documentation and new store captures. Retain internal save keys; a naming change must not reset balances or ownership.
- Verify score/statistic writes and their failure handling. Wallet saves are already checked and serialized; score/statistic setters currently fire off separate writes without awaiting confirmation. Complete saves reliably and make recoverable failures visible.
- Define run endings before adding new goals: death finalizes a completed run once; End run retains already banked Flux and any milestone already earned during play. Preserve the meaning of existing completed-game counters and leaderboard submission rules.
- Surface a compact Play Games status with pending updates and a retry action. Verify offline retries, disconnect/reconnect and account changes without duplicate grants or accidental uploads to the wrong account.
- Inspect the actual leaderboard configuration before changing it. The current client accepts Normal scores only through 200 and Hardcore through 100. If those historical boards cannot support higher earned scores, create replacement boards with suitable ranges, retain the historical boards, and submit actual best scores without clamping.

**Done when:** cold restart preserves records, Flux, worlds and progress; save/retry failures are understandable; repeated ending/retry actions cannot duplicate progress; every visible action has a working destination.

## 2. Make progression visible, then add six achievements

**Priority: release essential. Depends on step 1.**

- Add a local Achievements screen on Android and iOS, available offline and without sign-in. Show the requirement, current progress, locked/unlocked state and a consistent badge for each trophy.
- Reuse the existing 12 achievement rules through a small shared catalog/evaluator. Keep the published Google IDs and thresholds. The Android service reports earned progress; it must no longer be the only place the rules exist.
- Add the six proposed achievements below, bringing the initial catalog to **18**. Names and thresholds are starting proposals to validate through playtesting.
- Show one relevant next goal on the home/results screen and a brief, nonblocking unlock notification. Collect multiple unlocks into the result recap instead of covering the arena with popups.
- Add a compact Statistics view: both personal bests, completed runs, total completed-game points, recorded playtime and worlds owned. Label existing counters honestly; do not imply that abandoned-run time was historically tracked.

| Proposed achievement | Exact starting condition | Purpose |
| --- | --- | --- |
| First Contact | Collect the first pickup in a real run | Introduce progression immediately |
| Finding Orbit | Reach 5 points in Normal | Offer a reachable early skill goal |
| Hardcore Cadet | Reach 5 points in Hardcore | Encourage trying the second mode |
| Steady Hands | Reach 10 points in Normal before taking any hit in that run | Reward control; unlock at the milestone, before eventual death |
| New Horizons | Purchase the first non-Classic world | Connect play to the world collection |
| World Tour | Reach 5 points in each of Classic, Cow Abduction and Deep Blue | Encourage using the collection |

Backfill only milestones proved by existing saves or authenticated platform unlocks. Ownership does not prove a historical run in a world; old aggregate points do not prove a damage-free run. Merge unlocked states monotonically, preserve old saves, and make repeated evaluation harmless. Tutorial actions never earn these achievements. Keep achievement rewards as recognition initially, so this work does not also require rebalancing Flux.

Google documents visible progress, tiered goals, unique icons and offline unlocking in its [achievement guidance](https://developer.android.com/games/pgs/achievements). Configure, test and publish new platform achievement IDs as part of delivery; adding client code alone is insufficient.

**Done when:** a signed-out player on either platform sees accurate, persistent progress; all 18 conditions are achievable; boundaries, migration and repeated callbacks are tested; Android reporting preserves the original 12.

## 3. Teach the game through a short playable introduction

**Priority: release essential. Depends on the progress rules above.**

- Add a skippable first-run practice sequence, replayable from help: hold to move outward, release to move inward, collect a target and observe direction reversal, then recognize a hazard.
- Use a controlled practice arena, isolated from ranked scores, Flux, statistics and achievements. Explain Normal health regeneration and Hardcore's one-hit rule before the first run in each mode.
- Keep existing one-button controls and quick replay. A returning player should reach a real run immediately.
- Test the introduction with five people unfamiliar with the game. A useful initial acceptance target is four of five explaining the controls and completing a pickup without verbal coaching. Adjust the prompts based on observation.

**Done when:** first-run, skip, replay, interruption and restart flows work; practice cannot affect real progress; observed newcomers understand the reversal mechanic.

## 4. Complete the design across the whole experience

**Priority: release essential polish. Build on the current artwork.**

- Keep the current dark navy, cyan, coral and gold palette, Roboto typography and smooth illustrated worlds. Define consistent spacing, buttons, panels and badge treatment using `ArcadePalette` and existing components.
- Give Achievements, Statistics, Settings and onboarding the same visual quality as the home screen and world shop. Keep Play and Replay dominant, with one next goal and quieter secondary actions.
- Refine artwork at actual gameplay size: distinguish the UFO/submarine, cow/pearl and hazards immediately. Use silhouette, outline and motion as well as color; do not change collision radii or hide additional hazards behind decoration.
- Preserve the existing trail, pickup and damage effects. Refine transitions and unlock celebrations while respecting reduced motion and keeping effects out of the competitive sightline.
- Add separate music/effects controls and optional restrained haptics. Verify mute and interruption behavior on hardware.
- Localize the full player-facing interface into English and German, matching the existing store languages. Include help, save errors, accessibility labels and native action messages.
- Check small phones, large text, landscape and tablets using the existing layout matrix. Retain touch targets, contrast, focus order and semantic labels; gameplay remains a visual skill game.

**Done when:** every screen looks related, both languages fit, all worlds are readable on a phone, reduced motion works, and new UI never alters the simulation or visible field.

## 5. Complete platform services and ship the exact tested build

**Priority: release essential verification; Game Center is the platform-parity milestone.**

- Verify Android sign-in, score submission, original/new achievements, offline replay of pending updates and disconnect from a **Play-installed, Play-signed** internal build. A sideloaded upload-key APK is a different authentication/signing case.
- Add iOS Game Center achievements and separate Normal/Hardcore leaderboards for native competition parity. Reuse the shared rules; enable the capability, authenticate, configure platform IDs and test cancellation/offline behavior. Apple provides these features through [GameKit](https://developer.apple.com/documentation/gamekit/). Local play and achievements remain usable without authentication. Game Center is a distinct deliverable, not a prerequisite for a functional offline game.
- Enable a working iOS rating destination when a public listing exists; keep the button hidden until then. Add the appropriate install link to score sharing once the destination is available.
- Run a physical-device matrix: older 60 Hz Android, modern high-refresh Android, iPhone and iPad. Measure a sustained 20–30 minute session, input response, frame pacing, audio interruptions, backgrounding, rotation, battery/thermal behavior and save persistence. Keep the 60 Hz simulation fair on high-refresh displays.
- Verify an upgrade from the released Android application using a compatible signature, including best scores, statistics, mute/opt-out and new wallet defaults. Protect existing local progress before any installation requiring removal.
- Recheck the live store records. The October 23 handoff recorded Android upload-key activation scheduled for October 25 at 19:14 and an Apple draft build 42; this plan does not verify either current Console state. The latest gameplay/artwork also postdates that uploaded Apple artifact.
- Build fresh signed artifacts from the final tested source, use unused build numbers where required, and record their hashes. Refresh screenshots, support copy, privacy/data declarations and review notes to reflect the actual shipped features. Reassess declarations if Game Center or another data feature is added.
- Commit the reviewed release scope, distribute to Internal/TestFlight, fix acceptance failures, then submit that same accepted build for public review. Much of the current working tree is uncommitted; preserve it and review its scope before release.

**Done when:** the exact release candidate passes automated and hardware acceptance, an internal tester can install it through each store, services work under distribution signing, and listing/screenshots describe that build.

## 6. Expand content after the completion pass

**Priority: optional follow-up, guided by playtesting.**

- Add two complete worlds, such as Honey Heist and Haunted Orbit, using the existing cosmetic-world system. Each needs a coherent core, player, collectible, hazards, shop preview and phone-scale readability checks.
- Measure actual early scores, run lengths and time to first/second world unlock before changing the 100 starting Flux, one-per-pickup earnings or 150-Flux prices. These numbers are currently a design choice, not retention evidence.
- If players want a recurring challenge, try one optional seeded daily run with a separate leaderboard and validated deterministic generation. Keep it separate from existing Normal/Hardcore rankings. Do not make this a launch blocker.
- Consider backup/cloud recovery only when there is a clear need. It requires explicit reconciliation and deletion behavior; native achievements alone do not restore a Flux wallet or cross-platform world ownership.

Defer multiplayer, accounts/backend, paid currency, advertising, loot boxes, battle passes, more currencies, physics changes and a replacement game engine. None is needed to finish this arcade game.

## Implementation scope and checks

| Area | Existing owners to extend | Required checks |
| --- | --- | --- |
| Run milestones and lifecycle | `lib/game/game_engine.dart`, `lib/game/game_screen.dart` | Pickup/hit/end boundaries, practice isolation, no repeated grants, unchanged RNG and physics |
| Persistence and progress | `lib/services/settings_service.dart`, one small shared achievement catalog if needed | Old-save migration, corrupt/failed saves, retries, cold restart, stable wallet IDs |
| Home/results/help and new screens | `lib/game/menu_scene.dart`, `lib/game/skin_shop.dart`, `lib/game/arcade_style.dart`, `lib/main.dart` | Existing layout matrix, navigation, both languages, semantics, reduced motion |
| Platform services | `lib/services/play_games_service.dart`, Android `PlayGamesBridge.kt`/`MainActivity.kt`, iOS `AppDelegate.swift` and capabilities | ID allowlists, real distribution auth, account changes, offline sync, native UI return |
| Artwork and feedback | `lib/game/game_skin.dart`, `lib/game/gameplay_feedback.dart` | Small-scale readability, opaque core, bounded artwork, no simulation differences |
| Release and documentation | `pubspec.yaml`, platform configuration, release records, store assets | Fresh artifacts/build IDs, declared features, listing accuracy, signed upgrade |

Keep the released-Java oracle fixtures unchanged. Add focused tests for new behavior and update presentation expectations only for intentional design changes. No architecture rewrite or dependency is required for the shared local progression work.

Recommended order: **reliability/settings → visible progression → onboarding → consistent design/localization → distribution and hardware acceptance**. Game Center can proceed once the shared achievement rules are stable; more worlds and daily challenges follow the completed release.
