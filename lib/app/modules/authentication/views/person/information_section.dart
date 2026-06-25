import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/validator_service.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/job_title_search_field.dart';
import 'package:wisper/app/core/widgets/common/label.dart';

class InformationSection extends StatefulWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController titleController;

  const InformationSection({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.titleController,
  });

  @override
  State<InformationSection> createState() => _InformationSectionState();
}

class _InformationSectionState extends State<InformationSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Label(label: 'First Name'),
        heightBox10,
        CustomTextField(
          controller: widget.firstNameController,
          hintText: 'Enter first name',
          keyboardType: TextInputType.name,
          validator: ValidatorService.validateSimpleField,
        ),
        heightBox12,

        const Label(label: 'Last Name'),
        heightBox10,
        CustomTextField(
          controller: widget.lastNameController,
          hintText: 'Enter last name',
          keyboardType: TextInputType.name,
          validator: ValidatorService.validateSimpleField,
        ),
        heightBox12,

        const Label(label: 'Email'),
        heightBox10,
        CustomTextField(
          controller: widget.emailController,
          hintText: 'email@gmail.com',
          keyboardType: TextInputType.emailAddress,
          validator: (_) => ValidatorService.validateEmailAddress(
            widget.emailController.text,
          ),
        ),
        heightBox12,

        const Label(label: 'Phone Number'),
        heightBox10,
        CustomTextField(
          controller: widget.phoneController,
          hintText: 'Enter phone number',
          keyboardType: TextInputType.phone,
          validator: ValidatorService.validateSimpleField,
        ),
        heightBox12,

        const Label(label: 'Job Title'),
        heightBox10,
        JobTitleSearchField(
          initialValue: widget.titleController.text.isNotEmpty
              ? widget.titleController.text
              : null,
          hintText: 'Search your job title...',
          onSelected: (title) {
            widget.titleController.text = title;
          },
        ),
        heightBox4,
        const Text(
          'Type at least 2 characters to search from 1000+ job titles',
          style: TextStyle(color: Color(0xff8E8E93), fontSize: 11),
        ),
      ],
    );
  }
}
