# Review improvements — 25 October 2026

Source version: **2.3.0 (44)**. This implements the owner's approval of the multi-agent review. It does not establish public release, store acceptance, physical-device performance or newcomer comprehension. Existing uploaded build 43 predates these changes.

## Reliability and accessibility

- Practice lets focused Skip and completion buttons handle Enter/Space. Moving keyboard focus releases held gameplay input. Completion uses the localized “GOT IT” label, including when opened manually.
- Audio initialization retries after a failed load, with concurrent attempts coalesced. Enabling sound or starting/resuming a run can recover without restarting the app.
- Unreadable-save errors preserve the original data and point to Settings recovery; a Retry button is shown only for retryable writes.
- Personal-best accessibility announcements use English/German strings. Android's native start-prompt image is prepared again after a language change.
- Results show elapsed gameplay time. Paused/background time is excluded by the existing simulation clock.
- Unused direct dependencies `cupertino_icons`, `flutter_animate` and `vector_math` are removed; Flutter still supplies `vector_math` indirectly.

## Save backup and recovery

Settings offers Export save, Import save and Restore previous save using native document pickers on Android/iOS. Backups include local scores, statistics, achievements, settings, preserved cosmetic ownership/balance and daily results. Platform profile identifiers and pending upload queues remain on their original installation.

Imports are size bounded and validated before a preview. Explicit confirmation replaces values; counters and balances are never added together. Missing supported fields receive defaults rather than falling back to the destination's legacy statistics. Unknown valid future cosmetic IDs remain preserved. The previous readable save can be restored; unreadable original bytes are retained separately when importing a valid replacement.

A checked journal protects the multiple preference keys: the previous values are recorded before mutation, the journal is removed to commit, and incomplete replacements roll back before reading saves at startup. Failed rollback preserves recovery material and blocks further progress writes. A successful restore ends any old paused/result run and returns home so that an old run cannot modify the newly imported save.

Exports are ordinary unencrypted JSON files. Users choose their destination in the operating system picker. There is no new developer service or automatic cloud backup.

## Local daily challenge

Home Menu → Daily challenge opens the current UTC day's Normal challenge. The dialog shows the date, next reset in local time, local best and the device-clock limitation. Attempts are unlimited.

Identity is `YYYY-MM-DD/rules-1/xorshift32-1`. The Xorshift32 (13, 17, 5) generator has known-answer tests; each attempt starts from a fresh generator. Identical seed and input traces produce identical simulation. Difficulty retains the original score-dependent rules, so different input/score histories can produce different later hazard patterns.

A run keeps its original identity across midnight and interruptions. Replaying after midnight chooses the new UTC day. Daily records are separate from Normal/Hardcore records, achievements, statistics, saved currency and platform leaderboards. The 30 most recently saved challenges are retained. Failed writes keep the highest pending result for retry, including after lower later attempts. There is no online daily competition or claim that the device clock establishes a trustworthy global date.

## Validation and acceptance

- `flutter analyze --no-pub`: no issues.
- Full `flutter test --no-pub --reporter expanded`: **394 passing tests** on the combined source. The final daily pause-copy change also passed **69 focused menu/daily tests**. Original released-game oracle fixtures are byte-for-byte unchanged.
- **17 focused UI/render checks** pass for daily/backup flows, localized result announcements, duration, live locale changes and large text. [Daily dialog](evidence/improvements-2026-10-25/daily-intro.png), [result](evidence/improvements-2026-10-25/daily-result.png), [import preview](evidence/improvements-2026-10-25/backup-preview.png) were inspected.
- Production Android release AAB builds and its JAR signature verifies. [Preserved candidate](../build/releases/2.3.0+44/review-improvements/app-production-release.aab), SHA-256 `43c0717150f6670bb42044f03865281960cf3549891c770cd26b435b49972f13`.
- iOS simulator build succeeds with version/build **2.3.0 (44)**. On the dedicated iOS 26.2 iPhone simulator, native export saved a JSON file through On My iPhone; import read that same file, showed the expected preview, restored it and returned home while preserving Normal 28, Hardcore 12 and 100 Stars. Daily UTC date/local reset, practice skip, ready/pause and end-run return were checked. These simulator observations do not establish physical-device or distribution behavior.
- **51 store render checks** pass; **52 opaque RGB images** (50 localized screenshots, feature graphic and icon) are refreshed under [store-assets/2.3.0+44](../store-assets/2.3.0+44/manifest.json). Capture fixtures explicitly match the current app's enabled collection UI. Listing copy is updated locally; no listing was submitted.
- [Verification summary](evidence/improvements-2026-10-25/verification.json), [source hashes](evidence/improvements-2026-10-25/source-sha256.json), [full test log](evidence/improvements-2026-10-25/flutter-tests.txt), [analysis](evidence/improvements-2026-10-25/analysis.txt).
- Concurrent world-shop edits continued after the candidate was built. The source manifest pins the checked candidate; changes to `lib/game/skin_shop.dart` afterward require their own affected checks before distributing the combined workspace.

Tests cover keyboard buttons, focus loss, EN/DE semantics and large text, locale text preparation, save validation, rollback/restart and repeated restore, daily known answers/determinism/isolation and failure retries, plus unchanged original-game oracles. No dependency or engine/toolchain upgrade was made; current build tools emit advisory Kotlin/CocoaPods migration notices.

The [acceptance sheet](acceptance/2.3.0.md) still requires five real newcomers and sustained physical Android/iPhone/iPad sessions. Also verify signed in-place upgrades, native file-provider cancellation/export/import on both platforms, changing audio routes and real Game Center/Play Games authentication. No store upload or public submission is implied by this source change.
