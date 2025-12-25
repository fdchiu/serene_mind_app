# Repository Guidelines

## Project Structure & Module Organization
Flutter sources live in `lib/`, with feature screens under `lib/screens/`, shared UI in `lib/widgets/`, and state/data helpers in `lib/state/` and `lib/data/`. App bootstrap, themes, and navigation shells are centralized in `lib/main.dart`. Integration tests belong in `test/`, while platform-specific scaffolds reside inside `android/`, `ios/`, `macos/`, `linux/`, `windows/`, and `web/`. Audio, images, and JSON assets are declared in `pubspec.yaml` and loaded via the `assets/` directories referenced there.

## Build, Test, and Development Commands
- `flutter pub get` — Install updated dependencies after editing `pubspec.yaml`.
- `flutter run -d <device>` — Launch the full app on a simulator, emulator, or device for manual verification.
- `flutter analyze` — Run the Dart analyzer with the `flutter_lints` suite to catch style or API issues.
- `flutter test` — Execute all unit and widget tests inside `test/`.
- `flutter build <platform>` — Produce release artifacts (e.g., `flutter build apk` or `flutter build web`) before publishing.

## Coding Style & Naming Conventions
Follow Dart’s default 2-space indentation and keep imports ordered: SDK, third-party, then local. Run `dart format .` (or let IDE on-save formatting) to ensure consistent layout before committing. Class and widget names use PascalCase, files and directories use snake_case, and constants belong in upper snake case. Prefer `const` constructors and widgets where possible, and extract reusable UI into `lib/widgets/` to avoid duplication. Stick to null safety and leverage the analyzer to resolve warnings proactively.

## Testing Guidelines
Add `*_test.dart` files beneath `test/`, mirroring the directory of the code under test (e.g., `lib/state/meditation_controller.dart` → `test/state/meditation_controller_test.dart`). Write widget tests using `WidgetTester` for UI flows and standard `test()`/`group()` for state logic. Target meaningful coverage on meditation streaks, ambient player state, and persistence helpers, and run `flutter test --coverage` before opening a PR when behavior changes are significant.

## Commit & Pull Request Guidelines
Use present-tense, imperative commit subjects (`Add relaxation timer presets`) and keep bodies concise. Reference ticket IDs or issue numbers when available (`Refs #42`). Each pull request should summarize the motivation, list functional changes, attach simulator screenshots for UI tweaks, and note any new dependencies or migration steps. Rebase onto the latest `main`, verify `flutter analyze` and `flutter test` locally, and request review from a teammate most familiar with the touched feature area.
