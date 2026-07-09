// Full KYC status returned by GET /kyc/status

class KycStatusModel {
  final KycFieldDetail email;
  final KycFieldDetail phone;
  final KycNinDetail nin;
  final KycAddressDetail address;
  final KycBadgeDetail badge;
  final int recommendationCount;
  final bool isEligibleForBadge;

  KycStatusModel({
    required this.email,
    required this.phone,
    required this.nin,
    required this.address,
    required this.badge,
    required this.recommendationCount,
    required this.isEligibleForBadge,
  });

  factory KycStatusModel.fromJson(Map<String, dynamic> j) {
    return KycStatusModel(
      email: KycFieldDetail.fromJson(j['email'] ?? {}),
      phone: KycFieldDetail.fromJson(j['phone'] ?? {}),
      nin: KycNinDetail.fromJson(j['nin'] ?? {}),
      address: KycAddressDetail.fromJson(j['address'] ?? {}),
      badge: KycBadgeDetail.fromJson(j['badge'] ?? {}),
      recommendationCount: j['recommendationCount'] ?? 0,
      isEligibleForBadge: j['isEligibleForBadge'] ?? false,
    );
  }
}

class KycFieldDetail {
  final String status; // UNVERIFIED | VERIFIED | REJECTED | PENDING_REVIEW
  final String? verifiedValue; // verifiedEmail or verifiedPhone

  KycFieldDetail({required this.status, this.verifiedValue});

  factory KycFieldDetail.fromJson(Map<String, dynamic> j) {
    return KycFieldDetail(
      status: j['status'] ?? 'UNVERIFIED',
      verifiedValue: j['verifiedEmail'] ?? j['verifiedPhone'],
    );
  }

  bool get isVerified => status == 'VERIFIED';
}

class KycNinDetail {
  final String status;
  final int attemptsUsed;
  final int maxAttempts;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;

  KycNinDetail({
    required this.status,
    required this.attemptsUsed,
    required this.maxAttempts,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
  });

  factory KycNinDetail.fromJson(Map<String, dynamic> j) {
    return KycNinDetail(
      status: j['status'] ?? 'UNVERIFIED',
      attemptsUsed: j['attemptsUsed'] ?? 0,
      maxAttempts: j['maxAttempts'] ?? 3,
      firstName: j['firstName'],
      lastName: j['lastName'],
      dateOfBirth: j['dateOfBirth'],
    );
  }

  bool get isVerified => status == 'VERIFIED';
  bool get isLocked => attemptsUsed >= maxAttempts && !isVerified;
}

class KycAddressDetail {
  final String status;
  final String? addressText;
  final String? docType;

  KycAddressDetail({
    required this.status,
    this.addressText,
    this.docType,
  });

  factory KycAddressDetail.fromJson(Map<String, dynamic> j) {
    return KycAddressDetail(
      status: j['status'] ?? 'UNVERIFIED',
      addressText: j['addressText'],
      docType: j['docType'],
    );
  }

  bool get isVerified => status == 'VERIFIED';
  bool get isPendingReview => status == 'PENDING_REVIEW';
}

class KycBadgeDetail {
  final bool isActive;
  final bool isAdminGranted;
  final DateTime? nextBillingDate;
  final DateTime? gracePeriodEnd;
  final bool isFeeExempt;
  final DateTime? feeExemptUntil;

  KycBadgeDetail({
    required this.isActive,
    required this.isAdminGranted,
    this.nextBillingDate,
    this.gracePeriodEnd,
    required this.isFeeExempt,
    this.feeExemptUntil,
  });

  factory KycBadgeDetail.fromJson(Map<String, dynamic> j) {
    return KycBadgeDetail(
      isActive: j['isActive'] ?? false,
      isAdminGranted: j['isAdminGranted'] ?? false,
      nextBillingDate: j['nextBillingDate'] != null
          ? DateTime.tryParse(j['nextBillingDate'])
          : null,
      gracePeriodEnd: j['gracePeriodEnd'] != null
          ? DateTime.tryParse(j['gracePeriodEnd'])
          : null,
      isFeeExempt: j['isFeeExempt'] ?? false,
      feeExemptUntil: j['feeExemptUntil'] != null
          ? DateTime.tryParse(j['feeExemptUntil'])
          : null,
    );
  }
}
