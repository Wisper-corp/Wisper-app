
class MessageModel {
  MessageModel({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool? success;
  final String? message;
  final MessageData? data;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      success: json["success"],
      message: json["message"],
      data: json["data"] == null ? null : MessageData.fromJson(json["data"]),
    );
  }
}

class MessageData {
  MessageData({required this.meta, required this.messages});

  final Meta? meta;
  final List<Message> messages;

  factory MessageData.fromJson(Map<String, dynamic> json) {
    return MessageData(
      meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
      messages: json["messages"] == null
          ? []
          : List<Message>.from(
              json["messages"]!.map((x) => Message.fromJson(x)),
            ),
    );
  }
}

class Message {
  Message({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.text,
    required this.file,
    required this.fileType,
    required this.isEdited,
    required this.createdAt,
    required this.isRead,
  });

  final String? id;
  final String? chatId;
  final Sender? sender;
  final String? text;
  final dynamic file;
  final dynamic fileType;
  final bool? isEdited;
  final DateTime? createdAt;
  final bool? isRead;
  final Map<String, dynamic>? offerData;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json["id"],
      chatId: json["chatId"],
      sender: json["sender"] == null ? null : Sender.fromJson(json["sender"]),
      text: json["text"],
      file: json["file"],
      fileType: json["fileType"],
      isEdited: json["isEdited"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      isRead: json["isRead"],
      offerData: json["offerData"] != null
          ? Map<String, dynamic>.from(json["offerData"])
          : null,
    );
  }
}

class Sender {
  Sender({required this.id, required this.person, required this.business});

  final String? id;
  final Person? person;
  final Business? business;

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      id: json["id"],
      person: json["person"] == null ? null : Person.fromJson(json["person"]),
      business: json["business"] == null
          ? null
          : Business.fromJson(json["business"]),
    );
  }
}

class Person {
  Person({required this.id, required this.name, required this.image});

  final String? id;
  final String? name;
  final String? image;

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(id: json["id"], name: json["name"], image: json["image"]);
  }
}

class Business {
  Business({required this.id, required this.name, required this.image});

  final String? id;
  final String? name;
  final String? image;

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(id: json["id"], name: json["name"], image: json["image"]);
  }
}

class Meta {
  Meta({required this.page, required this.limit, required this.total});

  final int? page;
  final int? limit;
  final int? total;

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(page: json["page"], limit: json["limit"], total: json["total"]);
  }
}
