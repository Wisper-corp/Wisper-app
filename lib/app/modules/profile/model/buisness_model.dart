class BusinessModel {
  BusinessModel({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool? success;
  final String? message;
  final BusinessData? data;

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      success: json["success"],
      message: json["message"],
      data: json["data"] == null ? null : BusinessData.fromJson(json["data"]),
    );
  }
}

class BusinessData {
  BusinessData({
    required this.auth,
    required this.connection,
    this.avgRating = 0.0,
    this.ratingCount = 0,
  });

  final Auth? auth;
  final Connection? connection;
  final double avgRating;
  final int ratingCount;

  factory BusinessData.fromJson(Map<String, dynamic> json) {
    return BusinessData(
      auth: json["auth"] == null ? null : Auth.fromJson(json["auth"]),
      connection: json["connection"] == null
          ? null
          : Connection.fromJson(json["connection"]),
      avgRating: (json["avgRating"] as num?)?.toDouble() ?? 0.0,
      ratingCount: json["ratingCount"] as int? ?? 0,
    );
  }
}

class Auth {
  Auth({required this.id, required this.createdAt, required this.business});

  final String? id;
  final DateTime? createdAt;
  final Business? business;

  factory Auth.fromJson(Map<String, dynamic> json) {
    return Auth(
      id: json["id"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      business: json["business"] == null
          ? null
          : Business.fromJson(json["business"]),
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
    required this.industry,
    required this.address,
  });

  final String? id;
  final String? name;
  final String? email;
  final dynamic image;
  final dynamic phone;
  final String? industry;
  final dynamic address;

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json["id"],
      name: json["name"],
      email: json["email"],
      image: json["image"],
      phone: json["phone"],
      industry: json["industry"],
      address: json["address"],
    );
  }
}

class Connection {
  Connection({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  final String? id;
  final String? requesterId;
  final String? receiverId;
  final String? status;
  final DateTime? createdAt;

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json["id"],
      requesterId: json["requesterId"],
      receiverId: json["receiverId"],
      status: json["status"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
    );
  }
}
