# Local Android Play Games sign-in — 2026-10-23

The owner reproduced the account-picker/Continue flow on the connected Pixel 9 Pro. Google returned `DEVELOPER_ERROR`, explicitly reporting that the package and certificate fingerprint did not match a registered OAuth client. [Filtered phone error](evidence/local-signin-2026-10-23/phone-error.txt).

The installed APK is the sideloaded production 2.2.0 (42), package `de.numpy.orbital.orbital4`, SHA-256 `f0d6e18b2c4d0e18d6b36109612744ea28a290356f1fb41c6ae6608c7a6ef4ad`. Its signing SHA-1 is `7C:41:71:A4:A7:B3:E7:DD:14:8A:8B:F2:E5:40:9F:04:C0:96:F5:34`, independently verified by pulling the installed APK and inspecting its certificate. The existing production OAuth client instead uses Google's distribution signing SHA-1 `1F:10:EA:59:62:98:04:99:9F:78:EE:20:A4:DE:78:19:CE:D3:15:8E`.

With the owner's explicit approval, created **Atomic Orbital Local Upload Key** in Cloud project `atomic-orbital-7008314`, restricted to the installed package and local signing SHA-1. Client ID: `239790895284-97p1kqrdhji69aaqjm0m6u1o9r8vm2kn.apps.googleusercontent.com`. [Creation proof](evidence/local-signin-2026-10-23/client-created.png), [saved restrictions](evidence/local-signin-2026-10-23/client-verified.png).

The owner confirmed **“yes works now”** immediately after OAuth registration. No additional Play Games credential was saved: the existing game configuration already allowed the now-registered app to connect. The unused Add credential form was closed. Existing distribution/debug clients, default credential, testers, upload-key reset and publishing state were not changed. No app replacement, uninstall or data clearing was needed. Temporary verbose Games logging was restored to its previous setting.

The app also ignored unsuccessful boolean results from manual Sign in, Trophies and Scores. Those paths now show **“Google Play Games sign-in did not complete. You can keep playing offline.”** instead of silently returning. Existing native error messages remain visible. The test covers all three unsuccessful paths, retained disconnect preference and successful retry.

`flutter analyze`, all **197 tests**, formatting and `git diff --check` pass. The feedback fix is local source only; the phone's successful sign-in uses its existing installed APK. Leaderboard/achievement operations on this physical phone were not separately exercised during this fix.
