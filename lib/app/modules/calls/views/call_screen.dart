
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/modules/calls/controller/call_logs_controller.dart';
import 'package:wisper/app/modules/calls/views/all_calls.dart';
import 'package:wisper/app/modules/calls/views/missed_calls.dart';


class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState(); 
}

class _CallScreenState extends State<CallScreen> {
  int selectIndex = 0;
  late final CallLogsController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(CallLogsController());
  }
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heightBox30,
            Text(
              'Calls',
              style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w800),
            ),
            heightBox10,
            SizedBox(
              height: 48.h,
              child: CustomTextField(hintText: 'Search calls'),
            ),
            heightBox20,
            Container(
              height: 40.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: Color(0xff1B1E25),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectIndex = 0;
                        });
                      },
                      child: Container(
                        height: 36.h,
                        width: 150.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          color: selectIndex == 0
                              ? Color.fromARGB(255, 0, 0, 0)
                              : Colors.transparent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Center(
                            child: Text(
                              'All Calls',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectIndex = 1;
                        });
                      },
                      child: Container(
                        height: 36.h,
                        width: 150.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          color: selectIndex == 1
                              ? Color.fromARGB(255, 0, 0, 0)
                              : Colors.transparent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Center(
                            child: Text(
                              'Missed Calls',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            heightBox10,
            Text(
              'Recent',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
            heightBox10,
            selectIndex == 0 ? AllCalls() : MissedCalls(),
          ],
        ),
      ),
    );
  }
}
