import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hatkaj_app/core/network/api_client.dart';
import 'package:hatkaj_app/core/network/api_exception.dart';
import 'package:hatkaj_app/data/models/booking_status.dart';
import 'package:hatkaj_app/data/models/new_booking.dart';
import 'package:hatkaj_app/data/repositories/booking_repository.dart';
import 'package:hatkaj_app/data/repositories/service_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _clientReturning(int status, Object body) {
  return ApiClient(
    baseUrl: 'http://test',
    client: MockClient((_) async => http.Response(jsonEncode(body), status)),
  );
}

final _newBooking = NewBooking(
  serviceId: 1,
  customerName: 'Rahim',
  customerPhone: '01712345678',
  address: 'Dhaka',
  scheduledAt: DateTime.utc(2026, 12, 30, 4),
);

void main() {
  test('ServiceRepository returns parsed services', () async {
    final repository = ServiceRepository(
      _clientReturning(200, {
        'data': [
          {
            'id': 1,
            'name': 'AC Servicing',
            'description': null,
            'price': '1200.00',
            'duration_minutes': 90,
          },
        ],
      }),
    );

    final services = await repository.fetchServices();

    expect(services.single.name, 'AC Servicing');
  });

  test('a 409 becomes an ApiException flagged as a conflict', () async {
    final repository = BookingRepository(
      _clientReturning(409, {
        'message': 'This time slot is already booked for the selected service.',
      }),
    );

    await expectLater(
      repository.createBooking(_newBooking),
      throwsA(
        isA<ApiException>().having((e) => e.isConflict, 'isConflict', isTrue),
      ),
    );
  });

  test('a 422 exposes per-field validation messages', () async {
    final repository = BookingRepository(
      _clientReturning(422, {
        'message': 'The customer phone is invalid.',
        'errors': {
          'customer_phone': [
            'The phone number must be 7-20 digits and may start with +.',
          ],
        },
      }),
    );

    await expectLater(
      repository.updateStatus(1, BookingStatus.confirmed),
      throwsA(
        isA<ApiException>()
            .having((e) => e.isValidationError, 'isValidationError', isTrue)
            .having(
              (e) => e.fieldErrors['customer_phone'],
              'field errors',
              isNotEmpty,
            ),
      ),
    );
  });

  test(
    'a network failure becomes an ApiException without a status code',
    () async {
      final client = ApiClient(
        baseUrl: 'http://test',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );

      await expectLater(
        ServiceRepository(client).fetchServices(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isNetworkError,
            'isNetworkError',
            isTrue,
          ),
        ),
      );
    },
  );
}
