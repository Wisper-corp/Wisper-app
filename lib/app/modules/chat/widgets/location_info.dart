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
    final bool hasLocation = location != null && location!.isNotEmpty && location != 'No Location';
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 4,
      children: [
        if (hasLocation)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                Assets.images.location.keyName,
                height: 16.h,
                color: const Color(0xff7F8694),
              ),
              widthBox4,
              Flexible(
                child: Text(
                  location!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xff7F8694),
                  ),
                ),
              ),
            ],
          ),
        if (isDate!)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                Assets.images.calendar.keyName,
                height: 16.h,
                color: const Color(0xff7F8694),
              ),
              widthBox4,
              Text(
                'Joined $date',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xff7F8694),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
