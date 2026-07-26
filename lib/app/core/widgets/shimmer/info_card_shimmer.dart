import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wisper/app/core/others/custom_size.dart';

class InfoCardShimmerEffectWidget extends StatelessWidget {
  const InfoCardShimmerEffectWidget({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Shimmer.fromColors(
     baseColor: const Color.fromARGB(255, 48, 46, 46),
      highlightColor:const Color.fromARGB(255, 48, 46, 46),
      child: SizedBox(
        height: height / 5,
        child: SingleChildScrollView(
          child: Column(children: [shimmerC(height, width)]),
        ),
      ),
    );
  }

  Padding shimmerC(double height, double width) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          heightBox14,
          CircleAvatar(radius: 36.r),
          heightBox20,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100.r),
                  color: Colors.grey,
                ),
                height: 30,
                width: 30,
              ),
              widthBox10,
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100.r),
                  color: Colors.grey,
                ),
                height: 30,
                width: 30,
              ),
              widthBox10,
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: Colors.grey,
                ),
                height: height / 25,
                width: width / 3.5,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
