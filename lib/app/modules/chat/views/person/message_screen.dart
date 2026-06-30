// ChatScreen with WhatsApp-like message animation
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/widgets/shimmer/chat_shimmer.dart';
import 'package:wisper/app/modules/chat/controller/message_controller.dart';
import 'package:wisper/app/modules/chat/controller/offer_service.dart';
import 'package:wisper/app/modules/chat/controller/seen_message_controller.dart';
import 'package:wisper/app/modules/chat/model/message_keys.dart';
import 'package:wisper/app/modules/chat/model/offer_model.dart';
import 'package:wisper/app/modules/chat/views/person/message_input_bar.dart';
import 'package:wisper/app/modules/chat/widgets/chatting_header.dart';
import 'package:wisper/app/modules/chat/widgets/message_bubble.dart';
import 'package:wisper/app/modules/chat/widgets/offer_card.dart';

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
  final MessageController ctrl = Get.put(MessageController());
  final ScrollController _scrollController = ScrollController();
  final SeenMessageController seenMessageController = SeenMessageController();
  late final OfferService _offerService;
  bool _showNewMessageIndicator = false;
  bool _isAtBottom = true;
  int _previousMessageCount = 0;
  String? _lastDateSeparator;

  @override
  void initState() {
    print(
      'Chat ID: ${widget.chatId} Receiver ID: ${widget.receiverId} Receiver Name: ${widget.receiverName} Receiver Image: ${widget.receiverImage}',
    );

    try {
      _offerService = Get.find<OfferService>();
    } catch (_) {
      _offerService = Get.put(OfferService());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      seenMessageController.seenMessage(widget.chatId!);
      ctrl.setupChat(chatId: widget.chatId);
      _loadOffers();
      _scrollToBottom(animated: false);
    });

    _scrollController.addListener(_scrollListener);
    super.initState();
  }

  /// Load all offers for this chat and inject them as messages
  Future<void> _loadOffers() async {
    if (widget.chatId == null || widget.chatId!.isEmpty) return;
    try {
      final offers = await _offerService.getOffersByChatId(widget.chatId!);
      for (final offer in offers) {
        ctrl.injectOfferMessage(offer);
      }
    } catch (e) {
      print('Failed to load offers: $e');
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final threshold = 100.0; // WhatsApp-like threshold
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
    if (_scrollController.hasClients) {
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
      setState(() {
        _showNewMessageIndicator = false;
      });
    }
  }

  void _handleNewMessages() {
    final currentCount = ctrl.messages.length;

    if (currentCount > _previousMessageCount) {
      final newMessagesCount = currentCount - _previousMessageCount;

      // If user is at bottom, auto scroll with animation
      if (_isAtBottom) {
        Future.delayed(const Duration(milliseconds: 50), () {
          _scrollToBottom();
        });
      } else {
        // Show new message indicator
        setState(() {
          _showNewMessageIndicator = true;
        });
      }

      _previousMessageCount = currentCount;
    }
  }

  // Helper to get date separator text
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
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
    }
  }

  // Check if we need to show date separator for this message
  bool _shouldShowDateSeparator(
    int index,
    List<Map<String, dynamic>> messages,
  ) {
    if (messages.isEmpty || index >= messages.length) return false;

    final currentMsg = messages[index];
    final currentDateStr = currentMsg[SocketMessageKeys.createdAt];
    final currentDate = DateTime.tryParse(currentDateStr) ?? DateTime.now();

    if (index == 0) {
      _lastDateSeparator = _getDateSeparatorText(currentDate);
      return true;
    }

    final prevMsg = messages[index - 1];
    final prevDateStr = prevMsg[SocketMessageKeys.createdAt];
    final prevDate = DateTime.tryParse(prevDateStr) ?? DateTime.now();

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

  /// Builds a Fiverr-style offer bubble aligned to sender side
  Widget _buildOfferBubble(Map<String, dynamic> msg, bool isMe) {
    final offer = msg[SocketMessageKeys.offerData];
    if (offer == null) return const SizedBox.shrink();
    final currentUserId = StorageUtil.getData(StorageUtil.userId) ?? '';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            SizedBox(width: 8.w),
          ],
          Container(
            margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xff2799EA) : const Color(0xff1E1E1E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
                bottomLeft: isMe ? Radius.circular(16.r) : Radius.circular(0),
                bottomRight: isMe ? Radius.circular(0) : Radius.circular(16.r),
              ),
              border: Border.all(
                color: isMe
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
                bottomLeft: isMe ? Radius.circular(16.r) : Radius.circular(0),
                bottomRight: isMe ? Radius.circular(0) : Radius.circular(16.r),
              ),
              child: OfferCard(
                offer: offer,
                currentUserId: currentUserId,
                onOfferUpdated: (updatedOffer) {
                  ctrl.injectOfferMessage(updatedOffer);
                },
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(width: 8.w),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
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
            chatId: widget.chatId,
            name: widget.receiverName,
            image: widget.receiverImage,
            memberId: widget.receiverId,
            status: widget.isOnline,
          ),

          Expanded(
            child: Stack(
              children: [
                Obx(() {
                  // Handle new messages
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
                                  "No messages yet 3", 
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

                  // Create a reversed list for display (newest at bottom)
                  final displayedMessages = ctrl.messages
                      .toList()
                      .reversed
                      .toList();

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: false, // Regular list (newest at bottom)
                    padding: EdgeInsets.only(
                      top: 10.r,
                      bottom: 10.r,
                      left: 10.r,
                      right: 10.r,
                    ),
                    itemCount:
                        displayedMessages.length +
                        1, // +1 for encryption notice
                    itemBuilder: (context, index) {
                      // Encryption notice at top
                      if (index == 0) {
                        return _buildEncryptionNotice();
                      }

                      // Adjust index for message items
                      final messageIndex = index - 1;

                      if (messageIndex >= displayedMessages.length) {
                        return const SizedBox.shrink();
                      }

                      final msg = displayedMessages[messageIndex];
                      final isMe =
                          msg[SocketMessageKeys.senderId] == ctrl.userAuthId;
                      final imageUrl = msg[SocketMessageKeys.imageUrl] ?? "";

                      // Check if we need date separator
                      bool showDateSeparator = _shouldShowDateSeparator(
                        messageIndex,
                        displayedMessages,
                      );

                      return Column(
                        children: [
                          if (showDateSeparator && _lastDateSeparator != null)
                            _buildDateSeparator(_lastDateSeparator!),

                          // ── OFFER MESSAGE ──────────────────────────────
                          if (msg[SocketMessageKeys.fileType] == SocketMessageKeys.offerFileType)
                            _buildOfferBubble(msg, isMe)
                          // ── REGULAR MESSAGE ────────────────────────────
                          else if (messageIndex <
                              (ctrl.messages.length - _previousMessageCount))
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
                    bottom: 70.h, // Position above message input bar
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {
                          _scrollToBottom();
                        },
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
                                decoration: BoxDecoration(
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
            chatId: widget.chatId ?? '',
            receiverId: widget.receiverId ?? '',
            onSend: () {
              ctrl.sendMessage(widget.chatId ?? '');
              // Auto scroll after sending message
              Future.delayed(const Duration(milliseconds: 100), () {
                _scrollToBottom();
              });
            },
          ),
        ],
      ),
    );
  }
}

// New animated version of MessageBubble
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
        Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
          ),
        );

    // Start animation after a small delay
    Future.delayed(const Duration(milliseconds: 50), () {
      _controller.forward();
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
