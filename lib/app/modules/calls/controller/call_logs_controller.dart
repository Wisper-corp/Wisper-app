import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/modules/calls/model/call_log_model.dart';
import 'package:wisper/app/urls.dart';

class CallLogsController extends GetxController {
  final RxList<CallLogItem> allCalls = <CallLogItem>[].obs;
  final RxList<CallLogItem> missedCalls = <CallLogItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  /// What is typed in the search box. The lists below are filtered by it, so
  /// the box was previously decorative: it had no controller at all and
  /// nothing read what was typed.
  final RxString searchTerm = ''.obs;

  void search(String? term) => searchTerm.value = (term ?? '').trim();

  List<CallLogItem> _matching(List<CallLogItem> calls) {
    final needle = searchTerm.value.toLowerCase();
    if (needle.isEmpty) return calls;
    return calls
        .where((call) => call.otherName.toLowerCase().contains(needle))
        .toList();
  }

  /// The lists the screen shows: everything, narrowed by the search box.
  List<CallLogItem> get visibleCalls => _matching(allCalls);
  List<CallLogItem> get visibleMissedCalls => _matching(missedCalls);

  @override
  void onInit() {
    super.onInit();
    fetchCallLogs();
  }

  Future<void> fetchCallLogs() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final token = StorageUtil.getData(StorageUtil.userAccessToken);

      // Fetch all calls
      final allRes = await Get.find<NetworkCaller>().getRequest(
        Urls.myCallsUrl,
        accessToken: token,
      );
      if (allRes.isSuccess && allRes.responseData != null) {
        final parsed = CallLogsResponse.fromJson(allRes.responseData);
        allCalls.value = parsed.data?.calls ?? [];
      }

      // Fetch missed calls (filtered by backend)
      final missedRes = await Get.find<NetworkCaller>().getRequest(
        '${Urls.myCallsUrl}?status=MISSED',
        accessToken: token,
      );
      if (missedRes.isSuccess && missedRes.responseData != null) {
        final parsed = CallLogsResponse.fromJson(missedRes.responseData);
        missedCalls.value = parsed.data?.calls ?? [];
      }
    } catch (e) {
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }
}
