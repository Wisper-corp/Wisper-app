class GroupInfoModel {
    GroupInfoModel({
        required this.success,
        required this.message,
        required this.data,
    });

    final bool? success;
    final String? message;
    final GroupInfoData? data;

    factory GroupInfoModel.fromJson(Map<String, dynamic> json){ 
        return GroupInfoModel(
            success: json["success"],
            message: json["message"],
            data: json["data"] == null ? null : GroupInfoData.fromJson(json["data"]),
        );
    }

}

class GroupInfoData {
    GroupInfoData({
        required this.id,
        required this.name,
        required this.description,
        required this.createdAt,
        required this.image,
        required this.isPrivate,
        required this.allowInvitation,
        required this.chat,
    });

    final String? id;
    final String? name;
    final String? description;
    final DateTime? createdAt;
    final dynamic image;
    final bool? isPrivate;
    final bool? allowInvitation;
    final Chat? chat;

    factory GroupInfoData.fromJson(Map<String, dynamic> json){ 
        return GroupInfoData(
            id: json["id"],
            name: json["name"],
            description: json["description"],
            createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
            image: json["image"],
            isPrivate: json["isPrivate"],
            allowInvitation: json["allowInvitation"],
            chat: json["chat"] == null ? null : Chat.fromJson(json["chat"]),
        );
    }

}

class Chat {
    Chat({
        required this.count,
    });

    final Count? count;

    factory Chat.fromJson(Map<String, dynamic> json){ 
        return Chat(
            count: json["_count"] == null ? null : Count.fromJson(json["_count"]),
        );
    }

}

class Count {
    Count({
        required this.participants,
    });

    final int? participants;

    factory Count.fromJson(Map<String, dynamic> json){ 
        return Count(
            participants: json["participants"],
        );
    }

}
