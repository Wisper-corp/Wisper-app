import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/services/socket/call_services.dart';
import 'package:wisper/app/modules/calls/views/audio_call.dart';
import 'package:wisper/app/modules/calls/views/video_call.dart';

class PendingCallBanner extends StatefulWidget {
  final Widget child;
  const PendingCallBanner({super.key, required this.child});

  @override
  State<PendingCallBanner> createState() => _PendingCallBannerState();
}

class _PendingCallBannerState extends State<PendingCallBanner> {
  Timer? _dismissTimer;
  Map<String, dynamic>? _currentCallData;
  Worker? _pendingWorker;

  @override
  void initState() {
    super.initState();
    // CallService এর pendingCall listen করো
    final callService = Get.isRegistered<CallService>()
        ? Get.find<CallService>()
        : Get.put(CallService());

    // If pendingCall was already set before this widget mounted, show it
    _currentCallData = callService.pendingCall.value;
    if (_currentCallData != null) {
      _dismissTimer?.cancel();
      _dismissTimer = Timer(const Duration(seconds: 30), () {
        _dismiss();
      });
    }

    _pendingWorker = ever(callService.pendingCall, (callData) {
      if (mounted) {
        setState(() {
          _currentCallData = callData;
        });
        if (callData != null) {
          print('🟢 PendingCallBanner showing for: ${callData['callerName']}');
          _dismissTimer?.cancel();
          _dismissTimer = Timer(const Duration(seconds: 30), () {
            _dismiss();
          });
        } else {
          _dismissTimer?.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _pendingWorker?.dispose();
    super.dispose();
  }

  void _dismiss() {
    final callService = Get.isRegistered<CallService>()
        ? Get.find<CallService>()
        : Get.put(CallService());
    callService.pendingCall.value = null;
  }

  void _joinCall(Map<String, dynamic> callData) {
    _dismiss();
    final callType = callData['callType'] ?? 'AUDIO';
    if (callType == 'VIDEO') {
      Get.to(() => VideoCallPage(
            name: callData['callerName'] ?? '',
            photoUrl: callData['callerImage'] ?? '',
            chatId: '',
            channelName: callData['channelName'] ?? '',
            token: callData['token'] ?? '',
            uuid: callData['uuid'] ?? 0,
            callId: callData['callId'] ?? '',
            groupId: callData['groupId'],
            classId: callData['classId'],
            isGroupCall: callData['isGroupCall'] == true,
            callerName: callData['callerName'],
          ));
    } else {
      Get.to(() => AudioCallPage(
            name: callData['callerName'] ?? '',
            photoUrl: callData['callerImage'] ?? '',
            chatId: '',
            channelName: callData['channelName'] ?? '',
            token: callData['token'] ?? '',
            uuid: callData['uuid'] ?? 0,
            callId: callData['callId'] ?? '',
            groupId: callData['groupId'],
            classId: callData['classId'],
            isGroupCall: callData['isGroupCall'] == true,
            callerName: callData['callerName'],
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentCallData != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF4CAF50), width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage:
                          (_currentCallData!['callerImage'] ?? '').isNotEmpty
                              ? NetworkImage(
                                  _currentCallData!['callerImage'])
                              : null,
                      backgroundColor: const Color(0xFF4CAF50),
                      child: (_currentCallData!['callerImage'] ?? '').isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentCallData!['callerName'] ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                _currentCallData!['callType'] == 'VIDEO'
                                    ? Icons.videocam
                                    : Icons.phone_in_talk,
                                color: const Color(0xFF4CAF50),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentCallData!['callType'] == 'VIDEO'
                                    ? 'Video call accepted'
                                    : 'Audio call accepted',
                                style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _joinCall(_currentCallData!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Join',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: const Icon(Icons.close,
                          color: Colors.white54, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
