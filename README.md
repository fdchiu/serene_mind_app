# Serene Mind

This directory contains the Flutter reimplementation of the Serene Mind Space meditation experience. It recreates the Vite/React app’s structure with native mobile widgets, persistent storage, and offline-friendly audio.

## Features

- Five tab navigation (Home, Meditate, Sounds, Videos, Progress) that mirrors the original routes
- Guided meditation flow with duration/mood selection, breathing timer, reflections, and streak tracking
- Local session storage powered by `shared_preferences`, including streaks, mood improvements, and weekly goals
- Ambient sound mixer built with `audioplayers` that loops curated soundscapes
- Curated YouTube video grid with search and deep links (launches YouTube externally)
- Modern glassmorphism styling, animated breathing orb, and daily inspirational quotes

## Local development

```bash
cd serene_mind_app
flutter run     # launches on the connected simulator/device
```

Use `flutter pub get` after changing dependencies. The project targets Flutter 3.6 (Dart 3.6) and uses Material 3 widgets plus Google Fonts.

## Directory highlights

- `lib/main.dart` – app bootstrap, theme, bottom navigation shell
- `lib/state/meditation_controller.dart` – persistence + derived stats logic
- `lib/screens/` – individual feature screens that parallel the original React routes
- `lib/widgets/` – reusable UI (breathing orb, ambient player, stats cards, etc.)

## Notes

- The YouTube screen opens videos externally via `url_launcher`; embedding requires extra platform setup.
- Ambient sounds stream from royalty-free Pixababy loops. Replace the URLs in `lib/data/ambient_sounds.dart` if you need offline assets.
