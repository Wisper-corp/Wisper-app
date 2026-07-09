import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/modules/kyc/controller/kyc_status_controller.dart';
import 'package:wisper/app/urls.dart';

class KycAddressScreen extends StatefulWidget {
  const KycAddressScreen({super.key});

  @override
  State<KycAddressScreen> createState() => _KycAddressScreenState();
}

class _KycAddressScreenState extends State<KycAddressScreen> {
  final _addressCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedDocType = 'utility_bill';
  File? _selectedFile;
  String? _selectedFileName;
  bool _uploading = false;
  bool _submitting = false;

  // Status from controller
  String _currentStatus = 'UNVERIFIED';

  static const Map<String, String> _docTypeLabels = {
    'utility_bill': 'Utility Bill',
    'bank_statement': 'Bank Statement (last 3 months)',
    'tenancy_agreement': 'Tenancy Agreement',
  };

  @override
  void initState() {
    super.initState();
    final status = Get.find<KycStatusController>().status.value;
    if (status != null) {
      _currentStatus = status.address.status;
      _addressCtrl.text = status.address.addressText ?? '';
      _selectedDocType = status.address.docType ?? 'utility_bill';
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg'],
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<String?> _uploadDocument() async {
    if (_selectedFile == null) return null;
    setState(() => _uploading = true);

    final res = await Get.find<NetworkCaller>().postRequest(
      '${Urls.baseUrl}/upload-files',
      image: _selectedFile,
      keyNameImage: 'file',
      accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
    );

    setState(() => _uploading = false);

    if (res.isSuccess && res.responseData != null) {
      return res.responseData['data']?['url'] as String?;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null && _currentStatus == 'UNVERIFIED') {
      showSnackBarMessage(context, 'Please upload a proof of address document.', true);
      return;
    }

    setState(() => _submitting = true);

    String? docUrl;
    if (_selectedFile != null) {
      docUrl = await _uploadDocument();
      if (docUrl == null) {
        setState(() => _submitting = false);
        showSnackBarMessage(context, 'Document upload failed. Please try again.', true);
        return;
      }
    }

    final body = {
      'addressText': _addressCtrl.text.trim(),
      'addressDocType': _selectedDocType,
      if (docUrl != null) 'addressDocUrl': docUrl,
    };

    // If resubmitting without changing file — must have existing doc
    if (docUrl == null && _currentStatus == 'REJECTED') {
      showSnackBarMessage(context, 'Please upload a new document to resubmit.', true);
      setState(() => _submitting = false);
      return;
    }

    final res = await Get.find<NetworkCaller>().postRequest(
      Urls.kycAddressSubmitUrl,
      body: body,
      accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
    );

    setState(() => _submitting = false);

    if (res.isSuccess) {
      showSnackBarMessage(context,
          'Address submitted for review. You will be notified once approved.');
      Navigator.pop(context);
    } else {
      showSnackBarMessage(context, res.errorMessage, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPendingReview = _currentStatus == 'PENDING_REVIEW';
    final isVerified = _currentStatus == 'VERIFIED';
    final isRejected = _currentStatus == 'REJECTED';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Verify your Address',
            style: TextStyle(
                color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status banner ────────────────────────────────────────
            if (isVerified)
              _StatusBanner(
                icon: Icons.verified,
                color: Colors.green,
                message: 'Your address has been verified.',
              ),
            if (isPendingReview)
              _StatusBanner(
                icon: Icons.hourglass_top,
                color: Colors.orange,
                message: 'Your address submission is under review. We will notify you.',
              ),
            if (isRejected)
              _StatusBanner(
                icon: Icons.cancel_outlined,
                color: Colors.red,
                message: 'Your address was rejected. Please resubmit with a valid document.',
              ),

            if (isVerified) ...[
              heightBox24,
              CustomElevatedButton(title: 'Done', onPress: () => Navigator.pop(context)),
            ] else if (!isPendingReview) ...[
              if (isVerified || isRejected) heightBox16,

              // ── Form ─────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Residential / Office Address',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600)),
                    heightBox8,
                    CustomTextField(
                      controller: _addressCtrl,
                      hintText: 'Enter your full address',
                      maxLines: 3,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Address is required';
                        if (v.trim().length < 10) return 'Please enter a complete address';
                        return null;
                      },
                    ),
                    heightBox20,

                    // ── Document type ──────────────────────────────
                    Text('Document Type',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600)),
                    heightBox8,
                    ..._docTypeLabels.entries.map((e) => _DocTypeOption(
                          value: e.key,
                          label: e.value,
                          groupValue: _selectedDocType,
                          onChanged: (v) => setState(() => _selectedDocType = v!),
                        )),

                    heightBox20,

                    // ── File upload ────────────────────────────────
                    Text('Proof of Address',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600)),
                    heightBox4,
                    Text('Accepted: PDF, JPG, JPEG',
                        style: TextStyle(
                            color: const Color(0xFF9E9E9E), fontSize: 12.sp)),
                    heightBox12,
                    GestureDetector(
                      onTap: _pickDocument,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 16.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: _selectedFile != null
                                ? const Color(0xFF168DE1)
                                : const Color(0xFF333333),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedFile != null
                                  ? Icons.insert_drive_file
                                  : Icons.upload_file,
                              color: _selectedFile != null
                                  ? const Color(0xFF168DE1)
                                  : const Color(0xFF9E9E9E),
                              size: 24.sp,
                            ),
                            widthBox12,
                            Expanded(
                              child: Text(
                                _selectedFileName ?? 'Tap to upload document',
                                style: TextStyle(
                                  color: _selectedFile != null
                                      ? Colors.white
                                      : const Color(0xFF9E9E9E),
                                  fontSize: 14.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_selectedFile != null)
                              GestureDetector(
                                onTap: () => setState(() {
                                  _selectedFile = null;
                                  _selectedFileName = null;
                                }),
                                child: Icon(Icons.close,
                                    color: const Color(0xFF9E9E9E), size: 18.sp),
                              ),
                          ],
                        ),
                      ),
                    ),
                    heightBox24,

                    (_uploading || _submitting)
                        ? const Center(child: CircularProgressIndicator())
                        : CustomElevatedButton(
                            title: isRejected ? 'Resubmit Address' : 'Submit for Review',
                            onPress: _submit,
                          ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  const _StatusBanner(
      {required this.icon, required this.color, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.sp),
          widthBox10,
          Expanded(
            child: Text(message,
                style: TextStyle(color: color, fontSize: 13.sp, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _DocTypeOption extends StatelessWidget {
  final String value;
  final String label;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _DocTypeOption({
    required this.value,
    required this.label,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF168DE1).withOpacity(0.1)
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: selected
                ? const Color(0xFF168DE1)
                : const Color(0xFF333333),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color:
                  selected ? const Color(0xFF168DE1) : const Color(0xFF666666),
              size: 18.sp,
            ),
            widthBox10,
            Text(label,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
