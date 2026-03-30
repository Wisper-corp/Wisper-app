import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/gen/assets.gen.dart';

class LocationInfo extends StatelessWidget {
  final bool? isDate;
  final String? location;
  final String? date;
  const LocationInfo({super.key, this.location, this.date, this.isDate = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            CrashSafeImage(
              Assets.images.location.keyName,
              height: 16.h,
              color: const Color(0xff7F8694),
            ),
            widthBox8,
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.42,
              child: Text(
                location ?? '',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xff7F8694),
                ),
              ),
            ),
          ],
        ),
        
        isDate!
            ? Row(
                children: [
                  CrashSafeImage(
                    Assets.images.calendar.keyName,
                    height: 16.h,
                    color: const Color(0xff7F8694),
                  ),
                  widthBox4,
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.20,
                    child: Text(
                      'Created $date',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xff7F8694),
                      ),
                    ),
                  ),
                ],
              )
            : Container(),
      ],
    );
  }
}
