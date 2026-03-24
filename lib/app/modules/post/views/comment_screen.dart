import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/modules/post/controller/comment_controller.dart';
import 'package:wisper/app/modules/post/controller/edit_comment_controller.dart';
import 'package:wisper/app/modules/post/views/my_post_section.dart';
import 'package:wisper/app/modules/profile/views/business/others_business_screen.dart';
import 'package:wisper/app/modules/profile/views/person/others_person_screen.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  const CommentScreen({super.key, required this.postId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final CommentController commentController = Get.put(CommentController());
  final EditCommentController editCommentController = EditCommentController();
  final TextEditingController commentCtrl = TextEditingController();

  // এডিট মোডে আছি কিনা এবং কোন কমেন্ট এডিট করছি
  String? currentEditingCommentId;

  @override
  void initState() {
    super.initState();
    commentController.getAllComment(widget.postId);
  }

  // সেন্ড বাটনের কাজ (Add অথবা Edit)
  void submitComment() {
    if (commentCtrl.text.trim().isEmpty) {
      showSnackBarMessage(context, "Please write something", true);
      return;
    }

    showLoadingOverLay(
      asyncFunction: () async => await performSubmit(context),
      msg: 'Please wait...',
    );
  }

  Future<void> performSubmit(BuildContext context) async {
    bool isSuccess = false;

    if (currentEditingCommentId != null) {
      // Edit mode
      isSuccess = await editCommentController.editComment(
        commentId: currentEditingCommentId!,
        comment: commentCtrl.text.trim(),
      );
    } else {
      // Add mode
      isSuccess = await commentController.addComment(
        widget.postId,
        commentCtrl.text.trim(),
      );
    }

    if (isSuccess) {
      await commentController.getAllComment(widget.postId);
      commentCtrl.clear();
      setState(() {
        currentEditingCommentId = null; // এডিট মোড বন্ধ
      });
    } else {
      final errorMsg = currentEditingCommentId != null
          ? editCommentController.errorMessage
          : commentController.errorMessage;
      showSnackBarMessage(context, errorMsg, true);
    }
  }

  // Delete comment
  void deleteComment(String commentId) {
    showLoadingOverLay(
      asyncFunction: () async => await performDeleteComment(context, commentId),
      msg: 'Please wait...',
    );
  }

  Future<void> performDeleteComment(
    BuildContext context,
    String commentId,
  ) async {
    final bool isSuccess = await editCommentController.deleteComment(
      commentId: commentId,
    );

    if (isSuccess) {
      await commentController.getAllComment(widget.postId);
      Get.back(); // বটমশিট বন্ধ
    } else {
      showSnackBarMessage(context, editCommentController.errorMessage, true);
    }
  }

  // Edit বাটনে ক্লিক → টেক্সট ফিল্ডে লোড
  void startEdit(String commentId, String currentText) {
    setState(() {
      currentEditingCommentId = commentId;
      commentCtrl.text = currentText;
      commentCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: commentCtrl.text.length),
      ); // কার্সর শেষে রাখা
    });
  }

  void _showDeleteComment(String commentId) {
    ConfirmationBottomSheet.show(
      context: context,
      title: "Delete Comment?",
      message:
          "This comment will be permanently removed.\nThis action cannot be undone.",
      onDelete: () {
        deleteComment(commentId);
      },
      // deleteText: "Delete Now", // optional customization
      // cancelText: "Keep it",   // optional
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Comments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          children: [
            /// COMMENT LIST
            Expanded(
              child: Obx(() {
                if (commentController.inProgress) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (commentController.commentData == null ||
                    commentController.commentData!.isEmpty) {
                  return const Center(child: Text('No comment found'));
                }

                return ListView.builder(
                  itemCount: commentController.commentData!.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final comment = commentController.commentData![index];
                    final isPerson = comment.author?.person != null;
                    var authorId = comment.author?.id ?? '';
                    var authorName = isPerson
                        ? comment.author?.person?.name
                        : comment.author!.business?.name;
                    var authorImage = isPerson
                        ? comment.author?.person?.image
                        : comment.author!.business?.image;
                    return SizedBox(
                      height: 70.h,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: GestureDetector(
                          onTap: () {
                            if (isPerson) {
                              Get.to(OthersPersonScreen(userId: authorId));
                            } else {
                              Get.to(OthersBusinessScreen(userId: authorId));
                            }
                          },
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(authorImage ?? ''),
                            radius: 20.r,
                          ),
                        ),
                        title: Text(
                          authorName ?? '',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              comment.text ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                            heightBox4,
                            authorId == StorageUtil.getData(StorageUtil.userId)
                                ? Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          startEdit(
                                            comment.id!,
                                            comment.text ?? '',
                                          );
                                        },
                                        child: Text(
                                          'Edit',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                      widthBox8,
                                      GestureDetector(
                                        onTap: () {
                                          _showDeleteComment(comment.id!);
                                        },
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            /// COMMENT INPUT
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: commentCtrl,
                    hintText: currentEditingCommentId != null
                        ? 'Edit your comment...'
                        : 'Write a comment...',
                  ),
                ),
                widthBox8,
                GestureDetector(
                  onTap: submitComment,
                  child: CircleAvatar(
                    radius: 28.r,
                    backgroundColor: const Color(0xff121212),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
