# Match the released Atomic Orbital

The target is the original Android game **2.1.6 (version code 41)**, not a redesign. This plan includes implementation and verification. The implementation and simulator checks below have been carried out. The follow-up adds native Android glyph rendering and a real Play Games client connected to the original project; see the verification record for measured results. A passing test suite alone does not establish identical game feel.

## Reference

- Downloaded the original file from the owner's Google Play Console on 2026-10-21.
- Package: `de.numpy.orbital.orbital4`.
- APK SHA-256: `de2eab0ee467a81a4f3cdb7da1955cd5c3784630836c113861bf14ca859d9824`.
- Local APK: `/Users/maerz/Downloads/41.apk` (not committed).
- Recovered with JADX 1.5.6 under `/tmp/atomic-orbital-reference-tools/release-41` (temporary, not committed). Four bundled Google library methods failed decompilation; the game controllers used for verification compile successfully.
- The checked-in Java tree is a later, incomplete ECS rewrite. It has empty input handling, missing launch activities, and collisions that only log. Its constants and behavior must not replace the released game's behavior.
- Runtime reference: Android emulator, Android 16/API 36, 1080 × 1920 physical pixels, density 420 (2.625 logical-pixel ratio), 60 Hz. Original screenshots are in [evidence](evidence/).

## Work and order

### 1. Recover and freeze the original

- [x] Retrieve and fingerprint the actual released APK.
- [x] Recover the released controllers, resources, audio, and layouts.
- [x] Install and run the unmodified original on Android.
- [x] Generate Java controller fixtures independently of the Dart port. Keep source hashes and input sequences with the fixture.

The reference behavior is determined by the release classes `GameObjects`, `PlayerController`, `PhotonController`, `PhotonFactory`, `OrbitController`, `EnergyController`, `HitpointsController`, and their models/views. Existing port documentation saying parity was already achieved is not evidence.

### 2. Restore the rules that determine feel

- [x] Use the original physical-pixel dimensions, integer division, float rounding, coordinate origin, and update order.
- [x] Restore held/released radial acceleration, speed limit, orbit boundaries, direction changes, and angular motion. Remove invented drag-to-change-speed behavior.
- [x] Restore photon trajectories, growth phase, wave cadence/grouping, difficulty progression, and offscreen removal.
- [x] Restore initial energy placement, immediate collection/respawn, square collision behavior, orbit additions, and score progression.
- [x] Restore the health gauge: 100 initial health, 0.1 regeneration per simulation update, 45 normal damage / 130 hardcore damage, and the original strictly-negative death threshold.
- [x] Preserve ordering quirks that affect collisions and events. Do not substitute circle collision for the release's strict axis-aligned bounds.
- [x] Advance simulation using elapsed time, separately from display refresh; verify 30/60/90/120 Hz callback sequences produce the same simulation state.

**Confirmed timing target:** the user identified the Samsung Galaxy S10 and the original 60 FPS limit, and explicitly accepted simulator verification on 2026-10-21. The released game advances most logic once per `SurfaceView` loop, without an explicit frame limiter. The Flutter simulation therefore preserves 60 updates per second independently of display refresh. Slow emulator presentation of the original under host load is not a reason to retune the original mechanics. Higher simulation speed is not added; a faster display must not speed up the game.

### 3. Restore the look, flow, and sound

- [x] Match the original Canvas draw order: background → photons → dashed orbits → atom/score → energy → player/solid orbit → health → start instruction.
- [x] Restore black background, white atom/player, red photons, outlined square energy, original stroke widths, score position/font metrics, and green health gauge. The existing `stars.png` is a rating graphic, not a background.
- [x] Match NORMAL/HARDCORE selection, separate highscores, original animated atom menu, START shape, colors, icons, ready state, death screen, home, restart, and mute.
- [x] Preserve the original display-versus-canvas height offset and physical-pixel sizes; do not accidentally scale mechanics by Flutter logical pixels.
- [x] Reuse original sound bytes and match mute default, music state, event timing, and overlapping effects.
- [x] Make touch-down/up/cancel immediate. Backgrounding, interrupted touches, focus loss, and disposal must never leave input held or jump the simulation forward.

### 4. Make both versions runnable and compare

- [x] Restore a separate Flutter Android runner so the port and original can coexist for comparison. Preserve the legacy Java project.
- [x] Keep portrait layout on Android and iOS. Verify Android build, real app launch, ready state, playing, collection, damage, death, restart, mode change, and background/resume.
- [x] Run the original Java traces against the Dart controllers at multiple physical widths, including integer-division edge cases.
- [x] Add interaction tests for down/up/cancel, mode selection, restart, lifecycle, and persistent highscores/mute.
- [x] Capture paired screenshots on the same emulator, compare geometry and state, and record every visible difference. Dynamic random energy locations and video phases must be aligned or excluded explicitly, never silently accepted as a match.
- [x] Run static analysis and the complete focused test suite. Build an APK. Record commands, results, and remaining differences in [verification](VERIFICATION.md).

### 5. Simulator acceptance (user-approved scope)

- [x] Compare the original and port on the **same Android simulator**, using the same viewport and display refresh rate. The user explicitly selected simulator verification because the original S10 is unavailable.
- [x] Compare short tap, long hold, release at both boundaries, rapid alternation, energy reversal, dense waves, normal damage/recovery, and hardcore death.
- [x] Verify orbit period, boundary transit, and wave cadence against independent Java traces at the confirmed 60 Hz target. Check touch delivery and native sound routing in the simulator. Resolve discrepancies by returning to original code/traces, not subjective tuning alone.
- [x] Verify the same simulation results under 30/60/90/120 Hz frame callbacks. The simulator display itself runs at 60 Hz.
- [x] Review the paired simulator captures and list any rendering differences explicitly. Provide the runnable build for user comparison.
- [x] No unexplained visual/gameplay differences remain within this simulator scope. Keep exact per-pixel CPU/GPU raster differences and live services separate from verified mechanics.

Physical input latency, speaker/audio onset, battery load, and high-refresh hardware are follow-up checks if a phone becomes available; they are not represented as simulator measurements.

### 6. Complete native text and Play Games follow-up

- [x] Replace remaining Android font approximations with whole-string native TextView/Paint stamps; preserve XML rounding, target-26 width behavior, native gravity and integer menu allocation.
- [x] Verify source-matched font bounds and positions against original screenshots and actual inflated Android XML.
- [x] Use the original Android launcher icon, including density selection.
- [x] Create and link the specifically approved restricted debug OAuth client to the original Play Games project; keep original default credentials and published boards unchanged.
- [x] Implement and live-verify automatic sign-in, persisted app disconnect, explicit reconnect, native achievements, both mode leaderboards and server-acknowledged score/unlock updates.
- [x] Follow original published board limits; repair invalid default-zero queue entries without altering earned local statistics or fabricating scores.
- [x] Verify static screenshot pixels remain unchanged across native overlays and resume. Remove experiments unsupported by the saved pixel evidence.

## External services and boundaries

Local gameplay, visual design, menus, audio, scores, and lifecycle are in scope. No app publishing, production rollout, or store submission is part of this work. The owner explicitly approved creating and linking a restricted Android OAuth client for the comparison package and this computer’s debug certificate.

Play Games uses the original project (239790895284), achievement IDs, and mode-specific leaderboard IDs. A separate, draft Android credential supports the existing tester account without replacing the original package’s default credential. Their icons must not imply a successful connection when one is unavailable. Original RATE/SHARE can open native destinations without submitting anything automatically. The released COMING SOON skins button has an empty handler; it does not justify inventing a skin shop.

Unverified integrations and hardware-only properties remain visible. Source-derived mechanics, simulator rendering, and native input/audio routing can be verified here; none of those establishes identical pixels across different rasterizers or measures physical touch/speaker latency.
