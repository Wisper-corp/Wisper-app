import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/modules/chat/model/group_members_model.dart';
import 'package:wisper/app/urls.dart';

class GroupMembersController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final Rx<GroupMembersModel?> _groupMemnersModel = Rx<GroupMembersModel?>(null);
  List<GroupMembersItemModel>? get groupMemnersData =>
      _groupMemnersModel.value?.data?.members ?? [];

  /// How many members the community actually has.
  ///
  /// [groupMemnersData] is one page — the API returns 10 at a time — so
  /// counting it under-reports every community with more than a pageful. Use
  /// this for anything the user sees as a total.
  int get totalMembers =>
      _groupMemnersModel.value?.data?.meta?.total ??
      _groupMemnersModel.value?.data?.members?.length ??
      0;

  Future<bool> getGroupMembers(String? groupId) async {
    if (groupId == null || groupId.isEmpty) {
      print('getGroupMembers: groupId is empty — skipping');
      _inProgress.value = false;
      return false;
    }
    print('getGroupMembers: fetching for groupId=$groupId');
    _inProgress.value = true;

    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .getRequest(
            Urls.groupMembersById(groupId),
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      print('getGroupMembers: success=${response.isSuccess}');

      if (response.isSuccess && response.responseData != null) {
        final responseData = response.responseData as Map<String, dynamic>;

        // Backend returns: { success, message, data: { meta, community, members } }
        // Handle both nested and flat response shapes
        Map<String, dynamic> modelInput;
        if (responseData['data'] is Map) {
          modelInput = responseData;
        } else {
          // data is flat — wrap into expected shape
          modelInput = {
            'success': responseData['success'],
            'message': responseData['message'],
            'data': {
              'meta': responseData['meta'],
              'community': responseData['community'],
              'members': responseData['members'] ?? [],
            }
          };
        }

        _groupMemnersModel.value = GroupMembersModel.fromJson(modelInput);
        print('getGroupMembers: parsed ${_groupMemnersModel.value?.data?.members.length} members');

        _errorMessage.value = '';
        _inProgress.value = false;
        return true;
      } else {
        _errorMessage.value = response.errorMessage;
        if (_errorMessage.value.contains('expired')) Get.to(SignInScreen());
        _inProgress.value = false;
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to fetch members: ${e.toString()}';
      print('getGroupMembers error: $e');
      _inProgress.value = false;
      return false;
    }
  }
}
