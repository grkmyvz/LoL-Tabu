# LoL Tabu

A Flutter party game inspired by League champion taboo rounds.

## Features

- Three supported languages: Turkish (`tr`), English (`en`), Chinese (`zh`)
- Local JSON data model with:
	- Global champion metadata in `assets/data/global/champions/`
	- Localized forbidden words in `assets/data/<lang>/champions/`
- Round timer with Start/Pause/Resume, Next, and Reset controls
- Round-finished overlay and lock behavior for next champion
- Optional random non-default skin image usage

## Run

1. Install Flutter.
2. Run `flutter pub get`.
3. Start the app with `flutter run`.

## Quality Checks

- Static analysis: `flutter analyze`
- Tests: `flutter test`
- Data audit: `dart run tool/audit_champion_data.dart --languages en,tr,zh`
- Generate runtime bundles: `dart run tool/generate_champion_bundles.dart`

## Data Structure

- Master champion ID list: `assets/data/global/champions.json`
- Global champion index: `assets/data/global/index.json`
- Global champion files: `assets/data/global/champions/<id>.json`
- Local indexes: `assets/data/en/index.json`, `assets/data/tr/index.json`, `assets/data/zh/index.json`
- Local champion files: `assets/data/<lang>/champions/<id>.json`
- Runtime global bundle: `assets/data/global/champion_bundle.json`
- Runtime localized bundles: `assets/data/en/champion_bundle.json`, `assets/data/tr/champion_bundle.json`, `assets/data/zh/champion_bundle.json`

## Project Structure

- Home screen with language and round duration selection.
- Game screen with champion cards, forbidden words, countdown timer, and controls.
- About screen with localized content.
