// ignore_for_file: avoid_print

import 'dart:io';

import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/urls.dart';

class CreatePostController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;
 
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  Future<bool> createPost({
    String? privacy,
    String? description,
    List<File>? images,
    double? price,
    String? deliveryTime,
  }) async {
    _inProgress.value = true;

    try {
      Map<String, dynamic> body = {
        "caption": description,
        "commentAccess": privacy,
        if (price != null) "price": price,
        if (deliveryTime != null && deliveryTime.isNotEmpty) "deliveryTime": deliveryTime,
      };
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .postRequest(
            images: images,
            keyNameImage: 'images',
            Urls.postUrl,
            body: body,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';

        _inProgress.value = false;
        return true;
      } else {
        _errorMessage.value = response.errorMessage;
        _inProgress.value = false;
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to fetch district data: ${e.toString()}';
      print('Error fetching district data: $e');
      _inProgress.value = false;
      return false;
    }
  }

  Future<bool> updatePost({
    String? privacy,
    String? description,
    List<File>? images,
    String? postId,
  }) async {
    _inProgress.value = true;

    try {
      Map<String, dynamic> body = {
        "caption": description,
        "commentAccess": privacy,
      };
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .patchRequest(
            images: images,
            keyNameImage: 'images',
            Urls.editPostId(postId!),
            body: body,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';

        _inProgress.value = false;
        return true;
      } else {
        _errorMessage.value = response.errorMessage;
        _inProgress.value = false;
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to fetch district data: ${e.toString()}';
      print('Error fetching district data: $e');
      _inProgress.value = false;
      return false;
    }
  }
}
