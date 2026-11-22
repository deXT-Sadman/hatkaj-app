import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/booking_repository.dart';
import 'data/repositories/service_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/bookings_provider.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/services_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';

void main() {
  runApp(HatKajApp(apiClient: ApiClient(), tokenStorage: SecureTokenStorage()));
}

class HatKajApp extends StatelessWidget {
  const HatKajApp({
    super.key,
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(
        repository: AuthRepository(apiClient),
        storage: tokenStorage,
        apiClient: apiClient,
      )..restoreSession(),
      child: MaterialApp(
        title: 'HatKaj',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        // Data providers wrap the Navigator so every pushed screen can read them.
        // They only exist while signed in, so logging out discards the previous
        // user's bookings and resets the route stack.
        builder: (context, child) {
          final user = context.watch<AuthProvider>().user;
          if (user == null) return child!;

          return MultiProvider(
            key: ValueKey(user.id),
            providers: [
              ChangeNotifierProvider(
                create: (_) =>
                    ServicesProvider(ServiceRepository(apiClient))..refresh(),
              ),
              ChangeNotifierProvider(
                create: (_) =>
                    BookingsProvider(BookingRepository(apiClient))..refresh(),
              ),
              ChangeNotifierProvider(
                create: (_) =>
                    DashboardProvider(BookingRepository(apiClient))..refresh(),
              ),
            ],
            child: child!,
          );
        },
        home: const _AuthGate(),
      ),
    );
  }
}

/// Shows the app once signed in and the login screen otherwise.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return switch (context.watch<AuthProvider>().status) {
      AuthStatus.unknown => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.authenticated => const HomeScreen(),
    };
  }
}
