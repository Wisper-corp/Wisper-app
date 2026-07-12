import 'dart:io';
import 'package:get/get.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/urls.dart';

class SignUpController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  /// 🔁 Sign Up Function
  Future<bool> signUp({
    String? title,
    String? bussinessName,
    String? industry,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? password,
    String? confirmPassword,
    String? address,
    File? image,
  }) async {
    if (_inProgress.value) {
      _errorMessage.value = 'Operation in progress';
      return false;
    }

    _inProgress.value = true;
    update();
    print('Address::::::::::: $address');
    print('Image: $image');
    if (image != null) {
      print('Image path: ${image.path}');
      print('Image exists: ${await image.exists()}');
    } else {
      print('Image is null');
    }

    var name = '$firstName $lastName';

    try {
      // Prepare the body
      Map<String, dynamic> jsonFields = {
        "password": password,

        "person": {
          "industry": industry,
          "title": title,
          "email": email,
          "name": name,
          "phone": phone, // optional
          "address": address,
        },
      };

      Map<String, dynamic> jsonFieldsRecruiter = {
        "password": password,
        "business": {
          "email": email,
          "name": bussinessName,
          "industry": industry,
          "address": address,
          "phone": phone,
        },
      };

      final NetworkResponse response = await Get.find<NetworkCaller>()
          .postRequest(
            title == null ? Urls.signUpUrlBussiness : Urls.signUpUrlPerson,
            body: title == null ? jsonFieldsRecruiter : jsonFields,
          );

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';
        _inProgress.value = false;
        update();
        return true;
      } else {
        _errorMessage.value = response.errorMessage;
        _inProgress.value = false;
        update();
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Error signing up: $e';
      _inProgress.value = false;
      update();
      return false;
    }
  }
}
