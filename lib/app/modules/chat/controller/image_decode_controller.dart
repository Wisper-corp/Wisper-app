import 'dart:io';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/urls.dart';

class FileDecodeController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final RxString _url = ''.obs;
  String get imageUrl => _url.value;
  set imageUrl(String value) => _url.value = value;

  // **Reactive RxString getter for ever()**
  RxString get imageUrlRx => _url;

  final RxString _localPath = ''.obs;
  String get localPath => _localPath.value;
  RxString get localPathRx => _localPath;

  final RxString _currentFileType = ''.obs;
  String get currentFileType => _currentFileType.value;

  bool get hasAttachment => _url.value.isNotEmpty;

  void clearAll() {
    _url.value = '';
    _localPath.value = '';
    _currentFileType.value = '';
    _errorMessage.value = '';
    _inProgress.value = false;
  }

  Future<bool> imageDecode({File? image}) async {
    return _decodeFile(file: image, type: 'IMAGE', errorPrefix: 'image');
  }

  Future<bool> videoDecode({File? image}) async {
    return _decodeFile(file: image, type: 'VIDEO', errorPrefix: 'video');
  }

  Future<bool> fileDecode({File? image}) async {
    return _decodeFile(file: image, type: 'DOC', errorPrefix: 'file');
  }

  Future<bool> _decodeFile({
    required File? file,
    required String type,
    required String errorPrefix,
  }) async {
    _currentFileType.value = type;
    _localPath.value = file?.path ?? '';
    _inProgress.value = true;

    try {
      final NetworkResponse response =
          await Get.find<NetworkCaller>().postRequest(
        image: file,
        keyNameImage: 'file',
        Urls.fileDecodeUrl,
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );

      if (response.isSuccess && response.responseData != null) {
        _url.value = response.responseData['data']['url'];
        _errorMessage.value = '';
        _inProgress.value = false;
        return true;
      } else {
        _errorMessage.value = response.errorMessage;
        _inProgress.value = false;

        if (_errorMessage.value.contains('expired')) {
          Get.offAll(() => SignInScreen());
        }
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to decode $errorPrefix: ${e.toString()}';
      _inProgress.value = false;
      return false;
    }
  }
}
