import 'package:hatkaj_app/core/network/api_exception.dart';
import 'package:hatkaj_app/data/models/booking.dart';
import 'package:hatkaj_app/data/models/booking_status.dart';
import 'package:hatkaj_app/data/models/new_booking.dart';
import 'package:hatkaj_app/data/models/paginated.dart';
import 'package:hatkaj_app/data/models/service.dart';
import 'package:hatkaj_app/data/repositories/booking_repository.dart';
import 'package:hatkaj_app/data/repositories/service_repository.dart';

const acService = Service(
  id: 1,
  name: 'AC Servicing',
  price: 1200,
  durationMinutes: 90,
);

final newBookingFixture = NewBooking(
  serviceId: 1,
  customerName: 'Rahim',
  customerPhone: '01712345678',
  address: 'Dhaka',
  scheduledAt: DateTime(2030, 1, 1, 10),
);

Booking buildBooking(int id) => Booking(
  id: id,
  customerName: 'Rahim',
  customerPhone: '01712345678',
  address: 'Dhaka',
  scheduledAt: DateTime(2026, 12, 30, 10),
  status: BookingStatus.pending,
  service: acService,
);

class FakeServiceRepository implements ServiceRepository {
  FakeServiceRepository({this.services = const [acService], this.error});

  List<Service> services;
  Object? error;

  @override
  Future<List<Service>> fetchServices() async {
    if (error != null) throw error!;
    return services;
  }
}

class FakeBookingRepository implements BookingRepository {
  FakeBookingRepository({this.bookings = const [], this.createError});

  List<Booking> bookings;
  Object? createError;
  Object? fetchError;
  int createCalls = 0;

  @override
  Future<Paginated<Booking>> fetchBookings({
    BookingStatus? status,
    int? serviceId,
    int page = 1,
  }) async {
    if (fetchError != null) throw fetchError!;
    return Paginated(items: bookings, currentPage: 1, lastPage: 1);
  }

  @override
  Future<Booking> createBooking(NewBooking booking) async {
    createCalls++;
    if (createError != null) throw createError!;
    final created = buildBooking(bookings.length + 1);
    bookings = [...bookings, created];
    return created;
  }

  @override
  Future<Booking> updateStatus(int bookingId, BookingStatus status) {
    throw UnimplementedError();
  }
}

const networkError = ApiException(
  'Cannot reach the server. Check your connection.',
);
