import 'package:hatkaj_app/core/network/api_exception.dart';
import 'package:hatkaj_app/data/models/booking.dart';
import 'package:hatkaj_app/data/models/booking_status.dart';
import 'package:hatkaj_app/data/models/booking_summary.dart';
import 'package:hatkaj_app/data/models/new_booking.dart';
import 'package:hatkaj_app/data/models/paginated.dart';
import 'package:hatkaj_app/data/models/pricing.dart';
import 'package:hatkaj_app/data/models/service.dart';
import 'package:hatkaj_app/data/models/user.dart';
import 'package:hatkaj_app/data/repositories/auth_repository.dart';
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

const pricingFixture = Pricing(
  basePrice: 1200,
  serviceFee: 60,
  totalAmount: 1260,
);

const userFixture = User(
  id: 1,
  name: 'Rahim',
  email: 'rahim@example.com',
  phone: '01712345678',
  defaultAddress: 'Dhaka',
);

Booking buildBooking(int id, {BookingStatus status = BookingStatus.pending}) =>
    Booking(
      id: id,
      customerName: 'Rahim',
      customerPhone: '01712345678',
      address: 'Dhaka',
      scheduledAt: DateTime(2026, 12, 30, 10),
      status: status,
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
  FakeBookingRepository({
    this.bookings = const [],
    this.createError,
    this.previewError,
  });

  List<Booking> bookings;
  Object? createError;
  Object? previewError;
  Object? fetchError;
  int createCalls = 0;
  int previewCalls = 0;
  NewBooking? lastCreated;

  @override
  Future<BookingSummary> previewBooking(NewBooking booking) async {
    previewCalls++;
    if (previewError != null) throw previewError!;
    return BookingSummary(
      service: acService,
      customerName: booking.customerName,
      customerPhone: booking.customerPhone,
      address: booking.address,
      scheduledAt: booking.scheduledAt,
      paymentMethod: booking.paymentMethod,
      pricing: pricingFixture,
    );
  }

  @override
  Future<Paginated<Booking>> fetchBookings({
    BookingStatus? status,
    int? serviceId,
    int page = 1,
    int? perPage,
  }) async {
    lastFilter = status;
    if (fetchError != null) throw fetchError!;
    return Paginated(items: bookings, currentPage: 1, lastPage: 1);
  }

  @override
  Future<Booking> createBooking(NewBooking booking) async {
    createCalls++;
    lastCreated = booking;
    if (createError != null) throw createError!;
    final created = buildBooking(bookings.length + 1);
    bookings = [...bookings, created];
    return created;
  }

  BookingStatus? lastFilter;
  BookingStatus? lastUpdatedTo;

  @override
  Future<Booking> updateStatus(int bookingId, BookingStatus status) async {
    lastUpdatedTo = status;
    bookings = [
      for (final b in bookings)
        b.id == bookingId ? buildBooking(b.id, status: status) : b,
    ];
    return bookings.firstWhere((b) => b.id == bookingId);
  }
}

const networkError = ApiException(
  'Cannot reach the server. Check your connection.',
);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.loginError, this.profileError});

  Object? loginError;
  Object? profileError;
  int logoutCalls = 0;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (loginError != null) throw loginError!;
    return const AuthSession(user: userFixture, token: 'token-123');
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? defaultAddress,
  }) async => const AuthSession(user: userFixture, token: 'token-123');

  @override
  Future<void> logout() async => logoutCalls++;

  @override
  Future<User> fetchProfile() async {
    if (profileError != null) throw profileError!;
    return userFixture;
  }

  @override
  Future<User> updateProfile({
    required String name,
    String? phone,
    String? defaultAddress,
  }) async => User(
    id: userFixture.id,
    name: name,
    email: userFixture.email,
    phone: phone,
    defaultAddress: defaultAddress,
  );
}
