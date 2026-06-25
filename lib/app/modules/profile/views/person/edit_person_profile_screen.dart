// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/services/location/location_picker_field.dart';
import 'package:wisper/app/core/services/location/location_services.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/utils/validator_service.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/job_title_search_field.dart';
import 'package:wisper/app/core/widgets/common/label.dart';
import 'package:wisper/app/modules/authentication/widget/auth_header.dart';
import 'package:wisper/app/modules/profile/controller/person/edit_person_profile_controller.dart';
import 'package:wisper/app/modules/profile/controller/person/profile_controller.dart';

class EditPersonProfileScreen extends StatefulWidget {
  const EditPersonProfileScreen({super.key});

  @override
  State<EditPersonProfileScreen> createState() =>
      _EditPersonProfileScreenState();
}

class _EditPersonProfileScreenState extends State<EditPersonProfileScreen> {
  final ProfileController profileController = Get.put(ProfileController());
  final EditPersonProfileController editProfileController =
      EditPersonProfileController();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // এই কন্ট্রোলারটা আমরা Job Title এর জন্য ব্যবহার করবো
  final _titleCtrl = TextEditingController();

  final Rx<LatLng?> selectedLatLng = Rx<LatLng?>(null);
  final RxString selectedAddress = ''.obs;

  void setLocation(LatLng latLng, String address) {
    selectedLatLng.value = latLng;
    selectedAddress.value = address;
  }

  void clearLocation() {
    selectedLatLng.value = null;
    selectedAddress.value = '';
  }

  final List<String> _jobTitles = [];
  String? _selectedTitle;

  @override
  void initState() {
    super.initState();

    final user = profileController.profileData?.auth?.person;
    _nameCtrl.text = user?.name ?? '';
    _emailCtrl.text = user?.email ?? '';
    _phoneCtrl.text = user?.phone ?? '';
    _addressCtrl.text = user?.address ?? '';

    _selectedTitle = user?.title;
    _titleCtrl.text = _selectedTitle ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _submitProfile() {
    if (_formKey.currentState!.validate()) {
      showLoadingOverLay(
        asyncFunction: () async => await _performEditProfile(),
        msg: 'Updating profile...',
      );
    }
  }

  Future<void> _performEditProfile() async {
    final bool isSuccess = await editProfileController.editProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      title: _selectedTitle!,
      address: selectedAddress.value,
    );

    if (isSuccess) {
      final ProfileController profileController = Get.find<ProfileController>();
      profileController.getMyProfile();
      Get.back();
      showSnackBarMessage(context, 'Profile updated successfully', false);
    } else {
      showSnackBarMessage(context, editProfileController.errorMessage, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBox60,
              AuthHeader(title: 'Edit Profile Details'),
              heightBox30,

              const Label(label: 'Full Name'),
              heightBox10,
              CustomTextField(
                controller: _nameCtrl,
                hintText: 'Enter full name',
                keyboardType: TextInputType.name,
                validator: ValidatorService.validateSimpleField,
              ),

              heightBox20,
              const Label(label: 'Email'),
              heightBox10,
              CustomTextField(
                controller: _emailCtrl,
                hintText: 'example@gmail.com',
                keyboardType: TextInputType.emailAddress,
                enabled: false,
              ),

              heightBox20,
              const Label(label: 'Phone Number'),
              heightBox10,
              CustomTextField(
                controller: _phoneCtrl,
                hintText: 'Enter phone number',
                keyboardType: TextInputType.phone,
                validator: ValidatorService.validateSimpleField,
              ),

              _addressCtrl.text.isNotEmpty
                  ? Container()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heightBox20,
                        const Label(label: 'Address'),
                        heightBox10,
                        Obx(
                          () => LocationField(
                            address: selectedAddress.value,
                            onPick: () async {
                              final pos =
                                  selectedLatLng.value ??
                                  LatLng(23.8103, 90.4125);
                              final res = await Get.to(
                                () =>
                                    LocationPickerScreen(initialPosition: pos),
                              );
                              if (res is Map) {
                                setState(() {
                                  setLocation(res['latLng'], res['address']);
                                });
                              }
                            },
                            onClear: clearLocation,
                          ),
                        ),
                      ],
                    ),

              // CustomTextField(
              //   controller: _addressCtrl,
              //   hintText: 'Enter address',
              //   keyboardType: TextInputType.text,
              //   validator: ValidatorService.validateSimpleField,
              // ),
              heightBox20,
              const Label(label: 'Job Title'),
              heightBox10,
              JobTitleSearchField(
                initialValue: _titleCtrl.text.isNotEmpty ? _titleCtrl.text : null,
                hintText: 'Search your job title...',
                onSelected: (title) {
                  setState(() {
                    _titleCtrl.text = title;
                  });
                },
              ),
              heightBox4,
              const Text(
                'Type at least 2 characters to search from 1000+ job titles',
                style: TextStyle(color: Color(0xff8E8E93), fontSize: 11),
              ),

              heightBox50,

              Center(
                child: CustomElevatedButton(
                  height: MediaQuery.of(context).size.height * 0.05,
                  title: 'Submit',
                  onPress: _submitProfile,
                  color: Colors.blue,
                ),
              ),
              heightBox50,
            ],
          ),
        ),
      ),
    );
  }
}
