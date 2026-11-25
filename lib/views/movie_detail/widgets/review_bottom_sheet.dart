// lib/views/movie_detail/widgets/review_bottom_sheet.dart
// Modal bottom sheet untuk input ulasan & rating bintang (PB-082)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/review_model.dart';
import '../../../services/review_service.dart';
import '../../../utils/app_colors.dart';

class ReviewBottomSheet extends StatefulWidget {
  final int movieId;
  final String movieTitle;
  final Function(ReviewModel)? onReviewSubmitted;

  const ReviewBottomSheet({
    super.key,
    required this.movieId,
    required this.movieTitle,
    this.onReviewSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required int movieId,
    required String movieTitle,
    Function(ReviewModel)? onReviewSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReviewBottomSheet(
        movieId: movieId,
        movieTitle: movieTitle,
        onReviewSubmitted: onReviewSubmitted,
      ),
    );
  }

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  final _reviewController = TextEditingController();
  final _service = ReviewService();
  double _selectedRating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _reviewController.text.trim();
    if (text.isEmpty) {
      Get.snackbar('Perhatian', 'Mohon tuliskan ulasan singkat Anda');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final review = await _service.addReview(
        movieId: widget.movieId,
        movieTitle: widget.movieTitle,
        userId: 'usr-current',
        userName: 'Penonton Cinemate',
        rating: _selectedRating,
        reviewText: text,
      );

      widget.onReviewSubmitted?.call(review);
      if (mounted) {
        Navigator.pop(context);
        Get.snackbar(
          'Ulasan Terkirim',
          'Terima kasih telah berbagi ulasan untuk ${widget.movieTitle}',
          backgroundColor: AppColors.card,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tulis Ulasan Film',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            widget.movieTitle,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Rating Bintang
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1.0;
              return IconButton(
                icon: Icon(
                  starValue <= _selectedRating ? Icons.star : Icons.star_border,
                  color: AppColors.gold,
                  size: 36,
                ),
                onPressed: () {
                  setState(() => _selectedRating = starValue);
                },
              );
            }),
          ),
          Center(
            child: Text(
              '${_selectedRating.toInt()} dari 5 Bintang',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),

          const SizedBox(height: 16),

          // Field Ulasan
          TextField(
            controller: _reviewController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText:
                  'Bagikan pendapatmu tentang alur cerita, akting, atau visualnya...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tombol Kirim
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Kirim Ulasan',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
