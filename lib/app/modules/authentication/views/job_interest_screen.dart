// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';     // ← new
import 'package:geocoding/geocoding.dart';       // ← new
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/modules/authentication/controller/sign_up_controller.dart';
import 'package:wisper/app/modules/authentication/views/otp_verification_screen.dart';

// Single selected interest only
String? selectedInterest;

class JobInterestScreen extends StatefulWidget {
  final String? firstName;
  final String? lastName;
  final String? bussinessName;
  final String? email;
  final String? phone;
  final String? password;
  final String? title;
  const JobInterestScreen({
    super.key,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.password,
    this.title,
    this.bussinessName,
  });

  @override
  State<JobInterestScreen> createState() => _JobInterestScreenState();
}

class _JobInterestScreenState extends State<JobInterestScreen> {
  final SignUpController signUpController = Get.put(SignUpController());
  final TextEditingController _searchController = TextEditingController();
  late List<String> _filteredInterests;

  final List<String> jobInterests = [
    'AgriTech',
    'Agriculture and Agribusiness',
    'Banking and Financial Services',
    'Beauty and Personal Care',
    'Building Materials Production',
    'Cosmetic Products',
    'Diagnostic Services',
    'Digital Media and Entertainment',
    'Edtech',
    'Electronics and Appliances Retail',
    'E-Learning and Online Education',
    'Energy and Power',
    'Event Planning and Management',
    'Fashion and Accessories Retail',
    'Fintech',
  ];

  Future<String> _getCurrentCityCountry() async {
    try {
      // 1. Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          showSnackBarMessage(context, 'Please enable location services', true);
        }
        return '';
      }

      // 2. Check & request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            showSnackBarMessage(context, 'Location permission denied', true);
          }
          return '';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showSnackBarMessage(
            context,
            'Location permission permanently denied. Please enable from settings.',
            true,
          );
        }
        return '';
      }

      // 3. Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // balanced speed + accuracy
      ).timeout(const Duration(seconds: 10));

      // 4. Reverse geocoding → city & country
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String city = place.locality?.trim().isNotEmpty == true
            ? place.locality!
            : (place.subAdministrativeArea ?? 'Unknown city');

        String country = place.country ?? 'Unknown country';

        return '$city, $country';
      }

      return '';
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        showSnackBarMessage(context, 'Could not get current location', true);
      }
      return '';
    }
  }

  void _finishSignUp() {
    showLoadingOverLay(
      asyncFunction: () async {
        // Get real-time location before signup
        final String currentAddress = await _getCurrentCityCountry();

        if (widget.title == null) {
          // Recruiter / Business
          await signUpWithRecruiter(context, currentAddress);
        } else {
          // Person
          await signUpWithPerson(context, currentAddress);
        }
      },
      msg: 'Please wait...',
    );
  }

  Future<void> signUpWithPerson(BuildContext context, String address) async {
    final bool isSuccess = await signUpController.signUp(
      address: address, // ← now real location
      firstName: widget.firstName,
      lastName: widget.lastName,
      email: widget.email,
      phone: widget.phone,
      password: widget.password,
      confirmPassword: widget.password,
      title: widget.title,
      industry: selectedInterest ?? '',
    );

    if (isSuccess) {
      showSnackBarMessage(context, 'Successfully done');
      Get.to(() => OtpVerificationScreen(email: widget.email ?? ''));
    } else {
      showSnackBarMessage(context, signUpController.errorMessage, true);
    }
  }

  Future<void> signUpWithRecruiter(BuildContext context, String address) async {
    final bool isSuccess = await signUpController.signUp(
      address: address, // ← now real location
      firstName: widget.firstName,
      lastName: widget.lastName,
      bussinessName: widget.bussinessName,
      email: widget.email,
      phone: widget.phone,
      password: widget.password,
      confirmPassword: widget.password,
      title: widget.title,
      industry: selectedInterest ?? '',
    );

    if (isSuccess) {
      showSnackBarMessage(context, 'Successfully done');
      Get.to(() => OtpVerificationScreen(email: widget.email ?? ''));
    } else {
      showSnackBarMessage(context, signUpController.errorMessage, true);
    }
  }

  @override
  void initState() {
    super.initState();
    _filteredInterests = List<String>.from(jobInterests);
    _searchController.addListener(_applySearch);
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredInterests = List<String>.from(jobInterests);
      } else {
        _filteredInterests = jobInterests
            .where((item) => item.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    selectedInterest = null;
    _searchController.removeListener(_applySearch);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 0.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              heightBox60,
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finishSignUp,
                  child: Text(
                    'finished',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: LightThemeColors.blueColor,
                    ), 
                  ),
                ),
              ),
              Text(
                'Which position are you interested in?',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w800),
              ),
              heightBox12,
              CustomTextField(
                controller: _searchController,
                hintText: 'Search job title',
                validator: (value) => null,
              ),
              heightBox12,
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(0),
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selectedInterest == _filteredInterests[index]) {
                          selectedInterest = null; // deselect
                        } else {
                          selectedInterest = _filteredInterests[index]; // select
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _filteredInterests[index],
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: selectedInterest == _filteredInterests[index]
                              ? LightThemeColors.blueColor
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  itemCount: _filteredInterests.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
