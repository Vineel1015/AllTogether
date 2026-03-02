# Google ML Kit – Integration Guide

## Purpose in AllTogether

Google ML Kit's **Text Recognition** (OCR) is used in the **Receipt Scan** flow. The user takes a photo of a receipt, and ML Kit extracts all text on-device without any network call.

---

## Key Facts

- **On-device processing** — no API calls, no network required, works offline.
- **Free to use** — no API key, no billing.
- **No rate limits** — limited only by device capability.
- Privacy-preserving — receipt images never leave the device for OCR.

---

## SDK

```yaml
# pubspec.yaml
google_mlkit_text_recognition: ^0.x
```

---

## Implementation

### 1. Capture Image

Use `image_picker` to capture from camera:

```dart
final ImagePicker picker = ImagePicker();
final XFile? photo = await picker.pickImage(
  source: ImageSource.camera,
  imageQuality: 85,
  maxWidth: 1920,
);
```

### 2. Run OCR

```dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
final InputImage inputImage = InputImage.fromFilePath(photo.path);
final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

// Full raw text
String rawText = recognizedText.text;

// Structured access (blocks → lines → elements)
for (TextBlock block in recognizedText.blocks) {
  for (TextLine line in block.lines) {
    print(line.text);       // e.g., "WHOLE MILK 1GAL    $4.99"
    print(line.boundingBox); // position on image
  }
}

textRecognizer.close(); // Always close to free resources
```

### 3. Parse Line Items

Receipt lines typically follow this pattern:

```
ITEM_NAME    [QTY]    PRICE
```

Use this regex to extract price and item name:

```dart
// Matches: "WHOLE MILK 1GAL   4.99" or "WHOLE MILK   $4.99"
final lineRegex = RegExp(r'^(.+?)\s+\$?(\d+\.\d{2})\s*$');

for (String line in rawText.split('\n')) {
  final match = lineRegex.firstMatch(line.trim());
  if (match != null) {
    final itemName = match.group(1)!.trim();
    final price = double.parse(match.group(2)!);
    // add to items list
  }
}
```

---

## Text Normalization Pipeline

After extraction, normalize each item name before passing to Open Food Facts:

```
Step 1: lowercase
Step 2: remove trailing digits and weights (e.g., "1GAL", "16OZ", "2LB")
Step 3: expand common grocery abbreviations (see abbreviation map below)
Step 4: remove special characters, keep only letters and spaces
Step 5: trim whitespace
```

### Common Grocery Abbreviations

```dart
const Map<String, String> groceryAbbreviations = {
  'WHL':   'whole',
  'MLK':   'milk',
  'CHKN':  'chicken',
  'BRST':  'breast',
  'OG':    'organic',
  'LF':    'low fat',
  'FF':    'fat free',
  'SPNCH': 'spinach',
  'TMAT':  'tomato',
  'BNLS':  'boneless',
  'SKNLS': 'skinless',
  'GRND':  'ground',
  'FRZ':   'frozen',
  'RTE':   'ready to eat',
  'YLW':   'yellow',
  'GRN':   'green',
  'BROC':  'broccoli',
};
```

---

## Receipt Structure Heuristics

| Pattern                        | Meaning                          |
| ------------------------------ | -------------------------------- |
| Line matches `$X.XX` at end    | Likely a line item with price    |
| Line is all caps               | Likely a store/department header |
| Contains `SUBTOTAL` / `TOTAL`  | Footer line — skip               |
| Contains `TAX`                 | Tax line — skip                  |
| Contains `THANK YOU`           | Footer — stop parsing            |
| Negative price (e.g., `-1.00`) | Discount / coupon — track separately |

---

## Error Handling

ML Kit rarely throws errors, but handle these cases:

| Scenario                         | Action                                              |
| -------------------------------- | --------------------------------------------------- |
| Image too dark / blurry          | No text blocks returned — prompt user to retake     |
| `MlKitException`                 | Catch and show "Scan failed, please try again"      |
| Zero line items parsed           | Show "No items detected" with option to retry       |
| OCR text found but unparseable   | Store raw OCR text; show manual entry option        |

```dart
try {
  final recognized = await textRecognizer.processImage(inputImage);
  if (recognized.text.isEmpty) {
    return AppFailure('no_text_detected');
  }
  // parse...
} on Exception catch (e) {
  return AppFailure('ocr_failed: $e');
} finally {
  textRecognizer.close();
}
```

---

## Permissions Required

**Android** (`AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
```

**iOS** (`Info.plist`):

```xml
<key>NSCameraUsageDescription</key>
<string>AllTogether needs camera access to scan receipts.</string>
```

---

## Performance Notes

- OCR runs in ~200–500ms on modern devices.
- For best accuracy: ensure receipt is well-lit, flat, and fully in frame.
- ML Kit downloads the text recognition model on first use (~6 MB). Bundle it in the app to avoid first-run delays.

**Bundle model in app (recommended for production):**

In `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.mlkit.text_recognition'
```

In `ios/Podfile`:
```ruby
pod 'GoogleMLKit/TextRecognition', '~> 3.0'
```

---

## Service Location

`app/lib/features/history/services/ocr_service.dart`
