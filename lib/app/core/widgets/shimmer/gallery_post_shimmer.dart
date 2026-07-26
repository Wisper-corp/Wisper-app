import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wisper/app/core/others/custom_size.dart';

class PostShimmerEffectWidget extends StatelessWidget {
  const PostShimmerEffectWidget({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Shimmer.fromColors(
      baseColor: const Color.fromARGB(255, 48, 46, 46),
      highlightColor: const Color.fromARGB(255, 48, 46, 46),
      child: SizedBox(
        height: height - 250,
        child: SingleChildScrollView(
          child: Column(
            children: [
              shimmerC(height, width),
              heightBox10,
              shimmerC(height, width),
              heightBox10,
              shimmerC(height, width),
              heightBox10,
              shimmerC(height, width),
            ],
          ),
        ),
      ),
    );
  }

  Padding shimmerC(double height, double width) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 24.r),
          widthBox10,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  color: Colors.grey,
                ),
                height: height / 30,
                width: width / 1.6,
              ),
              heightBox10,
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  color: Colors.grey,
                ),
                height: height / 7,
                width: width / 1.6,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
