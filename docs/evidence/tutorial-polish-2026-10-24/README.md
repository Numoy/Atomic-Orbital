# Tutorial and interface revision — 24 October 2026

This source revision responds to owner feedback that the tutorial was weak and parts of the interface looked generic. It follows the shop-free design. It is newer than the signed/uploaded build 43 and has not been packaged or distributed.

## Changes

- Practice teaches four actions using the existing practice engine: hold to the outer ring, release to the inner ring, collect an outer square, then release to collect an inner square after reversing. Both pickups really reverse the player. Idle time cannot complete a lesson. There is no timed fake hazard stage.
- The rings fill a square arena instead of shrinking the entire portrait game canvas. The player is labelled; the requested ring is highlighted. English and German prompts use a short action plus one explanation.
- Input works across the practice body, including the instructions. Cancelled touches, keyboard focus loss and backgrounding release held input. Backgrounding pauses the simulation/music and returning cannot fast-forward the lesson. Practice does not change records, achievements, statistics or the saved wallet.
- First Play and Settings retain their practice routes. Home Menu → How to play now opens the same interactive practice without starting a scored run afterward. The pause screen retains the rules reference.
- Progress uses plain achievement rows with truthful counts and dividers. Decorative gradient badge cards and ambiguous empty progress bars are removed from that screen. Platform achievement assets and achievement rules/IDs are unchanged by this revision. Statistics and Settings use the same restrained spacing, bounded line width and quieter copy.

## Verification

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub --reporter expanded`: **308 passing tests**. Includes original gameplay parity plus practice action requirements, two actual reversals, save isolation, pointer cancellation, keyboard/background handling, first-Play skip, home-menu replay and completion at 200% text on a 256 × 600 phone in both languages.
- Existing layout tests cover Progress, Settings and Practice at 256 × 600, 852 × 393 and 768 × 1024 with 200% text in EN/DE.
- `flutter test --no-pub test/tutorial_polish_evidence_test.dart --dart-define=GENERATE_TUTORIAL_EVIDENCE=true --reporter expanded`: three export tests pass, producing these sixteen source renders. EN/DE hold, release, collection, reversal and completion, Progress and Settings were inspected. Landscape and narrow large-text German practice were inspected separately. The narrow large-text layout scrolls as one page so the explanation remains readable and the arena stays accessible.

[English practice](practice-hold-en.png), [collection](practice-collect-en.png), [direction change](practice-reverse-en.png), [completion](practice-done-en.png), [Progress](progress-en.png), [Settings](settings-en.png).

[German practice](practice-hold-de.png), [landscape](practice-landscape-de.png), [200% text](practice-large-text-de.png), [Progress](progress-de.png), [Settings](settings-de.png).

These are Flutter widget renders, not physical-device screenshots or evidence of newcomer comprehension. No native release build, hardware session, store upload or newcomer observation was performed for this revision. Make a new candidate with a new build number and refreshed affected store images before distribution. Use the [acceptance sheet](../../acceptance/2.3.0.md) and the [updated roadmap](../../roadmap-after-completion.md) for the next work.
