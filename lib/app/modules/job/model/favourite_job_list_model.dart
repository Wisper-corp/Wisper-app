class FavoriteJobModel {
  FavoriteJobModel({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool? success;
  final String? message;
  final List<FavoriteJobItemModel> data;

  factory FavoriteJobModel.fromJson(Map<String, dynamic> json) {
    return FavoriteJobModel(
      success: json["success"],
      message: json["message"],
      data: json["data"] == null
          ? []
          : List<FavoriteJobItemModel>.from(
              json["data"]!.map((x) => FavoriteJobItemModel.fromJson(x)),
            ),
    );
  }
}

class FavoriteJobItemModel {
  FavoriteJobItemModel({
    required this.id,
    required this.jobId,
    required this.authId,
    required this.job,
  });

  final String? id;
  final String? jobId;
  final String? authId;
  final Job? job;

  factory FavoriteJobItemModel.fromJson(Map<String, dynamic> json) {
    return FavoriteJobItemModel(
      id: json["id"],
      jobId: json["jobId"],
      authId: json["authId"],
      job: json["job"] == null ? null : Job.fromJson(json["job"]),
    );
  }
}

class Job {
  Job({
    required this.id,
    required this.authorId,
    required this.title,
    required this.description,
    required this.type,
    required this.experienceLevel,
    required this.compensationType,
    required this.salary,
    required this.location,
    required this.industry,
    required this.qualification,
    required this.requirements,
    required this.responsibilities,
    required this.applicationType,
    required this.applicationLink,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
  });

  final String? id;
  final String? authorId;
  final String? title;
  final String? description;
  final String? type;
  final String? experienceLevel;
  final String? compensationType;
  final int? salary;
  final String? location;
  final String? industry;
  final String? qualification;
  final List<String> requirements;
  final List<String> responsibilities;
  final String? applicationType;
  final dynamic applicationLink;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Author? author;

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json["id"],
      authorId: json["authorId"],
      title: json["title"],
      description: json["description"],
      type: json["type"],
      experienceLevel: json["experienceLevel"],
      compensationType: json["compensationType"],
      salary: json["salary"],
      location: json["location"],
      industry: json["industry"],
      qualification: json["qualification"],
      requirements: json["requirements"] == null
          ? []
          : List<String>.from(json["requirements"]!.map((x) => x)),
      responsibilities: json["responsibilities"] == null
          ? []
          : List<String>.from(json["responsibilities"]!.map((x) => x)),
      applicationType: json["applicationType"],
      applicationLink: json["applicationLink"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
      author: json["author"] == null ? null : Author.fromJson(json["author"]),
    );
  }
}

class Author {
  Author({required this.id, required this.business, this.person});

  final String? id;
  final Business? business;
  final Business? person; // reuse same shape — has name/image

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json["id"],
      business: json["business"] == null
          ? null
          : Business.fromJson(json["business"]),
      person: json["person"] == null
          ? null
          : Business.fromJson(json["person"]),
    );
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
