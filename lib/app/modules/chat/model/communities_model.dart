class CommunitiesModel {
    CommunitiesModel({
        required this.success,
        required this.message,
        required this.data,
    });

    final bool? success;
    final String? message;
    final Data? data;

    factory CommunitiesModel.fromJson(Map<String, dynamic> json){ 
        return CommunitiesModel(
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
    final List<CommunitiesItemModel> groups;

    factory Data.fromJson(Map<String, dynamic> json){ 
        return Data(
            meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
            groups: json["groups"] == null ? [] : List<CommunitiesItemModel>.from(json["groups"]!.map((x) => CommunitiesItemModel.fromJson(x))),
        );
    }

}

class CommunitiesItemModel {
    CommunitiesItemModel({
        required this.id,
        required this.name,
        required this.description,
        required this.image,
        required this.createdAt,
        required this.chatId,
        required this.isJoined,
        required this.memberCount,
        required this.members,
        this.isFeatured = false,
    });

    final String? id;
    final String? name;
    /// Community tags are encoded in the description as
    /// "Trade: X | Market: Y | Category: Z | Suffix: S" — see [communityTags].
    final String? description;
    final String? image;
    final DateTime? createdAt;
    final String? chatId;
    final bool? isJoined;
    final int? memberCount;

    /// Hand-picked for Explore. A featured community is suggested regardless
    /// of how many members it has.
    final bool isFeatured;
    final List<Member> members;

    factory CommunitiesItemModel.fromJson(Map<String, dynamic> json){
        return CommunitiesItemModel(
            id: json["id"],
            name: json["name"],
            description: json["description"],
            image: json["image"],
            createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
            chatId: json["chatId"],
            isJoined: json["isJoined"],
            memberCount: json["memberCount"],
            isFeatured: json["isFeatured"] ?? false,
            members: json["members"] == null ? [] : List<Member>.from(json["members"]!.map((x) => Member.fromJson(x))),
        );
    }

}

class Member {
    Member({
        required this.id,
        required this.image,
    });

    final String? id;
    final String? image;

    factory Member.fromJson(Map<String, dynamic> json){ 
        return Member(
            id: json["id"],
            image: json["image"],
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
