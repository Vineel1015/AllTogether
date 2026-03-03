import 'meal_model.dart';

/// Hardcoded catalog of preset meals available to all users.
const List<Meal> presetMeals = [
  // ── Breakfast ──────────────────────────────────────────────────────────
  Meal(
    id: 'preset_b1',
    name: 'Overnight Oats',
    ingredients: ['rolled oats', 'milk', 'Greek yogurt', 'honey', 'berries'],
    calories: 380,
    prepMinutes: 5,
    isPreset: true,
  ),
  Meal(
    id: 'preset_b2',
    name: 'Scrambled Eggs & Toast',
    ingredients: ['eggs', 'butter', 'whole-wheat bread', 'salt', 'pepper'],
    calories: 320,
    prepMinutes: 10,
    isPreset: true,
  ),
  Meal(
    id: 'preset_b3',
    name: 'Avocado Toast with Egg',
    ingredients: ['avocado', 'sourdough bread', 'egg', 'lemon juice', 'chili flakes'],
    calories: 400,
    prepMinutes: 10,
    isPreset: true,
  ),

  // ── Lunch ──────────────────────────────────────────────────────────────
  Meal(
    id: 'preset_l1',
    name: 'Grilled Chicken Salad',
    ingredients: ['chicken breast', 'mixed greens', 'cherry tomatoes', 'cucumber', 'olive oil'],
    calories: 430,
    prepMinutes: 15,
    isPreset: true,
  ),
  Meal(
    id: 'preset_l2',
    name: 'Turkey & Veggie Wrap',
    ingredients: ['turkey slices', 'whole-wheat tortilla', 'lettuce', 'tomato', 'mustard'],
    calories: 370,
    prepMinutes: 5,
    isPreset: true,
  ),
  Meal(
    id: 'preset_l3',
    name: 'Lentil Soup',
    ingredients: ['red lentils', 'onion', 'carrots', 'cumin', 'vegetable broth'],
    calories: 290,
    prepMinutes: 30,
    isPreset: true,
  ),
  Meal(
    id: 'preset_l4',
    name: 'Quinoa Buddha Bowl',
    ingredients: ['quinoa', 'chickpeas', 'roasted sweet potato', 'spinach', 'tahini dressing'],
    calories: 520,
    prepMinutes: 25,
    isPreset: true,
  ),

  // ── Dinner ─────────────────────────────────────────────────────────────
  Meal(
    id: 'preset_d1',
    name: 'Baked Salmon with Veggies',
    ingredients: ['salmon fillet', 'broccoli', 'lemon', 'garlic', 'olive oil'],
    calories: 550,
    prepMinutes: 25,
    isPreset: true,
  ),
  Meal(
    id: 'preset_d2',
    name: 'Chicken Stir-Fry',
    ingredients: ['chicken breast', 'bell peppers', 'broccoli', 'soy sauce', 'garlic', 'ginger', 'rice'],
    calories: 620,
    prepMinutes: 20,
    isPreset: true,
  ),
  Meal(
    id: 'preset_d3',
    name: 'Pasta Primavera',
    ingredients: ['pasta', 'zucchini', 'cherry tomatoes', 'garlic', 'parmesan', 'olive oil'],
    calories: 580,
    prepMinutes: 20,
    isPreset: true,
  ),
  Meal(
    id: 'preset_d4',
    name: 'Black Bean Tacos',
    ingredients: ['black beans', 'corn tortillas', 'avocado', 'salsa', 'lime', 'cilantro'],
    calories: 490,
    prepMinutes: 15,
    isPreset: true,
  ),

  // ── Snacks ─────────────────────────────────────────────────────────────
  Meal(
    id: 'preset_s1',
    name: 'Apple with Peanut Butter',
    ingredients: ['apple', 'peanut butter'],
    calories: 200,
    prepMinutes: 2,
    isPreset: true,
  ),
  Meal(
    id: 'preset_s2',
    name: 'Greek Yogurt with Granola',
    ingredients: ['Greek yogurt', 'granola', 'honey'],
    calories: 230,
    prepMinutes: 2,
    isPreset: true,
  ),
  Meal(
    id: 'preset_s3',
    name: 'Hummus & Veggie Sticks',
    ingredients: ['hummus', 'carrots', 'celery', 'cucumber'],
    calories: 160,
    prepMinutes: 5,
    isPreset: true,
  ),
  Meal(
    id: 'preset_s4',
    name: 'Trail Mix',
    ingredients: ['almonds', 'walnuts', 'dried cranberries', 'dark chocolate chips'],
    calories: 250,
    prepMinutes: 0,
    isPreset: true,
  ),
];
