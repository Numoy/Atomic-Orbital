# Atomic Orbital

A Flutter port of the released Java Android game **2.1.6 (build 41)**, now adapted for Android, iPhone and iPad. Gameplay and graphics use the owner's original Google Play APK as the reference. The accepted parity baseline is preserved separately from the subsequent scaling work.

The player moves around the atom. Hold to accelerate outward, release to move inward, collect the square energy to score and reverse direction, and avoid red photons. Normal mode has regenerating health; hardcore ends on the first hit. The start instruction, health gauge, audio, and separate mode highscores follow the original. The [arcade menu and results](docs/arcade-menu-2026-10-22.md) add an animated arena and physical play-button feedback, with the latest [compact mode switch](docs/mode-picker-2026-10-22.md), while preserving the accepted gameplay. Results now [highlight new personal bests](docs/records-2026-10-23.md), with ties retaining the ordinary best-score display.

The [matching gameplay visuals](docs/game-visuals-2026-10-22.md) use the same palette, a faint reactor glow and a beveled health rail, with the original movement, collision geometry and timing preserved.

Version **2.3.0 (44)** adds a playable, skippable practice introduction, **18 offline achievements**, statistics, English/German localization, separate music/effects controls, optional haptics and checked progress saving. The [October 25 improvements](docs/improvements-2026-10-25.md) add local daily challenges, save export/import with rollback and previous-save recovery, run duration on results, keyboard fixes and audio retries. The original twelve achievement conditions remain unchanged. Local progress works without a platform account; Android Play Games and iOS Game Center provide optional online competition with profile-bound pending uploads.

The [October 25 world review](docs/world-review-2026-10-25.md) expands the collection to eleven themed worlds plus free Classic. Haunted Harvest, Junkyard Dash, Volcano Hop, Cheese Chase and Jungle Jam join Cow Abduction, Deep Blue, Web Escape, Dragon’s Hoard, Pollen Patrol and Frost Bite. Deep Blue collects treasure chests. A minimal swipe selector previews one world at a time, with a compact unlock/equip action. Existing balances, ownership and stable save IDs are preserved. Daily challenges and practice keep Classic; the two world achievements are visible again in ordinary Progress.

See the [build 44 iOS handoff](docs/releases/2.3.0-build44.md) for current build/store status, the [earlier 2.3.0 handoff](docs/releases/2.3.0-internal.md) for historical evidence and acceptance gaps, and the [follow-up roadmap](docs/roadmap-after-completion.md) for later work. No public release is implied by the source version.

## Fair scaling

Every device uses the same 1080 × 1857 simulation world and 1080 × 1794 visible playfield, with fixed 60 Hz rules. Gameplay fits that complete playfield uniformly inside the safe area; menus adapt to the available space and system text size. Phones, tablets, landscape and split-screen windows cannot reveal extra hazards, stretch hitboxes or alter the run by resizing. Touch anywhere in the safe window except the pause control to hold; Space/Enter provide the same binary control. Rotation/focus loss releases held input.

The pause button, Escape/P or Android Back freeze the current run. App interruptions also pause; returning keeps the game frozen until Resume is selected. The [pause screen](docs/pause-2026-10-23.md) includes sound and End run controls. Escape/P or Back also resume a paused run. [How to play](docs/help-2026-10-23.md) is available from the menu and pause screen, covering movement, pickups, direction reversal, hazards and mode rules.

Apple builds use bundled Roboto, native audio, iPhone/iPad icons, a native share sheet and GameKit. The Game Center capability and EN/DE achievement/leaderboard metadata are configured in App Store Connect; distribution testing and public review are separate release gates. iOS rating stays hidden until a public listing exists. See [device scaling and verification](docs/device-scaling.md) and the [current handoff](docs/releases/2.3.0-internal.md).

## Run

Use Flutter, an Android SDK, and an Android emulator or phone:

```sh
flutter pub get
flutter run --flavor comparison
```

`android/` is the Flutter runner. Its `comparison` flavor keeps a separate application identity alongside the original; `production` updates `de.numpy.orbital.orbital4` and migrates the original scores and settings. The historical Java project remains in `app/` and the root Gradle files. Its launch classes are incomplete; it is not the released-game reference. Original audio and bundled Roboto are included. Historical menu artwork stays in the repository but is no longer packaged.

Verified with Flutter 3.47.7. Android explicitly uses Skia for the reference rendering; recheck the renderer comparison before upgrading Flutter, as described in the verification record.

For Play releases, copy `android/key.properties.example` to the ignored `android/key.properties`, set the registered upload key locally, and run `flutter build appbundle --release --flavor production`. Release builds never fall back to debug signing. The current release candidate version is `2.3.0 (44)`.

## Verify parity

```sh
flutter analyze
flutter test
flutter build apk --profile --flavor comparison
```

The independent fixture in `test/oracle/release_41.json` was generated by compiling the actual released Java controllers. To regenerate it, obtain the original build 41 APK from the owner's Play Console, install the official JADX CLI, and run:

```sh
python3 scripts/generate_release_oracle.py /path/to/41.apk /path/to/jadx
```

The generator validates the APK fingerprint and records controller-source hashes. It stubs Android rendering dependencies, not movement calculations.

See the [parity plan](docs/parity/PLAN.md) and [verification record](docs/parity/VERIFICATION.md) for the reference, checks, and remaining differences. The simulator is the agreed validation target; the reference phone was a 60 FPS Galaxy S10. Native Android gameplay text uses the original Canvas/Paint rasterization in the fixed reference frame; menus use accessible Flutter controls. Play Games connects to the original project through a restricted comparison credential; the verification record documents live checks. Physical touch/audio latency is outside the agreed simulator scope.
