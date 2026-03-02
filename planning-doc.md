# AllTogether – V1 Technical Planning Document

## Overview

AllTogether is a mobile application that helps users track, analyze, and improve their food consumption habits. It connects dietary preferences to personalized meal plans, nearby store locations, receipt scanning, and sustainability metrics — making healthy and eco-conscious eating easy and actionable.

---

## Core Value Proposition

> "Know what to buy, where to buy it, and what impact it has — on your body and the planet."

---

## Tech Stack

| Layer                | Technology                               |
| -------------------- | ---------------------------------------- |
| Mobile Framework     | Flutter (cross-platform iOS & Android)   |
| UI Library           | shadcn_flutter                           |
| Backend              | Supabase (auth, database, storage)       |
| AI / Recommendations | Claude API (meal plan generation)        |
| Receipt Scanning     | Google ML Kit (on-device OCR)            |
| Store Locator        | Google Places API                        |
| Nutrition Data       | Open Food Facts API (free & open source) |
| Sustainability Data  | climatiq.io API or custom dataset        |

---

## User Flows

### 1. Onboarding Flow

```
Launch App → Sign Up / Login → Dietary Preferences Setup → Home Dashboard
```

### 2. Meal Plan Flow

```
Finder Tab → Generate Plan (based on preferences) → View Weekly Meal Plan
→ View Nearby Stores for Each Item → Export / Save Plan
```

### 3. Receipt Scan Flow

```
Scan Receipt (camera) → OCR extracts items → Match to food database
→ Store in purchase history → Display nutrition + sustainability metrics
```

### 4. Analytics Flow

```
Analytics Tab → View nutrition trends (calories, protein, carbs, fat)
→ View sustainability impact (water usage, CO₂, land use)
→ Compare week-over-week
```

---

## Pages & Screens

### 1. Login Page

- Email/username + password authentication
- Sign up with basic info (name, email, password)
- "Forgot password" flow
- Supabase Auth handles sessions and tokens

### 2. Customizations Page

User inputs that drive all recommendations:

- **Diet type** – omnivore, vegetarian, vegan, pescatarian
- **Health goal** – lose weight, gain weight, maintain, build muscle
- **Diet style** – standard, keto, high-protein, low-carb, Mediterranean
- **Allergies / intolerances** – gluten, dairy, nuts, soy, shellfish
- **Household size** – number of people the plan is for
- **Budget** – weekly grocery budget range

### 3. Finder (Meal Plan Generator)

- "Generate My Plan" button triggers Claude API call with user preferences as context
- Displays a 7-day meal plan (breakfast, lunch, dinner, snacks)
- Each meal links to required ingredients
- Ingredient list aggregated into a master shopping list
- "Find Nearby Stores" button queries Google Places API for grocery stores
- Export options: copy to clipboard, share as text

### 4. User Analytics Page

Displays metrics pulled from scanned receipt history:

**Nutrition Panel**

- Daily avg: calories, protein, carbs, fat, fiber
- Weekly trend charts (line graph)
- Goal progress bars (e.g. protein target)

**Sustainability Panel**

- CO₂ equivalent of purchases (kg CO₂e)
- Water usage (liters)
- Land use (m²)
- Sustainability score (color-coded: green / yellow / red)
- Week-over-week comparison

### 5. History Page

- Chronological list of scanned receipts
- Each receipt entry shows: date, store, total items, total spend
- Tap to expand → full item list with nutrition + sustainability per item
- Filter by date range or store

---

## Data Models

### User

```
id, email, name, created_at
```

### UserPreferences

```
user_id, diet_type, health_goal, diet_style, allergies[], household_size, budget_range
```

### Receipt

```
id, user_id, scanned_at, store_name, raw_ocr_text, total_amount
```

### ReceiptItem

```
id, receipt_id, name, quantity, price, matched_food_id
```

### FoodItem (cached from Open Food Facts)

```
id, name, barcode, calories, protein, carbs, fat, fiber,
co2_per_kg, water_per_kg, land_per_kg, category
```

### MealPlan

```
id, user_id, created_at, plan_data (JSON), week_start_date
```

---

## AI Integration (Claude API)

The meal plan generator will send a structured prompt to Claude:

**Input context sent to Claude:**

- Diet type, health goal, diet style
- Allergies and intolerances
- Household size and budget
- Any previously purchased items (optional, for variety)

**Expected output from Claude:**

- 7-day meal plan in structured JSON
- Each meal with: name, ingredients, rough calories, prep time
- Shopping list with estimated quantities

---

## Key Technical Challenges & Solutions

| Challenge                           | Solution                                                                                      |
| ----------------------------------- | --------------------------------------------------------------------------------------------- |
| OCR accuracy on receipts            | Google ML Kit on-device OCR + fuzzy string matching to food DB                                |
| Matching receipt text to food items | Levenshtein distance matching + manual correction option                                      |
| Sustainability data gaps            | Default to category-level averages when product-level data is unavailable                     |
| Offline support                     | Cache meal plans and last receipt locally using Hive or Isar                                  |
| API costs                           | Cache Claude responses per preference fingerprint; don't regenerate unless preferences change |

---

## V1 Scope (MVP)

### In Scope

- [x] Auth (login / signup)
- [x] Dietary preference setup
- [x] AI-generated weekly meal plan
- [x] Nearby store finder
- [x] Receipt scanning + OCR parsing
- [x] Nutrition metrics per purchase
- [x] Sustainability metrics per purchase
- [x] Purchase history

### Out of Scope (V2+)

- [ ] Social / community features
- [ ] Barcode scanning at point of purchase
- [ ] Integration with grocery delivery apps (Instacart, etc.)
- [ ] Wearable / health app sync (Apple Health, Google Fit)
- [ ] Carbon offset purchasing

---

## Suggested Build Order

1. **Auth + preferences setup** — get user data flowing into Supabase
2. **Finder + Claude integration** — core value prop, validate the AI output quality
3. **Receipt scanning pipeline** — OCR → item matching → storage
4. **Analytics page** — visualize stored data
5. **History page** — surface purchase records
6. **Polish + store finder** — Google Places integration, UI refinement
