import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'data/repositories/booking_repository.dart';
import 'data/repositories/service_repository.dart';
import 'presentation/providers/bookings_provider.dart';
import 'presentation/providers/services_provider.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(HatKajApp(apiClient: ApiClient()));
}

class HatKajApp extends StatelessWidget {
  const HatKajApp({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              ServicesProvider(ServiceRepository(apiClient))..refresh(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              BookingsProvider(BookingRepository(apiClient))..refresh(),
        ),
      ],
      child: MaterialApp(
        title: 'HatKaj',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const HomeScreen(),
      ),
    );
  }
}
