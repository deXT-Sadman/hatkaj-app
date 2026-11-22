import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hatkaj_app/core/network/api_client.dart';
import 'package:hatkaj_app/core/network/api_exception.dart';
import 'package:hatkaj_app/core/storage/token_storage.dart';
import 'package:hatkaj_app/data/repositories/auth_repository.dart';
import 'package:hatkaj_app/data/repositories/booking_repository.dart';
import 'package:hatkaj_app/presentation/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fakes.dart';

AuthProvider _provider({
  FakeAuthRepository? repository,
  TokenStorage? storage,
  ApiClient? apiClient,
}) {
  return AuthProvider(
    repository: repository ?? FakeAuthRepository(),
    storage: storage ?? InMemoryTokenStorage(),
    apiClient: apiClient ?? ApiClient(baseUrl: 'http://test'),
  );
}

void main() {
  group('AuthProvider', () {
    test('is unauthenticated without a stored token', () async {
      final provider = _provider();
      expect(provider.status, AuthStatus.unknown);

      await provider.restoreSession();

      expect(provider.status, AuthStatus.unauthenticated);
    });

    test('restores the session from a stored token', () async {
      final apiClient = ApiClient(baseUrl: 'http://test');
      final provider = _provider(
        storage: InMemoryTokenStorage('stored'),
        apiClient: apiClient,
      );

      await provider.restoreSession();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user, userFixture);
      expect(apiClient.authToken, 'stored');
    });

    test('drops a token the server rejects', () async {
      final storage = InMemoryTokenStorage('expired');
      final provider = _provider(
        storage: storage,
        repository: FakeAuthRepository(
          profileError: const ApiException('Unauthenticated.', statusCode: 401),
        ),
      );

      await provider.restoreSession();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(await storage.read(), isNull);
    });

    test('keeps the token when the server is just unreachable', () async {
      final storage = InMemoryTokenStorage('valid');
      final provider = _provider(
        storage: storage,
        repository: FakeAuthRepository(profileError: networkError),
      );

      await provider.restoreSession();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(await storage.read(), 'valid');
    });

    test('login stores the token and authenticates the client', () async {
      final storage = InMemoryTokenStorage();
      final apiClient = ApiClient(baseUrl: 'http://test');
      final provider = _provider(storage: storage, apiClient: apiClient);

      await provider.login(email: 'rahim@example.com', password: 'secret');

      expect(provider.status, AuthStatus.authenticated);
      expect(await storage.read(), 'token-123');
      expect(apiClient.authToken, 'token-123');
    });

    test('a failed login throws and stays signed out', () async {
      final provider = _provider(
        repository: FakeAuthRepository(
          loginError: const ApiException(
            'The provided credentials are incorrect.',
            statusCode: 422,
          ),
        ),
      );
      await provider.restoreSession();

      await expectLater(
        provider.login(email: 'a@b.c', password: 'bad'),
        throwsA(isA<ApiException>()),
      );
      expect(provider.status, AuthStatus.unauthenticated);
    });

    test('logout revokes the token and clears local state', () async {
      final storage = InMemoryTokenStorage();
      final repository = FakeAuthRepository();
      final apiClient = ApiClient(baseUrl: 'http://test');
      final provider = _provider(
        repository: repository,
        storage: storage,
        apiClient: apiClient,
      );
      await provider.login(email: 'rahim@example.com', password: 'secret');

      await provider.logout();

      expect(repository.logoutCalls, 1);
      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.user, isNull);
      expect(await storage.read(), isNull);
      expect(apiClient.authToken, isNull);
    });

    test('a 401 from any request signs the user out', () async {
      final storage = InMemoryTokenStorage();
      final apiClient = ApiClient(
        baseUrl: 'http://test',
        client: MockClient(
          (_) async =>
              http.Response(jsonEncode({'message': 'Unauthenticated.'}), 401),
        ),
      );
      final provider = _provider(storage: storage, apiClient: apiClient);
      await provider.login(email: 'rahim@example.com', password: 'secret');

      await expectLater(
        BookingRepository(apiClient).fetchBookings(),
        throwsA(isA<ApiException>()),
      );

      expect(provider.status, AuthStatus.unauthenticated);
      expect(await storage.read(), isNull);
    });

    test('updateProfile replaces the current user', () async {
      final provider = _provider();
      await provider.login(email: 'rahim@example.com', password: 'secret');

      await provider.updateProfile(name: 'New Name', phone: '01800000000');

      expect(provider.user?.name, 'New Name');
      expect(provider.user?.phone, '01800000000');
    });
  });

  group('AuthRepository', () {
    test('login parses user and token from the top-level response', () async {
      final apiClient = ApiClient(
        baseUrl: 'http://test',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'user': {
                'id': 7,
                'name': 'Rahim',
                'email': 'rahim@example.com',
                'phone': null,
                'default_address': null,
              },
              'token': 'abc',
            }),
            200,
          ),
        ),
      );

      final session = await AuthRepository(apiClient)
          .login(email: 'rahim@example.com', password: 'secret');

      expect(session.token, 'abc');
      expect(session.user.id, 7);
      expect(session.user.phone, isNull);
    });

    test('requests carry the bearer token once it is set', () async {
      String? seenAuthHeader;
      final apiClient = ApiClient(
        baseUrl: 'http://test',
        client: MockClient((request) async {
          seenAuthHeader = request.headers['Authorization'];
          return http.Response(
            jsonEncode({
              'data': {'id': 1, 'name': 'R', 'email': 'r@e.c'},
            }),
            200,
          );
        }),
      )..authToken = 'abc';

      await AuthRepository(apiClient).fetchProfile();

      expect(seenAuthHeader, 'Bearer abc');
    });
  });
}
