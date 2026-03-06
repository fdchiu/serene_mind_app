# Repository Guidelines

## Project Structure & Module Organization
Serene Mind is a Flutter app with runtime code in `lib/`. Feature experiences live under `lib/screens/`, reusable UI stays in `lib/widgets/`, and shared logic is split between `lib/state/`, `lib/services/`, `lib/data/`, and `lib/models/`. App bootstrap, navigation shells, and theme glue stay in `lib/main.dart` and `lib/app_theme.dart`. Tests mirror this layout inside `test/` (for example, `lib/state/meditation_controller.dart` maps to `test/state/meditation_controller_test.dart`). Native hosts reside inside `android/`, `ios/`, `macos/`, `linux/`, `windows/`, and `web/`. Asset folders referenced in `pubspec.yaml` hold audio loops, imagery, and JSON presets—update the manifest whenever adding files.

## Build, Test, and Development Commands
- `flutter pub get` installs or refreshes packages after editing `pubspec.yaml`.
- `flutter run -d <device>` launches the full experience on a connected simulator or device for manual smoke tests.
- `flutter analyze` enforces the `flutter_lints` suite and repository-specific rules in `analysis_options.yaml`.
- `flutter test` runs all unit and widget suites; use `flutter test --coverage` before shipping behavioral changes.
- `flutter build <platform>` (e.g., `flutter build apk`) produces distributable artifacts for release validation.

## Coding Style & Naming Conventions
Indent with two spaces and favor small, composable widgets. Keep imports ordered as SDK, third-party, then local modules. Run `dart format .` or enable on-save formatting before committing. Widgets, classes, and enums use PascalCase, files and directories use snake_case, and constants remain in SCREAMING_SNAKE_CASE. Prefer `const` constructors, leverage null safety, and centralize repeated UI into `lib/widgets/` to avoid drift.

## Testing Guidelines
Tests rely on the Flutter test runner (`package:flutter_test/flutter_test.dart`). Organize specs with `group()` names that echo the file under test and suffix files with `_test.dart`. Cover meditation streak logic, ambient audio state machines, persistence helpers, and any regression-prone flows surfaced in `test/`. Capture new scenarios alongside bug fixes, and block pull requests on a green `flutter test`.

## Commit & Pull Request Guidelines
Commit subjects stay in present-tense imperative form (`Add focus session presets`) with optional ticket IDs in the body (`Refs #42`). Rebase onto `main`, run `flutter analyze` and `flutter test`, and include simulator screenshots for visible UI updates. Each PR description should summarize why the change is needed, highlight functional updates, call out migrations or new dependencies, and tag the teammate most familiar with the touched feature area.
