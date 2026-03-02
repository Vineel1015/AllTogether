# Planning Document: Finalizing Session 2 (Finder + Claude Integration)

## Objective
Verify the end-to-end integration of the Finder feature with Claude API via Supabase Edge Functions, resolve identified issues, and ensure a robust codebase for future sessions.

## Research Findings
- **Edge Function:** `generate-meal-plan` is deployed but uses a potentially invalid model name `claude-sonnet-4-6`.
- **ClaudeService:** Correctly handles `FunctionException` but relies on `Supabase.instance` which causes issues in unit tests.
- **MealPlanService:** Implements Hive caching and Supabase persistence.
- **Tests:** `meal_plan_service_test.dart` is currently failing due to uninitialized Supabase instance.
- **Status:** UI is built, but browser verification is pending.

## Strategy

### Phase 1: Fix Infrastructure & Tests
1.  **Fix Unit Tests:** Modify `meal_plan_service_test.dart` to properly mock or fake `SupabaseClient` to avoid `Supabase.instance` initialization errors.
2.  **Verify Edge Function:**
    - Update the Edge Function's Claude model to a valid one (e.g., `claude-3-5-sonnet-20240620`).
    - Test the Edge Function with `curl` to ensure it returns the expected JSON structure.
3.  **ClaudeService Improvement:**
    - Ensure `FunctionException.status` is handled safely.
    - Improve constructor to be more test-friendly.

### Phase 2: Functional Verification
1.  **End-to-End Test:** Run the Flutter app (in a simulated environment or by analyzing logs) to ensure the Finder screen correctly triggers the Edge Function and displays the meal plan.
2.  **Cache Verification:** Confirm Hive cache works as expected (hits on repeated requests, TTL handling).
3.  **Error Handling:** Verify that offline states and API errors are gracefully handled in the UI.

### Phase 3: Robustness & Maintenance
1.  **Logging:** Add more descriptive `debugPrint` or use a logging package for better traceability.
2.  **Documentation:** Update doc comments in services and models to reflect the final architecture.
3.  **Final Test Run:** Ensure all tests pass (`flutter test`).

## Implementation Plan (Step-by-Step)

1.  **Step 1:** Fix `app/test/unit/features/finder/meal_plan_service_test.dart`.
2.  **Step 2:** Update `supabase/functions/generate-meal-plan/index.ts` with valid model and improved logging.
3.  **Step 3:** Update `app/lib/services/claude_service.dart` for better testability and error handling.
4.  **Step 4:** Run all tests and verify success.
5.  **Step 5:** Final review of the Finder feature UI and provider logic.
