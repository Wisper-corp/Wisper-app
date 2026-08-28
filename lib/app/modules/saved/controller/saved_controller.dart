import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/saved/model/saved_item_model.dart';
import 'package:wisper/app/urls.dart';

/// Saving a post and reading back what was saved.
///
/// The toggle keeps its own set of ids so a bookmark can fill in immediately
/// rather than waiting for a round trip, and roll back if the request fails.
class SavedController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final RxList<SavedItemModel> _items = <SavedItemModel>[].obs;
  List<SavedItemModel> get items => _items;

  /// Ids the user has saved this session, keyed "kind:id", so every card
  /// showing the same post agrees with itself.
  final RxSet<String> _saved = <String>{}.obs;

  String _key(String kind, String id) => '$kind:$id';

  bool isSaved(String kind, String id) => _saved.contains(_key(kind, id));

  /// Seeds the local set from a listing that already told us `isSaved`, so a
  /// freshly loaded feed does not have to ask again.
  void seed(String kind, String id, bool saved) {
    final key = _key(kind, id);
    if (saved) {
      _saved.add(key);
    } else {
      _saved.remove(key);
    }
  }

  String? _token() => StorageUtil.getData(StorageUtil.userAccessToken);

  /// Returns the new state. Flips locally first and puts it back if the
  /// request fails, so the icon never lies for long.
  Future<bool> toggle(String kind, String id) async {
    final key = _key(kind, id);
    final wasSaved = _saved.contains(key);
    wasSaved ? _saved.remove(key) : _saved.add(key);

    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .patchRequest(
            Urls.savedToggleUrl(kind, id),
            accessToken: _token(),
          );

      if (!response.isSuccess) {
        wasSaved ? _saved.add(key) : _saved.remove(key);
        _errorMessage.value = response.errorMessage;
        return wasSaved;
      }

      final saved = response.responseData?['data']?['isSaved'] as bool?;
      if (saved != null) seed(kind, id, saved);
      // The saved list, if it is open, no longer matches.
      if (_items.isNotEmpty || !wasSaved) unawaitedRefresh();
      return saved ?? !wasSaved;
    } catch (e) {
      wasSaved ? _saved.add(key) : _saved.remove(key);
      _errorMessage.value = 'Could not save that. Please try again.';
      return wasSaved;
    }
  }

  void unawaitedRefresh() {
    getSavedItems(type: _lastType, searchTerm: _lastSearch);
  }

  String? _lastType;
  String? _lastSearch;

  Future<bool> getSavedItems({String? type, String? searchTerm}) async {
    _lastType = type;
    _lastSearch = searchTerm;
    _inProgress.value = true;

    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .getRequest(
            Urls.savedUrl,
            queryParams: {
              if (type != null && type.isNotEmpty) 'type': type,
              if (searchTerm != null && searchTerm.trim().isNotEmpty)
                'searchTerm': searchTerm.trim(),
            },
            accessToken: _token(),
          );

      if (response.isSuccess && response.responseData != null) {
        final data = response.responseData!['data'];
        final parsed = data is List
            ? data
                .map((e) => SavedItemModel.fromJson(e as Map<String, dynamic>))
                .toList()
            : <SavedItemModel>[];
        _items.assignAll(parsed);
        for (final item in parsed) {
          seed(item.kind, item.id, true);
        }
        _errorMessage.value = '';
        _inProgress.value = false;
        return true;
      }

      _errorMessage.value = response.errorMessage;
      _inProgress.value = false;
      return false;
    } catch (e) {
      _errorMessage.value = 'Could not load your saved posts.';
      _inProgress.value = false;
      return false;
    }
  }
}
