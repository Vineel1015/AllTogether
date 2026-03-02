# AllTogether – Claude Code Instructions

## Project Overview

AllTogether is a Flutter (iOS/Android) app for food habit tracking, AI meal planning, receipt scanning, and sustainability analytics.

- **Primary doc**: [AGENT_GUIDE.md](AGENT_GUIDE.md)
- **Workflow rules**: [docs/WORKFLOW.md](docs/WORKFLOW.md)

---

## Always Do

- Read `AGENT_GUIDE.md` at the start of every session.
- Read the relevant API doc before touching any service integration code.
- Place all new Dart files inside `app/lib/` following the feature-based structure.
- Use `const` constructors wherever possible in Flutter widgets.
- Handle every API call with try/catch and surface errors through the app's result pattern (`AppResult<T>`).
- Cache API responses per the caching guide — especially Claude and Open Food Facts responses.
- Use `snake_case` for Dart file names, `PascalCase` for class names.

## Never Do

- Never hardcode API keys, URLs, or credentials in Dart code.
- Never make raw HTTP calls outside of the `/services/` layer.
- Never regenerate a Claude meal plan if the user's preference fingerprint hasn't changed.
- Never store sensitive user data (tokens, passwords) in plain shared preferences — use `flutter_secure_storage`.
- Never commit `.env` files or files containing real API keys.

## Code Style

- Dart null safety is required on all new code.
- Prefer `async/await` over `.then()` chains.
- Keep widgets small — extract to separate files when a widget exceeds ~100 lines.
- Use `riverpod` for state management (preferred) unless the feature already uses another pattern.

## Environment Variables

All secrets are injected via `--dart-define` at build time:

```
SUPABASE_URL
SUPABASE_ANON_KEY
CLAUDE_API_KEY
GOOGLE_PLACES_API_KEY
CLIMATIQ_API_KEY
```

Access in Dart:
```dart
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
```

## File Naming Conventions

| Type              | Convention                          | Example                        |
| ----------------- | ----------------------------------- | ------------------------------ |
| Dart source file  | `snake_case.dart`                   | `meal_plan_service.dart`       |
| Widget file       | `snake_case_widget.dart`            | `meal_card_widget.dart`        |
| Model file        | `snake_case_model.dart`             | `food_item_model.dart`         |
| Service file      | `snake_case_service.dart`           | `claude_service.dart`          |
| Provider file     | `snake_case_provider.dart`          | `preferences_provider.dart`    |
| Test file         | `snake_case_test.dart`              | `claude_service_test.dart`     |

## Testing

- Unit tests go in `app/test/unit/`
- Widget tests go in `app/test/widget/`
- Run tests with `flutter test` from the `app/` directory.
- New service methods must have a corresponding unit test.
