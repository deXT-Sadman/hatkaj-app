import '../../core/network/api_client.dart';
import '../models/booking.dart';
import '../models/booking_status.dart';
import '../models/booking_summary.dart';
import '../models/new_booking.dart';
import '../models/paginated.dart';

class BookingRepository {
  const BookingRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Booking>> fetchBookings({
    BookingStatus? status,
    int? serviceId,
    int page = 1,
    int? perPage,
  }) async {
    final json = await _api.get(
      '/bookings',
      query: {
        'page': '$page',
        if (perPage != null) 'per_page': '$perPage',
        if (status != null) 'status': status.apiValue,
        if (serviceId != null) 'service_id': '$serviceId',
      },
    );
    return Paginated.fromJson(json, Booking.fromJson);
  }

  Future<BookingSummary> previewBooking(NewBooking booking) async {
    final json = await _api.post('/bookings/preview', booking.toJson());
    return BookingSummary.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Booking> createBooking(NewBooking booking) async {
    final json = await _api.post('/bookings', booking.toJson());
    return Booking.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Booking> updateStatus(int bookingId, BookingStatus status) async {
    final json = await _api.patch('/bookings/$bookingId/status', {
      'status': status.apiValue,
    });
    return Booking.fromJson(json['data'] as Map<String, dynamic>);
  }
}
