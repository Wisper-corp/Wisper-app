import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/core/widgets/shimmer/member_list_shimmer.dart';
import 'package:wisper/app/modules/calls/controller/all_call_controller.dart';
import 'package:wisper/app/modules/calls/widget/call_list_Tile.dart';
import 'package:wisper/app/modules/profile/views/business/others_business_screen.dart';
import 'package:wisper/app/modules/profile/views/person/others_person_screen.dart';
import 'package:wisper/gen/assets.gen.dart';
import 'package:intl/intl.dart';

class MissedCalls extends StatefulWidget {
  const MissedCalls({super.key});

  @override
  State<MissedCalls> createState() => _MissedCallsState();
}

class _MissedCallsState extends State<MissedCalls> {
  final AllCallController allCallController = Get.put(AllCallController());
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();

  @override
  void initState() {
    super.initState();
    allCallController.getAllCalls();
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

      final allCalls = allCallController.allCallsData ?? [];

      // ✅ শুধু missed call filter করো
      // আমার participant এর status == 'MISSED' হলে missed call
      final missedCalls = allCalls.where((call) {
        final myParticipant = call.participants.firstWhereOrNull(
          (p) => p.auth?.id == currentUserId,
        );
        return myParticipant?.status == 'MISSED';
      }).toList();

      if (missedCalls.isEmpty) {
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
              'No missed calls',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      }

      return Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(0),
          itemCount: missedCalls.length,
          itemBuilder: (context, index) {
            final call = missedCalls[index];

            // অন্য participant খোঁজো (আমি না)
            final otherParticipant = call.participants.firstWhere(
              (p) => p.auth?.id != currentUserId,
              orElse: () => call.participants.first,
            );

            // Name & image
            String displayName = 'Unknown';
            String? displayImage;

            if (otherParticipant.auth?.person?.name != null) {
              displayName = otherParticipant.auth!.person!.name!;
              displayImage = otherParticipant.auth!.person!.image;
            } else if (otherParticipant.auth?.business?.name != null) {
              displayName = otherParticipant.auth!.business!.name!;
              displayImage = otherParticipant.auth!.business!.image;
            }

            final timeStr = _formatCallTime(call.date);

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
                  imagePath: displayImage ?? Assets.images.image.keyName,
                  name: displayName,
                  time: timeStr,
                  callType: 'Missed',
                  callTypeColor: Colors.red,
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
      return DateFormat('h:mm a').format(date);
    } else if (callDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMM').format(date);
    }
  }
}
