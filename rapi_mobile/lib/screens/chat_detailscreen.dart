import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rapi_advmobprog/widgets/custom_text.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';

final ChatService chatService = ChatService();

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    super.key,
    required this.currentUserEmail,
    required this.tappedUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<String> _currentUserIdFuture;
  bool _isSending = false;
  Timestamp? _sendingStartedAt;

  // Local pending messages (optimistic UI)
  final List<_PendingMessage> _pendingMessages = [];

  static const _postSendDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  Future<String> _getCurrentUserId() async {
    // Chat requires Firebase login; get UID from FirebaseAuth
    final user = userService.value.currentUser;
    return user?.uid ?? '';
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _sendingStartedAt = Timestamp.now();
      // Add local pending bubble
      _pendingMessages.insert(
        0,
        _PendingMessage(
          id: UniqueKey().toString(),
          text: text,
          createdAt: DateTime.now(),
        ),
      );
    });

    try {
      await chatService.sendMessage(receiverId, text);
      _msgCtrl.clear();
      _msgFocus.requestFocus();
      if (_scrollCtrl.hasClients) {
        await _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      await Future.delayed(_postSendDelay);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendingStartedAt = null;
          if (_pendingMessages.isNotEmpty) {
            _pendingMessages.removeAt(0);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = widget.tappedUser['uid'] ?? '';
    final firstName = (widget.tappedUser['firstName'] ?? '').toString();
    final lastName = (widget.tappedUser['lastName'] ?? '').toString();
    final email = (widget.tappedUser['email'] ?? '').toString();
    final username = (widget.tappedUser['username'] ?? '').toString();
    final fullName = ('$firstName $lastName').trim();
    final tappedUserName = fullName.isNotEmpty
        ? fullName
        : (username.isNotEmpty
              ? username
              : (email.isNotEmpty ? email : 'Unknown'));

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: CustomText(
                key: ValueKey(tappedUserName),
                text: tappedUserName,
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading messages: ${snapshot.error}',
                        ),
                      );
                    }

                    List<QueryDocumentSnapshot> docs =
                        snapshot.data?.docs ?? [];

                    // Prevent duplicate bubble during optimistic send by hiding
                    // any just-sent message from the stream that matches a pending one
                    if (_pendingMessages.isNotEmpty) {
                      final pendingTexts = _pendingMessages
                          .map((p) => p.text)
                          .toSet();
                      docs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final senderId = (data['senderId'] ?? '').toString();
                        if (senderId != currentUserId) return true;
                        final msgText = (data['message'] ?? '').toString();
                        if (!pendingTexts.contains(msgText)) return true;
                        // Optional: also check timestamp proximity
                        final ts = data['timestamp'];
                        final sentAt = (ts is Timestamp) ? ts.toDate() : null;
                        if (sentAt == null) return false;
                        // If within a short window of local pending creation, hide it
                        final threshold = DateTime.now().subtract(
                          const Duration(seconds: 5),
                        );
                        return sentAt.isBefore(threshold);
                      }).toList();
                    }

                    if (docs.isEmpty) {
                      return const Center(child: Text('No messages yet'));
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: docs.length + _pendingMessages.length,
                      itemBuilder: (context, index) {
                        // First show pending items (top of list)
                        if (index < _pendingMessages.length) {
                          final pending = _pendingMessages[index];
                          return _MessageBubble(
                            text: pending.text,
                            isMe: true,
                            isPending: true,
                            timestamp: pending.createdAt,
                          );
                        }

                        final docIndex = index - _pendingMessages.length;
                        final data =
                            docs[docIndex].data() as Map<String, dynamic>;
                        final msgText = (data['message'] ?? '').toString();
                        final senderId = (data['senderId'] ?? '').toString();
                        final isMe = senderId == currentUserId;
                        final ts = data['timestamp'];
                        final sentAt = (ts is Timestamp)
                            ? ts.toDate()
                            : DateTime.now();

                        return _MessageBubble(
                          text: msgText.isNotEmpty ? msgText : '[empty]',
                          isMe: isMe,
                          isPending: false,
                          timestamp: sentAt,
                        );
                      },
                    );
                  },
                ),
              ),
              // Composer
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          focusNode: _msgFocus,
                          enabled: !_isSending,
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) => !_isSending
                              ? _send(currentUserId, tappedUserId)
                              : null,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: const TextStyle(fontFamily: 'Poppins'),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isSending
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () =>
                                  _send(currentUserId, tappedUserId),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final bool isPending;
  final DateTime timestamp;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.isPending,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMe
        ? Theme.of(context).colorScheme.primary.withOpacity(0.85)
        : Colors.grey.shade200;
    final fg = isMe ? Colors.white : Colors.black87;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bg,
          gradient: isMe
              ? LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.95),
                    Theme.of(context).colorScheme.primary.withOpacity(0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: isMe
                ? const Radius.circular(14)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(
                text,
                key: ValueKey(text),
                style: TextStyle(
                  color: fg,
                  fontFamily: 'Poppins',
                  fontSize: 15.sp,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(timestamp),
                  style: TextStyle(color: fg.withOpacity(0.8), fontSize: 11.sp),
                ),
                const SizedBox(width: 6),
                if (isMe)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isPending
                        ? SizedBox(
                            key: const ValueKey('sending'),
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                fg.withOpacity(0.9),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.check,
                            key: const ValueKey('sent'),
                            size: 14,
                            color: fg.withOpacity(0.9),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

class _PendingMessage {
  final String id;
  final String text;
  final DateTime createdAt;

  _PendingMessage({
    required this.id,
    required this.text,
    required this.createdAt,
  });
}
