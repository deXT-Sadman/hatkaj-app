import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Owns the signed-in user and the API token (kept in [TokenStorage] across launches).
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required this._repository,
    required this._storage,
    required this._apiClient,
  }) {
    _apiClient.onUnauthorized = _handleUnauthorized;
  }

  final AuthRepository _repository;
  final TokenStorage _storage;
  final ApiClient _apiClient;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;

  AuthStatus get status => _status;
  User? get user => _user;

  /// Signs back in with the stored token, if there is one and the server still accepts it.
  Future<void> restoreSession() async {
    final token = await _storage.read();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _apiClient.authToken = token;
    try {
      _user = await _repository.fetchProfile();
      _status = AuthStatus.authenticated;
    } on ApiException catch (error) {
      // A rejected token is dropped; on a network failure it is kept for the next launch.
      if (error.statusCode == 401) {
        await _clearSession();
      } else {
        _apiClient.authToken = null;
      }
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Throws [ApiException] (e.g. 422 wrong credentials) for the form to display.
  Future<void> login({required String email, required String password}) async {
    final session = await _repository.login(email: email, password: password);
    await _startSession(session);
  }

  /// Throws [ApiException] (e.g. 422 email taken) for the form to display.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? defaultAddress,
  }) async {
    final session = await _repository.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      defaultAddress: defaultAddress,
    );
    await _startSession(session);
  }

  /// Throws [ApiException] (e.g. 422 invalid phone) for the form to display.
  Future<void> updateProfile({
    required String name,
    String? phone,
    String? defaultAddress,
  }) async {
    _user = await _repository.updateProfile(
      name: name,
      phone: phone,
      defaultAddress: defaultAddress,
    );
    notifyListeners();
  }

  /// Revokes the token on the server when possible; the local session always ends.
  Future<void> logout() async {
    try {
      await _repository.logout();
    } on ApiException {
      // Offline or already expired: signing out locally is still correct.
    }
    await _endSession();
  }

  Future<void> _startSession(AuthSession session) async {
    _apiClient.authToken = session.token;
    await _storage.write(session.token);
    _user = session.user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> _handleUnauthorized() => _endSession();

  Future<void> _endSession() async {
    if (_status == AuthStatus.unauthenticated) return;
    _status = AuthStatus.unauthenticated;
    _user = null;
    _apiClient.authToken = null;
    notifyListeners();
    await _storage.clear();
  }

  Future<void> _clearSession() async {
    _apiClient.authToken = null;
    _user = null;
    await _storage.clear();
  }
}
