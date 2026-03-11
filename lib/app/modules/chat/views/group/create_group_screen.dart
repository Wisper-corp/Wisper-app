import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/chat/controller/all_connection_controller.dart';
import 'package:wisper/app/modules/chat/views/group/create_group_button_sheet.dart';
import 'package:wisper/app/modules/chat/widgets/add_icon_widget.dart';
import 'package:wisper/app/modules/chat/widgets/contact_widget.dart';
import 'package:wisper/app/modules/chat/widgets/create_header.dart';
import 'package:wisper/app/modules/chat/widgets/member_widget.dart';
import 'package:wisper/gen/assets.gen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final AllConnectionController allConnectionController =
      Get.find<AllConnectionController>();

  // শুধুমাত্র ID গুলো রাখবো এখানে
  final List<String> selectedMemberIds = [];

  // Search related - নতুন যোগ করা
  final TextEditingController _searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      allConnectionController.getAllConnection('ACCEPTED', '');
    });

    // রিয়েল-টাইম সার্চ লিসেনার
    _searchController.addListener(() {
      searchQuery.value = _searchController.text.toLowerCase().trim();
    });

    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heightBox40,
            CreateHeader(
              bgColor: const Color(0xff051B33),
              iconColor: const Color(0xff1F7DE9),
              title: 'Create Group',
              imagePath: Assets.images.userGroup.keyName,
              onTap: () {
                if (selectedMemberIds.isEmpty) {
                  Get.snackbar(
                    'Warning',
                    'Please select at least one member',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }
                _showCreateGroup();
              },
              trailinlgText: 'Next',
            ),
            heightBox16,
            const StraightLiner(height: 0.5),
            heightBox10,
            Text(
              'Add Members',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            heightBox12,

            // সার্চ ফিল্ড — শুধু এখানে পরিবর্তন
            SizedBox(
              height: 40,
              child: CustomTextField(
                controller: _searchController,
                hintText: 'Search',
                prefixIcon: Icons.search_outlined,
                pprefixIconColor: const Color(0xff8C8C8C),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            heightBox10,

            // Selected Members Preview — ঠিক আগের মতো
            selectedMemberIds.isNotEmpty
                ? Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xff2A2D33),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Members (${selectedMemberIds.length})',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          heightBox10,
                          SizedBox(
                            height: 36,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedMemberIds.length,
                              itemBuilder: (context, index) {
                                final selectedId = selectedMemberIds[index];

                                final connection = allConnectionController
                                    .allConnectionData!
                                    .firstWhere(
                                      (c) =>
                                          (c.partner?.id ?? '').toString() ==
                                          selectedId,
                                    );

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: MemberWidget(
                                    imagePath:
                                        connection.partner?.person != null
                                        ? connection.partner?.person?.image ??
                                              ''
                                        : connection.partner?.business?.image ??
                                              '',
                                    name:
                                        connection.partner?.person?.name ??
                                        'Unknown',
                                    onTap: () {
                                      setState(() {
                                        selectedMemberIds.removeAt(index);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(),
            heightBox10,

            // All Connections List with Search Filter — শুধু ফিল্টার যোগ করা
            Expanded(
              child: Obx(() {
                if (allConnectionController.inProgress) {
                  return const Center(child: CircularProgressIndicator());
                } else if (allConnectionController.allConnectionData!.isEmpty) {
                  return const Center(child: Text('No connection found'));
                } else {
                  final query = searchQuery.value;
                  final filteredList = query.isEmpty
                      ? allConnectionController.allConnectionData!
                      : allConnectionController.allConnectionData!.where((
                          data,
                        ) {
                          final name = data.partner?.person?.name ?? '';
                          return name.toLowerCase().contains(query);
                        }).toList();

                  if (filteredList.isEmpty) {
                    return const Center(child: Text('No matching contacts'));
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      var data = filteredList[index];
                      final userId = (data.partner?.id ?? '').toString();

                      bool isSelected = selectedMemberIds.contains(userId);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: ContactWidget(
                          trailing: AddIconWidget(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedMemberIds.remove(userId);
                                } else {
                                  selectedMemberIds.add(userId);
                                }
                              });
                            },
                          ),
                          imagePath: data.partner?.person?.image ?? '',
                          title: data.partner?.person?.name ?? '',
                          subtitle: data.partner?.person?.title ?? '',
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedMemberIds.remove(userId);
                              } else {
                                selectedMemberIds.add(userId);
                              }
                            });
                          },
                        ),
                      );
                    },
                  );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return CreateGroupButtomSheet(selectedMemberIds: selectedMemberIds);
      },
    );
  }
}
