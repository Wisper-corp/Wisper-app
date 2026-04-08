import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/urls.dart';

class CreateJobController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  Future<bool> createJob({
    String? locationType, 
    String? title,
    String? description,
    String? type, // FULL_TIME, PART_TIME, CONTRACT
    String? experienceLevel, // ENTRY_LEVEL, JUNIOR, MID_LEVEL, SENIOR
    String? compensationType, // MONTHLY, ONE_OFF
    double? salary,
    String? location, // REMOTE, ON_SITE, HYBRID
    String? qualification, // BSC, HND, OND, PHD
    List<String>? requirements,
    List<String>? responsibilities,
    String? applicationType,
    String? applicationLink, // শুধু EXTERNAL হলে দরকার
    String? industry = 'Web Development',
  }) async {
    _inProgress.value = true;

    try {
      Map<String, dynamic> body = {
        "title": title,
        "description": description,
        "type": type,
        "experienceLevel": experienceLevel,
        "compensationType": compensationType,
        "salary": salary,
        'locationType': locationType,
        "location": location,
        "industry": industry,
        "qualification": qualification,
        "requirements": requirements,
        "responsibilities": responsibilities,
        "applicationType": applicationType,
      };
      if (applicationType == 'EXTERNAL') {
        if (applicationLink != null || applicationLink != '') {
          body['applicationLink'] = applicationLink;
        }
      }

      final NetworkResponse response = await Get.find<NetworkCaller>()
          .postRequest(
            Urls.feedJobUrl,
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
