// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/shimmer/member_list_shimmer.dart';
import 'package:wisper/app/modules/chat/controller/create_chat_controller.dart'
    show CreateChatController;
import 'package:wisper/app/modules/chat/views/person/message_screen.dart';
import 'package:wisper/app/modules/homepage/controller/add_request_controller.dart';
import 'package:wisper/app/modules/homepage/controller/all_role_controller.dart';
import 'package:wisper/app/modules/homepage/widget/role_card.dart';

class RoleSection extends StatefulWidget {
  const RoleSection({super.key, this.searchQuery, this.country});
  final String? searchQuery;
  final String? country;
 
  @override
  State<RoleSection> createState() => _RoleSectionState();
}

class _RoleSectionState extends State<RoleSection> {
  final AllRoleController allRoleController = Get.find<AllRoleController>();
  final AddRequestController addRequestController = Get.put(
    AddRequestController(),
  );
  final CreateChatController createChatController = Get.put(
    CreateChatController(),
  );

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      allRoleController.getAllRole(widget.searchQuery, country: widget.country);
    });

    super.initState();
  }

  @override
  void didUpdateWidget(covariant RoleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery ||
        widget.country != oldWidget.country) {
      allRoleController.getAllRole(widget.searchQuery, country: widget.country);
    }
  }

  Future<void> executeWithLoading({
    required Future<bool> Function() action,
    required String loadingMessage,
    required Future<void> Function() onSuccess,
    void Function(String error)? onError,
  }) async {
    showLoadingOverLay(
      asyncFunction: () async {
        try {
          final success = await action();
          if (success) {
            await onSuccess();
          } else {
            final errorMsg = "Operation failed. Please try again.";
            if (onError != null) {
              onError(errorMsg);
            } else {
              showSnackBarMessage(context, errorMsg, true);
            }
          }
        } catch (e) {
          final errorMsg = e.toString().replaceAll('Exception: ', '').trim();
          if (onError != null) {
            onError(errorMsg);
          } else {
            showSnackBarMessage(context, errorMsg, true);
          }
        }
      },
      msg: loadingMessage,
    );
  }

  void addRequest(String? receiverId) {
    if (receiverId == null) return;

    executeWithLoading(
      loadingMessage: 'Please wait...',
      action: () => addRequestController.addRequest(receiverId: receiverId),
      onSuccess: () async {
        await allRoleController.getAllRole('');
        showSnackBarMessage(context, 'Request sent successfully', false);
      },
      onError: (error) {
        showSnackBarMessage(
          context,
          addRequestController.errorMessage ?? error,
          true,
        );
      },
    );
  }

  void createChat(String? memberId, String? memberName, String? memberImage) {
    if (memberId == null) return;

    executeWithLoading(
      loadingMessage: 'Please wait...',
      action: () => createChatController.createChat(memberId: memberId),
      onSuccess: () async {
        var chatId = createChatController.chatId;
        Get.to(
          ChatScreen(
            chatId: chatId,
            receiverId: memberId,
            receiverImage: memberImage ?? '',
            receiverName: memberName ?? '',
          ),
        );
      },
      onError: (error) {
        showSnackBarMessage(
          context,
          createChatController.errorMessage ?? error,
          true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(() {
        if (allRoleController.inProgress) {
          return MemberShimmerEffectWidget();
        } else if (allRoleController.allRoleData!.isEmpty) {
          return const Center(
            child: Text('No role found', style: TextStyle(fontSize: 12)),
          );
        } else {
          var data = allRoleController.allRoleData;
          return ListView.builder(
            padding: EdgeInsets.all(0),
            itemCount: data!.length,
            itemBuilder: (context, index) {
              var status = data[index].connectionStatus;
              print(
                'id ${data[index].id} and my id ${StorageUtil.getData(StorageUtil.userId)}',
              );
              print('status $status for ${data[index].person?.name}');
              var id =
                  data[index].id == StorageUtil.getData(StorageUtil.userId);
              return status == 'ACCEPTED' || status == 'PENDING'
                  ? Container()
                  : status == 'REJECTED' || status == 'REQUEST_RECEIVED'
                  ? Container()
                  : id == true
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: RoleCard(
                        isEnable: status == 'REQUEST_SENT' ? false : true,
                        status: status == 'REQUEST_SENT'
                            ? 'Pending'
                            : status == 'NOT_CONNECTED'
                            ? '+ Add'
                            : 'N/A',
                        title: data[index].person?.name ?? 'N/A',
                        post: data[index].count?.posts ?? 0,
                        imagePath: data[index].person?.image ?? '',
                        recommendations:
                            data[index].count?.receivedRecommendations ?? 0,
                        messagesOnTap: () {
                          createChat(
                            data[index].id,
                            data[index].person?.name,
                            data[index].person?.image,
                          );
                        },
                        addOnTap: () {
                          status == 'NOT_CONNECTED'
                              ? addRequest(data[index].id)
                              : null;
                        },
                        role: data[index].person?.title ?? 'N/A',
                        id: data[index].id ?? 'N/A',
                      ),
                    );
            },
          );
        }
      }),
    );
  }
}
