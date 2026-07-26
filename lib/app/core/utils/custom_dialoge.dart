
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/custom_size_button.dart';

class CustomDialog extends StatelessWidget {
  final VoidCallback yesOntap;
  final VoidCallback noOntap; 
  final IconData iconData;
  final String title; 
  final String subtitle;
  final String noText;
  final String yesText;
  final bool isLoading; // New parameter to handle loading state

  const CustomDialog({
    super.key,
    required this.iconData,
    required this.title,
    required this.yesOntap,
    required this.noOntap,
    required this.subtitle,
    required this.noText,
    required this.yesText,
    this.isLoading = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16.h),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            heightBox10,
            subtitle == ''
                ? const SizedBox()
                : Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
            SizedBox(height: 20.h),
            isLoading
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      children: [
                        LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.black,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Grabbing item...',
                          style: GoogleFonts.poppins( 
                            fontSize: 14.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      CustomSizeButton(
                        height: 48,
                        width: 122,
                        title: yesText,
                        icon: null,
                        ontap: yesOntap,
                        color: Colors.blue,
                        textColor: Colors.white,
                        iconColor: Colors.white,
                      ),
                      CustomSizeButton(
                        height: 48,
                        width: 122,
                        title: noText,
                        icon: null,
                        ontap: noOntap,
                        color: Colors.grey.shade200,
                        textColor: Colors.black,
                        iconColor: Colors.white,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}