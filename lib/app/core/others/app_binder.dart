import 'package:get/get.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/modules/chat/controller/all_connection_controller.dart';
import 'package:wisper/app/modules/chat/controller/group/all_group_member_controller.dart';
import 'package:wisper/app/modules/chat/controller/image_decode_controller.dart';
import 'package:wisper/app/modules/homepage/controller/all_role_controller.dart';
import 'package:wisper/app/modules/post/controller/create_post_controller.dart';
import 'package:wisper/app/modules/job/controller/feed_job_controller.dart';
import 'package:wisper/app/modules/post/controller/feed_post_controller.dart';
import 'package:wisper/app/modules/job/controller/my_job_controller.dart';
import 'package:wisper/app/modules/post/controller/my_post_controller.dart';
import 'package:wisper/app/modules/homepage/controller/my_resume_controller.dart';
import 'package:wisper/app/modules/profile/controller/upload_photo_controller.dart';

class ControllerBinder extends Bindings {
  @override
  void dependencies() {
    Get.put(NetworkCaller());
    // Get.put(ProfileController());
    // Get.put(BusinessController());
    Get.put(AllFeedPostController());
    Get.put(AllFeedJobController());
    Get.put(CreatePostController());
    Get.put(MyFeedPostController());
    Get.put(MyFeedJobController());
    Get.put(AllChatsController());
    Get.put(ProfilePhotoController());
    Get.put(AllConnectionController());
    Get.put(GroupMembersController());
    Get.put(AllRoleController());
    Get.put(MyResumeController());
    Get.put(FileDecodeController());
  }
}
