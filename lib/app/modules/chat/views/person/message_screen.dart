// ChatScreen with WhatsApp-like message animation
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/widgets/shimmer/chat_shimmer.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/modules/chat/controller/all_chats_controller.dart';
import 'package:wisper/app/modules/chat/controller/create_chat_controller.dart';
import 'package:wisper/app/modules/chat/controller/message_controller.dart';
import 'package:wisper/app/modules/chat/controller/seen_message_controller.dart';
import 'package:wisper/app/modules/chat/model/message_keys.dart';
import 'package:wisper/app/modules/chat/views/person/message_input_bar.dart';
import 'package:wisper/app/modules/chat/widgets/chatting_header.dart';
import 'package:wisper/app/modules/chat/widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String? receiverId;
  final String? receiverName;
  final String? receiverImage;
  final String? chatId; 
  final bool? isPerson;
  final bool? isOnline;

  const ChatScreen({
    super.key,
    this.receiverId,
    this.receiverName,
    this.receiverImage,
    this.chatId,
    this.isPerson,
    this.isOnline,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ✅ Use Get.find — controller was pre-loaded in ChatListScreen before navigation
  final MessageController ctrl = Get.put(MessageController());
  final CreateChatController createChatController =
      Get.put(CreateChatController());
  final AllChatsController allChatsController =
      Get.put(AllChatsController());
  final SocketService socketService = Get.find<SocketService>();
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();
  final SeenMessageController seenMessageController = SeenMessageController();
  

  bool _showNewMessageIndicator = false;
  bool _isAtBottom = true;
  int _previousMessageCount = 0;
  String? _lastDateSeparator;
  String? _chatId;

  @override
  void initState() {
    super.initState();
    // Suppress blocking no-internet popup while in chat screen.
    connectivityService.suppressDialog.value = true;

    // ✅ Only mark as seen — setupChat already ran before navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatId = widget.chatId;
      if (_chatId != null && _chatId!.isNotEmpty) {
        seenMessageController.seenMessage(_chatId!);
        if (ctrl.currentChatId != _chatId) {
          ctrl.setupChat(chatId: _chatId);
        }
      }
      _previousMessageCount = ctrl.messages.length;
      _scrollToBottom(animated: false);
    });

    ctrl.scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (ctrl.scrollController.hasClients) {
      final maxScroll = ctrl.scrollController.position.maxScrollExtent;
      final currentScroll = ctrl.scrollController.offset;
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
  }

  void _scrollToBottom({bool animated = true}) {
    if (ctrl.scrollController.hasClients) {
      if (animated) {
        ctrl.scrollController.animateTo(
          ctrl.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        ctrl.scrollController.jumpTo(
          ctrl.scrollController.position.maxScrollExtent,
        );
      }
      setState(() {
        _showNewMessageIndicator = false;
      });
    }
  }

  Future<bool> _ensureChatId() async {
    if (_chatId != null && _chatId!.isNotEmpty) return true;
    if (widget.receiverId == null || widget.receiverId!.isEmpty) return false;

    final ok = await createChatController.createChat(
      memberId: widget.receiverId,
    );
    if (!ok) return false;

    final createdId = createChatController.chatId;
    if (createdId.isEmpty) return false;

    if (!mounted) return false;
    setState(() {
      _chatId = createdId;
    });

    // Initialize message socket/list for the new chat
    await ctrl.setupChat(chatId: _chatId);
    // Refresh chat list so new conversation appears immediately
    await allChatsController.getAllChats();
    return true;
  }

  Future<void> _handleSend() async {
    final ok = await _ensureChatId();
    if (!ok) {
      Get.snackbar('Error', 'Unable to start chat');
      return;
    }
    _ensureChatListEntry();
    ctrl.sendMessage(_chatId ?? '');
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _ensureChatListEntry() {
    final String chatId = _chatId ?? '';
    if (chatId.isEmpty) return;

    final int index = socketService.socketFriendList.indexWhere(
      (e) => e['id'] == chatId,
    );
    if (index != -1) return;

    final String text = ctrl.textController.text.trim();
    final String fileUrl = ctrl.imageDecodeController.imageUrl.trim();
    final String lastMessage = text.isNotEmpty
        ? text
        : fileUrl.isNotEmpty
        ? '📷 photo'
        : '📎 file';

    socketService.socketFriendList.add({
      "id": chatId,
      "type": "INDIVIDUAL",
      "latestMessageAt": DateTime.now().toIso8601String(),
      "lastMessage": lastMessage,
      "unreadMessageCount": 0,
      "group": null,
      "groupId": "",
      "classId": "",
      "chatClass": null,
      "receiverName": widget.receiverName ?? '',
      "receiverImage": widget.receiverImage ?? '',
      "receiverId": widget.receiverId ?? '',
      "isPerson": widget.isPerson == true,
      "receiverOnline": widget.isOnline == true,
    });

    socketService.socketFriendList.sort((a, b) {
      final DateTime aTime =
          DateTime.tryParse(a['latestMessageAt'] ?? '') ?? DateTime(1970);
      final DateTime bTime =
          DateTime.tryParse(b['latestMessageAt'] ?? '') ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
    socketService.socketFriendList.refresh();
  }

  void _handleNewMessages() {
    final currentCount = ctrl.messages.length;

    if (currentCount > _previousMessageCount) {
      if (_isAtBottom) {
        Future.delayed(const Duration(milliseconds: 50), () {
          _scrollToBottom();
        });
      } else {
        setState(() {
          _showNewMessageIndicator = true;
        });
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

    final currentSeparator = _getDateSeparatorText(currentDate);
    final prevSeparator = _getDateSeparatorText(prevDate);

    if (currentSeparator != prevSeparator) {
      _lastDateSeparator = currentSeparator;
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
    // Re-enable popup for other screens.
    connectivityService.suppressDialog.value = false;
    ctrl.scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ChatHeader(
            isPerson: widget.isPerson,
            chatId: _chatId ?? widget.chatId,
            name: widget.receiverName,
            image: widget.receiverImage,
            memberId: widget.receiverId,
            status: widget.isOnline,
          ),

          Expanded(
            child: Stack(
              children: [
                Obx(() {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (ctrl.messages.isNotEmpty) {
                      _handleNewMessages();
                    }
                  });

                  if (ctrl.isLoading.value) {
                    return const Center(child: ChatShimmerEffectWidget());
                  }

                  if (ctrl.messages.isEmpty) {
                    return Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "No messages yet",
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  "Start the conversation!",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildEncryptionNotice(),
                      ],
                    );
                  }

                  final displayedMessages = ctrl.messages.toList();

                  return ListView.builder(
                    controller: ctrl.scrollController,
                    reverse: false,
                    padding: EdgeInsets.all(10.r),
                    itemCount: displayedMessages.length + 1, // +1 encryption notice
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

                      // New messages are those beyond the initial loaded count
                      final isNewMessage = messageIndex >=
                          (displayedMessages.length - _previousMessageCount);

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

                // WhatsApp-style new message indicator
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
            onSend: _handleSend,
          ),
        ],
      ),
    );
  }
}

// Animated wrapper for new incoming messages
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

    _slideAnimation =
        Tween<Offset>(
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
