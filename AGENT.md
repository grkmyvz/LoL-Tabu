Build a clean, production-quality Flutter mobile app called “LoL Tabu” for Android and iOS. Keep the implementation simple and readable, without unnecessary packages or overengineering.

The app must have two screens:

1. Home Screen
- Visually impressive but minimal League-inspired dark design.
- App title, language selector, round duration selector, and a prominent Start Game button.
- Default language: English.
- Support Turkish and English with an architecture that allows adding more languages later.

2. Game Screen
- Show one random champion card at a time.
- Use the champion loading image from this URL pattern:
  https://ddragon.leagueoflegends.com/cdn/img/champion/loading/{ChampionSlug}_0.jpg
- Display the champion name over the top of the image.
- Display exactly five forbidden words vertically near the bottom.
- Include countdown timer, start/pause/reset controls, and a Next Champion button.
- Avoid showing the same champion twice consecutively.
- Add smooth, lightweight card transitions.
- Handle loading and network errors with a placeholder.

Data architecture:
- Do not store all champions in one JSON file.
- Create separate JSON files for every champion and language.
- Use this structure:

assets/data/en/champions/ahri.json
assets/data/en/champions/garen.json
assets/data/tr/champions/ahri.json
assets/data/tr/champions/garen.json
assets/data/en/index.json
assets/data/tr/index.json

Each champion JSON should contain:

{
  "id": "ahri",
  "name": "Ahri",
  "imageSlug": "Ahri",
  "forbiddenWords": ["Fox", "Charm", "Orb", "Nine Tails", "Mage"]
}

The language-specific index.json should list the champion JSON paths.

Create localized JSON data for these 10 demo champions:
Ahri, Garen, Lux, Yasuo, Jinx, Teemo, Zed, Ashe, Darius, Morgana.

Project requirements:
- Use current stable Flutter and Dart.
- Use Material 3.
- Use Navigator or a lightweight routing solution; do not add complex architecture.
- Separate models, repositories/services, screens, widgets, theme, localization, and game state.
- Prefer built-in Flutter state management unless another package provides a clear benefit.
- Load champion data from local assets.
- Preload the next champion image where practical.
- Design primarily for portrait phones and make the UI responsive.
- Configure pubspec.yaml correctly for all JSON assets.
- Include brief setup and run instructions in README.md.
- Ensure `flutter analyze` passes without errors.