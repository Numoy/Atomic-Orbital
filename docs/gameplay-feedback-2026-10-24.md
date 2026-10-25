# In-run readability and feedback — 2026-10-24

The user emphasized actual gameplay and then confirmed the gameplay itself feels good. This pass adds presentation cues to themed runs while preserving movement, difficulty and competitive rules.

- A short fading trail follows sampled player positions, with a thin cyan ring around the existing player radius. The ready screen briefly labels the player.
- Gold corner marks distinguish collectibles from red hazards. Their subtle brightness pulse uses simulation time.
- A pickup produces a brief ring and +1 at the collected object's original position. Reversal clears the previous trail so it does not point in the wrong direction. Damage has a short local red ring alongside the existing hit flash.
- Effects use game time, so pause freezes them. Replay clears them. Reduced-motion settings disable trails, bursts and marker pulsing while preserving static player/target markers.
- Classic retains its existing rendering. A separate presentation tracker reads positions/health without changing engine state, callbacks, RNG, geometry, scores or wallets.

The actual movement, acceleration, direction reversal, pickup value, hazard spawning/growth, collision rules, health and fixed visible field are unchanged. No audio or haptic changes are included.

Motion evidence records production GameScreen widgets with real scripted press/release events. One starting pickup is placed on the inner orbit to make collection and reversal reproducible; later pickups, hazards, collisions and damage follow the ordinary engine. These are widget captures with mock preferences, not a physical-device recording.

- [Cow Abduction gameplay](evidence/gameplay-feedback-2026-10-24/cow_abduction-gameplay.gif).
- [Deep Blue gameplay](evidence/gameplay-feedback-2026-10-24/deep_blue-gameplay.gif).

## Verification and installation

- All **262 tests pass**, including eight tracker tests, pickup-position/banking integration, Classic image equality with feedback present, reduced-motion image equality and painter/engine purity. Existing Java oracle, scaling, wallet and game-state checks pass.
- `flutter analyze`, formatting and `git diff --check` pass.
- Both five-second themed clips pass their real pickup/reversal assertion and encode as 100 frames at 393×852. They use scripted widget input and a controlled starting pickup; they are not physical-phone recordings.
- Android **production release** and iOS debug simulator builds pass. The production APK's application ID, version code 42, release AOT and registered local signing certificate are verified.
- Installed the signed update in place on the owner's Pixel 9 Pro using `adb install -r`, then cold-launched the production package. No reset, uninstall, wallet edit or paid-world purchase was performed. ADB's libusb connection was unstable; restarting its server with the native USB backend restored device access without changing app configuration.
- Native checks passed for Classic ready/play, held input, release, pause/resume and End run. Two paused playfield captures were pixel-identical outside the system bars. A real pickup raised the wallet from 100 to 101; best 43 remained visible and both values survived a cold restart. The test run ended from pause, without completing/submitting a game.
- Both themed shop previews render correctly on the phone. Classic remains equipped: the two themed worlds are locked at 150 while the wallet has 101. Native in-run themed effects and sustained frame pacing remain unverified. Their drawing, reduced-motion handling and lifecycle behavior are covered by the automated tests and clips.
- The current app process showed no fatal or unhandled Flutter/runtime error in the filtered log check. No store release was published.

Physical-device evidence:

- [Ready](evidence/gameplay-feedback-2026-10-24/pixel9pro-classic-ready.png), [paused](evidence/gameplay-feedback-2026-10-24/pixel9pro-classic-paused.png), [after Resume](evidence/gameplay-feedback-2026-10-24/pixel9pro-after-resume.png) and [cold-restart wallet/best](evidence/gameplay-feedback-2026-10-24/pixel9pro-menu-after-restart.png).
- [Cow preview](evidence/gameplay-feedback-2026-10-24/pixel9pro-cow-preview.png) and [Deep Blue preview](evidence/gameplay-feedback-2026-10-24/pixel9pro-deep-preview.png).


## Owner testing unlocks

At the owner's explicit request, granted `cow_abduction` and `deep_blue` on the connected Pixel 9 Pro. A temporary signed in-place update added only the two ownership IDs to the existing valid wallet. Runtime assertions confirmed all other preferences and the existing 138 Stardust balance were unchanged. No currency was charged, defaults or prices changed, or app data cleared.

Restored the original application source, rebuilt and reinstalled the normal signed production APK, and verified the installed APK's SHA-256 matches that normal artifact. The temporary grant code is absent from its DEX files. Both worlds showed “Use world” in the normal build; Deep Blue was successfully equipped without spending currency. A later device capture showed Cow Abduction running with its UFO, cow, Earth and feedback visible. The owner can now test full runs; sustained frame pacing remains unverified.
