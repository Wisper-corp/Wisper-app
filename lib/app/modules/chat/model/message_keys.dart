// app/modules/chat/constants/message_keys.dart

class SocketMessageKeys {
  static const String id = "id";
  static const String text = "text";
  static const String imageUrl = "imageUrl";
  static const String seen = "seen";
  static const String senderId = "senderId";
  static const String senderName = "senderName";
  static const String senderImage = "senderImage";
  static const String senderType = "senderType"; // PERSON | BUSINESS
  static const String chat = "chat";
  static const String createdAt = "createdAt";
  static const String fileType = "fileType";

  /// The forum post a private reply is about, as a plain map.
  static const String forumPost = "forumPost";

  // Offer message type
  static const String offerFileType = "OFFER";
  static const String offerData = "offerData";
}
