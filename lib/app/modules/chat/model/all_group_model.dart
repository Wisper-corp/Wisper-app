class AllGroupModel {
    AllGroupModel({
        required this.success,
        required this.message,
        required this.data,
    });

    final bool? success;
    final String? message;
    final Data? data;

    factory AllGroupModel.fromJson(Map<String, dynamic> json){ 
        return AllGroupModel(
            success: json["success"],
            message: json["message"],
            data: json["data"] == null ? null : Data.fromJson(json["data"]),
        );
    }

}
 
class Data {
    Data({
        required this.meta,
        required this.groups,
    });

    final Meta? meta;
    final List<AllGroupItemModel> groups;

    factory Data.fromJson(Map<String, dynamic> json){ 
        return Data(
            meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
            groups: json["groups"] == null ? [] : List<AllGroupItemModel>.from(json["groups"]!.map((x) => AllGroupItemModel.fromJson(x))),
        );
    }

}

class AllGroupItemModel {
    AllGroupItemModel({
        required this.id,
        required this.name,
        required this.image,
        required this.createdAt,
        required this.chat,
    });

    final String? id;
    final String? name;
    final dynamic image;
    final DateTime? createdAt;
    final Chat? chat;

    factory AllGroupItemModel.fromJson(Map<String, dynamic> json){ 
        return AllGroupItemModel(
            id: json["id"],
            name: json["name"],
            image: json["image"],
            createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
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

class Meta {
    Meta({
        required this.page,
        required this.limit,
        required this.total,
    });

    final int? page;
    final int? limit;
    final int? total;

    factory Meta.fromJson(Map<String, dynamic> json){ 
        return Meta(
            page: json["page"],
            limit: json["limit"],
            total: json["total"],
        );
    }

}
