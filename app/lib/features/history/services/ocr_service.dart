import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../core/models/app_result.dart';

/// On-device OCR service using Google ML Kit Text Recognition.
///
/// No network call — all processing happens locally on the device.
/// The caller is responsible for providing a valid image file path.
class OcrService {
  /// Extracts all text from the image at [imagePath].
  ///
  /// Returns [AppFailure('no_text_detected')] when the image yields no text.
  Future<AppResult<String>> extractText(String imagePath) async {
    final textRecognizer =
        TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        return const AppFailure(
          'No text was found in the image.',
          code: 'no_text_detected',
        );
      }

      return AppSuccess(recognizedText.text);
    } on Exception catch (e) {
      return AppFailure(
        'OCR failed: $e',
        code: 'ocr_failed',
      );
    } finally {
      // Always release ML Kit resources
      await textRecognizer.close();
    }
  }
}
