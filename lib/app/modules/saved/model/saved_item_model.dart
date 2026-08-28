/// A service post or forum post someone kept for later.
///
/// The two are different shapes — a service carries a price and delivery time,
/// a forum post carries the community it was posted in — so one model holds
/// both and [kind] says which fields mean anything.
class SavedItemModel {
  const SavedItemModel({
    required this.savedId,
    required this.kind,
    required this.id,
    required this.text,
    required this.images,
    required this.authorName,
    required this.authorImage,
    required this.authorTitle,
    required this.createdAt,
    this.price,
    this.currency,
    this.deliveryTime,
    this.groupId,
    this.groupName,
  });

  final String savedId;

  /// 'service' or 'forum'.
  final String kind;
  final String id;
  final String text;
  final List<String> images;
  final String authorName;
  final String? authorImage;
  final String? authorTitle;
  final DateTime? createdAt;

  /// Service posts only.
  final double? price;
  final String? currency;
  final String? deliveryTime;

  /// Forum posts only — which community it came from.
  final String? groupId;
  final String? groupName;

  bool get isService => kind == 'service';

  factory SavedItemModel.fromJson(Map<String, dynamic> json) {
    return SavedItemModel(
      savedId: json['savedId']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'service',
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      images: json['images'] == null
          ? const []
          : List<String>.from(
              (json['images'] as List).map((e) => e.toString()),
            ),
      authorName: json['author']?['name']?.toString() ?? 'Someone',
      authorImage: json['author']?['image']?.toString(),
      authorTitle: json['author']?['title']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency']?.toString(),
      deliveryTime: json['deliveryTime']?.toString(),
      groupId: json['groupId']?.toString(),
      groupName: json['groupName']?.toString(),
    );
  }
}
