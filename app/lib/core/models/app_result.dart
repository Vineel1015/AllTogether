/// Core result type used by every service method.
///
/// Forces callers to handle both success and failure paths without
/// scattering try/catch throughout providers and screens.
sealed class AppResult<T> {
  const AppResult();
}

final class AppSuccess<T> extends AppResult<T> {
  final T data;
  const AppSuccess(this.data);
}

final class AppFailure<T> extends AppResult<T> {
  final String message;

  /// API error code or HTTP status string (e.g. '429', '23505', 'offline').
  final String? code;

  /// Whether the UI should offer a retry button for this error.
  final bool isRetryable;

  const AppFailure(
    this.message, {
    this.code,
    this.isRetryable = false,
  });
}
