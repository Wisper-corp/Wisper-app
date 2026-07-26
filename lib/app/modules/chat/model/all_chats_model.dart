class AllChatsModel {
  AllChatsModel({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool? success;
  final String? message;
  final Data? data;

  factory AllChatsModel.fromJson(Map<String, dynamic> json) {
    return AllChatsModel(
      success: json["success"],
      message: json["message"],
      data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );
  }
}

class Data {
  Data({required this.meta, required this.chats});

  final Meta? meta;
  final List<AllChatsItemModel> chats;

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
      chats: json["chats"] == null
          ? []
          : List<AllChatsItemModel>.from(
              json["chats"]!.map((x) => AllChatsItemModel.fromJson(x)),
            ),
    );
  }
}

class AllChatsItemModel {
  AllChatsItemModel({
    required this.id,
    required this.type,
    required this.latestMessageAt,
    required this.groupId,
    required this.classId,
    required this.participants,
    required this.group,
    required this.chatClass,
    required this.messages,
    required this.count,
  });

  final String? id;
  final String? type;
  final DateTime? latestMessageAt;
  final String? groupId;
  final String? classId;
  final List<Participant> participants;
  final Class? group;
  final Class? chatClass;
  final List<Message> messages;
  final Count? count;

  factory AllChatsItemModel.fromJson(Map<String, dynamic> json) {
    return AllChatsItemModel(
      id: json["id"],
      type: json["type"],
      latestMessageAt: DateTime.tryParse(json["latestMessageAt"] ?? ""),
      groupId: json["groupId"],
      classId: json["classId"],
      participants: json["participants"] == null
          ? []
          : List<Participant>.from(
              json["participants"]!.map((x) => Participant.fromJson(x)),
            ),
      group: json["group"] == null ? null : Class.fromJson(json["group"]),
      chatClass: json["class"] == null ? null : Class.fromJson(json["class"]),
      messages: json["messages"] == null
          ? []
          : List<Message>.from(
              json["messages"]!.map((x) => Message.fromJson(x)),
            ),
      count: json["_count"] == null ? null : Count.fromJson(json["_count"]),
    );
  }
}

class Class {
  Class({required this.image, required this.name});

  final String? image;
  final String? name;

  factory Class.fromJson(Map<String, dynamic> json) {
    return Class(image: json["image"], name: json["name"]);
  }
}

class Count {
  Count({required this.messages});

  final int? messages;

  factory Count.fromJson(Map<String, dynamic> json) {
    return Count(messages: json["messages"]);
  }
}

class Message {
  Message({
    required this.id,
    required this.text,
    required this.file,
    required this.fileType,
    required this.sender,
  });

  final String? id;
  final String? text;
  final dynamic file;
  final dynamic fileType;
  final Sender? sender;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json["id"],
      text: json["text"],
      file: json["file"],
      fileType: json["fileType"],
      sender: json["sender"] == null ? null : Sender.fromJson(json["sender"]),
    );
  }
}

class Sender {
  Sender({required this.id, required this.person, required this.business});

  final String? id;
  final Person? person;
  final dynamic business;

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      id: json["id"],
      person: json["person"] == null ? null : Person.fromJson(json["person"]),
      business: json["business"],
    );
  }
}

class Person {
  Person({required this.name});

  final String? name;

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(name: json["name"]);
  }
}

class Participant {
  Participant({required this.id, required this.auth, required this.isOnline});

  final String? id;
  final Auth? auth;
  final bool? isOnline;

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json["id"],
      auth: json["auth"] == null ? null : Auth.fromJson(json["auth"]),
      isOnline: json["isOnline"],
    );
  }
}

class Auth {
  Auth({required this.id, required this.person, required this.business});

  final String? id;
  final Class? person;
  final Class? business;

  factory Auth.fromJson(Map<String, dynamic> json) {
    return Auth(
      id: json["id"],
      person: json["person"] == null ? null : Class.fromJson(json["person"]),
      business: json["business"] == null
          ? null
          : Class.fromJson(json["business"]),
    );
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
