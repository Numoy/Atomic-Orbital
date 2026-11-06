# Android Google Play Games access — 2026-10-25

The owner asked to verify access to the real Google Play Games scores and achievements on the connected Pixel 9 Pro. The installed comparison build uses the original game project `239790895284`, the previously registered comparison package `de.numpy.orbital.atomic_orbital`, and the registered debug signing certificate. It is authenticated to Google; its pending upload queue is empty.

The existing **Leaderboard** action opens the newer board for the selected mode. Added **All leaderboards** to the Android home and results menus so the original published boards and games-played ranking remain accessible too. The action opens Google's native list using [`LeaderboardsClient.getAllLeaderboardsIntent`](https://developers.google.com/android/reference/com/google/android/gms/games/LeaderboardsClient#getAllLeaderboardsIntent()), through the existing authenticated native bridge and `startActivityForResult` flow. Failed/canceled sign-in does not open the list. The action is hidden on Apple; the existing per-mode score submission targets and achievement rules are unchanged.

## Physical Pixel checks

The native Google screens (`com.google.android.gms`) showed:

| Google screen | Verified result |
| --- | --- |
| Normal Highscore | Original account record: 61 |
| Hardcore Highscore | Original account record: 36 |
| Most played Games | Score: 13 |
| Normal | Current board score: 22 |
| Hardcore | Opens successfully; no score present |
| Achievements | 13 of 18 unlocked, including an April 2018 unlock |

The updated local **2.3.0 (46)** comparison/profile APK was installed in place. Preferences matched byte-for-byte immediately after installation; all twelve themes and the owner's Deep Blue selection were retained. After live verification, the Google profile remained connected and the pending queue was still empty. No synthetic scores were submitted or leaderboard records reset.

[Sanitized verification and APK checksum](evidence/play-games-access-2026-10-25/verification.json). Native screenshots and the private pre-update preferences are kept locally under ignored `build/play-games-device-check/`.

All **453 Flutter tests** pass, Dart analysis is clean, and the Android build compiles the native Play Games bridge successfully. Checks cover the new action, canceled sign-in, existing per-mode dispatch, disconnect behavior and Apple visibility. This pass verifies the owner's sideloaded Pixel build; Play-installed distribution authentication and a fresh completed-game upload were not repeated. No Google Console configuration, publication, tester list or App Store Connect build was changed.
