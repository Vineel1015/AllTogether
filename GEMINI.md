# AllTogether Gemini Workspace

This document provides a comprehensive guide for interacting with the AllTogether codebase using Gemini.

## Project Overview

AllTogether is a Flutter-based mobile application designed for:

*   **Food Habit Tracking:** Logging meals and dietary intake.
*   **AI Meal Planning:** Generating meal plans using AI (likely via the Claude API).
*   **Receipt Scanning:** Extracting food items from receipts.
*   **Sustainability Analytics:** Analyzing the environmental impact of food choices.

The app uses a modern Flutter stack:

*   **Backend:** [Supabase](https://supabase.io/) for authentication, database, and storage.
*   **State Management:** [Riverpod](https://riverpod.dev/) for managing application state.
*   **Local Cache:** [Hive](https://hivedb.dev/) for local key-value storage.
*   **API Integration:** Standard `http` package for communicating with the [Claude API](https://www.anthropic.com/claude) and other services.

## Building and Running

### Prerequisites

1.  **Flutter SDK:** Ensure you have the Flutter SDK installed.
2.  **Environment Variables:** The app requires API keys for Supabase, Claude, Google Places, and Climatiq.
    *   Copy the `.env.example` file to `.env`: `cp .env.example .env`
    *   Populate the `.env` file with your actual API keys. See `docs/SETUP.md` for more details.

### Development

To run the app in development mode, use the provided shell script. This script loads the necessary environment variables from your `.env` file.

```bash
bash app/scripts/run_dev.sh
```

You can pass additional flags to `flutter run`. For example, to run on a specific device:

```bash
bash app/scripts/run_dev.sh -d "iPhone 15"
```

### Testing

The project contains unit and widget tests. To run the tests, use the standard `flutter test` command from within the `app` directory:

```bash
cd app
flutter test
```

## Development Conventions

*   **State Management:** The project uses Riverpod for state management. State is exposed via `Providers`.
*   **Immutability:** Data models and states should be treated as immutable.
*   **Asynchronous Operations:** Asynchronous operations are handled using `Future`s and `Stream`s, with Riverpod's `AsyncValue` to manage loading and error states.
*   **Code Style:** The project follows the standard Dart and Flutter linting rules defined in `analysis_options.yaml`.
*   **Directory Structure:** The `lib` directory is organized by feature, with a `core` directory for shared utilities and a `shared` directory for common widgets.
*   **API Services:** API interactions are encapsulated within dedicated service classes (e.g., `ClaudeService`).
