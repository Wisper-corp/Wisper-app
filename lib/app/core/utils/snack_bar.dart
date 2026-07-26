import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showSnackBarMessage(
  BuildContext context,
  String msg, [
  bool isError = false,
]) {
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger != null) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
    return;
  }

  // Fallback for contexts that don't have a ScaffoldMessenger (rare).
  // Also avoids crashing when there's no overlay available yet.
  if (Get.overlayContext == null) {
    debugPrint('SnackBar skipped (no overlay): $msg');
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (Get.overlayContext == null) return;
    Get.snackbar(
      isError ? 'Failed' : 'Success',
      msg,
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  });
}
