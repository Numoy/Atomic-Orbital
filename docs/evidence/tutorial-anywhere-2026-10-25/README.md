# Hold-anywhere tutorial — 25 October 2026

The tutorial now teaches two actions with the existing practice simulation: hold anywhere until the outer square is collected, then release to collect the inner square. Both pickups really reverse the player. Holding through the second prompt cannot finish the lesson; idle time cannot start it. Practice still leaves records, achievements and currency untouched.

The square is visible before the first touch, the requested ring is highlighted, and the screen shows whether a hold or release has registered. Instructions explicitly explain that neither the dot nor the square needs to be tapped. The input listener covers the screen, including the padding around its content. Skip has a labelled touch target, and the completion button remains visible below the scrollable content at large text sizes.

Cancelled touches, focus loss, resizing and backgrounding clear held input. Touching the lesson after tabbing to Skip restores keyboard control. Multiple fingers and keyboard keys share one held state. The final recap repeats the direction reversal and introduces the red hazards.

## Verification

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub test/completion_ui_test.dart test/practice_keyboard_test.dart --reporter expanded`: 25 passing tests.
- `flutter test --no-pub --reporter expanded --dart-define=GENERATE_TUTORIAL_EVIDENCE=true`: 397 passing tests in the shared workspace, including gameplay oracle tests and the screenshot captures.
- Checked first-Play completion and skip, replay from Home, early-release recovery, screen edges and safe-area padding, text and arena touches, mixed inputs, keyboard focus, resizing, and background/resume behavior.
- Checked EN/DE layouts and completion at 200% text on a 256 × 600 viewport, plus landscape and tablet layouts. Inspected the phone, landscape and large-text renders.

## Renders

- [English: start](practice-hold-en.png), [holding](practice-holding-en.png), [release prompt](practice-release-en.png), [released](practice-released-en.png), [complete](practice-done-en.png).
- [German: start](practice-hold-de.png), [release prompt](practice-release-de.png), [complete](practice-done-de.png).
- [German landscape](practice-landscape-de.png), [200% text](practice-large-text-de.png), [200% completion](practice-large-text-done-de.png).

These are Flutter test renders. Physical-device touch feel, screen-reader operation and newcomer observations remain unverified. This tutorial task did not package or publish a release.
