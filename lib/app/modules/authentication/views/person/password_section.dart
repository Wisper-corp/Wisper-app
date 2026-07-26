import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/validator_service.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/label.dart';

class PasswordSection extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const PasswordSection({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Label(label: 'Password'),
        heightBox10,
        CustomTextField(
          controller: passwordController,
          suffixIcon: Icons.visibility_off,
          hintText: '********',
          obscureText: true,
          keyboardType: TextInputType.text,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) =>
              ValidatorService.validatePassword(passwordController.text),
        ),

        heightBox12,
        Label(label: 'Confirm Password'),
        heightBox10,
        CustomTextField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          controller: confirmPasswordController,
          suffixIcon: Icons.visibility_off,
          hintText: '********',
          obscureText: true,
          keyboardType: TextInputType.text,
          validator: (value) => ValidatorService.validateConfirmPassword(
            value,
            passwordController.text,
          ),
        ),

        heightBox20,
        Text('Password must contain at least'),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: passwordController,
          builder: (context, value, _) {
            final password = value.text;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                heightBox8,
                info('7 characters', password.length >= 7),
                heightBox8,
                info('One uppercase letter', RegExp(r'[A-Z]').hasMatch(password)),
                heightBox8,
                info('One number', RegExp(r'[0-9]').hasMatch(password)),
                heightBox8,
                info(
                  'One Special Character e.g !^@*#(',
                  RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget info(String text, bool isValid) {
    final color = isValid ? Colors.green : Colors.grey;

    return Row(
      children: [
        Icon(Icons.check_circle, size: 14.h, color: color),
        widthBox4,
        Text(
          text,
          style: TextStyle(fontSize: 12.sp, color: color),
        ),
      ],
    );
  }
}
