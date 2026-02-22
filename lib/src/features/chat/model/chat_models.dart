class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.isRead,
    this.createdAt,
  });

  final int id;
  final int conversationId;
  final int senderId;
  final String content;
  final bool isRead;
  final DateTime? createdAt;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: _asInt(map['id']),
      conversationId: _asInt(map['conversationId']),
      senderId: _asInt(map['senderId']),
      content: map['content']?.toString() ?? '',
      isRead: _asBool(map['isRead']),
      createdAt: _asDateTime(map['createdAt']),
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.participantOneId,
    required this.participantTwoId,
    this.participantOneName,
    this.participantTwoName,
    this.unreadCount = 0,
    this.lastMessageAt,
    this.createdAt,
  });

  final int id;
  final int jobId;
  final String jobTitle;
  final int participantOneId;
  final int participantTwoId;
  final String? participantOneName;
  final String? participantTwoName;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  /// Get the display name for the other participant
  String otherParticipantName(int currentUserId) {
    if (currentUserId == participantOneId) {
      return participantTwoName ?? 'User';
    }
    return participantOneName ?? 'User';
  }

  int otherParticipantId(int currentUserId) {
    if (currentUserId == participantOneId) {
      return participantTwoId;
    }
    return participantOneId;
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: _asInt(map['id']),
      jobId: _asInt(map['jobId']),
      jobTitle: map['jobTitle']?.toString() ?? 'Untitled',
      participantOneId: _asInt(map['participantOneId']),
      participantTwoId: _asInt(map['participantTwoId']),
      participantOneName: map['participantOneName']?.toString(),
      participantTwoName: map['participantTwoName']?.toString(),
      unreadCount: _asInt(map['unreadCount']),
      lastMessageAt: _asDateTime(map['lastMessageAt']),
      createdAt: _asDateTime(map['createdAt']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true';
}

DateTime? _asDateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
