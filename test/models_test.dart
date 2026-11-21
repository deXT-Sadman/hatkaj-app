import 'package:flutter_test/flutter_test.dart';
import 'package:hatkaj_app/data/models/booking.dart';
import 'package:hatkaj_app/data/models/booking_status.dart';
import 'package:hatkaj_app/data/models/new_booking.dart';
import 'package:hatkaj_app/data/models/paginated.dart';

const _bookingJson = {
  'id': 7,
  'customer_name': 'Rahim Uddin',
  'customer_phone': '+8801712345678',
  'address': 'Dhaka',
  'scheduled_at': '2026-12-30T04:00:00+00:00',
  'status': 'confirmed',
  'notes': null,
  'service': {
    'id': 1,
    'name': 'AC Servicing',
    'description': null,
    'price': '1200.00',
    'duration_minutes': 90,
  },
  'created_at': '2026-11-21T10:00:00+00:00',
};

void main() {
  test(
    'Booking.fromJson parses status, nested service and decimal price strings',
    () {
      final booking = Booking.fromJson(_bookingJson);

      expect(booking.id, 7);
      expect(booking.status, BookingStatus.confirmed);
      expect(booking.service?.price, 1200.0);
      expect(booking.service?.durationMinutes, 90);
      expect(booking.scheduledAt.toUtc().hour, 4);
    },
  );

  test('Booking.toJson round-trips through fromJson', () {
    final booking = Booking.fromJson(_bookingJson);

    final again = Booking.fromJson(booking.toJson());

    expect(again.id, booking.id);
    expect(again.scheduledAt, booking.scheduledAt);
    expect(again.service?.name, 'AC Servicing');
  });

  test('NewBooking.toJson sends UTC time and omits empty notes', () {
    final json = NewBooking(
      serviceId: 1,
      customerName: 'Rahim',
      customerPhone: '01712345678',
      address: 'Dhaka',
      scheduledAt: DateTime.utc(2026, 12, 30, 4),
      notes: '',
    ).toJson();

    expect(json['scheduled_at'], '2026-12-30T04:00:00.000Z');
    expect(json.containsKey('notes'), isFalse);
  });

  test('Paginated.fromJson reads data and meta', () {
    final page = Paginated.fromJson({
      'data': [_bookingJson],
      'meta': {'current_page': 1, 'last_page': 3},
    }, Booking.fromJson);

    expect(page.items, hasLength(1));
    expect(page.hasMore, isTrue);
  });

  test('unknown status throws a FormatException', () {
    expect(() => BookingStatus.fromApi('nope'), throwsFormatException);
  });
}
