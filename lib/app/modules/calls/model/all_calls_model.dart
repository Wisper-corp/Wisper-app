class AllCallsModel {
  AllCallsModel({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool? success;
  final String? message;
  final Data? data;
 
  factory AllCallsModel.fromJson(Map<String, dynamic> json) {
    return AllCallsModel(
      success: json["success"],
      message: json["message"],
      data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );
  }
}

class Data {
  Data({required this.meta, required this.calls});

  final Meta? meta;
  final List<CallItemModel> calls;

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
      calls: json["calls"] == null
          ? []
          : List<CallItemModel>.from(
              json["calls"]!.map((x) => CallItemModel.fromJson(x)),
            ),
    );
  }
}

class CallItemModel {
  CallItemModel({
    required this.id,
    required this.type,
    required this.duration,
    required this.mode,
    required this.date,
    required this.participants,
  });

  final String? id;
  final String? type;
  final int? duration;
  final String? mode;
  final DateTime? date;
  final List<Participant> participants;

  factory CallItemModel.fromJson(Map<String, dynamic> json) {
    return CallItemModel(
      id: json["id"],
      type: json["type"],
      duration: json["duration"],
      mode: json["mode"],
      date: DateTime.tryParse(json["date"] ?? ""),
      participants: json["participants"] == null
          ? []
          : List<Participant>.from(
              json["participants"]!.map((x) => Participant.fromJson(x)),
            ),
    );
  }
}

class Participant {
  Participant({required this.status, required this.auth});

  final String? status;
  final Auth? auth;

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      status: json["status"],
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

class Meta {
  Meta({required this.page, required this.limit, required this.total});

  final int? page;
  final int? limit;
  final int? total;

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(page: json["page"], limit: json["limit"], total: json["total"]);
  }
}
