import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatkaj_app/core/network/api_exception.dart';
import 'package:hatkaj_app/presentation/providers/bookings_provider.dart';
import 'package:hatkaj_app/presentation/providers/services_provider.dart';
import 'package:hatkaj_app/presentation/screens/booking_form_screen.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

Future<FakeBookingRepository> _pumpForm(
  WidgetTester tester, {
  Object? createError,
}) async {
  final bookingRepository = FakeBookingRepository(createError: createError);
  final servicesProvider = ServicesProvider(FakeServiceRepository());
  await servicesProvider.refresh();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: servicesProvider),
        ChangeNotifierProvider(
          create: (_) => BookingsProvider(bookingRepository),
        ),
      ],
      child: const MaterialApp(home: BookingFormScreen(initialServiceId: 1)),
    ),
  );
  return bookingRepository;
}

/// Fills every field with valid data; the date is the 15th of next month so it is always in the future.
Future<void> _fillForm(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Your name'),
    'Rahim',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Phone'),
    '01712345678',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Address'),
    'Dhaka',
  );

  await tester.tap(find.widgetWithText(TextFormField, 'Date'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Next month'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('15'));
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await tester.tap(find.widgetWithText(TextFormField, 'Time'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Book now'));
  await tester.tap(find.text('Book now'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty form shows validation messages and does not submit', (
    tester,
  ) async {
    final repository = await _pumpForm(tester);

    await _submit(tester);

    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(find.text('Pick a date'), findsOneWidget);
    expect(repository.createCalls, 0);
  });

  testWidgets('a valid form creates the booking and closes', (tester) async {
    final repository = await _pumpForm(tester);
    await _fillForm(tester);

    await _submit(tester);

    expect(repository.createCalls, 1);
  });

  testWidgets(
    'a 409 from the API is shown as a banner and the form stays open',
    (tester) async {
      const message =
          'This time slot is already booked for the selected service.';
      final repository = await _pumpForm(
        tester,
        createError: const ApiException(message, statusCode: 409),
      );
      await _fillForm(tester);

      await _submit(tester);

      expect(repository.createCalls, 1);
      expect(find.text(message), findsOneWidget);
      expect(find.byType(BookingFormScreen), findsOneWidget);
    },
  );
}
