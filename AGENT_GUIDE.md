# AllTogether – Agent Entry Point

> **Read this file first before making any code or documentation changes.**

AllTogether is a Flutter mobile app that helps users track food consumption habits, generate AI-powered meal plans, scan receipts, and view nutrition + sustainability metrics.

---

## Quick Reference

| What you need               | Where to look                                |
| --------------------------- | -------------------------------------------- |
| Workflow rules (READ FIRST) | [docs/WORKFLOW.md](docs/WORKFLOW.md)         |
| App folder structure        | [docs/architecture/app-structure.md](docs/architecture/app-structure.md) |
| Data models                 | [docs/architecture/data-models.md](docs/architecture/data-models.md) |
| Claude API                  | [docs/api/claude-api.md](docs/api/claude-api.md) |
| Supabase                    | [docs/api/supabase.md](docs/api/supabase.md) |
| Google Places API           | [docs/api/google-places.md](docs/api/google-places.md) |
| Open Food Facts API         | [docs/api/open-food-facts.md](docs/api/open-food-facts.md) |
| Climatiq API                | [docs/api/climatiq.md](docs/api/climatiq.md) |
| Google ML Kit (OCR)         | [docs/api/google-ml-kit.md](docs/api/google-ml-kit.md) |
| Error handling patterns     | [docs/guides/error-handling.md](docs/guides/error-handling.md) |
| Caching strategy            | [docs/guides/caching.md](docs/guides/caching.md) |
| Initial setup (APIs, DB)    | [docs/SETUP.md](docs/SETUP.md)               |
| Non-technical overview      | [Planning.md](Planning.md)                   |
| Technical planning          | [planning-doc.md](planning-doc.md)           |

---

## Tech Stack at a Glance

| Layer                | Technology                          |
| -------------------- | ----------------------------------- |
| Mobile Framework     | Flutter (iOS + Android)             |
| UI Library           | shadcn_flutter                      |
| Backend              | Supabase (auth, DB, storage)        |
| AI / Meal Plans      | Claude API (claude-sonnet-4-6)      |
| Receipt OCR          | Google ML Kit (on-device)           |
| Store Locator        | Google Places API                   |
| Nutrition Data       | Open Food Facts API                 |
| Sustainability Data  | Climatiq API                        |
| Local Cache          | Hive or Isar                        |

---

## Build Order (V1)

Follow this order when implementing features:

1. Auth + preferences setup → Supabase
2. Finder + Claude API integration → core value prop
3. Receipt scanning pipeline → ML Kit → Open Food Facts → Supabase
4. Analytics page → visualize stored data
5. History page → surface purchase records
6. Polish + Google Places integration

---

## Key Rules for Agents

1. **Always read [docs/WORKFLOW.md](docs/WORKFLOW.md) before writing or editing any file.**
2. **Always consult the relevant API doc before calling any external service.**
3. **Never hardcode API keys** – use environment variables or Flutter `--dart-define`.
4. **Cache external API responses** where documented – see [docs/guides/caching.md](docs/guides/caching.md).
5. **Follow error handling patterns** in [docs/guides/error-handling.md](docs/guides/error-handling.md) for every API call.
6. **Place new files in the correct feature folder** – see [docs/architecture/app-structure.md](docs/architecture/app-structure.md).
