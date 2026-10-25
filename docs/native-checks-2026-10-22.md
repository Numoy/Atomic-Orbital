# Native simulator follow-up — 2026-10-22

The Mac was unlocked and the native checks blocked on 2026-10-21 were resumed. No production code changed during this follow-up.

This record covers the first responsive menu. The later [arcade presentation checks](arcade-menu-2026-10-22.md#native-simulator-checks) contain the current menu/results captures and updated installation evidence.

## Android refresh

The final arm64 profile APK installed successfully with `adb install -r`, without uninstalling or clearing app data. The installed `base.apk` SHA-256 matches the local artifact exactly: `a98c3762d137b66730a0411c80df9f9693d9af939b28d3415a48986b120144ed`.

Read-back of the app's preferences confirmed Normal best **8**, Hardcore best **4**, and **13 games played**. The earlier installation timeout is resolved. This follow-up verified installation and stored data; the native Android menu/ready captures remain in the [menu record](menu-design.md).

## iPad and iPhone UI

Both dedicated simulators use iOS 26.2. The current app was installed on the iPad (A16) and iPhone 16. The actual Simulator windows were inspected through native UI automation; these captures include the simulator bezel and toolbar.

- iPad menu adapts between portrait and landscape. Ready-state gameplay retains the full portrait field with black side bars in landscape. A Hardcore run was started and ended through a real collision. Results, Restart, and Escape back to the menu were exercised.
- The iPad native share popover opens with the selected best score, remains within the visible window through rotation, and dismisses back to the menu.
- iPhone portrait respects the cutout and home-indicator safe areas. Landscape menus scroll; mode and play controls were reached by swiping. The native share sheet was also opened from that layout and remained usable after returning to upright portrait. Its preview showed the existing Normal best of **28**.
- iPhone ready gameplay was inspected in portrait and landscape, including cutout clearance and the complete fixed field. Escape returned to the menu.
- Apple menus expose Sound and Share without unavailable Google Play Games or store-rating actions. No share destination was selected.

| Evidence | Capture |
| --- | --- |
| iPad portrait menu | [View](evidence/native-checks-2026-10-22/ipad-menu-portrait.png) |
| iPad landscape menu | [View](evidence/native-checks-2026-10-22/ipad-menu-landscape.png) |
| iPad share in landscape | [View](evidence/native-checks-2026-10-22/ipad-share-landscape.png) |
| iPad share after rotation | [View](evidence/native-checks-2026-10-22/ipad-share-portrait.png) |
| iPad portrait ready | [View](evidence/native-checks-2026-10-22/ipad-ready-portrait.png) |
| iPad landscape ready | [View](evidence/native-checks-2026-10-22/ipad-ready-landscape.png) |
| iPad results | [View](evidence/native-checks-2026-10-22/ipad-results-portrait.png) |
| iPhone portrait menu | [View](evidence/native-checks-2026-10-22/iphone-menu-portrait.png) |
| iPhone landscape controls | [View](evidence/native-checks-2026-10-22/iphone-menu-landscape-controls.png) |
| iPhone share | [View](evidence/native-checks-2026-10-22/iphone-share-portrait.png) |
| iPhone portrait ready | [View](evidence/native-checks-2026-10-22/iphone-ready-portrait.png) |
| iPhone landscape ready | [View](evidence/native-checks-2026-10-22/iphone-ready-landscape.png) |

## Native Apple audio

Both existing `RunnerTests` passed on the dedicated iPad, with parallel simulator cloning disabled:

- `testAppleAudioPreparesAssetsValidatesRequestsAndDisposes`
- `testAppleAudioPlaysOverlappingEffectsAndMusicWithoutSessionConflict`

XCTest reports **2 tests, 0 failures**. These checks establish asset preparation, validation/disposal and successful native playback requests through the exercised pause/resume and repeated-cue paths. The previous audio-queue startup failure did not recur. They do not measure audible latency, assert sustained overlap/voice counts, or exercise a real OS interruption.

Result bundle: `/tmp/atomic-native-audio-unlocked-2026-10-22.xcresult`; build/test log: `/tmp/atomic-native-audio-unlocked-2026-10-22.log`. A portable [result summary](evidence/native-checks-2026-10-22/native-audio-summary.json) is retained with the screenshots.

Physical touch/audio latency, real interruption recovery, signed-device validation and production store signing remain distribution checks. The existing 186-test Flutter result and Android/iOS builds are recorded in the [menu verification](menu-design.md); this follow-up did not change Dart or native production source or publish an app.
