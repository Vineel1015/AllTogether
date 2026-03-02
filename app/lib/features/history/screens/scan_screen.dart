import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/string_utils.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../models/receipt_model.dart';
import '../providers/scan_provider.dart';

/// Launches the image picker immediately on open, then drives the scan pipeline.
///
/// On success: pops back to HistoryScreen (list auto-refreshes via provider
/// invalidation in [ScanNotifier]).
/// On error: shows an [ErrorBanner] with a retry option.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  @override
  void initState() {
    super.initState();
    // Defer until the first frame so the navigator context is stable
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickAndScan());
  }

  Future<void> _pickAndScan() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
    );

    if (!mounted) return;

    if (photo == null) {
      // User cancelled — just go back
      Navigator.pop(context);
      return;
    }

    await ref.read(scanNotifierProvider.notifier).scan(photo.path);
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanNotifierProvider);

    // Pop automatically on success
    ref.listen<AsyncValue<Receipt?>>(scanNotifierProvider, (_, next) {
      if (next is AsyncData<Receipt?> && next.value != null && mounted) {
        Navigator.pop(context);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: scanState.when(
        data: (_) => const LoadingIndicator(), // brief; listener pops
        loading: () => const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingIndicator(),
            SizedBox(height: 16),
            Text('Scanning receipt…'),
          ],
        ),
        error: (e, _) {
          final code = _extractCode(e.toString());
          return ErrorBanner(
            message: toUserMessage(code),
            onRetry: _pickAndScan,
          );
        },
      ),
    );
  }

  /// Extracts the bracketed error code from `[code] message` format.
  String? _extractCode(String errorMessage) {
    final match = RegExp(r'^\[(.+?)\]').firstMatch(errorMessage);
    return match?.group(1);
  }
}
