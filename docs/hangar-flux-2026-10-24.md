# Hangar, Flux and craft identity — 2026-10-24

The shop now keeps the same layout while browsing, unlocking and equipping worlds. World titles, descriptions and button labels reserve the largest natural text extent for the current width and text scale. The progress track retains its slot when hidden, every thumbnail has a status line, and thumbnail borders keep the same thickness. This prevents the controls, previews and scroll extent from changing with the selection. Browsing still only previews; equipping requires the explicit action.

Stardust is now called **Flux** throughout the displayed interface: shop, balance semantics, help, results and save errors. A shared gold energy token replaces the sparkle mark in the shop and main-menu shop button. The existing v1 wallet key, balance field, IDs, service API and prices remain compatible; this is a display rename, with no balance conversion or new grant.

The shop is presented as a **Hangar**. Its old Material About alert is replaced by a framed, star-field **Flux field guide**, with a custom token, short earning/unlock explanations and a full-width return control. The guide scrolls at large text sizes and short screen heights, supports ordinary Back/dismiss behavior, and never changes the wallet or starts a run.

The Cow Abduction craft is now the **MOO-1**: a cow-print faceted hull, copper thruster pods and mint beam emitter around the existing readable alien pilot. Deep Blue uses the **Bathyscout**, with a rescue stripe, caged propeller, larger viewport, searchlight and pearl gripper. The same shared artwork appears in the hangar, menu and actual gameplay. All artwork stays within the original radius; Classic, simulation, hitboxes, rewards and leaderboards are unchanged.

## Verification

- Two layout regression tests first reproduced the old jumping, then passed with identical action/thumbnail bounds through browsing, becoming affordable and equipping, at 1× and 2× text scale. The normal-size check also uses actual thumbnail and equip taps.
- Three field-guide tests cover its content, close action, unchanged wallet, and scrolling at 3.2× text on narrow and landscape windows. Existing shop checks cover 12 size/scale combinations and a notched phone.
- All **267 tests pass**. The art tests retain circular bounds, readable pilot eyes, opaque cores, hazard/core occlusion and seeded simulation equality.
- The final guide button typography was checked with the 33-test shop/evidence run. `flutter analyze` is clean. The signed Android production release build passes; package, version code 42 and registered local certificate are verified.
- Production widget and canvas renders were inspected at phone, tablet and gameplay sizes. They use isolated mock preferences and do not modify the phone wallet.

## Visual evidence

- [Equipped hangar](evidence/hangar-flux-2026-10-24/shop-equipped-phone.png) and [Flux field guide](evidence/hangar-flux-2026-10-24/flux-field-guide-phone.png).
- [MOO-1 and Cow Abduction](evidence/hangar-flux-2026-10-24/cow_abduction-characters.png), [Bathyscout and Deep Blue](evidence/hangar-flux-2026-10-24/deep_blue-characters.png).
- [Cow gameplay](evidence/hangar-flux-2026-10-24/cow_abduction-gameplay-phone.png), [Deep Blue gameplay](evidence/hangar-flux-2026-10-24/deep_blue-gameplay-phone.png). These gameplay images are widget fixtures, not physical-device recordings.

Device update: after USB reconnection, installed the reviewed signed shop APK in place on the Pixel 9 Pro and verified its installed SHA-256. No app reset or foreground launch was performed, so full native interaction and sustained gameplay checks are pending. Existing wallet fields and unlock IDs remain unchanged.

The reviewed APK was built before a concurrent achievements/settings pass began changing `settings_service.dart`, `game_engine.dart` and `play_games_service.dart` in the shared folder. That newer source remains intact. A later compatibility run against it encountered wallet-test timeouts; this does not describe the reviewed APK, which passed the 267-test suite before those edits. The newer source needs its own completed validation before another build is installed.

Reviewed APK SHA-256: `27cd47e35b1f22d7f6da670ba27ab658d36a439e579ec2861cb638ecae735d72`.
