// lib/models/review_model.dart
// Model untuk rating & review pengguna (PB-082)

class ReviewModel {
  final String id;
  final int movieId;
  final String movieTitle;
  final String userId;
  final String userName;
  final String? userAvatar;
  final double rating; // 1.0 s.d. 5.0
  final String reviewText;
  final DateTime createdAt;
  final int helpfulCount;
  final List<String> tags;
  final bool isVerifiedAudience;

  const ReviewModel({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
    this.helpfulCount = 0,
    this.tags = const [],
    this.isVerifiedAudience = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'movieId': movieId,
        'movieTitle': movieTitle,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'rating': rating,
        'reviewText': reviewText,
        'createdAt': createdAt.toIso8601String(),
        'helpfulCount': helpfulCount,
        'tags': tags,
        'isVerifiedAudience': isVerifiedAudience,
      };

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as String,
        movieId: json['movieId'] as int,
        movieTitle: json['movieTitle'] as String? ?? '',
        userId: json['userId'] as String? ?? 'anon',
        userName: json['userName'] as String? ?? 'Penonton Cinemate',
        userAvatar: json['userAvatar'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        reviewText: json['reviewText'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        helpfulCount: json['helpfulCount'] as int? ?? 0,
        tags: (json['tags'] as List? ?? []).map((e) => e.toString()).toList(),
        isVerifiedAudience: json['isVerifiedAudience'] as bool? ?? true,
      );

  ReviewModel copyWith({
    int? helpfulCount,
    double? rating,
    String? reviewText,
  }) =>
      ReviewModel(
        id: id,
        movieId: movieId,
        movieTitle: movieTitle,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        rating: rating ?? this.rating,
        reviewText: reviewText ?? this.reviewText,
        createdAt: createdAt,
        helpfulCount: helpfulCount ?? this.helpfulCount,
        tags: tags,
        isVerifiedAudience: isVerifiedAudience,
      );
}
