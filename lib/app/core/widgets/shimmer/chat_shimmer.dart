import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wisper/app/core/others/custom_size.dart';

class ChatShimmerEffectWidget extends StatelessWidget {
  const ChatShimmerEffectWidget({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Shimmer.fromColors(
      baseColor: const Color.fromARGB(255, 48, 46, 46),
      highlightColor:const Color.fromARGB(255, 48, 46, 46),
      child: SizedBox(
        height: height,
        child: SingleChildScrollView(
          child: Column(
            children: [
              shimmerC(height, width),
              shimmerC(height, width),
              shimmerC(height, width),
              shimmerC(height, width),
              shimmerC(height, width),
            ],
          ),
        ),
      ),
    );
  }

  Padding shimmerC(double height, double width) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 20.r),
              widthBox10,
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  color: Colors.grey,
                ),
                height: height / 20,
                width: width / 1.6,
              ),
            ],
          ),
          heightBox30,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  color: Colors.grey,
                ),
                height: height / 20,
                width: width / 1.6,
              ),
              widthBox10,
              CircleAvatar(radius: 20.r),
            ],
          ),
        ],
      ),
    );
  }
}
