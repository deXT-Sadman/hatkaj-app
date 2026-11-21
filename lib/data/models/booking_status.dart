enum BookingStatus {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  const BookingStatus(this.apiValue, this.label);

  /// The string the Laravel API uses.
  final String apiValue;
  final String label;

  static BookingStatus fromApi(String value) {
    return BookingStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => throw FormatException('Unknown booking status: $value'),
    );
  }

  /// Mirrors the API's transition rules so the UI only offers valid actions.
  List<BookingStatus> get allowedTransitions => switch (this) {
    pending => [confirmed, cancelled],
    confirmed => [completed, cancelled],
    completed || cancelled => const [],
  };
}
