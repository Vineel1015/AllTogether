# Supabase – Integration Guide

## Purpose in AllTogether

Supabase provides:
- **Authentication** – email/password login, session management, JWT tokens.
- **Database** – PostgreSQL tables for all user data (preferences, receipts, meal plans, food items).
- **Storage** – receipt images uploaded after scanning.

---

## SDK

```yaml
# pubspec.yaml
supabase_flutter: ^2.x
```

Initialize once in `main.dart`:

```dart
await Supabase.initialize(
  url: String.fromEnvironment('SUPABASE_URL'),
  anonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

Access the client anywhere:

```dart
final supabase = Supabase.instance.client;
```

---

## Authentication

### Sign Up

```dart
final response = await supabase.auth.signUp(
  email: email,
  password: password,
  data: {'name': name},
);
```

### Sign In

```dart
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);
```

### Session Management

- Supabase Flutter SDK auto-refreshes JWT tokens.
- Listen to auth state changes:

```dart
supabase.auth.onAuthStateChange.listen((data) {
  final session = data.session;
  // update app state
});
```

### Current User

```dart
final user = supabase.auth.currentUser;   // null if not logged in
```

---

## Database – Tables & RLS

All tables use **Row Level Security (RLS)**. Every table has a `user_id` column referencing `auth.users.id`.

### RLS Policy Pattern (apply to every table)

```sql
-- Users can only select their own rows
CREATE POLICY "Users can view own data"
ON <table_name> FOR SELECT
USING (auth.uid() = user_id);

-- Users can only insert their own rows
CREATE POLICY "Users can insert own data"
ON <table_name> FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can only update their own rows
CREATE POLICY "Users can update own data"
ON <table_name> FOR UPDATE
USING (auth.uid() = user_id);
```

---

## Common Query Patterns

### Insert

```dart
await supabase.from('receipts').insert({
  'user_id': supabase.auth.currentUser!.id,
  'store_name': storeName,
  'scanned_at': DateTime.now().toIso8601String(),
});
```

### Select

```dart
final data = await supabase
    .from('receipt_items')
    .select()
    .eq('receipt_id', receiptId);
```

### Upsert (create or update)

```dart
await supabase.from('user_preferences').upsert({
  'user_id': userId,
  'diet_type': 'vegetarian',
  // ...
});
```

### Delete

```dart
await supabase.from('receipts').delete().eq('id', receiptId);
```

---

## Storage – Receipt Images

```dart
// Upload
final bytes = await imageFile.readAsBytes();
await supabase.storage
    .from('receipts')
    .uploadBinary('$userId/$receiptId.jpg', bytes);

// Get public URL
final url = supabase.storage
    .from('receipts')
    .getPublicUrl('$userId/$receiptId.jpg');
```

---

## Error Handling

The Supabase Flutter SDK throws `PostgrestException` for database errors and `AuthException` for auth errors.

```dart
try {
  final data = await supabase.from('receipts').select();
  return AppSuccess(data);
} on PostgrestException catch (e) {
  // e.code — PostgreSQL error code (e.g., '23505' = unique violation)
  // e.message — human-readable message
  return AppFailure(e.message, code: e.code);
} on AuthException catch (e) {
  return AppFailure(e.message);
} catch (e) {
  return AppFailure('Unexpected error: $e');
}
```

### Common PostgreSQL Error Codes

| Code  | Meaning                  | Action                                    |
| ----- | ------------------------ | ----------------------------------------- |
| 23505 | Unique constraint violation | Surface duplicate error to user        |
| 23503 | Foreign key violation    | Check referential integrity in code       |
| 42501 | Insufficient privilege   | RLS policy issue — check policy setup     |
| PGRST | PostgREST-level errors   | Check query syntax                        |

---

## Rate Limits (Free Tier)

| Resource          | Free Tier Limit                |
| ----------------- | ------------------------------ |
| Database          | 500 MB storage                 |
| File storage      | 1 GB                           |
| Bandwidth         | 5 GB / month                   |
| Auth users        | 50,000 monthly active users    |
| API requests      | 500 requests/second (soft)     |
| Realtime messages | 2 million / month              |

For V1 these limits are not a concern. Monitor usage in the Supabase dashboard.

---

## Environment Variables

```
SUPABASE_URL       → Project URL (e.g., https://xxxx.supabase.co)
SUPABASE_ANON_KEY  → Public anon key (safe to use in client apps)
```

**Do not use the service role key in the Flutter app.** The service role key bypasses RLS and must only be used in trusted server environments.

---

## Service Location

`app/lib/services/supabase_service.dart`

Auth-specific logic: `app/lib/features/auth/services/auth_service.dart`
