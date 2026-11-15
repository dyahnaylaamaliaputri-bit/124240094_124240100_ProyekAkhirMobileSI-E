// lib/models/advanced_recommendation_model.dart
// Model hasil rekomendasi Profiling Mood Lanjutan & LLM Engine (PB-036, PB-038)

class AdvancedRecommendationResult {
  final int movieId;
  final String title;
  final String overview;
  final String posterPath;
  final int matchScore; // 88 - 99%
  final String reasoning;
  final String companionFit;
  final int estimatedPrice;
  final int durationMinutes;
  final List<String> genres;

  const AdvancedRecommendationResult({
    required this.movieId,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.matchScore,
    required this.reasoning,
    required this.companionFit,
    required this.estimatedPrice,
    required this.durationMinutes,
    required this.genres,
  });

  Map<String, dynamic> toJson() => {
        'movie_id': movieId,
        'title': title,
        'overview': overview,
        'poster_path': posterPath,
        'match_score': matchScore,
        'reasoning': reasoning,
        'companion_fit': companionFit,
        'estimated_price': estimatedPrice,
        'duration_minutes': durationMinutes,
        'genres': genres,
      };

  factory AdvancedRecommendationResult.fromJson(Map<String, dynamic> json) {
    return AdvancedRecommendationResult(
      movieId: (json['movie_id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      overview: json['overview']?.toString() ?? '',
      posterPath: json['poster_path']?.toString() ?? '',
      matchScore: (json['match_score'] as num?)?.toInt() ?? 90,
      reasoning: json['reasoning']?.toString() ?? '',
      companionFit: json['companion_fit']?.toString() ?? 'Cocok untuk semua',
      estimatedPrice: (json['estimated_price'] as num?)?.toInt() ?? 50000,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 115,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Drama'],
    );
  }
}
