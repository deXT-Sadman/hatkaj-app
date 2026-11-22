import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatkaj_app/core/network/api_client.dart';
import 'package:hatkaj_app/core/network/api_exception.dart';
import 'package:hatkaj_app/core/storage/token_storage.dart';
import 'package:hatkaj_app/data/models/payment_method.dart';
import 'package:hatkaj_app/presentation/providers/auth_provider.dart';
import 'package:hatkaj_app/presentation/providers/bookings_provider.dart';
import 'package:hatkaj_app/presentation/providers/services_provider.dart';
import 'package:hatkaj_app/presentation/screens/booking_form_screen.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

const _slotTaken = 'This time slot is already booked for the selected service.';

Future<FakeBookingRepository> _pumpForm(
  WidgetTester tester, {
  Object? createError,
  Object? previewError,
}) async {
  final bookingRepository = FakeBookingRepository(
    createError: createError,
    previewError: previewError,
  );
  final authProvider = AuthProvider(
    repository: FakeAuthRepository(),
    storage: InMemoryTokenStorage(),
    apiClient: ApiClient(baseUrl: 'http://test'),
  );
  await authProvider.login(email: 'rahim@example.com', password: 'password');
  final servicesProvider = ServicesProvider(FakeServiceRepository());
  await servicesProvider.refresh();

  // Tall enough that the checkout list builds every row without scrolling.
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
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

/// Picks a date (the 15th of next month, so it is always in the future) and the default time.
/// Name, phone and address come pre-filled from the signed-in profile.
Future<void> _pickSlot(WidgetTester tester) async {
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

Future<void> _clearContactFields(WidgetTester tester) async {
  for (final label in ['Your name', 'Phone', 'Address']) {
    await tester.enterText(find.widgetWithText(TextFormField, label), '');
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _review(WidgetTester tester) =>
    _tap(tester, find.text('Review booking'));

Future<void> _confirm(WidgetTester tester) =>
    _tap(tester, find.textContaining('Confirm booking'));

void main() {
  testWidgets('contact fields are pre-filled from the profile', (tester) async {
    await _pumpForm(tester);

    expect(find.text('Rahim'), findsOneWidget);
    expect(find.text('01712345678'), findsOneWidget);
    expect(find.text('Dhaka'), findsOneWidget);
  });

  testWidgets('empty form shows validation messages and does not submit', (
    tester,
  ) async {
    final repository = await _pumpForm(tester);
    await _clearContactFields(tester);

    await _review(tester);

    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(find.text('Pick a date'), findsOneWidget);
    expect(repository.previewCalls, 0);
    expect(repository.createCalls, 0);
  });

  testWidgets('a valid form shows the checkout summary without booking yet', (
    tester,
  ) async {
    final repository = await _pumpForm(tester);
    await _pickSlot(tester);

    await _review(tester);

    expect(repository.previewCalls, 1);
    expect(repository.createCalls, 0);
    expect(find.text('Review & confirm'), findsOneWidget);
    expect(find.text('৳60.00'), findsOneWidget);
    expect(find.text('৳1260.00'), findsWidgets);
  });

  testWidgets('confirming books with the chosen payment method', (
    tester,
  ) async {
    final repository = await _pumpForm(tester);
    await _pickSlot(tester);
    await _review(tester);

    await _tap(tester, find.text('Demo wallet'));
    await _confirm(tester);

    expect(repository.createCalls, 1);
    expect(repository.lastCreated?.paymentMethod, PaymentMethod.demoWallet);
    expect(find.textContaining('placed'), findsOneWidget);
  });

  testWidgets(
    'a 409 from the preview is shown as a banner and the form stays open',
    (tester) async {
      final repository = await _pumpForm(
        tester,
        previewError: const ApiException(_slotTaken, statusCode: 409),
      );
      await _pickSlot(tester);

      await _review(tester);

      expect(repository.previewCalls, 1);
      expect(repository.createCalls, 0);
      expect(find.text(_slotTaken), findsOneWidget);
      expect(find.byType(BookingFormScreen), findsOneWidget);
    },
  );

  testWidgets('a failure while confirming stays on the checkout screen', (
    tester,
  ) async {
    final repository = await _pumpForm(
      tester,
      createError: const ApiException(_slotTaken, statusCode: 409),
    );
    await _pickSlot(tester);
    await _review(tester);

    await _confirm(tester);

    expect(repository.createCalls, 1);
    expect(find.text(_slotTaken), findsOneWidget);
    expect(find.text('Review & confirm'), findsOneWidget);
  });
}
