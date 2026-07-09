class ProfileModel {
  ProfileModel({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool? success;
  final String? message;
  final ProfileData? data;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      success: json["success"],
      message: json["message"],
      data: json["data"] == null ? null : ProfileData.fromJson(json["data"]),
    );
  }
}

class ProfileData {
  ProfileData({
    required this.auth,
    required this.recommendations,
    this.avgRating = 0.0,
    this.ratingCount = 0,
  });

  final Auth? auth;
  final List<dynamic> recommendations;
  final double avgRating;
  final int ratingCount;

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      auth: json["auth"] == null ? null : Auth.fromJson(json["auth"]),
      recommendations: json["recommendations"] == null
          ? []
          : List<dynamic>.from(json["recommendations"]!.map((x) => x)),
      avgRating: (json["avgRating"] as num?)?.toDouble() ?? 0.0,
      ratingCount: json["ratingCount"] as int? ?? 0,
    );
  }

  void operator [](String other) {}
}

class Auth {
  Auth({
    required this.id,
    required this.role,
    required this.createdAt,
    required this.person,
    required this.business,
  });

  final String? id;
  final String? role;
  final DateTime? createdAt;
  final Person? person;
  final Business? business;

  factory Auth.fromJson(Map<String, dynamic> json) {
    return Auth(
      id: json["id"],
      role: json["role"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      person: json["person"] == null ? null : Person.fromJson(json["person"]),
      business: json["business"] == null
          ? null
          : Business.fromJson(json["business"]),
    );
  }
}

class Person {
  Person({
    required this.id,
    required this.name,
    required this.email,
    required this.image,
    required this.phone,
    required this.title,
    required this.industry,
    required this.defaultResume,
    required this.address,
  });

  final String? id;
  final String? name;
  final String? email;
  final String? image;
  final String? phone;
  final String? title;
  final String? industry;
  final dynamic defaultResume;
  final String? address;

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json["id"],
      name: json["name"],
      email: json["email"],
      image: json["image"],
      phone: json["phone"],
      title: json["title"],
      industry: json["industry"],
      defaultResume: json["defaultResume"],
      address: json["address"],
    );
  }
}

class Business {
  Business({
    required this.id,
    required this.name,
    required this.email,
    required this.image,
    required this.phone,
    required this.title,
    required this.industry,
    required this.defaultResume,
    required this.address,
  });

  final String? id;
  final String? name;
  final String? email;
  final String? image;
  final String? phone;
  final String? title;
  final String? industry;
  final dynamic defaultResume;
  final String? address;

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json["id"],
      name: json["name"],
      email: json["email"],
      image: json["image"],
      phone: json["phone"],
      title: json["title"],
      industry: json["industry"],
      defaultResume: json["defaultResume"],
      address: json["address"],
    );
  }
}
