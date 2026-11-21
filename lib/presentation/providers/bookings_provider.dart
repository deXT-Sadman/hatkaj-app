import 'package:flutter/foundation.dart';

import '../../data/models/booking.dart';
import '../../data/models/booking_status.dart';
import '../../data/models/new_booking.dart';
import '../../data/repositories/booking_repository.dart';
import 'view_state.dart';

class BookingsProvider extends ChangeNotifier {
  BookingsProvider(this._repository);

  final BookingRepository _repository;

  ViewState _state = ViewState.loading;
  List<Booking> _bookings = const [];
  String? _errorMessage;
  int _page = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  BookingStatus? _statusFilter;

  ViewState get state => _state;
  List<Booking> get bookings => _bookings;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  BookingStatus? get statusFilter => _statusFilter;

  /// Reloads the first page. Returns an error message if the request failed, otherwise null.
  ///
  /// Existing data stays on screen when a refresh fails; the full error state
  /// is only used when there is nothing to show.
  Future<String?> refresh() async {
    final hadData = _bookings.isNotEmpty;
    if (!hadData) {
      _state = ViewState.loading;
      notifyListeners();
    }

    try {
      final page = await _repository.fetchBookings(status: _statusFilter);
      _bookings = page.items;
      _page = page.currentPage;
      _hasMore = page.hasMore;
      _errorMessage = null;
      _state = _bookings.isEmpty ? ViewState.empty : ViewState.success;
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

  /// Appends the next page. Returns an error message if the request failed, otherwise null.
  Future<String?> loadMore() async {
    if (!_hasMore || _isLoadingMore) return null;

    _isLoadingMore = true;
    notifyListeners();
    try {
      final page = await _repository.fetchBookings(
        status: _statusFilter,
        page: _page + 1,
      );
      _bookings = [..._bookings, ...page.items];
      _page = page.currentPage;
      _hasMore = page.hasMore;
      return null;
    } catch (error) {
      return describeError(error);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Creates a booking, then reloads the list so server ordering is preserved.
  /// Throws [ApiException] (e.g. 409 slot taken, 422 validation) for the form to display.
  Future<void> createBooking(NewBooking booking) async {
    await _repository.createBooking(booking);
    await refresh();
  }

  /// Filters the list by status (null shows all) and reloads from page 1.
  Future<String?> setStatusFilter(BookingStatus? status) {
    _statusFilter = status;
    _bookings = const [];
    return refresh();
  }

  /// Moves a booking to [status], then reloads the list.
  /// Throws [ApiException] (e.g. 422 invalid transition) for the caller to display.
  Future<void> updateStatus(Booking booking, BookingStatus status) async {
    await _repository.updateStatus(booking.id, status);
    await refresh();
  }
}
