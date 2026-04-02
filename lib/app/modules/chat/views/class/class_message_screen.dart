// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/modules/chat/controller/message_controller.dart';
import 'package:wisper/app/modules/chat/controller/seen_message_controller.dart';
import 'package:wisper/app/modules/chat/model/message_keys.dart';
import 'package:wisper/app/modules/chat/views/person/message_input_bar.dart';
import 'package:wisper/app/modules/chat/widgets/class_chatting_header.dart';
import 'package:wisper/app/modules/chat/widgets/empty_group_card.dart';
import 'package:wisper/app/modules/chat/widgets/message_bubble.dart';

class ClassChatScreen extends StatefulWidget {
  final String? className;
  final String? classImage;
  final String? chatId;
  final String? classId;
  final bool? isOnline;

  const ClassChatScreen({
    super.key,
    this.className,
    this.classImage,
    this.chatId,
    this.classId,
    this.isOnline,
  });

  @override
  State<ClassChatScreen> createState() => _ClassChatScreenState();
}

class _ClassChatScreenState extends State<ClassChatScreen> {
  final MessageController ctrl = Get.isRegistered<MessageController>()
      ? Get.find<MessageController>()
      : Get.put(MessageController());
  final SeenMessageController seenMessageController = SeenMessageController();
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();

  // ✅ নিজস্ব ScrollController
  final ScrollController _scrollController = ScrollController();

  bool _showNewMessageIndicator = false;
  bool _isAtBottom = true;
  int _previousMessageCount = 0;
  int _initialMessageCount = 0;
  bool _initialScrollDone = false;
  String? _lastDateSeparator;
  Worker? _messagesWorker;

  @override
  void initState() {
    super.initState();
    connectivityService.suppressDialog.value = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.chatId != null && widget.chatId!.isNotEmpty) {
        seenMessageController.seenMessage(widget.chatId!);
        if (ctrl.currentChatId != widget.chatId) {
          ctrl.setupChat(chatId: widget.chatId);
        }
      }

      _previousMessageCount = ctrl.messages.length;
      _initialMessageCount = ctrl.messages.length;

      if (ctrl.messages.isNotEmpty) {
        _initialScrollDone = true;
        _initialMessageCount = ctrl.messages.length;
        _previousMessageCount = ctrl.messages.length;
        _scrollToBottom(animated: false);
      }
    });

    _scrollController.addListener(_scrollListener);

    _messagesWorker = ever(ctrl.messages, (_) {
      if (!mounted) return;
      _handleNewMessages();
    });
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.positions.length != 1) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    const threshold = 100.0;
    final isAtBottom = (maxScroll - currentScroll) <= threshold;

    if (isAtBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = isAtBottom;
        if (isAtBottom && _showNewMessageIndicator) {
          _showNewMessageIndicator = false;
        }
      });
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (_scrollController.positions.length != 1) return;

    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    }

    if (mounted) {
      setState(() => _showNewMessageIndicator = false);
    }
  }

  void _handleNewMessages() {
    final currentCount = ctrl.messages.length;

    if (!_initialScrollDone && currentCount > 0) {
      _initialScrollDone = true;
      _initialMessageCount = currentCount;
      _previousMessageCount = currentCount;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _scrollToBottom(animated: false);
      });
      return;
    }

    if (currentCount < _previousMessageCount) {
      _previousMessageCount = currentCount;
      if (mounted && _showNewMessageIndicator) {
        setState(() => _showNewMessageIndicator = false);
      }
      return;
    }

    if (currentCount > _previousMessageCount) {
      final lastMsg = ctrl.messages.isNotEmpty ? ctrl.messages.last : null;
      final isMyMessage =
          lastMsg != null &&
          lastMsg[SocketMessageKeys.senderId] == ctrl.userAuthId;

      if (isMyMessage) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _scrollToBottom();
        });
      } else if (_isAtBottom) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) _scrollToBottom();
        });
      } else {
        if (mounted) {
          setState(() => _showNewMessageIndicator = true);
        }
      }

      _previousMessageCount = currentCount;
    }
  }

  String _getDateSeparatorText(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
    }
  }

  bool _shouldShowDateSeparator(
    int index,
    List<Map<String, dynamic>> messages,
  ) {
    if (messages.isEmpty || index >= messages.length) return false;

    final currentMsg = messages[index];
    final currentDate =
        DateTime.tryParse(currentMsg[SocketMessageKeys.createdAt]) ??
        DateTime.now();

    if (index == 0) {
      _lastDateSeparator = _getDateSeparatorText(currentDate);
      return true;
    }

    final prevMsg = messages[index - 1];
    final prevDate =
        DateTime.tryParse(prevMsg[SocketMessageKeys.createdAt]) ??
        DateTime.now();

    if (_getDateSeparatorText(currentDate) !=
        _getDateSeparatorText(prevDate)) {
      _lastDateSeparator = _getDateSeparatorText(currentDate);
      return true;
    }

    return false;
  }

  Widget _buildDateSeparator(String text) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 16.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEncryptionNotice() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        children: [
          Text(
            "🔒 Messages and calls are end-to-end encrypted",
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 4.h),
          Text(
            "No one outside of this chat can read or listen to them.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    connectivityService.suppressDialog.value = false;
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _messagesWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ClassChatHeader(
            chatId: widget.chatId ?? '',
            className: widget.className ?? '',
            classImage: widget.classImage ?? '',
            classId: widget.classId ?? '',
          ),

          Expanded(
            child: Stack(
              children: [
                Obx(() {
                  if (ctrl.messages.isEmpty) {
                    return Center(
                      child: EmptyGroupInfoCard(
                        isGroup: false,
                        name: widget.className ?? '',
                        member: '5',
                      ),
                    );
                  }

                  final displayedMessages = ctrl.messages.toList();

                  return ListView.builder(
                    controller: _scrollController, // ✅ নিজস্ব controller
                    reverse: false,
                    padding: EdgeInsets.all(10.r),
                    itemCount: displayedMessages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildEncryptionNotice();

                      final messageIndex = index - 1;
                      if (messageIndex >= displayedMessages.length) {
                        return const SizedBox.shrink();
                      }

                      final msg = displayedMessages[messageIndex];
                      final isMe =
                          msg[SocketMessageKeys.senderId] == ctrl.userAuthId;
                      final imageUrl = msg[SocketMessageKeys.imageUrl] ?? "";

                      final showDateSeparator = _shouldShowDateSeparator(
                        messageIndex,
                        displayedMessages,
                      );

                      final isNewMessage = messageIndex >= _initialMessageCount;

                      return Column(
                        children: [
                          if (showDateSeparator && _lastDateSeparator != null)
                            _buildDateSeparator(_lastDateSeparator!),

                          if (isNewMessage)
                            AnimatedMessageBubble(
                              message: msg,
                              isMe: isMe,
                              fileUrl: imageUrl,
                              fileType: msg[SocketMessageKeys.fileType] ?? '',
                              senderImage: msg[SocketMessageKeys.senderImage],
                              senderName: msg[SocketMessageKeys.senderName],
                              time: DateFormatter(
                                msg[SocketMessageKeys.createdAt],
                              ).getRelativeTimeFormat(),
                              isGroupChat: false,
                            )
                          else
                            MessageBubble(
                              message: msg,
                              isMe: isMe,
                              fileUrl: imageUrl,
                              fileType: msg[SocketMessageKeys.fileType] ?? '',
                              senderImage: msg[SocketMessageKeys.senderImage],
                              senderName: msg[SocketMessageKeys.senderName],
                              time: DateFormatter(
                                msg[SocketMessageKeys.createdAt],
                              ).getRelativeTimeFormat(),
                              isGroupChat: false,
                            ),
                        ],
                      );
                    },
                  );
                }),

                // ✅ New message indicator
                if (_showNewMessageIndicator)
                  Positioned(
                    bottom: 70.h,
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: _scrollToBottom,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff2799EA),
                            borderRadius: BorderRadius.circular(24.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 24.r,
                                height: 24.r,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: Icon(
                                  Icons.arrow_downward,
                                  color: const Color(0xff2799EA),
                                  size: 14.sp,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'New messages',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          MessageInputBar(
            controller: ctrl.textController,
            onSend: () {
              ctrl.sendMessage(widget.chatId ?? '');
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) _scrollToBottom();
              });
            },
          ),
        ],
      ),
    );
  }
}

// ✅ Animated wrapper
class AnimatedMessageBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final String fileUrl;
  final String fileType;
  final String senderName;
  final String? senderImage;
  final String time;
  final bool isGroupChat;

  const AnimatedMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.fileUrl,
    required this.fileType,
    required this.senderName,
    this.senderImage,
    required this.time,
    this.isGroupChat = false,
  });

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: MessageBubble(
          message: widget.message,
          isMe: widget.isMe,
          fileUrl: widget.fileUrl,
          fileType: widget.fileType,
          senderName: widget.senderName,
          senderImage: widget.senderImage,
          time: widget.time,
          isGroupChat: widget.isGroupChat,
        ),
      ),
    );
  }
}