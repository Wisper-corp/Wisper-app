class OfferModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderImage;
  final String receiverId;
  final String receiverName;
  final String? receiverImage;
  final String chatId;
  final double amount;
  final String description;
  final OfferStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  OfferModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderImage,
    required this.receiverId,
    required this.receiverName,
    this.receiverImage,
    required this.chatId,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'],
      senderId: json['senderId'],
      senderName: json['sender']['person'] != null
          ? json['sender']['person']['name']
          : json['sender']['business']['name'],
      senderImage: json['sender']['person'] != null
          ? json['sender']['person']['image']
          : json['sender']['business']['image'],
      receiverId: json['receiverId'],
      receiverName: json['receiver']['person'] != null
          ? json['receiver']['person']['name']
          : json['receiver']['business']['name'],
      receiverImage: json['receiver']['person'] != null
          ? json['receiver']['person']['image']
          : json['receiver']['business']['image'],
      chatId: json['chatId'],
      amount: json['amount'].toDouble(),
      description: json['description'],
      status: OfferStatus.values.firstWhere(
        (e) => e.toString() == 'OfferStatus.${json['status']}',
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'chatId': chatId,
      'amount': amount,
      'description': description,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

enum OfferStatus {
  PENDING,
  ACCEPTED,
  DECLINED,
  PAID,
}
