class GroupMembersModel {
    GroupMembersModel({
        required this.success,
        required this.message,
        required this.data,
    });

    final bool? success;
    final String? message;
    final Data? data;

    factory GroupMembersModel.fromJson(Map<String, dynamic> json){ 
        return GroupMembersModel(
            success: json["success"],
            message: json["message"],
            data: json["data"] == null ? null : Data.fromJson(json["data"]),
        );
    }

}

class Data {
    Data({ 
        required this.meta,
        required this.community,
        required this.members,
    });

    final Meta? meta;
    final Community? community;
    final List<GroupMembersItemModel> members;

    factory Data.fromJson(Map<String, dynamic> json){ 
        return Data(
            meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
            community: json["community"] == null ? null : Community.fromJson(json["community"]),
            members: json["members"] == null ? [] : List<GroupMembersItemModel>.from(json["members"]!.map((x) => GroupMembersItemModel.fromJson(x))),
        );
    }

}

class Community {
    Community({
        required this.id,
        required this.name,
        required this.image,
        required this.chat,
    });

    final String? id;
    final String? name;
    final String? image;
    final Chat? chat;

    factory Community.fromJson(Map<String, dynamic> json){ 
        return Community(
            id: json["id"],
            name: json["name"],
            image: json["image"],
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

class GroupMembersItemModel {
    GroupMembersItemModel({
        required this.id,
        required this.role,
        required this.auth,
    });

    final String? id;
    final String? role;
    final Auth? auth;

    factory GroupMembersItemModel.fromJson(Map<String, dynamic> json){ 
        return GroupMembersItemModel(
            id: json["id"],
            role: json["role"],
            auth: json["auth"] == null ? null : Auth.fromJson(json["auth"]),
        );
    }

}

class Auth {
    Auth({required this.id, required this.person, required this.business});
    final String? id;
    final Person? person;
    final Business? business;

    factory Auth.fromJson(Map<String, dynamic> json){ 
        return Auth(
            id: json["id"],
            person: json["person"] == null ? null : Person.fromJson(json["person"]),
            business: json["business"] == null ? null : Business.fromJson(json["business"]),
        );
    }
}

class Person {
    Person({
        required this.name,
        required this.email,
        required this.image,
        this.title,
    });

    final String? name;
    final String? email;
    final String? image;
    final String? title;

    factory Person.fromJson(Map<String, dynamic> json){ 
        return Person(
            name: json["name"],
            email: json["email"],
            image: json["image"],
            title: json["title"],
        );
    }
}

class Business {
    Business({this.name, this.email, this.image, this.industry});
    final String? name;
    final String? email;
    final String? image;
    final String? industry;

    factory Business.fromJson(Map<String, dynamic> json) {
        return Business(
            name: json["name"],
            email: json["email"],
            image: json["image"],
            industry: json["industry"],
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
