import 'package:get/get.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';
import 'package:wisper/app/modules/profile/views/business/others_business_screen.dart';
import 'package:wisper/app/modules/profile/views/person/others_person_screen.dart';

/// Which profile screen an author belongs to, or none at all.
enum ForumAuthorDestination { person, business, none }

/// A person and a business have separate profile screens, and the author on a
/// forum post is flattened to a name and a picture — so the payload carries
/// `isPerson` to say which one to open.
///
/// An author with no id resolves to [ForumAuthorDestination.none]: pushing a
/// profile screen that can only fail to load is worse than not moving.
ForumAuthorDestination forumAuthorDestination(ForumAuthor author) {
  final id = author.id;
  if (id == null || id.trim().isEmpty) return ForumAuthorDestination.none;
  return author.isPerson
      ? ForumAuthorDestination.person
      : ForumAuthorDestination.business;
}

/// Opens a forum author's profile.
void openForumAuthor(ForumAuthor author) {
  switch (forumAuthorDestination(author)) {
    case ForumAuthorDestination.person:
      Get.to(() => OthersPersonScreen(userId: author.id!));
    case ForumAuthorDestination.business:
      Get.to(() => OthersBusinessScreen(userId: author.id!));
    case ForumAuthorDestination.none:
      break;
  }
}
