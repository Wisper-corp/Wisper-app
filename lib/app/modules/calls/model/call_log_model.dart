class CallLogsResponse {
  final bool? success;
  final String? message;
  final CallLogsData? data;

  CallLogsResponse({this.success, this.message, this.data});

  factory CallLogsResponse.fromJson(Map<String, dynamic> json) {
    return CallLogsResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] == null ? null : CallLogsData.fromJson(json['data']),
    );
  }
}

class CallLogsData {
  final List<CallLogItem> calls;
  final CallLogMeta? meta;

  CallLogsData({required this.calls, this.meta});

  factory CallLogsData.fromJson(Map<String, dynamic> json) {
    return CallLogsData(
      calls: (json['calls'] as List? ?? [])
          .map((c) => CallLogItem.fromJson(c))
          .toList(),
      meta: json['meta'] == null ? null : CallLogMeta.fromJson(json['meta']),
    );
  }
}

class CallLogMeta {
  final int? page;
  final int? limit;
  final int? total;

  CallLogMeta({this.page, this.limit, this.total});

  factory CallLogMeta.fromJson(Map<String, dynamic> json) {
    return CallLogMeta(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
    );
  }
}

class CallLogItem {
  final String? id;
  final String? type;   // VIDEO | AUDIO
  final String? mode;   // ONE_TO_ONE | GROUP
  final int? duration;  // seconds
  final String? date;
  final List<CallLogParticipant> participants;

  CallLogItem({
    this.id,
    this.type,
    this.mode,
    this.duration,
    this.date,
    required this.participants,
  });

  factory CallLogItem.fromJson(Map<String, dynamic> json) {
    return CallLogItem(
      id: json['id'],
      type: json['type'],
      mode: json['mode'],
      duration: json['duration'],
      date: json['date'],
      participants: (json['participants'] as List? ?? [])
          .map((p) => CallLogParticipant.fromJson(p))
          .toList(),
    );
  }

  /// The status of the current user in this call (INCOMING / OUTGOING / MISSED)
  String get myStatus {
    if (participants.isEmpty) return 'OUTGOING';
    return participants.first.status ?? 'OUTGOING';
  }

  /// Display name of the other party
  String get otherName {
    final other = participants.firstWhere(
      (p) => p.status != myStatus,
      orElse: () => participants.isNotEmpty
          ? participants.first
          : CallLogParticipant(status: null, name: 'Unknown', image: null),
    );
    return other.name ?? 'Unknown';
  }

  /// Profile image of the other party
  String? get otherImage {
    final other = participants.firstWhere(
      (p) => p.status != myStatus,
      orElse: () => participants.isNotEmpty
          ? participants.first
          : CallLogParticipant(status: null, name: 'Unknown', image: null),
    );
    return other.image;
  }

  /// Formatted duration string  e.g. "2:05"
  String get durationFormatted {
    if (duration == null || duration == 0) return '';
    final m = duration! ~/ 60;
    final s = duration! % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Formatted date/time  e.g. "10:30 AM"
  String get timeFormatted {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date!).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $ampm';
    } catch (_) {
      return '';
    }
  }
}

class CallLogParticipant {
  final String? status;  // MISSED | OUTGOING | INCOMING
  final String? name;
  final String? image;

  CallLogParticipant({this.status, this.name, this.image});

  factory CallLogParticipant.fromJson(Map<String, dynamic> json) {
    final auth = json['auth'] as Map<String, dynamic>?;
    final person = auth?['person'] as Map<String, dynamic>?;
    final business = auth?['business'] as Map<String, dynamic>?;
    return CallLogParticipant(
      status: json['status'],
      name: (person?['name'] ?? business?['name'] ?? '') as String,
      image: (person?['image'] ?? business?['image']) as String?,
    );
  }
}
