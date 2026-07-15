class AllTransectionModel {
  AllTransectionModel({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool? success;
  final String? message;
  final TransactionData? data;

  factory AllTransectionModel.fromJson(Map<String, dynamic> json) {
    return AllTransectionModel(
      success: json["success"],
      message: json["message"],
      data: json["data"] == null ? null : TransactionData.fromJson(json["data"]),
    );
  }
}

class TransactionData {
  TransactionData({required this.meta, required this.payments});

  final Meta? meta;
  final List<TransectionItemModel> payments;

  factory TransactionData.fromJson(Map<String, dynamic> json) {
    // Handle both /payments and /wallet/transactions responses
    final List<dynamic> items = json["transactions"] ?? json["payments"] ?? [];
    return TransactionData(
      meta: json["pagination"] != null
          ? Meta.fromJson(json["pagination"])
          : json["meta"] != null
              ? Meta.fromJson(json["meta"])
              : null,
      payments: List<TransectionItemModel>.from(
        items.map((x) => TransectionItemModel.fromJson(x)),
      ),
    );
  }
}

// Keep old name for backward compat
typedef Data = TransactionData;

class Meta {
  Meta({required this.page, required this.limit, required this.total});

  final int? page;
  final int? limit;
  final int? total;

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      page: json["page"],
      limit: json["limit"] ?? json["pageSize"],
      total: json["total"],
    );
  }
}

class TransectionItemModel {
  TransectionItemModel({
    required this.id,
    required this.amount,
    required this.date,
    this.type,
    this.transactionId,
    this.auth,
  });

  final String? id;
  final double? amount;
  final DateTime? date;
  final String? type;         // DEPOSIT | WITHDRAW | SPEND
  final String? transactionId;
  final Auth? auth;

  factory TransectionItemModel.fromJson(Map<String, dynamic> json) {
    return TransectionItemModel(
      id: json["id"],
      amount: json["amount"] != null
          ? (json["amount"] as num).toDouble()
          : null,
      date: DateTime.tryParse(json["date"] ?? ""),
      type: json["type"],
      transactionId: json["transactionId"],
      auth: json["auth"] == null ? null : Auth.fromJson(json["auth"]),
    );
  }

  /// Human-readable label for the transaction type
  String get typeLabel {
    switch (type) {
      case 'DEPOSIT':
        return 'Wallet Funded';
      case 'WITHDRAW':
        return 'Withdrawal';
      case 'SPEND':
        return 'Payment';
      default:
        return 'Transaction';
    }
  }

  /// Icon for type
  bool get isCredit => type == 'DEPOSIT';
  bool get isDebit => type == 'WITHDRAW' || type == 'SPEND';
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
