import 'package:flutter/material.dart';

class ValidatorService {
  static bool validateAndSave(globalFormKey) {
    final FormState form = globalFormKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  //<============================================= Full Name Validator
  static String? validateFullName(String? fullName) {
    if (fullName == null) {
      return 'Field Required';
    }

    // Remove leading and trailing whitespace
    final trimmedName = fullName.trim();

    // Check if the name has at least two words
    final words = trimmedName.split(' ');

    if (words.length < 2) {
      return 'First should contain at least two words';
    }

    // Check if the name contains only letters and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmedName)) {
      return 'First name can only contain letters and spaces';
    }

    // Validation passed, return null (no error)
    return null;
  }

  //<<================= bangladeshi phone number validator
  static String? validateEmailAddress(String? email) {
    // Check if email is null
    if (email == null) {
      return 'E-mail Address is required';
    }

    String p =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

    RegExp regExp = RegExp(p);

    if (!regExp.hasMatch(email)) {
      return 'Invalid e-mail address';
    }

    // Validation passed, return null (no error)
    return null;
  }

  //<======= Password validator
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 7) {
      return 'Password must be at least 7 characters long';
    }

    // At least 1 uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least 1 capital letter';
    }

    // At least 1 number
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least 1 number';
    }

    // At least 1 special character
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password must contain at least 1 special character';
    }

    // All validations passed
    return null;
  }

  // Confirm Password Validator
  static String? validateConfirmPassword(
    String? confirmPassword,
    String originalPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirm password is required';
    }

    if (confirmPassword != originalPassword) {
      return 'Passwords do not match';
    }

    // Validation passed, return null (no error)
    return null;
  }

  static String? validateSimpleField(String? value) {
    if (value == null) {
      return 'Field Required';
    }
    // Remove leading and trailing whitespace
    final words = value.trim();

    if (words.isEmpty) {
      return 'Field Required';
    }
    return null;
  }

  static String? validateSimpleField10Carecter(String? value) {
    if (value == null) {
      return 'Field Required';
    } else if (value.length < 10) {
      return 'Length should be 10';
    }
    // Remove leading and trailing whitespace
    final words = value.trim();

    if (words.isEmpty) {
      return 'Field Required';
    }
    return null;
  }
}
