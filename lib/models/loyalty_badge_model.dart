// lib/models/loyalty_badge_model.dart
// Model untuk Gamifikasi Badge Loyalitas Penonton Cinemate (PB-064)

class LoyaltyBadgeModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final double progress; // 0.0 sampai 1.0
  final String progressLabel; // Misal: "1/1 Tiket", "3/6 Tiket"

  const LoyaltyBadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.progress = 1.0,
    this.progressLabel = 'Tercapai',
  });

  LoyaltyBadgeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    bool? isUnlocked,
    double? progress,
    String? progressLabel,
  }) {
    return LoyaltyBadgeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      progressLabel: progressLabel ?? this.progressLabel,
    );
  }
}
