// connectivity_services.dart (full updated code – only change is making method public)

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  RxBool isOnline = true.obs;
  // When true, we won't show the blocking no-internet dialog (e.g. in chat).
  RxBool suppressDialog = false.obs;
  bool _isShowingDialog = false;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final List<ConnectivityResult> initialResults = await _connectivity
        .checkConnectivity();
    await _updateConnectionStatus(initialResults);

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateConnectionStatus(results);
    });
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    final bool hasNoNetwork =
        results.isEmpty || results.contains(ConnectivityResult.none);

    if (hasNoNetwork) {
      isOnline.value = false;
      if (suppressDialog.value) {
        if (_isShowingDialog) {
          Get.back(closeOverlays: true);
          _isShowingDialog = false;
        }
        return;
      }
      _showNoInternetDialog();
      return;
    }

    final bool hasRealAccess =
        await checkInternetAccess(); // ← use public method
    isOnline.value = hasRealAccess;

    if (hasRealAccess) {
      if (_isShowingDialog) {
        Get.back(closeOverlays: true);
        _isShowingDialog = false;
        Get.snackbar(
          "Online Now",
          "Internet connection restored ✓",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } else {
      _showNoInternetDialog();
    }
  }

  // Made public so NoInternetScreen can call it
  Future<bool> checkInternetAccess() async {
    try {
      final response = await http
          .get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  void _showNoInternetDialog() {
    if (suppressDialog.value) return;
    if (_isShowingDialog) return;

    _isShowingDialog = true;

    Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_sharp, color: Colors.red, size: 70),
            const Text(
              "Oh No!",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Internet connection is not found", 
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
            const Text(
              "Please check your internet connection",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
            heightBox20,
            SizedBox(
              width: MediaQuery.of(Get.context!).size.width / 2,
              child: CustomElevatedButton(
                color: Colors.red,
                textColor: Colors.white,
                title: "Retry",
                onPress: () async {
                  final connected = await checkInternetAccess();
                  if (connected) {
                    isOnline.value = true;
                    if (Get.isDialogOpen ?? false) {
                      Get.back(closeOverlays: true);
                    }
                    _isShowingDialog = false;
                    Get.snackbar(
                      "Success",
                      "You're back online!",
                      backgroundColor: Colors.green,
                    );
                  } else {
                    Get.snackbar(
                      "Still Offline",
                      "No connection yet – please check again",
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ).then((_) => _isShowingDialog = false);
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
