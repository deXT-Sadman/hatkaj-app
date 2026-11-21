import 'package:flutter_test/flutter_test.dart';
import 'package:hatkaj_app/data/models/booking_status.dart';
import 'package:hatkaj_app/presentation/providers/bookings_provider.dart';
import 'package:hatkaj_app/presentation/providers/dashboard_provider.dart';
import 'package:hatkaj_app/presentation/providers/services_provider.dart';
import 'package:hatkaj_app/presentation/providers/view_state.dart';

import 'fakes.dart';

void main() {
  group('ServicesProvider', () {
    test('starts loading, then succeeds with data', () async {
      final provider = ServicesProvider(FakeServiceRepository());
      expect(provider.state, ViewState.loading);

      await provider.refresh();

      expect(provider.state, ViewState.success);
      expect(provider.services, [acService]);
    });

    test('is empty when the API returns no services', () async {
      final provider = ServicesProvider(FakeServiceRepository(services: []));

      await provider.refresh();

      expect(provider.state, ViewState.empty);
    });

    test('shows the error state when the first load fails', () async {
      final provider = ServicesProvider(
        FakeServiceRepository(error: networkError),
      );

      final message = await provider.refresh();

      expect(provider.state, ViewState.error);
      expect(provider.errorMessage, networkError.message);
      expect(message, networkError.message);
    });

    test('keeps existing data when a later refresh fails', () async {
      final repository = FakeServiceRepository();
      final provider = ServicesProvider(repository);
      await provider.refresh();

      repository.error = networkError;
      final message = await provider.refresh();

      expect(provider.state, ViewState.success);
      expect(provider.services, [acService]);
      expect(message, isNotNull);
    });
  });

  group('BookingsProvider', () {
    test('is empty with no bookings and success with some', () async {
      final repository = FakeBookingRepository();
      final provider = BookingsProvider(repository);

      await provider.refresh();
      expect(provider.state, ViewState.empty);

      repository.bookings = [buildBooking(1)];
      await provider.refresh();
      expect(provider.state, ViewState.success);
      expect(provider.bookings, hasLength(1));
    });

    test('createBooking reloads the list', () async {
      final repository = FakeBookingRepository();
      final provider = BookingsProvider(repository);
      await provider.refresh();

      await provider.createBooking(newBookingFixture);

      expect(repository.createCalls, 1);
      expect(provider.bookings, hasLength(1));
    });

    test('createBooking rethrows API errors for the form to show', () async {
      final repository = FakeBookingRepository(createError: networkError);
      final provider = BookingsProvider(repository);

      await expectLater(
        provider.createBooking(newBookingFixture),
        throwsA(networkError),
      );
    });

    test('setStatusFilter reloads with the chosen status', () async {
      final repository = FakeBookingRepository(bookings: [buildBooking(1)]);
      final provider = BookingsProvider(repository);

      await provider.setStatusFilter(BookingStatus.confirmed);

      expect(provider.statusFilter, BookingStatus.confirmed);
      expect(repository.lastFilter, BookingStatus.confirmed);
    });

    test('updateStatus sends the change and reloads the list', () async {
      final repository = FakeBookingRepository(bookings: [buildBooking(1)]);
      final provider = BookingsProvider(repository);
      await provider.refresh();

      await provider.updateStatus(
        provider.bookings.first,
        BookingStatus.confirmed,
      );

      expect(repository.lastUpdatedTo, BookingStatus.confirmed);
      expect(provider.bookings.first.status, BookingStatus.confirmed);
    });

    test('pending can only move to confirmed or cancelled', () {
      expect(BookingStatus.pending.allowedTransitions, [
        BookingStatus.confirmed,
        BookingStatus.cancelled,
      ]);
      expect(BookingStatus.completed.allowedTransitions, isEmpty);
    });
  });

  group('DashboardProvider', () {
    test('loads counts and upcoming bookings', () async {
      final provider = DashboardProvider(
        FakeBookingRepository(bookings: [buildBooking(1), buildBooking(2)]),
      );
      expect(provider.state, ViewState.loading);

      await provider.refresh();

      expect(provider.state, ViewState.success);
      expect(provider.countOf(BookingStatus.pending), 2);
    });

    test('shows the error state when loading fails', () async {
      final repository = FakeBookingRepository()..fetchError = networkError;
      final provider = DashboardProvider(repository);

      final message = await provider.refresh();

      expect(provider.state, ViewState.error);
      expect(message, networkError.message);
    });
  });
}
