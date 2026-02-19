import 'package:aroundu/src/core/network/api_client.dart';
import 'package:aroundu/src/core/network/api_exception.dart';
import 'package:aroundu/src/core/providers/core_providers.dart';
import 'package:aroundu/src/core/storage/local_storage.dart';
import 'package:aroundu/src/features/auth/data/auth_api.dart';
import 'package:aroundu/src/features/auth/view_model/auth_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class FakeAuthApi extends AuthApi {
  FakeAuthApi({
    this.loginResult,
    this.loginFailure,
    this.clientProfile = const UserProfileData(),
    this.workerProfile = const UserProfileData(),
  }) : super(
         ApiClient(
           baseUrl: 'http://localhost:20232',
           httpClient: http.Client(),
         ),
       );

  final LoginResult? loginResult;
  final Object? loginFailure;
  final UserProfileData clientProfile;
  final UserProfileData workerProfile;

  int clientRegisterCalls = 0;
  int workerRegisterCalls = 0;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    if (loginFailure != null) {
      throw loginFailure!;
    }
    return loginResult!;
  }

  @override
  Future<UserProfileData> fetchClientProfile(String token) async {
    return clientProfile;
  }

  @override
  Future<UserProfileData> fetchWorkerProfile(String token) async {
    return workerProfile;
  }

  @override
  Future<void> registerClient(RegistrationRequest request) async {
    clientRegisterCalls += 1;
  }

  @override
  Future<void> registerWorker(RegistrationRequest request) async {
    workerRegisterCalls += 1;
  }
}

class FakeLocalStorage extends LocalStorage {
  FakeLocalStorage({Map<String, dynamic>? seedSession})
    : _session = seedSession == null ? null : <String, dynamic>{...seedSession};

  Map<String, dynamic>? _session;

  @override
  Future<Map<String, dynamic>?> readAuthSession() async {
    return _session == null ? null : <String, dynamic>{..._session!};
  }

  @override
  Future<void> saveAuthSession(Map<String, dynamic> session) async {
    _session = <String, dynamic>{...session};
  }

  @override
  Future<void> clearAuthSession() async {
    _session = null;
  }
}

RegisterUserInput _registerInput(UserRole role) {
  return RegisterUserInput(
    role: role,
    name: 'Alex Doe',
    email: 'alex@example.com',
    phoneNumber: '+12345678901',
    password: 'secret123',
    country: 'US',
    postalCode: '94016',
    city: 'San Francisco',
    area: 'Sunset',
    fullAddress: '123 Main Street',
    latitude: 37.7749,
    longitude: -122.4194,
    currency: 'USD',
    skillIds: role == UserRole.worker ? const <int>[1, 3] : const <int>[],
  );
}

void main() {
  group('AuthController', () {
    ProviderContainer buildContainer({
      required FakeAuthApi authApi,
      FakeLocalStorage? localStorage,
    }) {
      return ProviderContainer(
        overrides: [
          authApiProvider.overrideWithValue(authApi),
          localStorageProvider.overrideWithValue(
            localStorage ?? FakeLocalStorage(),
          ),
        ],
      );
    }

    test('login hydrates provider session state', () async {
      final fakeApi = FakeAuthApi(
        loginResult: const LoginResult(
          userId: 101,
          token: 'provider-token',
          email: 'provider@example.com',
          role: 'ROLE_CLIENT',
        ),
        clientProfile: const UserProfileData(
          currentAddressId: 501,
          currency: 'USD',
        ),
      );

      final container = buildContainer(authApi: fakeApi);
      addTearDown(container.dispose);

      final success = await container
          .read(authControllerProvider.notifier)
          .login(email: 'provider@example.com', password: 'secret123');

      final state = container.read(authControllerProvider);
      expect(success, isTrue);
      expect(state.isAuthenticated, isTrue);
      expect(state.role, UserRole.provider);
      expect(state.userId, 101);
      expect(state.currentAddressId, 501);
      expect(state.currency, 'USD');
    });

    test('login hydrates worker skills from profile', () async {
      final fakeApi = FakeAuthApi(
        loginResult: const LoginResult(
          userId: 202,
          token: 'worker-token',
          email: 'worker@example.com',
          role: 'ROLE_WORKER',
        ),
        workerProfile: const UserProfileData(
          currentAddressId: 601,
          skillIds: <int>[8, 9],
          currency: 'INR',
        ),
      );

      final container = buildContainer(authApi: fakeApi);
      addTearDown(container.dispose);

      final success = await container
          .read(authControllerProvider.notifier)
          .login(email: 'worker@example.com', password: 'secret123');

      final state = container.read(authControllerProvider);
      expect(success, isTrue);
      expect(state.role, UserRole.worker);
      expect(state.skillIds, <int>[8, 9]);
      expect(state.currentAddressId, 601);
      expect(state.currency, 'INR');
    });

    test('login failure stores readable error message', () async {
      final fakeApi = FakeAuthApi(
        loginFailure: const ApiException('Invalid credentials'),
      );

      final container = buildContainer(authApi: fakeApi);
      addTearDown(container.dispose);

      final success = await container
          .read(authControllerProvider.notifier)
          .login(email: 'bad@example.com', password: 'wrong');

      final state = container.read(authControllerProvider);
      expect(success, isFalse);
      expect(state.errorMessage, 'Invalid credentials');
      expect(state.isLoading, isFalse);
    });

    test('login failure includes status and details when available', () async {
      final fakeApi = FakeAuthApi(
        loginFailure: const ApiException(
          'Unauthorized',
          statusCode: 401,
          details: 'Email/password mismatch',
        ),
      );

      final container = buildContainer(authApi: fakeApi);
      addTearDown(container.dispose);

      final success = await container
          .read(authControllerProvider.notifier)
          .login(email: 'bad@example.com', password: 'wrong');

      final state = container.read(authControllerProvider);
      expect(success, isFalse);
      expect(
        state.errorMessage,
        'Unauthorized (HTTP 401): Email/password mismatch',
      );
    });

    test('register routes to role-specific API method', () async {
      final fakeApi = FakeAuthApi();
      final container = buildContainer(authApi: fakeApi);
      addTearDown(container.dispose);

      final providerSuccess = await container
          .read(authControllerProvider.notifier)
          .register(_registerInput(UserRole.provider));
      final workerSuccess = await container
          .read(authControllerProvider.notifier)
          .register(_registerInput(UserRole.worker));

      expect(providerSuccess, isTrue);
      expect(workerSuccess, isTrue);
      expect(fakeApi.clientRegisterCalls, 1);
      expect(fakeApi.workerRegisterCalls, 1);
    });

    test('restores persisted session on startup', () async {
      final fakeStorage = FakeLocalStorage(
        seedSession: <String, dynamic>{
          'email': 'stored@example.com',
          'role': 'ROLE_CLIENT',
          'token': 'stored-token',
          'userId': 999,
          'currentAddressId': 111,
          'skillIds': <int>[1, 2],
          'currency': 'USD',
        },
      );
      final container = buildContainer(
        authApi: FakeAuthApi(),
        localStorage: fakeStorage,
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);

      // Let async restore in build complete.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authControllerProvider);
      expect(state.isHydrating, isFalse);
      expect(state.isAuthenticated, isTrue);
      expect(state.email, 'stored@example.com');
      expect(state.userId, 999);
      expect(state.role, UserRole.provider);
    });
  });
}
