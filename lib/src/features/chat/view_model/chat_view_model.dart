import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../model/chat_models.dart';

// ─────────────────── Conversations List ───────────────────

class ConversationsController extends AsyncNotifier<List<Conversation>> {
  Timer? _pollTimer;

  @override
  Future<List<Conversation>> build() {
    ref.onDispose(() => _pollTimer?.cancel());
    _startPolling();
    return _fetch();
  }

  Future<List<Conversation>> _fetch() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated || auth.userId == null) {
      return const <Conversation>[];
    }

    final chatApi = ref.read(chatApiProvider);
    final rawList = await chatApi.getConversations(
      token: auth.token!,
      userId: auth.userId!,
    );

    final conversations = rawList.map(Conversation.fromMap).toList();
    conversations.sort((a, b) {
      final aTime = a.lastMessageAt ?? a.createdAt ?? DateTime(2000);
      final bTime = b.lastMessageAt ?? b.createdAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return conversations;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final result = await _fetch();
        state = AsyncValue.data(result);
      } catch (error, stackTrace) {
        AppLogger.error(
          'Conversation poll failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final conversationsControllerProvider =
    AsyncNotifierProvider<ConversationsController, List<Conversation>>(
      ConversationsController.new,
    );

// ─────────────────── Chat Messages ───────────────────

class ChatMessagesState {
  const ChatMessagesState({
    this.messages = const <ChatMessage>[],
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;

  ChatMessagesState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ChatMessagesController extends FamilyNotifier<ChatMessagesState, int> {
  Timer? _pollTimer;

  @override
  ChatMessagesState build(int conversationId) {
    ref.onDispose(() => _pollTimer?.cancel());
    _loadMessages();
    _startPolling();
    return const ChatMessagesState(isLoading: true);
  }

  Future<void> _loadMessages() async {
    try {
      final auth = ref.read(authControllerProvider);
      if (!auth.isAuthenticated || auth.userId == null) return;

      final chatApi = ref.read(chatApiProvider);
      final rawList = await chatApi.getMessages(
        token: auth.token!,
        conversationId: arg,
        userId: auth.userId!,
        page: 0,
        size: 100,
      );

      final messages = rawList.map(ChatMessage.fromMap).toList();
      messages.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return aTime.compareTo(bTime);
      });

      state = state.copyWith(
        messages: messages,
        isLoading: false,
        clearError: true,
      );

      // Mark as read
      await chatApi.markAsRead(
        token: auth.token!,
        conversationId: arg,
        userId: auth.userId!,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final auth = ref.read(authControllerProvider);
        if (!auth.isAuthenticated || auth.userId == null) return;

        final chatApi = ref.read(chatApiProvider);
        final rawList = await chatApi.getMessages(
          token: auth.token!,
          conversationId: arg,
          userId: auth.userId!,
          page: 0,
          size: 100,
        );

        final messages = rawList.map(ChatMessage.fromMap).toList();
        messages.sort((a, b) {
          final aTime = a.createdAt ?? DateTime(2000);
          final bTime = b.createdAt ?? DateTime(2000);
          return aTime.compareTo(bTime);
        });

        state = state.copyWith(messages: messages, clearError: true);

        await chatApi.markAsRead(
          token: auth.token!,
          conversationId: arg,
          userId: auth.userId!,
        );
      } catch (error) {
        AppLogger.error('Chat poll failed', error: error);
      }
    });
  }

  Future<bool> sendMessage({
    required int jobId,
    required int recipientId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return false;

    state = state.copyWith(isSending: true, clearError: true);

    try {
      final auth = ref.read(authControllerProvider);
      if (!auth.isAuthenticated || auth.userId == null) return false;

      final chatApi = ref.read(chatApiProvider);
      final rawMsg = await chatApi.sendMessage(
        token: auth.token!,
        jobId: jobId,
        senderId: auth.userId!,
        recipientId: recipientId,
        content: content.trim(),
      );

      final newMessage = ChatMessage.fromMap(rawMsg);
      final updatedMessages = [...state.messages, newMessage];

      state = state.copyWith(messages: updatedMessages, isSending: false);
      ref.invalidate(conversationsControllerProvider);
      return true;
    } catch (error) {
      state = state.copyWith(isSending: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadMessages();
  }
}

final chatMessagesControllerProvider =
    NotifierProvider.family<ChatMessagesController, ChatMessagesState, int>(
      ChatMessagesController.new,
    );
