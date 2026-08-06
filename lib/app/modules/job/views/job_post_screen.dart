import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/currency_helper.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/label.dart';
import 'package:wisper/app/modules/job/controller/create_job_controller.dart';
import 'package:wisper/app/modules/job/controller/feed_job_controller.dart';
import 'package:wisper/app/modules/profile/controller/buisness/buisness_controller.dart';
import 'package:wisper/app/modules/profile/controller/person/profile_controller.dart';
import 'package:wisper/app/modules/job/controller/my_job_controller.dart';

class JobPostScreen extends StatefulWidget {
  final String? groupId;
  const JobPostScreen({super.key, this.groupId});

  @override
  State<JobPostScreen> createState() => _JobPostScreenState();
}

class _JobPostScreenState extends State<JobPostScreen> {
  final CreateJobController createJobController = CreateJobController();

  // Controllers
  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  final _salaryC = TextEditingController();
  final _locationC = TextEditingController();
  final _reqC = TextEditingController();
  final _resC = TextEditingController();
  final _linkC = TextEditingController();

  // Dropdown selected values (default values)
  String? type = 'FULL_TIME';
  String? experienceLevel = 'MID_LEVEL';
  String? compensationType = 'MONTHLY';
  String? qualification = 'BSC';
  String? applicationType = 'CHAT';
  String? industry = 'Web Development';
  String? locationType = 'ON_SITE';

  List<String> requirements = [];
  List<String> responsibilities = [];

  bool isFormValid = false;

  @override
  void initState() {
    super.initState();

    // Listeners for real-time validation
    _titleC.addListener(_validateForm);
    _descC.addListener(_validateForm);
    _salaryC.addListener(_validateForm);

    // Initial validation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateForm();
    });
  }

  void _validateForm() {
    final title = _titleC.text.trim();
    final desc = _descC.text.trim();
    final salaryText = _salaryC.text.trim();
    final salary = double.tryParse(salaryText) ?? 0;

    // Only require title, description and salary — requirements/responsibilities are optional
    final newValidState =
        title.isNotEmpty &&
        desc.isNotEmpty &&
        salaryText.isNotEmpty &&
        salary > 0;

    if (newValidState != isFormValid) {
      setState(() {
        isFormValid = newValidState;
      });
    }
  }

  void _addItem(String type) {
    final controller = type == 'req' ? _reqC : _resC;
    final text = controller.text.trim();

    if (text.isNotEmpty) {
      setState(() {
        if (type == 'req') {
          requirements.add(text);
        } else {
          responsibilities.add(text);
        }
        controller.clear();
      });
      _validateForm();
    }
  }

  void _removeItem(String type, int index) {
    setState(() {
      if (type == 'req') {
        requirements.removeAt(index);
      } else {
        responsibilities.removeAt(index);
      }
    });
    _validateForm();
  }

  bool _isNigeriaUser() {
    if (CurrencyHelper.isNaira) return true;
    try {
      final role = StorageUtil.getData(StorageUtil.userRole) ?? '';
      String address = '';
      if (role == 'PERSON') {
        address = Get.find<ProfileController>().profileData?.auth?.person?.address?.toLowerCase() ?? '';
      } else {
        address = Get.find<BusinessController>().buisnessData?.auth?.business?.address?.toLowerCase() ?? '';
      }
      if (address.contains('nigeria') || address.contains('lagos') || address.contains('abuja') || address.contains(' ng')) return true;
    } catch (_) {}
    return false;
  }

  void createJob() {
    showLoadingOverLay(
      asyncFunction: () async => await performCreateJob(context),
      msg: 'Posting job...',
    );
  }

  Future<void> performCreateJob(BuildContext context) async {
    final bool isSuccess = await createJobController.createJob(
      applicationLink: _linkC.text.trim(),
      title: _titleC.text.trim(),
      description: _descC.text.trim(),
      type: type ?? 'FULL_TIME',
      experienceLevel: experienceLevel ?? 'MID_LEVEL',
      compensationType: compensationType ?? 'MONTHLY',
      salary: double.tryParse(_salaryC.text.trim()) ?? 0.0,
      currency: _isNigeriaUser() ? 'NGN' : 'USD',
      location: _locationC.text.trim().isEmpty
          ? "Remote"
          : _locationC.text.trim(),
      qualification: qualification ?? 'BSC',
      industry: industry ?? 'Web Development',
      locationType: locationType ?? 'ON_SITE',
      requirements: requirements,
      responsibilities: responsibilities,
      applicationType: applicationType ?? 'CHAT',
      groupId: widget.groupId,
    );

    if (isSuccess) {
      // Refresh the correct job list after posting
      if (widget.groupId != null && widget.groupId!.isNotEmpty) {
        final tag = 'jobs_group_${widget.groupId}';
        if (Get.isRegistered<AllFeedJobController>(tag: tag)) {
          final ctrl = Get.find<AllFeedJobController>(tag: tag);
          ctrl.resetPagination();
          await ctrl.getJobs(groupId: widget.groupId);
        }
      } else {
        final allFeedJobController = Get.find<AllFeedJobController>(tag: 'jobs_global');
        allFeedJobController.resetPagination();
        await allFeedJobController.getJobs();
      }
      final MyFeedJobController myFeedJobController = Get.find<MyFeedJobController>();
      myFeedJobController.resetPagination();
      await myFeedJobController.getJobs();

      if (context.mounted) {
        Navigator.pop(context);
        showSnackBarMessage(context, "Job posted successfully!", false);
      }
    } else {
      if (context.mounted) {
        showSnackBarMessage(
          context,
          createJobController.errorMessage.isNotEmpty
              ? createJobController.errorMessage
              : "Failed to post job. Please try again.",
          true,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleC.removeListener(_validateForm);
    _descC.removeListener(_validateForm);
    _salaryC.removeListener(_validateForm);

    _titleC.dispose();
    _descC.dispose();
    _salaryC.dispose();
    _locationC.dispose();
    _reqC.dispose();
    _resC.dispose();
    _linkC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBox40,

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    width: 80,
                    child: CustomElevatedButton(
                      title: 'Post',
                      textSize: 14,
                      borderRadius: 50,
                      onPress: isFormValid ? createJob : null,
                    ),
                  ),
                ],
              ),

              heightBox20,
              const Text(
                'Post a Job',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              heightBox20,

              // Job Title *
              const Label(label: 'Job Title *'),
              heightBox6,
              CustomTextField(
                controller: _titleC,
                hintText: 'e.g. Frontend Developer',
              ),
              heightBox16,

              // Description *
              const Label(label: 'Description *'),
              heightBox6,
              SizedBox(
                height: 140.h,
                child: CustomTextField(
                  controller: _descC,
                  maxLines: 8,
                  hintText: 'Describe the role...',
                ),
              ),
              heightBox16,

              // Job Type
              const Label(label: 'Job Type'),
              heightBox6,
              CustomTextField(
                hintText: 'Select job type',
                value: type,
                onChanged: (v) => setState(() => type = v),
                items: const [
                  DropdownMenuItem(
                    value: 'FULL_TIME',
                    child: Text('Full Time'),
                  ),
                  DropdownMenuItem(
                    value: 'PART_TIME',
                    child: Text('Part Time'),
                  ),
                  DropdownMenuItem(value: 'CONTRACT', child: Text('Contract')),
                ],
              ),
              heightBox16,

              // Experience Level
              const Label(label: 'Experience Level'),
              heightBox6,
              CustomTextField(
                hintText: 'Select experience level',
                value: experienceLevel,
                onChanged: (v) => setState(() => experienceLevel = v),
                items: const [
                  DropdownMenuItem(
                    value: 'ENTRY_LEVEL',
                    child: Text('Entry Level'),
                  ),
                  DropdownMenuItem(value: 'JUNIOR', child: Text('Junior')),
                  DropdownMenuItem(
                    value: 'MID_LEVEL',
                    child: Text('Mid Level'),
                  ),
                  DropdownMenuItem(value: 'SENIOR', child: Text('Senior')),
                ],
              ),
              heightBox16,

              // Compensation Type
              const Label(label: 'Compensation Type'),
              heightBox6,
              CustomTextField(
                hintText: 'Select compensation type',
                value: compensationType,
                onChanged: (v) => setState(() => compensationType = v),
                items: const [
                  DropdownMenuItem(
                    value: 'MONTHLY',
                    child: Text('Monthly Salary'),
                  ),
                  DropdownMenuItem(
                    value: 'ONE_OFF',
                    child: Text('One-time Payment'),
                  ),
                ],
              ),
              heightBox16,

              // Salary *
              Builder(builder: (context) {
                // Detect Nigeria from profile address or device locale
                bool isNigeria = CurrencyHelper.isNaira;
                try {
                  final role = StorageUtil.getData(StorageUtil.userRole) ?? '';
                  String address = '';
                  if (role == 'PERSON') {
                    address = Get.find<ProfileController>().profileData?.auth?.person?.address?.toLowerCase() ?? '';
                  } else {
                    address = Get.find<BusinessController>().buisnessData?.auth?.business?.address?.toLowerCase() ?? '';
                  }
                  if (address.contains('nigeria') || address.contains('ng') || address.contains('lagos') || address.contains('abuja')) {
                    isNigeria = true;
                  }
                } catch (_) {}
                final currencyLabel = isNigeria ? '₦ (NGN)' : '\$ (USD)';
                return Label(label: 'Salary ($currencyLabel) *');
              }),
              heightBox6,
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _salaryC,
                      hintText: '1800',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  widthBox10,
                  Text(
                    compensationType == 'MONTHLY' ? '/ month' : 'total',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                  ),
                ],
              ),
              heightBox16,

              // Location Type
              const Label(label: 'Location Type'),
              heightBox6,
              CustomTextField(
                hintText: 'Select type',
                value: locationType,
                onChanged: (v) => setState(() => locationType = v),
                items: const [
                  DropdownMenuItem(value: 'ON_SITE', child: Text('On-site')),
                  DropdownMenuItem(value: 'HYBRID', child: Text('Hybrid')),
                  DropdownMenuItem(value: 'REMOTE', child: Text('Remote')),
                ],
              ),
              heightBox16,

              // Minimum Qualification
              const Label(label: 'Minimum Qualification'),
              heightBox6,
              CustomTextField(
                hintText: 'Select qualification',
                value: qualification,
                onChanged: (v) => setState(() => qualification = v),
                items: const [
                  DropdownMenuItem(
                    value: 'SSCE',
                    child: Text('Secondary School Certificate (SSCE)'),
                  ),
                  DropdownMenuItem(
                    value: 'OND',
                    child: Text('Ordinary National Diploma (OND)'),
                  ),
                  DropdownMenuItem(
                    value: 'HND',
                    child: Text('Higher National Diploma (HND)'),
                  ),
                  DropdownMenuItem(
                    value: 'BSC',
                    child: Text("Bachelor's Degree (BSc)"),
                  ),
                  DropdownMenuItem(
                    value: 'MSC',
                    child: Text("Master's Degree (MSc)"),
                  ),
                  DropdownMenuItem(value: 'PHD', child: Text('PhD')),
                ],
              ),
              heightBox16,

              // Application Method
              const Label(label: 'Application Method'),
              heightBox6,
              CustomTextField(
                hintText: 'How should candidates apply?',
                value: applicationType,
                onChanged: (v) => setState(() {
                  applicationType = v;
                  _linkC.clear(); // clear when switching method
                }),
                items: const [
                  DropdownMenuItem(
                    value: 'CHAT',
                    child: Text('Via Wisper Chat'),
                  ),
                  DropdownMenuItem(value: 'EMAIL', child: Text('Via Email')),
                  DropdownMenuItem(
                    value: 'EXTERNAL',
                    child: Text('External Link'),
                  ),
                ],
              ),
              heightBox16,

              // Conditional field based on application method
              if (applicationType == 'EXTERNAL') ...[
                const Label(label: 'External Link (URL)'),
                heightBox6,
                CustomTextField(
                  controller: _linkC,
                  hintText: 'https://example.com',
                  keyboardType: TextInputType.url,
                ),
                heightBox20,
              ] else if (applicationType == 'EMAIL') ...[
                const Label(label: 'Application Email Address'),
                heightBox6,
                CustomTextField(
                  controller: _linkC,
                  hintText: 'e.g. careers@company.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                heightBox20,
              ],

              // Requirements *
              const Label(label: 'Requirements * (at least 1)'),
              heightBox8,
              ...requirements.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      widthBox10,
                      Expanded(child: Text(e.value)),
                      GestureDetector(
                        onTap: () => _removeItem('req', e.key),
                        child: const Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _reqC,
                      hintText: 'Add requirement',
                    ),
                  ),
                  widthBox10,
                  IconButton(
                    onPressed: () => _addItem('req'),
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                  ),
                ],
              ),
              heightBox20,

              // Responsibilities *
              const Label(label: 'Responsibilities * (at least 1)'),
              heightBox8,
              ...responsibilities.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      widthBox10,
                      Expanded(child: Text(e.value)),
                      GestureDetector(
                        onTap: () => _removeItem('res', e.key),
                        child: const Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _resC,
                      hintText: 'Add responsibility',
                    ),
                  ),
                  widthBox10,
                  IconButton(
                    onPressed: () => _addItem('res'),
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                  ),
                ],
              ),

              heightBox80,
            ],
          ),
        ),
      ),
    );
  }
}
