// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/utils/validator_service.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/label.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/chat/controller/all_chats_controller.dart';
import 'package:wisper/app/modules/chat/controller/class/create_class_controller.dart';
import 'package:wisper/app/modules/chat/widgets/create_header.dart';
import 'package:wisper/app/modules/chat/widgets/toggle_option.dart';
import 'package:wisper/app/modules/dashboard/views/dashboard_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class CreateClassButtomSheet extends StatefulWidget {
  final List<String> selectedMemberIds;

  const CreateClassButtomSheet({super.key, required this.selectedMemberIds});

  @override
  State<CreateClassButtomSheet> createState() => _CreateClassButtomSheetState();
}

class _CreateClassButtomSheetState extends State<CreateClassButtomSheet> {
  final CreateClassController createClassController = Get.put(
    CreateClassController(),
  );

  // Text Controllers
  final TextEditingController _groupNameC = TextEditingController();
  final TextEditingController _groupDescriptionC = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Toggle states (RxBool for reactivity if needed later)
  final RxBool _isPrivate = false.obs;
  final RxBool _allowInvitation = true.obs;

  @override
  void initState() {
    print(widget.selectedMemberIds);
    super.initState();
  }

  @override
  void dispose() {
    _groupNameC.dispose();
    _groupDescriptionC.dispose();
    super.dispose();
  }

  void createGroup() {
    if (_groupNameC.text.trim().isEmpty) {
      showSnackBarMessage(context, 'Please enter class name', true);
      return;
    }

    showLoadingOverLay(
      asyncFunction: () async => await performCreateGroup(),
      msg: 'Please wait...',
    );
  }

  Future<void> performCreateGroup() async {
    final bool isSuccess = await createClassController.createGroup(
      name: _groupNameC.text.trim(),
      description: _groupDescriptionC.text.trim(),
      members: widget.selectedMemberIds,
      isPrivate: _isPrivate.value,
      allowInvitation: _allowInvitation.value,
    );

    if (isSuccess && mounted) {
      final AllChatsController allChatsController =
          Get.find<AllChatsController>();
      await allChatsController.getAllChats();
      Get.offAll(() => const MainButtonNavbarScreen());
    } else if (mounted) {
      showSnackBarMessage(context, createClassController.errorMessage, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          color: Colors.black,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CreateHeader(
                      bgColor: const Color(0xff051B33),
                      iconColor: const Color(0xff1F7DE9),
                      title: 'Create Class',
                      imagePath: Assets.images.education.keyName,
                      onTap: () {
                        if (formKey.currentState!.validate()) {
                          createGroup();
                        }
                      },
                      trailinlgText: 'Create',
                    ),
                    heightBox10,
                    const StraightLiner(height: 0.5),
                    heightBox10,
                    const Label(label: 'Class Name'),
                    heightBox10,
                    CustomTextField(
                      controller: _groupNameC,
                      hintText: 'Enter class name',
                      keyboardType: TextInputType.name,
                      validator: ValidatorService.validateSimpleField,
                    ),
                    heightBox10,
                    const Label(label: 'Description'),
                    heightBox10,
                    CustomTextField(
                      controller: _groupDescriptionC,
                      hintText: 'Write description',
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                      validator: ValidatorService.validateSimpleField,
                    ),
                    heightBox16,
                    ToggleOption(
                      isToggled: false,
                      title: 'Private Class',
                      subtitle: 'Only invited members can join',
                      onToggle: (bool value) {
                        _isPrivate.value = value;
                      },
                    ),
                    heightBox10,
                    ToggleOption(
                      isToggled: false,
                      title: 'Allow Member Invites',
                      subtitle: 'Let members invite others',
                      onToggle: (bool value) {
                        _allowInvitation.value = value;
                      },
                    ),
                    heightBox10,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Members (${widget.selectedMemberIds.length})',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
