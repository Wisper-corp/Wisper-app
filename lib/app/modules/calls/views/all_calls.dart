import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // ← add this for date formatting
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/core/widgets/shimmer/member_list_shimmer.dart';
import 'package:wisper/app/modules/calls/controller/all_call_controller.dart';
import 'package:wisper/app/modules/calls/widget/call_list_Tile.dart';
import 'package:wisper/app/modules/profile/views/business/others_business_screen.dart';
import 'package:wisper/app/modules/profile/views/person/others_person_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class AllCalls extends StatefulWidget {
  const AllCalls({super.key});

  @override
  State<AllCalls> createState() => _AllCallsState();
}

class _AllCallsState extends State<AllCalls> {
  final AllCallController allCallController = Get.put(AllCallController());
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();

  @override
  void initState() {
    allCallController.getAllCalls();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = StorageUtil.getData(StorageUtil.userId) ?? '';

    return Obx(() {
      if (allCallController.inProgress) {
        return SizedBox(
          height: Get.height / 2,
          child: Center(child: MemberShimmerEffectWidget()),
        );
      }

      if (allCallController.allCallsData?.isEmpty ?? true) {
        if (!connectivityService.isOnline.value) {
          return SizedBox(
            height: Get.height / 2,
            child: Center(child: MemberShimmerEffectWidget()),
          );
        }
        return SizedBox(
          height: Get.height / 2,
          child: const Center(
            child: Text(
              'No calls yet',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      }

      final calls = allCallController.allCallsData!;

      return Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(0),
          itemCount: calls.length,
          itemBuilder: (context, index) {
            final call = calls[index];

            // Find the OTHER participant (not current user)
            final otherParticipant = call.participants.firstWhere(
              (p) => p.auth?.id != currentUserId,
              orElse: () =>
                  call.participants.first, // fallback (shouldn't happen)
            );

            // Get name & image — person has priority, then business
            String displayName = 'Unknown';
            String? displayImage;

            if (otherParticipant.auth?.person?.name != null) {
              displayName = otherParticipant.auth!.person!.name!;
              displayImage = otherParticipant.auth!.person!.image;
            } else if (otherParticipant.auth?.business?.name != null) {
              displayName = otherParticipant.auth!.business!.name!;
              displayImage = otherParticipant.auth!.business!.image;
            }

            // Format time (you can customize format)
            final timeStr = _formatCallTime(call.date);

            // You can also show incoming/outgoing based on logic
            // Example: if first participant is me → outgoing, else incoming
            final isOutgoing =
                call.participants.first.auth?.id == currentUserId;
            final callType = isOutgoing ? 'Outgoing' : 'Incoming';
            final callTypeColor = isOutgoing
                ? LightThemeColors.themeGreyColor
                : Colors.green.shade700; // ← customize as needed

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: GestureDetector(
                onTap: () {
                  otherParticipant.auth?.person != null
                      ? Get.to(
                          OthersPersonScreen(
                            userId: otherParticipant.auth!.id ?? '',
                          ),
                        )
                      : Get.to(
                          OthersBusinessScreen(
                            userId: otherParticipant.auth?.id ?? '',
                          ),
                        );
                },
                child: CallListTile(
                  imagePath:
                      displayImage ??
                      Assets.images.image.keyName, // fallback image
                  name: call.mode == 'GROUP' ? displayName : displayName,
                  time: timeStr,
                  callType: callType,
                  callTypeColor: callTypeColor,
                ),
              ),
            );
          },
        ),
      );
    });
  }

  String _formatCallTime(DateTime? date) {
    if (date == null) return '—';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final callDay = DateTime(date.year, date.month, date.day);

    if (callDay == today) {
      return DateFormat('h:mm a').format(date); // 11:30 AM
    } else if (callDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMM').format(date); // 05 Mar
    }
  }
}
