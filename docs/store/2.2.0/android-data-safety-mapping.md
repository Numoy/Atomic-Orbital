# Android Data safety recommendation — 2.2.0 (42)

Reviewed 2026-10-23. Package `de.numpy.orbital.orbital4`. This is a recommendation for the owner's Console declaration, not a record of a saved/submitted form. No Console/API changes were made by this audit.

Console follow-through: the root task subsequently saved this complete five-type declaration on October 23, ready for review, with the app-specific deletion URL. It was not sent for public review. See [saved answers and confirmation](../../evidence/release-2026-10-23/play-data-safety-saved.json); audit evidence and Console state are separate records.

## Recommended answers

- Collects or shares user data: **Yes**.
- All collected user data encrypted in transit: **Yes**, based on the PGS HTTPS disclosure and the absence of another app-operated remote data service.
- App account creation: **My app does not allow users to create an account**. Atomic Orbital has no developer account, account database, server auth code, email/password or third-party in-game login. PGS authenticates a Google platform profile, separately from an in-game account. This is the interpretation supported by the [PGS identity architecture](https://developer.android.com/games/pgs/platform-authentication), not a claim that Google profile creation is impossible.

Use these five data types. For each, **collected: Yes; shared: Yes; processed ephemerally: No**.

| Category / subtype | Actual data | Required / optional | Collection and sharing purposes |
| --- | --- | --- | --- |
| Personal info / Name | Play Games gamer name | Optional | App functionality |
| Personal info / User IDs | Play Games player identity | Optional | App functionality |
| App activity / Other actions | Eligible best scores, completed-game counts, earned achievement updates | Optional | App functionality; Analytics |
| App activity / App interactions | Automatic SDK/API feature usage, including authentication attempts | Required | Analytics |
| App info and performance / Diagnostics | SDK request outcomes/status codes and timing/latency | Required | Analytics |

Gameplay belongs under **Other actions**, not merely App interactions. The latter row covers SDK usage analytics. These mappings apply Google's [data-type, purpose and handling definitions](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en-GB) to the evidence below. SDK analytics is not an advertising purpose.

Identity and gameplay service participation are optional: the game remains playable without a Play Games profile/authentication; app disconnection prevents its queued gameplay uploads. Automatic SDK analytics/diagnostics have no all-user in-app opt-out, and default initialization occurs before a menu choice. Do not label those two rows optional just because the game also works offline. Disconnection persists for the next process but does not unload an already initialized SDK.

The sharing recommendation deliberately claims no exception. PGS incorporates [controller–controller terms](https://developer.android.com/games/pgs/terms), rather than establishing Google as an instruction-only processor. No service-provider or specific-action/consent exception is assumed for automatic processing. Name/identity/gameplay support service features; SDK usage/diagnostics support stability and product improvement. Profiles and scores are retained service records, and product-improvement telemetry is not solely a transient real-time request.

## Current artifact and code evidence

Inspected local production AAB SHA-256 `3c45f9e0a8b7b48d7e1ca6982b8c1102209c76ea13f2c08f44ef34b10cd7e091`, plus release APK `f0d6e18b2c4d0e18d6b36109612744ea28a290356f1fb41c6ae6608c7a6ef4ad`. APK badging confirms version 42/2.2.0, min 24/target 36 and the production package.

- `build/app/outputs/sdk-dependencies/productionRelease/sdkDependencies.txt`: PGS `22.1.0`, base `18.5.0`, basement `18.9.0`, tasks `18.2.0`; Flutter/AndroidX/local-storage/audio support. No Ads, Firebase Analytics, measurement or Crashlytics dependency. AAB DEX inspection agrees.
- `android/app/src/main/kotlin/de/numpy/orbital/atomic_orbital/PlayGamesBridge.kt:55–117`: PGS authentication/current player; returns player ID/display name; submits allowlisted scores/achievements. No friends, saved games, Recall, email/profile/server-access scope requests or developer backend.
- `lib/services/play_games_service.dart:114–163,220–288,315–350,399–417`: precise events, authentication gating, local queue and disconnection. Total points are converted to achievement thresholds; local play time is not uploaded by game code.
- `AtomicOrbitalApplication.kt:14–35`, `LegacySettingsMigration.kt`, merged production manifest: migrate opt-out before explicit SDK initialization; default PGS auto-init provider disabled. The SDK is nevertheless allowed by default for a fresh installation.
- Bundled audio/fonts and local preferences do not transmit user files. Native Share sends the user-selected score text to the chosen app through the system chooser; that specific intentional action does not require an additional sharing declaration. Rate opens Google Play in an external activity. No WebView, remote assets, socket/HTTP client call, developer analytics or app crash uploader is used by application code.

The [PGS disclosure](https://developer.android.com/games/pgs/data-collection) describes automatic gamer identity, analytics and diagnostics, plus feature-dependent game records. The [current Google dependency table](https://developers.google.com/android/guides/setup) lists 22.1.0. The disclosure therefore covers the pinned PGS version; the core-library [no-collection statement](https://developers.google.com/android/guides/play-data-disclosure) does not negate PGS product collection.

The actual 22.1.0 SDK binary supplies concrete telemetry evidence, beyond the generic disclosure:

- `PlayGamesSdk.initialize` → internal `zzbw` → `zzas/zzar`: automatic authentication triggered by first Activity creation.
- GamesConnect `zzo` assigns method key 6737 to that attempt; `zzp.usesClientTelemetry()` and games-client `zzai.usesClientTelemetry()` return true. Other PGS feature calls also use method keys.
- Its actual base 18.5.0 `common.api.internal.zacd` completion logger constructs `MethodInvocation` with the method key, result/status/connection error codes, optional start/end timestamps, service ID and elapsed milliseconds. It uses configured allowlists/rate limits and can batch requests. It does not attach stack traces, email, Advertising ID, Firebase installation ID or a device-unique identifier in this record; the two additional string fields are null.
- These records justify SDK usage → App interactions and technical result/latency → Diagnostics. The exact mapping of API-method usage to App interactions is an explicit interpretation of the form definition. No arbitrary screen-tap analytics is claimed.

SDK decompilation used the local pinned Maven artifact and `/tmp/atomic-orbital-reference-tools/pgs-22.1.0/`; the telemetry class was extracted read-only to `/tmp/atomic-orbital-data-safety/`. This is static evidence of possible collection under SDK configuration, not a claim that every telemetry event is sent on every device.

## Legacy artifact coverage

Authoritative 41 APK SHA-256 `de2eab0ee467a81a4f3cdb7da1955cd5c3784630836c113861bf14ca859d9824`, `/Users/maerz/Downloads/41.apk`, was inspected through its decompiled released code and merged manifest. Repository Java source is an unfinished rewrite, so it is not substituted for the APK.

- 41 initializes Google Sign-In using `DEFAULT_GAMES_SIGN_IN`. Its bundled `GoogleSignInOptions.java:49` defines that as **games_lite only**, without email/profile/ID-token/server-auth requests. Released menu/game code sends scores/achievement unlocks; no developer account/backend or additional personal-data feature was found.
- Java Gradle declares games/auth/ads 11.8.0. Ads classes and `AdActivity` are present in 41, but released `ADController` never constructs its `AdView`; no `MobileAds.initialize`, `AdRequest`, `loadAd`, ad-unit layout or startup ad provider exists. Merely bundling these unused classes is not evidence of ads or Advertising ID collection. The released NO ADS button says the app is already ad-free. No Firebase Analytics/measurement/Crashlytics implementation is present.
- The inspected 41 functionality fits the identity/gameplay rows above. Google's latest-version-only disclosure does not retrospectively certify every internal field of the older released SDK. The repository's Gradle declaration is not proof of the exact resolved SDK version inside an older APK.

Beta **37 / 2.1.2** is now independently audited from the official Console **Original file**, artifact `4619466764796781160`, downloaded as `/Users/maerz/Downloads/37.apk`. SHA-256: `4961a9a16617b1d98b8f4f41e962748e25de8b69ac2f8a4f55aac800b7272741`. APK badging and the decoded manifest confirm package `de.numpy.orbital.orbital4`, min SDK 21 and target SDK 26. Decompiled evidence is under `/tmp/atomic-orbital-reference-tools/release-37/`; no application method failed decompilation (four reported failures are in third-party code).

- `MenuActivity.java:89–91,226–278`: uses `DEFAULT_GAMES_SIGN_IN`, prompts on launch, attempts silent sign-in on resume and provides sign-out. The bundled `GoogleSignInOptions.java:49` defines the requested scope as **games_lite only**, with no email/profile/ID-token/server-auth request. Cancellation/failure returns to the menu; gameplay has no login gate.
- `MenuActivity.java:342–345` and `Controller/GameObjects.java:114–237`: submits best scores, the completed-game counter and earned achievements when authenticated. These are the same gameplay data types/purposes as 41/42; local aggregate points determine achievement thresholds. No developer account/backend, friends, saved games, remote assets, HTTP/socket request, app analytics or crash uploader is implemented by the game.
- The 37 and 41 decompilations contain the same sets of 142 Auth, 439 Games and 242 Ads Java source files; each file in those three namespaces is identical between releases. Both carry `google_play_services_version=11910000`. This comparison establishes the released SDK/API behavior used for this audit without guessing a Maven version from the later repository Gradle file.
- 37's `advertising/ADController.java` is identical to 41's inert implementation: its `AdView` is never constructed; there is no `MobileAds.initialize`, `AdRequest`, `loadAd`, ad-unit layout or startup ad provider. The NO ADS control again says the app is already ad-free. Its only Android permissions are INTERNET and ACCESS_NETWORK_STATE. DEX inspection finds no Firebase Analytics, measurement or Crashlytics classes. The bundled Ads code therefore supplies no additional active advertising collection.
- Share uses a user-triggered system chooser; Rate opens an external Play Store URL. These add no developer-operated data endpoint. No new subtype, purpose or required/optional change is indicated by 37.

**Package-wide conclusion for the inspected distributed 37/41 and proposed 42 artifacts: the five recommended rows above suffice on the available code and SDK disclosure evidence.** The former missing-37-artifact gap is closed. Identity/gameplay remain optional; automatic SDK usage/diagnostics remain required. There is no evidence to add email, advertising/device IDs, location, photos, financial data or crash logs because of beta37. The form remains package-wide; an internal update alone does not exempt a production app from the declaration.

## Do not add unsupported types or claims

No inspected active app feature or SDK-specific disclosure supports selecting email, contacts, location, payment/purchases, health, personal photos/videos, recordings, files, installed-app inventory, crash logs or device/advertising IDs. Do not infer those from unrelated Firebase/Ads documentation or generic Google account/system-service practices. The PGS avatar is a platform gamer-profile image/selection; the app does not upload a user's photo or request photo-library access. This is not a promise about unrelated Google products.

Google's automatic analytics disclosure is broad, but the concrete telemetry path above resolves the relevant SDK usage/diagnostic categories without inventing additional fields. Revisit this mapping if SDK dependencies/features change or Google supplies a more specific conflicting disclosure. Both distributed legacy artifacts 37/41 have now been inspected; no missing-artifact gap remains for those versions.

## Deletion scope

Google documents deletion of individual-game data and the entire Play Games profile through [Play Games profile controls](https://support.google.com/googleplay/answer/9130646?hl=en-GB). App disconnection is not deletion. Local bests/pending updates remain until app data is cleared; reconnecting can upload locally retained progress again. Do not promise that clearing Google records clears this queue, or that Google profile deletion deletes all unrelated Google activity.

If the Console asks for a developer-provided deletion URL, use an actual app-specific page describing this scope and linking the working Google controls; do not mislabel the disconnect button as an account-deletion feature. If Google treats the platform-profile creation flow as app-account creation despite the separated v2 identity model, its [in-app and web account-deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en-GB) need explicit handling. This audit does not create that feature or make that alternative declaration.
