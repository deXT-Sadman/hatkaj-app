/// Every failure the UI can see, whether it came from the server or the network.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;

  /// Null when the request never reached the server (offline, timeout).
  final int? statusCode;

  /// Laravel's per-field validation messages, e.g. `{'customer_phone': ['...']}`.
  final Map<String, List<String>> fieldErrors;

  bool get isNetworkError => statusCode == null;

  /// The requested slot is already taken (HTTP 409).
  bool get isConflict => statusCode == 409;

  bool get isValidationError => statusCode == 422;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
