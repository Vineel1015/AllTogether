# AllTogether – Agent Workflow Guide

> **Agents must read this document before making any code or documentation change.**

---

## 1. Before You Write Anything

Follow this checklist every time:

- [ ] Read [AGENT_GUIDE.md](../AGENT_GUIDE.md) for the full project map.
- [ ] Identify which feature you are working on (`auth`, `finder`, `analytics`, `history`, `customizations`).
- [ ] Read the relevant API doc(s) in `docs/api/` for any external service you will touch.
- [ ] Check [docs/architecture/app-structure.md](architecture/app-structure.md) to confirm the correct file location.
- [ ] Check [docs/architecture/data-models.md](architecture/data-models.md) if you are reading or writing data.
- [ ] Review [docs/guides/error-handling.md](guides/error-handling.md) before writing any service method.
- [ ] Review [docs/guides/caching.md](guides/caching.md) before making any external API call.

---

## 2. Making Code Changes

### New Feature

1. Create the feature folder under `app/lib/features/<feature_name>/`.
2. Create sub-folders: `models/`, `services/`, `providers/`, `screens/`, `widgets/`.
3. Implement the data model first, then the service, then the provider, then the UI.
4. Write unit tests in `app/test/unit/<feature_name>/` alongside implementation.

### Editing Existing Code

1. Read the file before editing — never guess structure.
2. Do not change behavior outside the scope of your task.
3. If you change a model, check every service and provider that uses it.
4. If you change a service method signature, update all call sites.

### Adding a New API Integration

1. Read the API doc in `docs/api/`.
2. Create `app/lib/services/<api_name>_service.dart`.
3. All HTTP calls go through the service — no direct HTTP calls from UI or providers.
4. Wrap every call in the `AppResult<T>` pattern (see error handling guide).
5. Add caching as documented in the API doc and caching guide.
6. Store the API key name in `CLAUDE.md` environment variables section.

---

## 3. Making Documentation Changes

- Update the relevant `docs/api/*.md` if an API integration changes.
- Update `docs/architecture/data-models.md` if a Supabase schema or local model changes.
- Update `docs/architecture/app-structure.md` if new folders are added.
- Never delete documentation without replacing it with updated content.

---

## 4. Feature Workflow Map

```
User Action
    │
    ▼
Screen (app/lib/features/<feature>/screens/)
    │  calls
    ▼
Provider (app/lib/features/<feature>/providers/)   ◄── Riverpod state
    │  calls
    ▼
Service (app/lib/services/ or features/<feature>/services/)
    │  calls
    ├──► Supabase (auth, DB reads/writes)
    ├──► Claude API (meal plan generation)
    ├──► Google Places API (store locator)
    ├──► Open Food Facts API (nutrition lookup)
    ├──► Climatiq API (sustainability data)
    └──► Google ML Kit (on-device OCR – no network)
    │
    ▼
AppResult<T>  (Success | Failure)
    │
    ▼
Provider updates state
    │
    ▼
Screen rebuilds UI
```

---

## 5. API Call Decision Tree

Before calling any external API, ask:

```
Is the data already in local cache (Hive/Isar)?
├── YES → return cached data, skip API call
└── NO  →
        Is the user offline?
        ├── YES → return cached data or AppFailure(offline)
        └── NO  →
                Make API call
                ├── SUCCESS → store in cache → return AppSuccess(data)
                └── FAILURE →
                            Is it a rate limit (429)?
                            ├── YES → exponential backoff, retry up to 3x
                            └── NO  →
                                    Is it a server error (5xx)?
                                    ├── YES → retry once after 2s, then fail
                                    └── NO  → return AppFailure(error)
```

---

## 6. Git / Commit Conventions

- Branch naming: `feature/<name>`, `fix/<name>`, `docs/<name>`
- Commit message format: `type(scope): short description`
  - `feat(finder): add Claude meal plan generation`
  - `fix(auth): handle Supabase session expiry`
  - `docs(api): add Climatiq rate limit notes`
- Never commit API keys, `.env` files, or `*.g.dart` generated files.
- Run `flutter test` before committing service or model changes.

---

## 7. Critical Rules Summary

| Rule                                              | Why                                          |
| ------------------------------------------------- | -------------------------------------------- |
| No API keys in code                               | Security                                     |
| No HTTP calls outside service layer               | Maintainability, testability                 |
| Cache Claude responses per preference fingerprint | Cost — Claude is billed per token            |
| Cache Open Food Facts responses                   | Performance + politeness (no key required)   |
| Exponential backoff on 429 errors                 | Avoid getting banned / rate limited          |
| AppResult<T> wraps every service return           | Consistent error surface to the UI           |
| Row Level Security on all Supabase tables         | Users can only access their own data         |
