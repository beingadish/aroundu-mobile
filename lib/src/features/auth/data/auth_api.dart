import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class LoginResult {
  const LoginResult({
    required this.userId,
    required this.token,
    required this.email,
    required this.role,
  });

  final int userId;
  final String token;
  final String email;
  final String role;
}

class UserProfileData {
  const UserProfileData({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.currentAddressId,
    this.skillIds = const <int>[],
    this.currency = 'INR',
    this.profileImageUrl,
    this.experienceYears,
    this.certifications,
    this.isOnDuty,
    this.payoutAccount,
  });

  final int? id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final int? currentAddressId;
  final List<int> skillIds;
  final String currency;
  final String? profileImageUrl;
  final int? experienceYears;
  final String? certifications;
  final bool? isOnDuty;
  final String? payoutAccount;

  UserProfileData copyWith({
    int? id,
    String? name,
    String? email,
    String? phoneNumber,
    int? currentAddressId,
    List<int>? skillIds,
    String? currency,
    String? profileImageUrl,
    int? experienceYears,
    String? certifications,
    bool? isOnDuty,
    String? payoutAccount,
  }) {
    return UserProfileData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      currentAddressId: currentAddressId ?? this.currentAddressId,
      skillIds: skillIds ?? this.skillIds,
      currency: currency ?? this.currency,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      experienceYears: experienceYears ?? this.experienceYears,
      certifications: certifications ?? this.certifications,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      payoutAccount: payoutAccount ?? this.payoutAccount,
    );
  }
}

class UserProfileUpdateInput {
  const UserProfileUpdateInput({
    this.name,
    this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.experienceYears,
    this.certifications,
    this.isOnDuty,
    this.payoutAccount,
    this.currency,
  });

  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final int? experienceYears;
  final String? certifications;
  final bool? isOnDuty;
  final String? payoutAccount;
  final String? currency;

  Map<String, dynamic> toClientPayload() {
    return <String, dynamic>{
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
      if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
      if (phoneNumber != null && phoneNumber!.trim().isNotEmpty)
        'phoneNumber': phoneNumber!.trim(),
      if (profileImageUrl != null && profileImageUrl!.trim().isNotEmpty)
        'profileImageUrl': profileImageUrl!.trim(),
    };
  }

  Map<String, dynamic> toWorkerPayload() {
    return <String, dynamic>{
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
      if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
      if (phoneNumber != null && phoneNumber!.trim().isNotEmpty)
        'phoneNumber': phoneNumber!.trim(),
      if (profileImageUrl != null && profileImageUrl!.trim().isNotEmpty)
        'profileImageUrl': profileImageUrl!.trim(),
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (certifications != null) 'certifications': certifications,
      if (isOnDuty != null) 'isOnDuty': isOnDuty,
      if (payoutAccount != null && payoutAccount!.trim().isNotEmpty)
        'payoutAccount': payoutAccount!.trim(),
      if (currency != null && currency!.trim().isNotEmpty)
        'currency': currency!.trim().toUpperCase(),
    };
  }
}

class PagedUserProfiles {
  const PagedUserProfiles({
    this.users = const <UserProfileData>[],
    this.page = 0,
    this.size = 0,
    this.totalElements = 0,
    this.totalPages = 0,
    this.last = true,
  });

  final List<UserProfileData> users;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;
}

class RegistrationRequest {
  const RegistrationRequest({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.country,
    required this.postalCode,
    required this.city,
    required this.area,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    required this.currency,
    this.skillIds = const <int>[],
  });

  final String name;
  final String email;
  final String phoneNumber;
  final String password;
  final String country;
  final String postalCode;
  final String city;
  final String area;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String currency;
  final List<int> skillIds;

  Map<String, dynamic> toClientPayload() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'currency': currency,
      'currentAddress': <String, dynamic>{
        'country': country,
        'postalCode': postalCode,
        'city': city,
        'area': area,
        'latitude': latitude,
        'longitude': longitude,
        'fullAddress': fullAddress,
      },
      'savedAddresses': <Map<String, dynamic>>[],
    };
  }

  Map<String, dynamic> toWorkerPayload() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'currency': currency,
      'currentAddress': <String, dynamic>{
        'country': country,
        'postalCode': postalCode,
        'city': city,
        'area': area,
        'latitude': latitude,
        'longitude': longitude,
        'fullAddress': fullAddress,
      },
      'skillIds': skillIds.map((id) => id.toString()).toList(),
    };
  }
}

class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.postJson(
      '/api/v1/auth/login',
      body: <String, dynamic>{'email': email, 'password': password},
    );

    return LoginResult(
      userId: _asInt(response['userId']) ?? 0,
      token: response['token']?.toString() ?? '',
      email: response['email']?.toString() ?? email,
      role: response['role']?.toString() ?? '',
    );
  }

  Future<void> registerClient(RegistrationRequest request) async {
    final response = await _client.postJson(
      '/api/v1/client/register',
      body: request.toClientPayload(),
    );
    _ensureSuccessEnvelope(response);
  }

  Future<void> registerWorker(RegistrationRequest request) async {
    final response = await _client.postJson(
      '/api/v1/worker/register',
      body: request.toWorkerPayload(),
    );
    _ensureSuccessEnvelope(response);
  }

  Future<UserProfileData> fetchClientProfile(String token) async {
    final response = await _client.getJson(
      '/api/v1/client/me',
      bearerToken: token,
    );
    return _mapProfile(_readDataMap(response));
  }

  Future<UserProfileData> fetchWorkerProfile(String token) async {
    final response = await _client.getJson(
      '/api/v1/worker/me',
      bearerToken: token,
    );
    return _mapProfile(_readDataMap(response));
  }

  Future<UserProfileData> fetchClientById({
    required String token,
    required int clientId,
  }) async {
    final response = await _client.getJson(
      '/api/v1/client/$clientId',
      bearerToken: token,
    );
    return _mapProfile(_readDataMap(response));
  }

  Future<UserProfileData> fetchWorkerById({
    required String token,
    required int workerId,
  }) async {
    final response = await _client.getJson(
      '/api/v1/worker/$workerId',
      bearerToken: token,
    );
    return _mapProfile(_readDataMap(response));
  }

  Future<PagedUserProfiles> fetchAllClients({
    required String token,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.getJson(
      '/api/v1/client/all',
      bearerToken: token,
      query: <String, dynamic>{'page': page, 'size': size},
    );
    return _mapPagedUsers(_readDataMap(response));
  }

  Future<PagedUserProfiles> fetchAllWorkers({
    required String token,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.getJson(
      '/api/v1/worker/all',
      bearerToken: token,
      query: <String, dynamic>{'page': page, 'size': size},
    );
    return _mapPagedUsers(_readDataMap(response));
  }

  Future<UserProfileData> updateClientProfile({
    required String token,
    required int clientId,
    required UserProfileUpdateInput input,
  }) async {
    final response = await _client.patchJson(
      '/api/v1/client/update/$clientId',
      bearerToken: token,
      body: input.toClientPayload(),
    );
    return _mapProfile(_readDataMap(response));
  }

  Future<UserProfileData> updateWorkerProfile({
    required String token,
    required int workerId,
    required UserProfileUpdateInput input,
  }) async {
    final response = await _client.patchJson(
      '/api/v1/worker/update/$workerId',
      bearerToken: token,
      body: input.toWorkerPayload(),
    );
    return _mapProfile(_readDataMap(response));
  }

  Future<void> deleteClient({
    required String token,
    required int clientId,
  }) async {
    final response = await _client.deleteJson(
      '/api/v1/client/$clientId',
      bearerToken: token,
    );
    _ensureSuccessEnvelope(response);
  }

  Future<void> deleteWorker({
    required String token,
    required int workerId,
  }) async {
    final response = await _client.deleteJson(
      '/api/v1/worker/$workerId',
      bearerToken: token,
    );
    _ensureSuccessEnvelope(response);
  }

  void _ensureSuccessEnvelope(Map<String, dynamic> response) {
    final success = response['success'];
    if (success == true) {
      return;
    }

    throw ApiException(response['message']?.toString() ?? 'Request failed');
  }

  Map<String, dynamic> _readDataMap(Map<String, dynamic> envelope) {
    _ensureSuccessEnvelope(envelope);

    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw const ApiException('Malformed response payload');
  }

  PagedUserProfiles _mapPagedUsers(Map<String, dynamic> data) {
    final content = data['content'];
    final users = <UserProfileData>[];

    if (content is List) {
      for (final item in content) {
        if (item is Map<String, dynamic>) {
          users.add(_mapProfile(item));
        }
      }
    }

    return PagedUserProfiles(
      users: users,
      page: _asInt(data['page']) ?? 0,
      size: _asInt(data['size']) ?? users.length,
      totalElements: _asInt(data['totalElements']) ?? users.length,
      totalPages: _asInt(data['totalPages']) ?? 1,
      last: _asBool(data['last']) ?? true,
    );
  }

  UserProfileData _mapProfile(Map<String, dynamic> data) {
    final currentAddress = _asMap(data['currentAddress']);
    final skills = data['skills'];

    final skillIds = <int>[];
    if (skills is List) {
      for (final skill in skills) {
        if (skill is Map<String, dynamic>) {
          final id = _asInt(skill['id']);
          if (id != null) {
            skillIds.add(id);
          }
        }
      }
    }

    return UserProfileData(
      id: _asInt(data['id']),
      name: data['name']?.toString(),
      email: data['email']?.toString(),
      phoneNumber: data['phoneNumber']?.toString(),
      currentAddressId: _asInt(currentAddress['id']),
      skillIds: skillIds,
      currency: data['currency']?.toString() ?? 'INR',
      profileImageUrl: data['profileImageUrl']?.toString(),
      experienceYears: _asInt(data['experienceYears']),
      certifications: data['certifications']?.toString(),
      isOnDuty: _asBool(data['isOnDuty']),
      payoutAccount: data['payoutAccount']?.toString(),
    );
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return const <String, dynamic>{};
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  bool? _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    final text = value?.toString().toLowerCase();
    if (text == 'true') {
      return true;
    }
    if (text == 'false') {
      return false;
    }
    return null;
  }
}
