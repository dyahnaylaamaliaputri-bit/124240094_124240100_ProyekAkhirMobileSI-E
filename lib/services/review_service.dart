// lib/services/review_service.dart
// Service manajemen rating dan review komunitas film (PB-082)

import 'package:hive/hive.dart';
import '../models/review_model.dart';

class ReviewService {
  static const String boxReviews = 'reviews_cache';
  static final Map<int, List<Map<String, dynamic>>> _memoryFallback = {};

  Box? _getBox() {
    try {
      if (Hive.isBoxOpen(boxReviews)) {
        return Hive.box(boxReviews);
      }
    } catch (_) {}
    return null;
  }

  /// Ambil daftar review untuk suatu film
  List<ReviewModel> getReviewsForMovie(int movieId) {
    final box = _getBox();
    if (box != null) {
      final raw = box.get(movieId.toString());
      if (raw is List) {
        return raw
            .map((e) =>
                ReviewModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    }

    final mem = _memoryFallback[movieId];
    if (mem != null && mem.isNotEmpty) {
      return mem.map((e) => ReviewModel.fromJson(e)).toList();
    }

    // Default seed review ramah penonton jika belum ada data
    return _generateDefaultReviews(movieId);
  }

  /// Tambah ulasan baru dari pengguna
  Future<ReviewModel> addReview({
    required int movieId,
    required String movieTitle,
    required String userId,
    required String userName,
    required double rating,
    required String reviewText,
    List<String> tags = const [],
  }) async {
    // Validasi rating
    final clampedRating = rating.clamp(1.0, 5.0);
    final reviewId = 'rev-${DateTime.now().millisecondsSinceEpoch}';

    final newReview = ReviewModel(
      id: reviewId,
      movieId: movieId,
      movieTitle: movieTitle,
      userId: userId,
      userName: userName,
      rating: clampedRating,
      reviewText: reviewText.trim(),
      createdAt: DateTime.now(),
      tags: tags,
      helpfulCount: 0,
      isVerifiedAudience: true,
    );

    final currentReviews = getReviewsForMovie(movieId);
    final updatedList = [newReview, ...currentReviews];

    final jsonList = updatedList.map((r) => r.toJson()).toList();
    final box = _getBox();
    if (box != null) {
      await box.put(movieId.toString(), jsonList);
    } else {
      _memoryFallback[movieId] = jsonList;
    }

    return newReview;
  }

  /// Hitung rata-rata rating film dari komunitas
  double getAverageRating(int movieId) {
    final reviews = getReviewsForMovie(movieId);
    if (reviews.isEmpty) return 0.0;
    final total = reviews.fold(0.0, (sum, r) => sum + r.rating);
    return double.parse((total / reviews.length).toStringAsFixed(1));
  }

  /// Upvote ulasan bermanfaat
  Future<ReviewModel?> markHelpful(int movieId, String reviewId) async {
    final reviews = getReviewsForMovie(movieId);
    final index = reviews.indexWhere((r) => r.id == reviewId);
    if (index == -1) return null;

    final target = reviews[index];
    final updated = target.copyWith(helpfulCount: target.helpfulCount + 1);
    reviews[index] = updated;

    final jsonList = reviews.map((r) => r.toJson()).toList();
    final box = _getBox();
    if (box != null) {
      await box.put(movieId.toString(), jsonList);
    } else {
      _memoryFallback[movieId] = jsonList;
    }
    return updated;
  }

  List<ReviewModel> _generateDefaultReviews(int movieId) {
    return [
      ReviewModel(
        id: 'seed-1-$movieId',
        movieId: movieId,
        movieTitle: 'Film Pilihan',
        userId: 'usr-seed-1',
        userName: 'Ahmad Cinema',
        rating: 5.0,
        reviewText:
            'Visual efeknya luar biasa! Suasana di studio IMAX bikin merinding.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        helpfulCount: 14,
        tags: ['Alur Bagus', 'Visual Memukau'],
      ),
      ReviewModel(
        id: 'seed-2-$movieId',
        movieId: movieId,
        movieTitle: 'Film Pilihan',
        userId: 'usr-seed-2',
        userName: 'Nadia Putri',
        rating: 4.5,
        reviewText:
            'Akting pemeran utamanya juara. Sangat rekomen ditonton bareng teman!',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        helpfulCount: 8,
        tags: ['Seru Bareng Teman'],
      ),
    ];
  }
}
