import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../model/chat_models.dart';
import '../view_model/chat_view_model.dart';
import 'chat_detail_view.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: conversationsAsync.when(
        loading: () => const LoadingState(message: 'Loading conversations...'),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () =>
              ref.read(conversationsControllerProvider.notifier).refresh(),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No messages yet',
              subtitle:
                  'Your conversations will appear here when you start chatting about a task.',
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(conversationsControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                return _ConversationTile(conversation: conversations[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final currentUserId = auth.userId ?? 0;
    final otherName = conversation.otherParticipantName(currentUserId);
    final hasUnread = conversation.unreadCount > 0;

    final timeText = conversation.lastMessageAt != null
        ? _formatTime(conversation.lastMessageAt!)
        : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppPalette.primary.withValues(alpha: 0.1),
        child: Text(
          otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppPalette.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherName,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 12,
              color: hasUnread ? AppPalette.primary : AppPalette.textSecondary,
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              'Re: ${conversation.jobTitle}',
              style: TextStyle(
                fontSize: 13,
                color: AppPalette.textSecondary,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppPalette.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversationId: conversation.id,
              jobId: conversation.jobId,
              otherUserId: conversation.otherParticipantId(currentUserId),
              otherUserName: otherName,
              jobTitle: conversation.jobTitle,
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return DateFormat.jm().format(dateTime);
    if (diff.inDays < 7) return DateFormat.E().format(dateTime);
    return DateFormat.MMMd().format(dateTime);
  }
}
