# AllTogether – App Folder Structure

> All application code lives in `app/`. The `docs/` directory is documentation only.

---

## Top-Level Layout

```
AllTogether/
├── AGENT_GUIDE.md          ← Start here (agent entry point)
├── CLAUDE.md               ← Claude Code instructions
├── Planning.md             ← Non-technical overview
├── planning-doc.md         ← Technical planning document
│
├── docs/                   ← All documentation
│   ├── WORKFLOW.md         ← Agent workflow rules
│   ├── api/                ← One file per external API
│   ├── architecture/       ← Data models, folder structure
│   └── guides/             ← Error handling, caching
│
└── app/                    ← Flutter application
    ├── lib/
    ├── test/
    ├── android/
    ├── ios/
    └── pubspec.yaml
```

---

## `app/lib/` Structure

```
app/lib/
│
├── main.dart               ← App entry point; Supabase init; provider scope
│
├── core/                   ← Shared, feature-agnostic code
│   ├── constants/
│   │   ├── api_constants.dart          ← Base URLs, endpoint paths
│   │   └── sustainability_constants.dart ← Water/land use fallback values
│   ├── models/
│   │   └── app_result.dart             ← AppResult<T> = AppSuccess | AppFailure
│   ├── utils/
│   │   ├── string_utils.dart           ← Normalization, abbreviation expansion
│   │   ├── cache_utils.dart            ← Hive/Isar helpers
│   │   └── crypto_utils.dart           ← SHA-256 fingerprint generation
│   └── widgets/
│       ├── loading_indicator.dart
│       └── error_banner.dart
│
├── services/               ← External API service layer (one file per API)
│   ├── claude_service.dart
│   ├── places_service.dart
│   ├── food_facts_service.dart
│   └── climatiq_service.dart
│
├── features/               ← Feature modules (one folder per screen/flow)
│   │
│   ├── auth/
│   │   ├── models/
│   │   │   └── app_user_model.dart
│   │   ├── services/
│   │   │   └── auth_service.dart       ← Supabase auth wrapper
│   │   ├── providers/
│   │   │   └── auth_provider.dart      ← Current user state
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   └── widgets/
│   │       └── auth_form_widget.dart
│   │
│   ├── customizations/
│   │   ├── models/
│   │   │   └── user_preferences_model.dart
│   │   ├── services/
│   │   │   └── preferences_service.dart  ← Supabase read/write for preferences
│   │   ├── providers/
│   │   │   └── preferences_provider.dart
│   │   ├── screens/
│   │   │   └── customizations_screen.dart
│   │   └── widgets/
│   │       ├── diet_type_selector.dart
│   │       └── allergy_selector.dart
│   │
│   ├── finder/
│   │   ├── models/
│   │   │   ├── meal_plan_model.dart
│   │   │   └── store_result_model.dart
│   │   ├── services/
│   │   │   └── meal_plan_service.dart    ← Orchestrates Claude + cache + Supabase
│   │   ├── providers/
│   │   │   ├── meal_plan_provider.dart
│   │   │   └── stores_provider.dart
│   │   ├── screens/
│   │   │   └── finder_screen.dart
│   │   └── widgets/
│   │       ├── meal_card_widget.dart
│   │       ├── shopping_list_widget.dart
│   │       └── store_card_widget.dart
│   │
│   ├── history/
│   │   ├── models/
│   │   │   ├── receipt_model.dart
│   │   │   ├── receipt_item_model.dart
│   │   │   └── food_item_model.dart
│   │   ├── services/
│   │   │   ├── ocr_service.dart          ← Google ML Kit text recognition
│   │   │   ├── receipt_parser_service.dart ← OCR text → ReceiptItem list
│   │   │   └── receipt_service.dart      ← Supabase read/write for receipts
│   │   ├── providers/
│   │   │   ├── receipt_provider.dart
│   │   │   └── scan_provider.dart
│   │   ├── screens/
│   │   │   ├── history_screen.dart
│   │   │   ├── receipt_detail_screen.dart
│   │   │   └── scan_screen.dart
│   │   └── widgets/
│   │       ├── receipt_list_item.dart
│   │       └── nutrition_row_widget.dart
│   │
│   └── analytics/
│       ├── models/
│       │   ├── nutrition_summary_model.dart
│       │   └── sustainability_summary_model.dart
│       ├── services/
│       │   └── analytics_service.dart    ← Aggregates data for charts
│       ├── providers/
│       │   └── analytics_provider.dart
│       ├── screens/
│       │   └── analytics_screen.dart
│       └── widgets/
│           ├── nutrition_chart_widget.dart
│           ├── sustainability_chart_widget.dart
│           └── score_badge_widget.dart
│
└── shared/                 ← Shared UI elements used across features
    ├── bottom_nav_widget.dart
    └── app_scaffold.dart
```

---

## `app/test/` Structure

```
app/test/
├── unit/
│   ├── services/
│   │   ├── claude_service_test.dart
│   │   ├── food_facts_service_test.dart
│   │   └── places_service_test.dart
│   └── features/
│       ├── auth/
│       ├── finder/
│       ├── history/
│       └── analytics/
└── widget/
    └── features/
        ├── finder/
        └── history/
```

---

## Rules for File Placement

| Code type                      | Location                                         |
| ------------------------------ | ------------------------------------------------ |
| External API call              | `app/lib/services/<api>_service.dart`            |
| Business logic for a feature   | `app/lib/features/<feature>/services/`           |
| Riverpod state provider        | `app/lib/features/<feature>/providers/`          |
| Dart data model                | `app/lib/features/<feature>/models/`             |
| Screen (full page)             | `app/lib/features/<feature>/screens/`            |
| Widget (reusable component)    | `app/lib/features/<feature>/widgets/`            |
| Cross-feature reusable widget  | `app/lib/shared/`                                |
| Constants                      | `app/lib/core/constants/`                        |
| Utility functions              | `app/lib/core/utils/`                            |

---

## Key Files to Create First

When starting implementation, create these files in order:

1. `app/lib/core/models/app_result.dart` — error handling foundation
2. `app/lib/core/constants/api_constants.dart` — base URLs
3. `app/lib/features/auth/services/auth_service.dart` — first feature
4. `app/lib/services/claude_service.dart` — core value prop
