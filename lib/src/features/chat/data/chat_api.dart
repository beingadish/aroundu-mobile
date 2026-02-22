import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class ChatApi {
  const ChatApi(this._client);

  final ApiClient _client;

  /// Send a message in a job conversation
  Future<Map<String, dynamic>> sendMessage({
    required String token,
    required int jobId,
    required int senderId,
    required int recipientId,
    required String content,
  }) async {
    final response = await _client.postAny(
      '/api/v1/chat/jobs/$jobId/messages',
      bearerToken: token,
      query: <String, dynamic>{'senderId': senderId},
      body: <String, dynamic>{'recipientId': recipientId, 'content': content},
    );

    return _readMapPayload(response);
  }

  /// Get paginated messages for a conversation
  Future<List<Map<String, dynamic>>> getMessages({
    required String token,
    required int conversationId,
    required int userId,
    int page = 0,
    int size = 50,
  }) async {
    final response = await _client.getAny(
      '/api/v1/chat/conversations/$conversationId/messages',
      bearerToken: token,
      query: <String, dynamic>{'userId': userId, 'page': page, 'size': size},
    );

    return _readListPayload(response);
  }

  /// List all conversations for a user
  Future<List<Map<String, dynamic>>> getConversations({
    required String token,
    required int userId,
  }) async {
    final response = await _client.getAny(
      '/api/v1/chat/conversations',
      bearerToken: token,
      query: <String, dynamic>{'userId': userId},
    );

    return _readListPayload(response);
  }

  /// Mark all messages in a conversation as read
  Future<void> markAsRead({
    required String token,
    required int conversationId,
    required int userId,
  }) async {
    await _client.postAny(
      '/api/v1/chat/conversations/$conversationId/read',
      bearerToken: token,
      query: <String, dynamic>{'userId': userId},
    );
  }

  Map<String, dynamic> _readMapPayload(Object? payload) {
    if (payload is Map<String, dynamic>) {
      if (payload.containsKey('success')) {
        final success = payload['success'];
        if (success == true) {
          final data = payload['data'];
          if (data is Map<String, dynamic>) return data;
          return payload;
        }
        throw ApiException(payload['message']?.toString() ?? 'Request failed');
      }
      return payload;
    }
    throw const ApiException('Malformed response payload');
  }

  List<Map<String, dynamic>> _readListPayload(Object? payload) {
    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map((item) => <String, dynamic>{...item})
          .toList();
    }

    if (payload is Map<String, dynamic> && payload.containsKey('success')) {
      final success = payload['success'];
      if (success == true) {
        final data = payload['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((item) => <String, dynamic>{...item})
              .toList();
        }
      }
      throw ApiException(payload['message']?.toString() ?? 'Request failed');
    }

    throw const ApiException('Malformed response payload');
  }
}
