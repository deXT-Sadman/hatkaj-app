import 'package:flutter/foundation.dart';

import '../../data/models/booking.dart';
import '../../data/models/booking_status.dart';
import '../../data/repositories/booking_repository.dart';
import 'view_state.dart';

/// Numbers and upcoming bookings for the dashboard.
///
/// Counts come from each status query's `total`, so they stay correct
/// however many bookings exist (the lists themselves are paginated).
class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._repository);

  static const _upcomingLimit = 3;

  final BookingRepository _repository;

  ViewState _state = ViewState.loading;
  Map<BookingStatus, int> _counts = const {};
  List<Booking> _upcoming = const [];
  String? _errorMessage;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Booking> get upcoming => _upcoming;

  int countOf(BookingStatus status) => _counts[status] ?? 0;

  /// Reloads the numbers. Returns an error message if the request failed, otherwise null.
  /// Existing data stays visible when a refresh fails.
  Future<String?> refresh() async {
    final hadData = _state == ViewState.success;
    if (!hadData) {
      _state = ViewState.loading;
      notifyListeners();
    }

    try {
      final pending = await _repository.fetchBookings(
        status: BookingStatus.pending,
        perPage: 5,
      );
      final confirmed = await _repository.fetchBookings(
        status: BookingStatus.confirmed,
        perPage: 5,
      );
      final completed = await _repository.fetchBookings(
        status: BookingStatus.completed,
        perPage: 1,
      );
      final cancelled = await _repository.fetchBookings(
        status: BookingStatus.cancelled,
        perPage: 1,
      );

      _counts = {
        BookingStatus.pending: pending.total,
        BookingStatus.confirmed: confirmed.total,
        BookingStatus.completed: completed.total,
        BookingStatus.cancelled: cancelled.total,
      };

      final now = DateTime.now();
      final upcoming =
          [
              ...pending.items,
              ...confirmed.items,
            ].where((booking) => booking.scheduledAt.isAfter(now)).toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      _upcoming = upcoming.take(_upcomingLimit).toList();

      _errorMessage = null;
      _state = ViewState.success;
      notifyListeners();
      return null;
    } catch (error) {
      final message = describeError(error);
      if (!hadData) {
        _errorMessage = message;
        _state = ViewState.error;
      }
      notifyListeners();
      return message;
    }
  }
}
