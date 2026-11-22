import '../../core/network/api_client.dart';
import '../models/user.dart';

/// A signed-in user together with the token that proves it.
class AuthSession {
  const AuthSession({required this.user, required this.token});

  final User user;
  final String token;
}

class AuthRepository {
  const AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? defaultAddress,
  }) async {
    final json = await _api.post('/register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (defaultAddress != null && defaultAddress.isNotEmpty)
        'default_address': defaultAddress,
    });
    return _session(json);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _api.post('/login', {
      'email': email,
      'password': password,
    });
    return _session(json);
  }

  Future<void> logout() async {
    await _api.post('/logout');
  }

  Future<User> fetchProfile() async {
    final json = await _api.get('/profile');
    return User.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<User> updateProfile({
    required String name,
    String? phone,
    String? defaultAddress,
  }) async {
    final json = await _api.put('/profile', {
      'name': name,
      'phone': phone == null || phone.isEmpty ? null : phone,
      'default_address': defaultAddress == null || defaultAddress.isEmpty
          ? null
          : defaultAddress,
    });
    return User.fromJson(json['data'] as Map<String, dynamic>);
  }

  AuthSession _session(Map<String, dynamic> json) {
    return AuthSession(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }
}
