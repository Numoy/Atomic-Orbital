# Atomic Orbital 2.2.0 — listing and disclosure audit

Prepared 2026-10-22 from current source and the local release archive. This is a factual preparation record, not evidence that a store form or release is saved/published.

Local feature update 2026-10-23: [world skins and earned Stardust](../../skins-and-stardust-2026-10-23.md) now add animal artwork and themed hazards. The abstract-only content description and questionnaire guidance below describe the earlier baseline and need reassessment before this feature is published. Existing store declarations have not been changed for these skins. Stardust is earned locally; no real-money purchase integration was added.

Website update 2026-10-23: the two app-specific pages are now published and verified. See [deployment record](website-deploy-2026-10-23.md). The preparation findings below describe their original pre-deployment review; this website deployment does not establish a store publication.

Evening update 2026-10-23: the concrete SDK binary audit resolves automatic-telemetry mapping; see [the five-type Data safety recommendation](android-data-safety-mapping.md). Production APK 41 and active beta 37 are inspected. Reviewer-access instructions are saved without app-specific credentials; the complete Data safety form is saved ready for review, and App content has no outstanding declarations. Neither was sent for public review. The new [deletion page is live](website-delete-data-2026-10-23.md), with privacy/support links. Consult [the release handoff](../../releases/2.2.0-internal.md) for saved versus published store state.

## Supported listing claims

The game uses hold/release radial control, direction reversal on collection, increasing orbit count, Normal health regeneration and one-hit Hardcore. Local bests are separate. Core gameplay is offline. Menus/gameplay adapt to phones/tablets and portrait/landscape while simulation stays canonical. Music/effects can be muted. Native share sheets require a user action. There is no ad or purchase integration.

Android uses Google Play Games, including separate mode leaderboards and achievements. iOS has no Game Center or Play Games bridge and keeps scores locally. Neither listing implies multiplayer or cross-device sync. Current game UI is English; German listing text explicitly says so.

Sources: `lib/game/game_engine.dart`, `lib/models/components.dart`, `lib/game/game_screen.dart`, `lib/game/menu_scene.dart`, `lib/services/settings_service.dart`, `lib/services/play_games_service.dart`, Android `PlayGamesBridge.kt`/`MainActivity.kt`, iOS `AppDelegate.swift`.

## Content, age, health and finance

Recommended Apple responses are No/None throughout the content questionnaire: no parental controls/age assurance, unrestricted in-app web browsing, advertising, user-generated content, chat/messaging, profanity/crude humor, fear/horror, alcohol/tobacco/drugs, medical/treatment information, health/wellness topics, sexual/suggestive content, nudity, weapons, realistic/cartoon violence, gambling, simulated gambling, loot boxes or prize contests. Collisions involve abstract circles/diamonds and a numeric gauge, without people, animals, injury, weapons or depictions of violence. Random hazard placement is not wagering or a loot box. System sharing is not an in-app chat. External store links are not an unrestricted embedded browser. iOS local personal-best comparisons are not prize contests.

This supports the lowest applicable content rating, subject to the store's calculated result. Do not invent or override the calculated rating. Do not select the Kids Category or claim a child-targeted audience merely because the content is unobjectionable. The owner still chooses intended target ages/Families participation on Google Play. Android's native Google leaderboards expose gamer-chosen display names; answer any Android social/UGC prompt using that precise scope instead of copying the iOS questionnaire blindly.

Health declaration: no health/fitness/medical functionality or health-data access. HEALTH and regeneration are fictional gameplay mechanics. Financial declaration: no financial functionality, payments, lending, investing, crypto or monetary rewards. No government affiliation or Advertising ID usage is implemented.

[Apple content definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/) support the distinction between these questionnaire features and generic game mechanics. The store, not this audit, assigns region-specific ratings.

## iOS privacy

Proposed App Privacy answer: Data Not Collected; no tracking. Source uses bundled assets, native audio, local preferences and a user-initiated system share sheet; no app backend, account, advertising/analytics SDK or remote API is implemented. The inspected archive's Flutter, path_provider and shared_preferences privacy manifests all declare no tracking and empty collected-data arrays. Required API reasons for timestamps/boot time/UserDefaults are present. A privacy manifest is not itself a complete privacy-label assessment. Recheck the actual submitted archive if dependencies change.

System sharing goes to the recipient chosen by the user, not a developer endpoint. Apple/Google OS backups and OS-level diagnostics are platform-managed; do not claim the developer receives them from this app. Support emails are voluntary correspondence outside the app; the developer must handle any received personal information appropriately.

[Apple privacy definitions](https://developer.apple.com/app-store/app-privacy-details/) distinguish local processing from data sent off-device and retained by a developer/partner.

## Android Data safety

Do not submit a blanket “no data collected” answer. PGS processes identity and SDK telemetry; the app submits score/achievement events. Its documented transport is HTTPS, with Google profile deletion controls. [Primary SDK disclosure](https://developer.android.com/games/pgs/data-collection).

The October 23 source and binary audit supports Personal info → Name / User IDs, App activity → **Other actions** (scores/achievements/game counts) and **App interactions** (automatic SDK/API feature usage), plus App info and performance → Diagnostics (SDK request status/timing). Identity uses App functionality; gameplay uses App functionality and Analytics; SDK usage/diagnostics use Analytics. Identity/gameplay are optional, automatic SDK telemetry required, all collected/shared and non-ephemeral. Gameplay is Other actions rather than arbitrary screen-tap analytics. See [the concrete SDK and legacy-artifact evidence](android-data-safety-mapping.md), [SDK dependency table](https://developers.google.com/android/guides/setup) and [data-type definitions](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en-GB).

The earlier automatic-telemetry uncertainty and missing beta 37 artifact are resolved. Both distributed legacy APKs were inspected, and no additional active data subtype/purpose was found. Do not invent device identifiers or crash logs from unused SDK classes. The completed five-type preview was checked and saved on October 23; Console confirmed the change is ready to send for review. This is a saved declaration, not Google review approval. See [answer record](../../evidence/release-2026-10-23/play-data-safety-saved.json) and [complete App content checklist](../../evidence/release-2026-10-23/play-app-content-complete.png).

Do not automatically mark every category “optional” because gameplay works offline. The SDK initializes before an in-app choice by default; disconnect blocks app uploads, but does not unload an already-started SDK. Likewise, do not assert “not shared” solely by assuming Google is a processor: establish a valid exception or disclose sharing. [Google definitions](https://support.google.com/googleplay/android-developer/answer/10787469) include SDK transmissions and require care over optionality and service-provider exceptions.

[PGS terms §3](https://developer.android.com/games/pgs/terms) incorporate controller–controller terms; they do not establish an instruction-only service-provider exception. Treat Google-bound records as shared unless a specific documented user-action/consent exception applies. The lack of an app-owned account/backend supports “My app does not allow users to create an account” as an interpretation: Google distinguishes [platform authentication](https://developer.android.com/games/pgs/platform-authentication) from an in-game account. Do not infer app OAuth-account creation solely from the SDK's implementation. Google's [account-deletion scope](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en-GB) still needs attention if profile creation is treated as the app's account creation. The documented [individual-game deletion route](https://support.google.com/googleplay/answer/9130646?hl=en-GB) deletes Google-held game data; disconnect is not deletion and does not clear the local pending queue.

No contacts, precise/coarse location, photos, microphone recordings, financial or health data are used by game code. No Advertising ID permission or ads SDK is configured in current app source. Local play time/counters, pending queues and settings are not developer-server telemetry. The saved form follows the source, released binaries and SDK disclosure evidence, with app-specific deletion instructions linked. Re-audit when these dependencies or data features change.

## Existing URLs and minimal website addition

Read-only HTTP checks returned 200 on 2026-10-22 for `https://marvinmaerz.com` and `https://marvinmaerz.com/data-protection`. Public contact is `marvin.maerz@gmail.com` in the site's homepage/footer and policy. Do not invent a separate support inbox.

The existing policy is unsuitable unchanged: it broadly lists Firebase, Crashlytics, AdMob, Advertising ID/IMEI/MAC, and does not describe Atomic Orbital. Do not replace it globally because other apps may depend on it.

Local site: `/Users/maerz/Projects/marvinmaerz`. Astro 6, Netlify adapter, server output; `npm run build` runs `astro build`. The existing workspace has Netlify build/runtime artifacts, but its state file has no site ID, so CLI site linkage is not established by that file. The Git origin is `github.com/Numoy/marvinmaerz.git`. No package deploy script or deployment workflow was found in the inspected paths; verify the existing Netlify destination before deploying. No deployment was performed here.

Implemented addition: two static Astro pages, `src/pages/atomic-orbital/privacy.astro` and `src/pages/atomic-orbital/support.astro`, each using the existing `../../layouts/Layout.astro` with a descriptive title. They use the reviewed policy/support text and link to each other. Preserved `src/pages/data-protection.astro` and all unrelated app pages. The portfolio build passes; four headless desktop/mobile render checks pass with no horizontal overflow (see evidence/page-checks.json). On October 23 the existing Netlify destination and Git auto-publishing were verified, signed commit `972b09b` was pushed, and both live HTTPS pages returned 200 with source-matching article text. `listings.json` now contains their verified URLs. Both Apple locale URL fields are saved; Google's privacy URL is staged and its support URL is published. See the deployment and release evidence records for actual store state.

## Decisions and remaining work

- Review the concrete policy text; verify controller contact/legal identification and lawful basis/retention obligations for the owner's situation. No legal basis or retention deadline was invented.
- Website publication and store URL fields are complete. Before a public submission, both stores also require an accessible in-app privacy link or text: [Apple5.1.1(i)](https://developer.apple.com/app-store/review/guidelines/#privacy) and [Google User Data](https://support.google.com/googleplay/android-developer/answer/10144311). No current menu action provides it.
- Confirm intended Google target audience/Families choices. Suggested Apple subcategories: Action and Casual; avoid a child-specific marketing claim.
- Confirm final Android Data safety categories, purposes, sharing/optionality and Google's deletion route. App disconnect does not delete Google-held data.
- Keep platform screenshot sets accurate: Android may show Google buttons; iOS must not depict them. Use actual app captures, with local fixture scores identified in evidence.

## Metadata limits and validation

`listings.json` contains en-US/de-DE copy for both stores. Google fields: name30, short80, full4000, notes500 characters. Apple fields: name30, subtitle30, promotional170, description4000, keywords100 UTF-8 bytes, What's New4000. Apple initial-release What's New may not be editable/needed. `validate_copy.py` checks every prepared field.

Primary limits: [Google listing fields](https://support.google.com/googleplay/android-developer/answer/9859152), [Apple app information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/), [Apple platform version fields](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).
