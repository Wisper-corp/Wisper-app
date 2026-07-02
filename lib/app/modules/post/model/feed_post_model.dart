class FeedPostModel {
  FeedPostModel({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool? success;
  final String? message;
  final Data? data;

  factory FeedPostModel.fromJson(Map<String, dynamic> json) {
    return FeedPostModel(
      success: json["success"],
      message: json["message"],
      data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );
  }
}

class Data {
  Data({required this.meta, required this.posts});

  final Meta? meta;
  final List<FeedPostItemModel> posts;

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
      posts: json["posts"] == null
          ? []
          : List<FeedPostItemModel>.from(
              json["posts"]!.map((x) => FeedPostItemModel.fromJson(x)),
            ),
    );
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

class FeedPostItemModel {
  FeedPostItemModel({
    required this.id,
    required this.caption,
    required this.images,
    required this.views,
    required this.createdAt,
    required this.commentAccess,
    required this.author,
    this.price,
    this.deliveryTime,
  });

  final String? id;
  final String? caption;
  final List<String> images;
  final int? views;
  final DateTime? createdAt;
  final String? commentAccess;
  final Author? author;
  final double? price;
  final String? deliveryTime;

  factory FeedPostItemModel.fromJson(Map<String, dynamic> json) {
    return FeedPostItemModel(
      id: json["id"],
      caption: json["caption"],
      images: json["images"] == null
          ? []
          : List<String>.from(json["images"]!.map((x) => x)),
      views: json["views"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      commentAccess: json["commentAccess"],
      author: json["author"] == null ? null : Author.fromJson(json["author"]),
      price: json["price"] != null ? (json["price"] as num).toDouble() : null,
      deliveryTime: json["deliveryTime"],
    );
  }
}

class Author {
  Author({required this.id, required this.person, required this.business});

  final String? id;
  final Person? person;
  final Business? business;

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json["id"],
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
    required this.title,
    required this.image,
  });

  final String? id;
  final String? name;
  final String? title;
  final String? image;

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json["id"],
      name: json["name"],
      title: json["title"],
      image: json["image"],
    );
  }
}

class Business {
  Business({
    required this.id,
    required this.name,
    required this.industry,
    required this.image,
  });

  final String? id;
  final String? name;
  final String? industry;
  final String? image;

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json["id"],
      name: json["name"],
      industry: json["industry"],
      image: json["image"],
    );
  }
}
