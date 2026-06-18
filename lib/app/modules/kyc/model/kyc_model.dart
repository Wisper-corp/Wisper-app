class KycModel {
  KycModel({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool? success;
  final String? message;
  final KycData? data;

  factory KycModel.fromJson(Map<String, dynamic> json) {
    return KycModel(
      success: json["success"],
      message: json["message"],
      data: json["data"] == null ? null : KycData.fromJson(json["data"]),
    );
  }
}

class KycData {
  KycData({
    required this.id,
    required this.status,
    required this.smileJobId,
    required this.resultCode,
    required this.resultText,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.idNumber,
    required this.idType,
    required this.country,
    required this.verifiedAt,
  });

  final String? id;
  final String? status;       // PENDING | APPROVED | FAILED
  final String? smileJobId;
  final String? resultCode;
  final String? resultText;
  final String? fullName;
  final String? dateOfBirth;
  final String? gender;
  final String? idNumber;
  final String? idType;
  final String? country;
  final DateTime? verifiedAt;

  factory KycData.fromJson(Map<String, dynamic> json) {
    return KycData(
      id: json["id"],
      status: json["status"],
      smileJobId: json["smileJobId"],
      resultCode: json["resultCode"],
      resultText: json["resultText"],
      fullName: json["fullName"],
      dateOfBirth: json["dateOfBirth"],
      gender: json["gender"],
      idNumber: json["idNumber"],
      idType: json["idType"],
      country: json["country"],
      verifiedAt: DateTime.tryParse(json["verifiedAt"] ?? ""),
    );
  }

  bool get isVerified => status == "APPROVED";
  bool get isPending => status == "PENDING";
  bool get isFailed => status == "FAILED";
}
