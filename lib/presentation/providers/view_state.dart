import '../../core/network/api_exception.dart';

/// What a list screen should currently show.
enum ViewState { loading, error, empty, success }

/// Turns any thrown object into text that is safe to show to the user.
String describeError(Object error) {
  if (error is ApiException) return error.message;
  return 'Unexpected response from the server.';
}
