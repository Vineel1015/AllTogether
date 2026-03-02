// String normalization utilities for receipt item matching.

/// Common grocery abbreviations expanded to their full forms.
///
/// Keys are lowercase; the normalization pipeline lowercases input before
/// expanding, so this map is case-insensitive in practice.
const _abbreviations = <String, String>{
  // Original abbreviations
  'org': 'organic',
  'whl': 'whole',
  'chkn': 'chicken',
  'brkfst': 'breakfast',
  'veg': 'vegetable',
  'fr': 'fresh',
  'nat': 'natural',
  'orig': 'original',
  // Additional grocery abbreviations from ML Kit doc
  'mlk': 'milk',
  'brst': 'breast',
  'og': 'organic',
  'lf': 'low fat',
  'ff': 'fat free',
  'spnch': 'spinach',
  'tmat': 'tomato',
  'bnls': 'boneless',
  'sknls': 'skinless',
  'grnd': 'ground',
  'frz': 'frozen',
  'rte': 'ready to eat',
  'ylw': 'yellow',
  'grn': 'green',
  'broc': 'broccoli',
};

/// Normalizes an OCR receipt item name for Open Food Facts lookup.
///
/// - Lowercases the input
/// - Strips leading/trailing whitespace and punctuation
/// - Expands known abbreviations
String normalizeItemName(String raw) {
  var result = raw.trim().toLowerCase();
  // Remove trailing punctuation from OCR noise
  result = result.replaceAll(RegExp(r'[^\w\s]'), ' ');
  // Collapse whitespace
  result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
  // Expand abbreviations (whole-word match)
  for (final entry in _abbreviations.entries) {
    result = result.replaceAll(
      RegExp('\\b${entry.key}\\b'),
      entry.value,
    );
  }
  return result;
}

/// Maps a user-facing error code to a friendly message shown in the UI.
String toUserMessage(String? code) => switch (code) {
      'offline' => 'No internet connection. Check your network and try again.',
      'timeout' => 'The request took too long. Please try again.',
      '429' => 'We\'re experiencing high demand. Please try again in a moment.',
      '401' => 'Authentication error. Please sign in again.',
      'auth_error' => 'Authentication failed. Please check your credentials.',
      'auth_expired' => 'Session expired. Please sign in again.',
      'service_auth_error' =>
        'Meal plan service authentication failed. Please check the Claude API key on Supabase.',
      'service_config_error' =>
        'Meal plan service is not configured. Please add the CLAUDE_API_KEY secret to your Supabase project.',
      'ocr_failed' => 'Receipt scan failed. Please try again with better lighting.',
      'no_text_detected' =>
        'No text was found on the receipt. Please retake the photo.',
      'meal_plan_parse_error' =>
        'Could not process the meal plan. Please try generating again.',
      _ => 'Something went wrong. Please try again.',
    };
