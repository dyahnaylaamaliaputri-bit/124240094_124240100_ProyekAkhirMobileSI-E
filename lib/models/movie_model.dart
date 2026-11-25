// lib/models/movie_model.dart
// Model data film dari TMDB API (PB-012)
// Referensi: SRS §3.1, PB-012

class MovieModel {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final int voteCount;
  final List<int> genreIds;
  final double popularity;

  const MovieModel({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    required this.voteAverage,
    required this.voteCount,
    required this.genreIds,
    required this.popularity,
  });

  /// URL lengkap untuk poster film TMDB
  String get posterUrl {
    if (posterPath == null || posterPath!.isEmpty) {
      return '';
    }
    if (posterPath!.startsWith('http')) return posterPath!;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  /// URL lengkap untuk backdrop / banner film TMDB
  String get backdropUrl {
    if (backdropPath == null || backdropPath!.isEmpty) {
      return posterUrl;
    }
    if (backdropPath!.startsWith('http')) return backdropPath!;
    return 'https://image.tmdb.org/t/p/w780$backdropPath';
  }

  /// Rating yang diformat 1 angka di belakang koma (misal: "8.5")
  String get formattedRating => voteAverage.toStringAsFixed(1);

  /// Tahun rilis (misal: "2024")
  String get releaseYear {
    if (releaseDate == null || releaseDate!.isEmpty) return '-';
    final parts = releaseDate!.split('-');
    return parts.isNotEmpty ? parts[0] : '-';
  }

  /// Durasi film (estimasi realistis bioskop: jam dan menit)
  String get formattedDuration {
    final mins = 100 + (id % 45); // antara 100 - 145 menit
    final hours = mins ~/ 60;
    final remainingMinutes = mins % 60;
    return '${hours}j ${remainingMinutes}m';
  }

  /// Nama genre berdasarkan TMDB Genre ID
  List<String> get genreNames {
    return genreIds
        .map((id) => _tmdbGenres[id])
        .whereType<String>()
        .take(3)
        .toList();
  }

  /// String genre gabungan (misal: "Action • Sci-Fi")
  String get genreString {
    final names = genreNames;
    return names.isNotEmpty ? names.join(' • ') : 'Bioskop';
  }

  /// Batasan usia penonton bioskop
  String get ageRating {
    if (genreIds.contains(27)) return '17+ (Dewasa)';
    if (genreIds.contains(10751) || genreIds.contains(16)) return 'SU (Semua Umur)';
    return '13+ (Remaja)';
  }

  /// Sutradara film
  String get director {
    switch (id) {
      case 693134:
        return 'Denis Villeneuve';
      case 533535:
        return 'Shawn Levy';
      case 1022789:
        return 'Kelsey Mann';
      case 519182:
        return 'Chris Renaud';
      case 573435:
        return 'Adil & Bilall';
      case 558449:
        return 'Ridley Scott';
      case 402431:
        return 'Jon M. Chu';
      case 1241982:
        return 'David G. Derrick Jr.';
      case 933260:
        return 'Coralie Fargeat';
      default:
        return 'Cinemate International Studio';
    }
  }

  /// Daftar aktor / pemain utama film
  List<String> get cast {
    switch (id) {
      case 693134:
        return ['Timothée Chalamet', 'Zendaya', 'Rebecca Ferguson', 'Javier Bardem'];
      case 533535:
        return ['Ryan Reynolds', 'Hugh Jackman', 'Emma Corrin', 'Matthew Macfadyen'];
      case 1022789:
        return ['Amy Poehler', 'Maya Hawke', 'Kensington Tallman', 'Liza Lapira'];
      case 519182:
        return ['Steve Carell', 'Kristen Wiig', 'Will Ferrell', 'Sofia Vergara'];
      case 573435:
        return ['Will Smith', 'Martin Lawrence', 'Vanessa Hudgens', 'Alexander Ludwig'];
      case 558449:
        return ['Paul Mescal', 'Pedro Pascal', 'Denzel Washington', 'Connie Nielsen'];
      case 402431:
        return ['Cynthia Erivo', 'Ariana Grande', 'Jonathan Bailey', 'Jeff Goldblum'];
      case 1241982:
        return ["Auli'i Cravalho", 'Dwayne Johnson', 'Alan Tudyk', 'Rachel House'];
      case 933260:
        return ['Demi Moore', 'Margaret Qualley', 'Dennis Quaid', 'Hugo Diego Garcia'];
      default:
        return ['Pemeran Utama', 'Aktor Pendukung', 'Bintang Tamu'];
    }
  }

  /// Format studio bioskop yang tersedia
  List<String> get availableFormats => const ['2D', '3D', 'IMAX', 'Premiere'];

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? json['name'] as String? ?? 'Untitled',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate:
          json['release_date'] as String? ?? json['first_air_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'release_date': releaseDate,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'genre_ids': genreIds,
      'popularity': popularity,
    };
  }

  static const Map<int, String> _tmdbGenres = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Sci-Fi',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
  };
}
