// lib/app/modules/profile/controller/profile_photo_controller.dart

import 'dart:io';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/urls.dart';

class ProfilePhotoController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  Future<bool> uploadProfilePhoto(File image) async {
    _inProgress.value = true;
    update();

    try {
      final response = await Get.find<NetworkCaller>().patchRequest(
        image: image,
        keyNameImage: 'image',
        StorageUtil.getData(StorageUtil.userRole) == 'PERSON'
            ? Urls.personEditProfilePhotoUrl
            : Urls.businessEditProfilePhotoUrl,
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );

      if (response.isSuccess) {
        update();
        return true;
      } else {
        final msg = response.errorMessage;
        if (msg.toLowerCase().contains('expired') ||
            msg.toLowerCase().contains('unauthenticated')) {
          Get.offAll(() => const SignInScreen());
        } else {}
        _inProgress.value = false;
        update();
        return false;
      }
    } catch (e) {
      _inProgress.value = false;
      update();
      return false;
    }
  }

  Future<String?> uploadGroupPhoto(File image, String groupId) async {
    _inProgress.value = true;
    print('Uploading group photo...');
    update();

    try {
      final response = await Get.find<NetworkCaller>().patchRequest(
        Urls.changeGroupImageById(groupId),
        image: image,
        keyNameImage: 'image',
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );

      if (response.isSuccess) {
        _inProgress.value = false;
        update();
        // Extract the new image URL from the response if present
        try {
          final data = response.responseData;
          final imageUrl =
              data?['data']?['image'] as String? ??
              data?['image'] as String?;
          return imageUrl ?? '';
        } catch (_) {
          return '';
        }
      } else {
        final msg = response.errorMessage;
        if (msg.toLowerCase().contains('expired') ||
            msg.toLowerCase().contains('unauthenticated')) {
          Get.offAll(() => const SignInScreen());
        }
        _inProgress.value = false;
        update();
        return null;
      }
    } catch (e) {
      _inProgress.value = false;
      update();
      return null;
    }
  }

  Future<bool> uploadClassPhoto(File image, String classId) async {
    _inProgress.value = true;
    update();

    try {
      final response = await Get.find<NetworkCaller>().patchRequest(
        image: image,
        keyNameImage: 'image',
       Urls.changeClassImageById(classId),
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );

      if (response.isSuccess) {
        update();
        return true;
      } else {
        final msg = response.errorMessage;
        if (msg.toLowerCase().contains('expired') ||
            msg.toLowerCase().contains('unauthenticated')) {
          Get.offAll(() => const SignInScreen());
        } else {}
        _inProgress.value = false;
        update();
        return false;
      }
    } catch (e) {
      _inProgress.value = false;
      update();
      return false;
    }
  }
}
