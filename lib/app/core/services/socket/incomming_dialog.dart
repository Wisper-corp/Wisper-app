
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:wisper/app/core/services/socket/call_services.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/gen/assets.gen.dart';

class IncomingCallDialog extends StatefulWidget {
  final String callerName;
  final String callerImage;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isGroup;

  const IncomingCallDialog({
    required this.callerName,
    required this.callerImage,
    required this.onAccept,
    required this.onReject,
    required this.isGroup,
  });

  @override
  State<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<IncomingCallDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xff1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Incoming Call...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 2.5),
                ),
                child: widget.callerImage == 'group'
                    ? CircleIconWidget(
                        color: const Color(0xff051B33),
                        iconColor: const Color(0xff1F7DE9),
                        iconRadius: 35,
                        radius: 35,
                        imagePath: Assets.images.userGroup.keyName,
                        onTap: () {},
                      )
                    : CircleAvatar(
                        radius: 45,
                        backgroundColor: const Color(0xff2A2A2A),
                        backgroundImage: widget.callerImage.isNotEmpty
                            ? NetworkImage(widget.callerImage)
                            : null,
                        child: widget.callerImage.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 45,
                                color: Colors.white70,
                              )
                            : null,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            widget.isGroup
                ? const Text(
                    'Group',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 8),
            const Text(
              'is calling you...',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 36),
            Obx(() {
              final callService = Get.find<CallService>();
              if (callService.isLoading.value) {
                return const Column(
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 12),
                    Text(
                      'Connecting...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: widget.onReject,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Decline',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: widget.onAccept,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Accept',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
