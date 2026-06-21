// ignore_for_file: prefer_final_fields, avoid_print

import 'dart:convert';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/dashboard/views/dashboard_screen.dart';
import 'package:wisper/app/modules/profile/controller/buisness/buisness_controller.dart';
import 'package:wisper/app/modules/profile/controller/person/profile_controller.dart';
import 'package:wisper/app/urls.dart';

/// Controller to handle Google Sign-In + Firebase Authentication + Backend Verification
class GoogleSignUpAuthController extends GetxController {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ✅ FIXED: RxBool instead of regular bool
  RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  RxString _errorMessage = ''.obs;
  String? get errorMessage =>
      _errorMessage.value.isEmpty ? null : _errorMessage.value;

  RxString _token = ''.obs;
  String? get token => _token.value.isEmpty ? null : _token.value;

  final ProfileController profileController = Get.put(ProfileController());
  final BusinessController businessController = Get.put((BusinessController()));

  /// Main Google Sign-In Function
  Future<bool> signUpWithGoogle(String role) async {
    _inProgress.value = true; // ✅ No need for update(), RxBool auto-updates Obx

    try {
      // Step 1️⃣: Start Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in process
        _errorMessage.value = "Google sign-in was cancelled";
        _inProgress.value = false;
        return false;
      }

      // Step 2️⃣: Get authentication details from Google account
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Step 3️⃣: Create a Firebase credential from the Google token
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4️⃣: Sign in to Firebase with the created credential
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      // Step 5️⃣: Get the Firebase-issued ID token (✅ verified by Firebase)
      String? idToken = await userCredential.user?.getIdToken(true);

      // Optional: Log some details for debugging
      String? name = userCredential.user?.displayName ?? '';
      String? email = userCredential.user?.email ?? '';
      String? imageUrl = userCredential.user?.photoURL ?? '';
      print('✅ Firebase ID Token: $idToken');
      print('👤 Name: $name');
      print('📧 Email: $email');

      String? newIdToken = await userCredential.user?.getIdToken(true);
      final parts = newIdToken!.split('.');
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      print('Issuer: ${payload['iss']}');

      // Step 6️⃣: Send the Firebase ID token to your backend for verification
      final Map<String, dynamic> requestBody = {
        "email": email,
        "name": name,
        "image": imageUrl,
        "fcmToken": newIdToken,
        "role": role, // "PERSON", "BUSINESS"
      };

      final NetworkResponse response = await Get.find<NetworkCaller>()
          .postRequest(Urls.googleAuthUrl, body: requestBody);

      // Step 7️⃣: Handle backend response
      if (response.isSuccess) {
        // Save backend access token in local storage
        StorageUtil.saveData(
          StorageUtil.userAccessToken,
          response.responseData['data']['accessToken'],
        );

        var token = response.responseData['data']['accessToken'];
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        print(decodedToken);
        var role = decodedToken['role'];
        var userId = decodedToken['id'];
        StorageUtil.saveData(StorageUtil.userRole, role);
        StorageUtil.saveData(StorageUtil.userId, userId ?? '');
        StorageUtil.saveData(
          StorageUtil.userAccessToken,
          response.responseData['data']['accessToken'],
        );

        _errorMessage.value = '';
        _inProgress.value = false;

        // Fetch user profile data after login
        profileController.getMyProfile();
        businessController.getMyProfile();

        // Navigate to main home screen
        Future.delayed(Duration.zero, () {
          Get.offAll(() => MainButtonNavbarScreen());
        });

        return true;
      } else {
        // If backend returns "credentials" error, sign out from Google
        if (response.errorMessage.contains('credentials')) {
          await _googleSignIn.signOut();
        }

        _errorMessage.value = response.errorMessage;
        _inProgress.value = false;
        return false;
      }
    } catch (e) {
      // Catch and log any exceptions
      print("❌ Google Sign-In Error: $e");
      _errorMessage.value = e.toString();
      _inProgress.value = false;
      return false;
    }
  }

  // ✅ Helper method to reset state
  void reset() {
    _inProgress.value = false;
    _errorMessage.value = '';
    _token.value = '';
  }
}
