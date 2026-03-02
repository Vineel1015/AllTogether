# AllTogether – Initial Setup Checklist

Complete every step in this document before writing any application code.
Items marked ✅ require no action (free, no key needed).

---

## 1. Supabase

**URL:** https://supabase.com

### 1a. Create Project
1. Sign up / log in at supabase.com.
2. Click **New Project**.
3. Choose an organization (or create one).
4. Set project name: `alltogether`
5. Set a strong database password — **save it somewhere safe**.
6. Choose a region close to your users (e.g., `us-east-1`).
7. Click **Create new project** and wait ~2 minutes.

### 1b. Collect Credentials
Go to **Settings → API**:

| Variable           | Where to find it                          |
| ------------------ | ----------------------------------------- |
| `SUPABASE_URL`     | "Project URL" field                       |
| `SUPABASE_ANON_KEY`| "Project API keys" → `anon` `public` key  |

> **Do not copy the `service_role` key into your Flutter app.** It bypasses RLS.

### 1c. Enable Email Auth
1. Go to **Authentication → Providers**.
2. Confirm **Email** is enabled (it is by default).
3. Optionally disable "Confirm email" during development for faster testing.

### 1d. Create Database Tables

Open **SQL Editor** and run each block:

```sql
-- user_preferences
CREATE TABLE user_preferences (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  diet_type      TEXT NOT NULL DEFAULT 'omnivore',
  health_goal    TEXT NOT NULL DEFAULT 'maintain',
  diet_style     TEXT NOT NULL DEFAULT 'standard',
  allergies      TEXT[] DEFAULT '{}',
  household_size INT NOT NULL DEFAULT 1,
  budget_range   TEXT NOT NULL DEFAULT '$50-$100',
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

-- meal_plans
CREATE TABLE meal_plans (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  week_start_date  DATE NOT NULL,
  plan_data        JSONB NOT NULL,
  pref_fingerprint TEXT NOT NULL
);

-- receipts
CREATE TABLE receipts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  scanned_at   TIMESTAMPTZ DEFAULT NOW(),
  store_name   TEXT,
  raw_ocr_text TEXT NOT NULL,
  total_amount NUMERIC(10, 2),
  image_url    TEXT
);

-- receipt_items
CREATE TABLE receipt_items (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_id      UUID NOT NULL REFERENCES receipts(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  raw_name        TEXT NOT NULL,
  quantity        NUMERIC DEFAULT 1,
  price           NUMERIC(10, 2),
  matched_food_id TEXT
);
```

### 1e. Enable Row Level Security

Run this in the SQL Editor after creating tables:

```sql
-- Enable RLS on all tables
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plans       ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipts         ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipt_items    ENABLE ROW LEVEL SECURITY;

-- user_preferences policies
CREATE POLICY "Users manage own preferences" ON user_preferences
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- meal_plans policies
CREATE POLICY "Users manage own meal plans" ON meal_plans
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- receipts policies
CREATE POLICY "Users manage own receipts" ON receipts
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- receipt_items: access via parent receipt ownership
CREATE POLICY "Users manage own receipt items" ON receipt_items
  USING (
    EXISTS (
      SELECT 1 FROM receipts
      WHERE receipts.id = receipt_items.receipt_id
        AND receipts.user_id = auth.uid()
    )
  );
```

### 1f. Create Storage Bucket
1. Go to **Storage → New bucket**.
2. Name: `receipts`
3. Set to **Private** (users should only access their own images).
4. In **Storage → Policies**, add:

```sql
-- Allow users to upload to their own folder
CREATE POLICY "Users upload own receipts"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'receipts' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to read their own receipts
CREATE POLICY "Users read own receipts"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'receipts' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

---

## 2. Google Cloud Console (Places API)

**URL:** https://console.cloud.google.com

### 2a. Create Project
1. Click the project dropdown at the top → **New Project**.
2. Name: `AllTogether`
3. Click **Create**.

### 2b. Enable Billing
> Required to use the Places API. Google gives $200 free credit/month — you won't be charged for normal V1 usage.

1. Go to **Billing** in the sidebar.
2. Link or create a billing account.

### 2c. Enable APIs
Go to **APIs & Services → Library** and enable:

| API                     | Why needed                        |
| ----------------------- | --------------------------------- |
| **Places API**          | Nearby grocery store search       |
| **Maps SDK for Android**| Required for Places on Android    |
| **Maps SDK for iOS**    | Required for Places on iOS        |

Search each by name and click **Enable**.

### 2d. Create API Key
1. Go to **APIs & Services → Credentials**.
2. Click **+ Create Credentials → API key**.
3. Copy the key — this is your `GOOGLE_PLACES_API_KEY`.

### 2e. Restrict the API Key (Important)
Click the key → **Edit**:

**Application restrictions:**
- Select **Android apps** → add your app's package name (e.g., `com.yourname.alltogether`) + SHA-1 fingerprint.
- Add iOS restriction with your bundle ID (e.g., `com.yourname.alltogether`).
- If testing on a device before you have package names, temporarily set to **None** and add restrictions before release.

**API restrictions:**
- Select **Restrict key**.
- Choose: Places API, Maps SDK for Android, Maps SDK for iOS.

Click **Save**.

---

## 3. Anthropic (Claude API)

**URL:** https://console.anthropic.com

### Steps
1. Sign up / log in.
2. Go to **API Keys → Create Key**.
3. Name it `alltogether-dev`.
4. Copy the key — this is your `CLAUDE_API_KEY`.
5. Check **Usage** tab to monitor your tier and remaining limits.

> Default new accounts start on the **Free tier** (5 RPM). Upgrade to Build tier for higher limits when testing meal plan generation.

---

## 4. Climatiq

**URL:** https://climatiq.io

### Steps
1. Sign up at climatiq.io.
2. Go to **Dashboard → API Keys → Create API Key**.
3. Copy the key — this is your `CLIMATIQ_API_KEY`.
4. Free tier: 1,000 estimates/month — sufficient for V1 with caching.

---

## 5. Open Food Facts ✅

**No setup required.**
- No API key needed.
- No account needed.
- Free and open source.
- Add your app name as a `User-Agent` header in requests (see [docs/api/open-food-facts.md](api/open-food-facts.md)).

---

## 6. Google ML Kit ✅

**No console setup required.**
- On-device only — no network calls, no API key.
- Configured entirely through the Flutter package and `pubspec.yaml`.
- See [docs/api/google-ml-kit.md](api/google-ml-kit.md) for model bundling instructions.

---

## 7. Store All Keys Securely

The `.env` file and `.gitignore` are pre-created at the repo root.

### Fill in your keys

Open [`.env`](../.env) at the repo root and replace each placeholder value.

```
AllTogether/
├── .env             ← fill this in (gitignored, never committed)
├── .env.example     ← committed reference showing required variable names
└── .gitignore       ← already protects .env
```

### Run the app

A script handles loading `.env` and passing every key as `--dart-define`:

```bash
# From the repo root:
bash app/scripts/run_dev.sh

# With a specific device:
bash app/scripts/run_dev.sh -d "iPhone 15"

# Release build:
bash app/scripts/run_dev.sh --release
```

The script validates that all required variables are set before launching Flutter, and prints a clear error if any are missing or still have placeholder values.

---

## Setup Completion Checklist

- [ ] Supabase project created, URL + anon key copied
- [ ] Supabase: 4 tables created (`user_preferences`, `meal_plans`, `receipts`, `receipt_items`)
- [ ] Supabase: RLS enabled + policies applied on all 4 tables
- [ ] Supabase: `receipts` storage bucket created with access policies
- [ ] Google Cloud: project created, billing enabled
- [ ] Google Cloud: Places API + Maps SDKs enabled
- [ ] Google Cloud: API key created and restricted
- [ ] Anthropic: API key created
- [ ] Climatiq: API key created
- [ ] `.env` filled in with real values (file is pre-created and gitignored)
- [ ] `bash app/scripts/run_dev.sh` runs without errors
