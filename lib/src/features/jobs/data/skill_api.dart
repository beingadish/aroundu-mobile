import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

/// A skill returned by the auto-suggest endpoint.
class SkillItem {
  const SkillItem({required this.id, required this.skillName});

  final int id;
  final String skillName;

  factory SkillItem.fromMap(Map<String, dynamic> map) {
    return SkillItem(
      id: _asInt(map['id']),
      skillName: map['skillName']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SkillItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Data source for skill operations.
class SkillApi {
  const SkillApi(this._client);

  final ApiClient _client;

  /// GET /api/v1/skills/suggest?query=...&limit=...
  ///
  /// Returns skills whose name contains [query] (case-insensitive).
  /// Requires a valid JWT [bearerToken] — the endpoint sits behind Spring Security.
  Future<List<SkillItem>> suggestSkills(
    String query, {
    required String bearerToken,
    int limit = 10,
  }) async {
    final response = await _client.getJson(
      '/api/v1/skills/suggest',
      query: <String, dynamic>{'query': query, 'limit': limit},
      bearerToken: bearerToken,
    );

    final data = response['data'];
    if (data == null) return const <SkillItem>[];

    if (data is! List) {
      throw const ApiException('Malformed skill suggest response');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(SkillItem.fromMap)
        .toList();
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
