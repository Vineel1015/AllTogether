import 'package:flutter/material.dart';
import '../utils/string_utils.dart';

/// Displays a user-friendly error message with an optional retry button.
class ErrorBanner extends StatelessWidget {
  final String? message;

  /// When set, shows a "Retry" button that calls this callback.
  final VoidCallback? onRetry;

  const ErrorBanner({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final displayMessage =
        message != null ? message! : toUserMessage(null);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
