class ClassMembersModel {
  ClassMembersModel({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool? success;
  final String? message;
  final List<ClassMembersItemModel> data;

  factory ClassMembersModel.fromJson(Map<String, dynamic> json) {
    return ClassMembersModel(
      success: json["success"],
      message: json["message"],
      data: json["data"] == null
          ? []
          : List<ClassMembersItemModel>.from(
              json["data"]!.map((x) => ClassMembersItemModel.fromJson(x)),
            ),
    );
  }
}

class ClassMembersItemModel {
  ClassMembersItemModel({
    required this.id,
    required this.role,
    required this.auth,
  });

  final String? id;
  final String? role;
  final Auth? auth;

  factory ClassMembersItemModel.fromJson(Map<String, dynamic> json) {
    return ClassMembersItemModel(
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

  factory Auth.fromJson(Map<String, dynamic> json) {
    return Auth(
      id: json["id"],
      person: json["person"] == null ? null : Person.fromJson(json["person"]),
      business: json["business"] == null
          ? null
          : Business.fromJson(json["business"]),
    );
  }
}

class Person {
  Person({required this.name, required this.image});

  final String? name;
  final String? image;

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(name: json["name"], image: json["image"]);
  }
}

class Business {
  Business({required this.name, required this.image});

  final String? name;
  final String? image;

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(name: json["name"], image: json["image"]);
  }
}
