import 'dart:typed_data';
import '../../../core/network/api_client.dart';

/// API client for user profile image management.
class UserProfileApi {
  const UserProfileApi(this._client);

  final ApiClient _client;

  /// Uploads a profile image.
  /// [imageBytes] is the raw image data.
  /// [fileName] is the original filename (e.g., "photo.jpg").
  /// Returns the public URL of the uploaded image.
  Future<String> uploadProfileImage({
    required String token,
    required int userId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final response = await _client.postMultipart(
      '/api/v1/users/$userId/profile-image',
      bearerToken: token,
      fieldName: 'file',
      fileName: fileName,
      fileBytes: imageBytes,
    );

    final data = response['data'];
    if (data is String) return data;
    throw Exception('Unexpected response: $response');
  }

  /// Deletes the user's profile image.
  Future<void> deleteProfileImage({
    required String token,
    required int userId,
  }) async {
    await _client.deleteJson(
      '/api/v1/users/$userId/profile-image',
      bearerToken: token,
    );
  }
}
