import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/chat/controller/all_connection_controller.dart';
import 'package:wisper/app/modules/chat/views/class/create_class_screen.dart';
import 'package:wisper/app/modules/chat/views/group/create_group_screen.dart';
import 'package:wisper/app/modules/chat/widgets/contact_widget.dart';
import 'package:wisper/app/modules/chat/widgets/create_widget.dart';
import 'package:wisper/app/modules/profile/views/business/others_business_screen.dart';
import 'package:wisper/app/modules/profile/views/person/others_person_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class CreateGroupClassScreen extends StatefulWidget {
  const CreateGroupClassScreen({super.key});

  @override
  State<CreateGroupClassScreen> createState() => _CreateGroupClassScreenState();
}

class _CreateGroupClassScreenState extends State<CreateGroupClassScreen> {
  final AllConnectionController allConnectionController = Get.put(
    AllConnectionController(),
  );

  // Search related
  final TextEditingController _searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    allConnectionController.getAllConnection('ACCEPTED', '');

    // Listen to search input changes
    _searchController.addListener(() {
      searchQuery.value = _searchController.text.toLowerCase().trim();
    });
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
            Align(
              alignment: Alignment.centerRight,
              child: CircleIconWidget(
                imagePath: Assets.images.cross.keyName,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ),
            heightBox10,
            CreateWidget(
              ontap: () {
                Get.to(() => CreateGroupScreen());
              },
              imagePath: Assets.images.education.keyName,
              bgColor: Color(0xff102B19),
              iconColor: Color(0xff11AE46),
              title: 'Create New Group',
              subtitle: 'Start a group conversation',
            ),
            heightBox10,
            StraightLiner(height: 0.5),
            heightBox10,
            CreateWidget(
              ontap: () {
                Get.to(() => CreateClassScreen());
              },
              imagePath: Assets.images.userGroup.keyName,
              bgColor: Color(0xff1B1E25),
              iconColor: Color.fromARGB(255, 255, 255, 255),
              title: 'Create New Class',
              subtitle: 'Start a new educational class',
            ),
            heightBox30,

            Text(
              'Contacts on the Platform',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            heightBox12,

            // Search Field
            SizedBox(
              height: 40,
              child: CustomTextField(
                controller: _searchController,
                hintText: 'Search',
                prefixIcon: Icons.search_outlined,
                pprefixIconColor: const Color(0xff8C8C8C),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            heightBox10,

            // Contacts List with Search Filter
            Expanded(
              child: Obx(() {
                if (allConnectionController.inProgress) {
                  return const Center(child: CircularProgressIndicator());
                }

                final originalList =
                    allConnectionController.allConnectionData ?? [];
                final query = searchQuery.value;

                // Filter contacts based on name
                final filteredList = query.isEmpty
                    ? originalList
                    : originalList.where((connection) {
                        final name = connection.partner?.person?.name ?? '';
                        return name.toLowerCase().contains(query);
                      }).toList();

                if (filteredList.isEmpty) {
                  return const Center(
                    child: Text(
                      'No contacts found',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final connection = filteredList[index];
                    final name = connection.partner?.person != null
                        ? connection.partner?.person?.name
                        : connection.partner?.business?.name ?? '';
                    final title = connection.partner?.person != null
                        ? connection.partner?.person?.title
                        : connection.partner?.business?.industry ?? '';

                    final imagePath = connection.partner?.person != null
                        ? connection.partner?.person?.image
                        : connection.partner?.business?.image;
                    '';

                    bool isPerson = connection.partner?.person != null
                        ? true
                        : false;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ContactWidget(
                        imagePath: imagePath ?? '',
                        title: name ?? '',
                        subtitle: title ?? '',
                        onTap: () {
                          isPerson == true
                              ? Get.to(
                                  () => OthersPersonScreen(
                                    userId: connection.partner?.id ?? '',
                                  ),
                                )
                              : Get.to(
                                  () => OthersBusinessScreen(
                                    userId: connection.partner?.id ?? '',
                                  ),
                                );
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
