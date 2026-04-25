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
import 'package:wisper/app/modules/chat/controller/group/edit_group_controller.dart';
import 'package:wisper/app/modules/chat/controller/group/group_info_controller.dart';
import 'package:wisper/app/modules/chat/widgets/toggle_option.dart';

class EditGroupScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupCaption;
  final bool isPublic;
  final bool isAllowInvitation;

  const EditGroupScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupCaption,
    required this.isPublic,
    required this.isAllowInvitation,
  });

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final EditGroupController editGroupController = EditGroupController();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();

  late bool _isPublic;
  late bool _isAllowInvitation;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.groupName;
    _captionCtrl.text = widget.groupCaption;
    _isPublic = widget.isPublic;
    _isAllowInvitation = widget.isAllowInvitation;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  void _updateGroup() {
    if (_formKey.currentState!.validate()) {
      showLoadingOverLay(
        asyncFunction: () async => await _performUpdateGroup(),
        msg: 'Updating group...',
      );
    }
  }

  Future<void> _performUpdateGroup() async {
    final bool isSuccess = await editGroupController.editGroup(
      groupId: widget.groupId,
      name: _nameCtrl.text.trim(),
      caption: _captionCtrl.text.trim(),
      isPrivate: !_isPublic, // যদি _isPublic true হয় → isPrivate = false
      allowInvitation: _isAllowInvitation,
    );

    if (isSuccess) {
      final groupInfoController = Get.find<GroupInfoController>();
      await groupInfoController.getGroupInfo(widget.groupId);
      Navigator.pop(context);
      showSnackBarMessage(context, 'Group updated successfully', false);
    } else {
      showSnackBarMessage(context, editGroupController.errorMessage, true);
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
                  onPress: _updateGroup,
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
