# Box Fort 📦🐱

A cozy logic puzzle for Android and iOS: **every cat needs its own box.**

Drag cardboard boxes onto the floor so each box holds exactly one cat. Tap a box to turn it.
Boxes can't sit on furniture or overlap. Kittens (with a bow) only fit boxes of 3 cells or
less, and big cats need 5 cells or more.

- Endless campaign: levels are generated from their number, get bigger and trickier as
  you go, and every one is guaranteed solvable.
- Daily puzzle with a streak and a share button.
- Hints: 3 to start, 1 free every 5 levels, 2 more for watching a short video.
- Ads through Google AdMob: a banner on the puzzle screen, an interstitial every third level
  (never in the first 5 levels), and optional rewarded videos for hints. EU/UK consent is
  handled by Google's User Messaging Platform.

## Project layout

| Path | What's there |
| --- | --- |
| `lib/game/` | Puzzle rules (`game_state.dart`), level generator (`generator.dart`), seeded RNG |
| `lib/ui/` | Screens and the hand-drawn cat, box and room art (no image assets) |
| `lib/services/` | AdMob (`ads.dart`, IDs in `ad_ids.dart`) and saved progress |
| `test/` | Generator and rules tests (300 levels + 60 daily puzzles checked solvable) |
| `codemagic.yaml` | Cloud builds to Google Play and TestFlight |
| `docs/` | Launch checklist, store listing text, promotion plan, privacy policy |

## Run it

```sh
flutter pub get
flutter test
flutter run            # on a connected phone or emulator
flutter run -d chrome  # quick browser preview (no ads on web)
```

## Launching

Follow [docs/LAUNCH_CHECKLIST.md](docs/LAUNCH_CHECKLIST.md). Store text is in
[docs/STORE_LISTING.md](docs/STORE_LISTING.md) and the growth plan is in
[docs/PROMOTION.md](docs/PROMOTION.md).

Font: [Nunito](https://github.com/googlefonts/nunito), SIL Open Font License (`assets/fonts/OFL.txt`).
