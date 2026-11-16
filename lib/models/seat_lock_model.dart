// lib/models/seat_lock_model.dart
// Model untuk temporary hold dan concurrency lock kursi bioskop (PB-028, PB-029)

class SeatLockModel {
  final String id;
  final String showtimeId;
  final String seatLabel;
  final String userId;
  final DateTime lockedUntil;
  final DateTime createdAt;

  SeatLockModel({
    required this.id,
    required this.showtimeId,
    required this.seatLabel,
    required this.userId,
    required this.lockedUntil,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Apakah kunci kursi sudah kedaluwarsa
  bool get isExpired => DateTime.now().isAfter(lockedUntil);

  /// Sisa durasi penguncian
  Duration get remainingDuration {
    final now = DateTime.now();
    if (now.isAfter(lockedUntil)) return Duration.zero;
    return lockedUntil.difference(now);
  }

  /// Sisa detik penguncian
  int get remainingSeconds => remainingDuration.inSeconds;

  SeatLockModel copyWith({
    String? id,
    String? showtimeId,
    String? seatLabel,
    String? userId,
    DateTime? lockedUntil,
    DateTime? createdAt,
  }) {
    return SeatLockModel(
      id: id ?? this.id,
      showtimeId: showtimeId ?? this.showtimeId,
      seatLabel: seatLabel ?? this.seatLabel,
      userId: userId ?? this.userId,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'showtime_id': showtimeId,
      'seat_label': seatLabel,
      'user_id': userId,
      'locked_until': lockedUntil.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SeatLockModel.fromJson(Map<String, dynamic> json) {
    return SeatLockModel(
      id: json['id']?.toString() ?? '',
      showtimeId: json['showtime_id']?.toString() ?? '',
      seatLabel: json['seat_label']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      lockedUntil: json['locked_until'] != null
          ? DateTime.tryParse(json['locked_until'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  String toString() =>
      'SeatLockModel(seat: $seatLabel, showtime: $showtimeId, user: $userId, remaining: ${remainingSeconds}s)';
}
