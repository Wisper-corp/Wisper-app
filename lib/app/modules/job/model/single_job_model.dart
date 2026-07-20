class SingleJobModel {
  SingleJobModel({ 
    required this.success,
    required this.message,
    required this.data,
  });

  final bool? success;
  final String? message;
  final JobData? data;

  factory SingleJobModel.fromJson(Map<String, dynamic> json) {
    return SingleJobModel(
      success: json["success"],
      message: json["message"],
      data: json["data"] == null ? null : JobData.fromJson(json["data"]),
    );
  }
}

class JobData {
  JobData({
    required this.id,
    required this.authorId,
    required this.title,
    required this.description,
    required this.type,
    required this.experienceLevel,
    required this.compensationType,
    required this.salary,
    required this.locationType,
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
    required this.isFavorite,
    this.companyName,
    this.companyLogo,
    this.isScraped,
  });

  final String? id;
  final String? authorId;
  final String? title;
  final String? description;
  final String? type;
  final String? experienceLevel;
  final String? compensationType;
  final int? salary;
  final String? locationType;
  final dynamic location;
  final String? industry;
  final String? qualification;
  final List<String> requirements;
  final List<String> responsibilities;
  final String? applicationType;
  final dynamic applicationLink;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Author? author;
  final bool? isFavorite;
  final String? companyName;
  final String? companyLogo;
  final bool? isScraped;

  factory JobData.fromJson(Map<String, dynamic> json) {
    return JobData(
      id: json["id"],
      authorId: json["authorId"],
      title: json["title"],
      description: json["description"],
      type: json["type"],
      experienceLevel: json["experienceLevel"],
      compensationType: json["compensationType"],
      salary: json["salary"],
      locationType: json["locationType"],
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
      isFavorite: json["isFavorite"],
      companyName: json["companyName"],
      companyLogo: json["companyLogo"],
      isScraped: json["isScraped"] as bool?,
    );
  }
}

class Author {
  Author({required this.id, required this.business});

  final String? id;
  final Business? business;

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json["id"],
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
    required this.industry,
    required this.address,
    required this.image,
  });

  final String? id;
  final String? name;
  final String? industry;
  final dynamic address;
  final String? image;

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json["id"],
      name: json["name"],
      industry: json["industry"],
      address: json["address"],
      image: json["image"],
    );
  }
}
