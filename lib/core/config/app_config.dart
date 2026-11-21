/// Environment configuration.
///
/// The Android emulator reaches the host machine at `10.0.2.2`, so that is the
/// default. For a real device, pass your computer's LAN IP at run time:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8000
///
/// (start the API with `php artisan serve --host=0.0.0.0`).
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const Duration requestTimeout = Duration(seconds: 15);
}
