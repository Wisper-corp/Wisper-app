// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/utils/validator_service.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/label.dart';
import 'package:wisper/app/modules/authentication/widget/auth_header.dart';
import 'package:wisper/app/modules/chat/controller/class/class_info_controller.dart';
import 'package:wisper/app/modules/chat/controller/class/edit_class_info_controller.dart';
import 'package:wisper/app/modules/chat/widgets/toggle_option.dart';

class EditClassScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String classCaption;
  final bool isPublic; // true = public, false = private
  final bool isAllowInvitation;

  const EditClassScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.classCaption,
    required this.isPublic,
    required this.isAllowInvitation,
  });

  @override
  State<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
  final EditClassController editClassController = EditClassController();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();

  late bool _isPublic;
  late bool _isAllowInvitation;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.className;
    _captionCtrl.text = widget.classCaption;
    _isPublic = widget.isPublic;
    _isAllowInvitation = widget.isAllowInvitation;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  void _updateClass() {
    if (_formKey.currentState!.validate()) {
      showLoadingOverLay(
        asyncFunction: () async => await _performUpdateClass(),
        msg: 'Updating group...',
      );
    }
  }

  Future<void> _performUpdateClass() async {
    final bool isSuccess = await editClassController.editClass(
      classId: widget.classId,
      name: _nameCtrl.text.trim(),
      caption: _captionCtrl.text.trim(),
      isPrivate: !_isPublic,
      allowInvitation: _isAllowInvitation,
    );

    if (isSuccess) {
      final classInfoController = Get.find<ClassInfoController>();
      await classInfoController.getClassInfo(widget.classId);
      Navigator.pop(context);
      showSnackBarMessage(context, 'Group updated successfully', false);
    } else {
      showSnackBarMessage(context, editClassController.errorMessage, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBox60,
              AuthHeader(title: 'Edit Group Details'),
              heightBox30,

              const Label(label: 'Group Name'),
              heightBox10,
              CustomTextField(
                controller: _nameCtrl,
                hintText: 'Enter group name',
                keyboardType: TextInputType.text,
                validator: ValidatorService.validateSimpleField,
              ),

              heightBox20,
              const Label(label: 'Group Description'),
              heightBox10,
              CustomTextField(
                controller: _captionCtrl,
                hintText: 'Write something about the group',
                keyboardType: TextInputType.text,
              ),

              heightBox30,

              // Private Group Toggle
              ToggleOption(
                title: 'Private Group',
                subtitle: 'Only invited members can join',
                isToggled: !_isPublic,
                onToggle: (bool value) {
                  setState(() {
                    _isPublic = !value;
                  });
                },
              ),

              heightBox20,

              // Allow Member Invites Toggle
              ToggleOption(
                title: 'Allow Member Invites',
                subtitle: 'Let members invite others',
                isToggled: _isAllowInvitation,
                onToggle: (bool value) {
                  setState(() {
                    _isAllowInvitation = value;
                  });
                },
              ),

              heightBox50,

              Center(
                child: CustomElevatedButton(
                  height: 46.h,
                  title: 'Update',
                  onPress: _updateClass,
                  color: Colors.blue,
                ),
              ),
              heightBox50,
            ],
          ),
        ),
      ),
    );
  }
}
