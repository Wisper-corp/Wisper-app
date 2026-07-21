import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/calls/controller/call_logs_controller.dart';
import 'package:wisper/app/modules/calls/widget/call_list_Tile.dart';

class MissedCalls extends StatelessWidget {
  const MissedCalls({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CallLogsController>();

    return Expanded(
      child: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.hasError.value) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.grey, size: 40.sp),
                SizedBox(height: 8.h),
                Text(
                  'Failed to load calls',
                  style: TextStyle(color: Colors.grey, fontSize: 13.sp),
                ),
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: ctrl.fetchCallLogs,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (ctrl.missedCalls.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_missed_rounded, color: Colors.grey, size: 48.sp),
                SizedBox(height: 10.h),
                Text(
                  'No missed calls',
                  style: TextStyle(color: Colors.grey, fontSize: 13.sp),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: ctrl.fetchCallLogs,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: ctrl.missedCalls.length,
            separatorBuilder: (_, __) => Divider(
              color: const Color(0xff2A2A2A),
              height: 1,
              thickness: 0.5,
            ),
            itemBuilder: (context, index) {
              final call = ctrl.missedCalls[index];
              return CallListTile(
                name: call.otherName,
                imageUrl: call.otherImage,
                time: call.timeFormatted,
                callType: 'MISSED',
                callMode: call.type ?? 'AUDIO',
                duration: call.durationFormatted,
              );
            },
          ),
        );
      }),
    );
  }
}
