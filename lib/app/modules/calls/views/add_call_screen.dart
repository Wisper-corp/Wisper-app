import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/modules/chat/widgets/add_icon_widget.dart';
import 'package:wisper/app/modules/chat/widgets/contact_widget.dart'; 
import 'package:wisper/gen/assets.gen.dart';

class AddCallScreen extends StatefulWidget {
  const AddCallScreen({super.key});

  @override
  State<AddCallScreen> createState() => _AddCallScreenState();
}

class _AddCallScreenState extends State<AddCallScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(0.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              heightBox10,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Cancel", style: TextStyle(fontSize: 12.sp)),

                  Text(
                    "Add Participants",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(width: 20.w),
                ],
              ),
              heightBox10,
              SizedBox(
                height: 48,
                child: CustomTextField(hintText: 'Search participants'),
              ),
              heightBox10,
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ContactWidget(
                        trailing: AddIconWidget(),
                        imagePath: Assets.images.image.keyName,
                        title: 'Aminul Islam',
                        subtitle: 'Student',
                        onTap: () {},
                      ),
                    );
                  },
                  itemCount: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
