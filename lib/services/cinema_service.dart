// lib/services/cinema_service.dart
// Service untuk mengambil data bioskop dari Supabase & menghitung bioskop terdekat (PB-015, PB-043, PB-045)
// Mendukung offline caching dengan Hive, seed data multi-kota, dan filter radius.

import 'package:flutter/foundation.dart';
import '../models/cinema_model.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

class CinemaService {
  CinemaService._internal();
  static final CinemaService _instance = CinemaService._internal();
  factory CinemaService() => _instance;

  final SupabaseService _supabase = SupabaseService();
  final StorageService _storage = StorageService();

  /// Data fallback bioskop jika database Supabase offline tanpa cache
  static const List<Map<String, dynamic>> seedCinemas = [
    // ── JAKARTA ─────────────────────────────────────────────────────────────
    {
      'id': 'cin-jkt-1',
      'name': 'Cinemate Plaza',
      'address': 'Jl. Sudirman No. 1, Jakarta Pusat',
      'latitude': -6.2088,
      'longitude': 106.8456,
      'city': 'Jakarta',
      'facilities': ['ScreenX', 'SphereX', '4DX', 'Gold Class'],
    },
    {
      'id': 'cin-jkt-2',
      'name': 'Metro Cinema Senayan',
      'address': 'Jl. Asia Afrika No. 8, Jakarta Selatan',
      'latitude': -6.2176,
      'longitude': 106.8013,
      'city': 'Jakarta',
      'facilities': ['Dolby Atmos', 'Premiere', 'IMAX'],
    },
    {
      'id': 'cin-jkt-2b',
      'name': 'Plaza Senayan XXI',
      'address': 'Jl. Asia Afrika No. 8, Jakarta Pusat',
      'latitude': -6.2253,
      'longitude': 106.7998,
      'city': 'Jakarta',
      'facilities': ['Dolby Atmos', 'Premiere', 'IMAX'],
    },
    {
      'id': 'cin-jkt-3',
      'name': 'Kota Kasablanka XXI',
      'address': 'Jl. Casablanca Raya Kav. 88, Jakarta Selatan',
      'latitude': -6.2239,
      'longitude': 106.8431,
      'city': 'Jakarta',
      'facilities': ['Dolby Atmos', 'Premiere', 'Studio Regular'],
    },
    {
      'id': 'cin-jkt-4',
      'name': 'Gandaria City IMAX',
      'address': 'Jl. Sultan Iskandar Muda, Jakarta Selatan',
      'latitude': -6.2443,
      'longitude': 106.7838,
      'city': 'Jakarta',
      'facilities': ['IMAX Laser', 'Dolby Atmos', 'Premiere'],
    },
    {
      'id': 'cin-jkt-5',
      'name': 'Mall Kelapa Gading IMAX',
      'address': 'Jl. Boulevard Raya, Jakarta Utara',
      'latitude': -6.1578,
      'longitude': 106.9084,
      'city': 'Jakarta',
      'facilities': ['IMAX', 'Dolby Atmos', 'Premiere'],
    },
    {
      'id': 'cin-jkt-6',
      'name': 'Central Park CGV',
      'address': 'Jl. Letjen S. Parman No. 28, Jakarta Barat',
      'latitude': -6.1774,
      'longitude': 106.7907,
      'city': 'Jakarta',
      'facilities': ['4DX', 'Velvet Class', 'Regular 2D'],
    },

    // ── YOGYAKARTA ──────────────────────────────────────────────────────────
    {
      'id': 'cin-jog-1',
      'name': 'Plaza Ambarrukmo XXI',
      'address': 'Jl. Laksda Adisucipto No. 80, Caturtunggal, Sleman, Yogyakarta',
      'latitude': -7.7828,
      'longitude': 110.4011,
      'city': 'Yogyakarta',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-5'],
    },
    {
      'id': 'cin-jog-2',
      'name': 'CGV Pakuwon Mall Jogja',
      'address': 'Jl. Ring Road Utara, Condongcatur, Sleman, Yogyakarta',
      'latitude': -7.7594,
      'longitude': 110.3997,
      'city': 'Yogyakarta',
      'facilities': ['4DX', 'SphereX', 'Velvet Class', 'Regular 2D'],
    },
    {
      'id': 'cin-jog-3',
      'name': 'Empire XXI Jogja',
      'address': 'Jl. Urip Sumoharjo No. 104, Gondokusuman, Yogyakarta',
      'latitude': -7.7831,
      'longitude': 110.3835,
      'city': 'Yogyakarta',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-6'],
    },
    {
      'id': 'cin-jog-4',
      'name': 'Jogja City XXI',
      'address': 'Jl. Magelang KM 6 No. 18, Sinduadi, Mlati, Sleman, Yogyakarta',
      'latitude': -7.7533,
      'longitude': 110.3597,
      'city': 'Yogyakarta',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-6'],
    },
    {
      'id': 'cin-jog-5',
      'name': 'Cinepolis Lippo Plaza Jogja',
      'address': 'Jl. Laksda Adisucipto No. 32-34, Demangan, Gondokusuman, Yogyakarta',
      'latitude': -7.7836,
      'longitude': 110.3912,
      'city': 'Yogyakarta',
      'facilities': ['VIP', 'Macro XE', 'Regular 2D'],
    },
    {
      'id': 'cin-jog-6',
      'name': 'Sleman City Hall XXI',
      'address': 'Jl. Magelang KM 9.6, Tridadi, Sleman, Yogyakarta',
      'latitude': -7.7169,
      'longitude': 110.3619,
      'city': 'Yogyakarta',
      'facilities': ['Studio Regular', 'Dolby 7.1'],
    },

    // ── BANDUNG ─────────────────────────────────────────────────────────────
    {
      'id': 'cin-bdg-1',
      'name': 'Paris Van Java CGV',
      'address': 'Jl. Sukajadi No. 137-139, Cipedes, Sukajadi, Bandung',
      'latitude': -6.8893,
      'longitude': 107.5962,
      'city': 'Bandung',
      'facilities': ['4DX', 'Velvet Class', 'Dolby Atmos'],
    },
    {
      'id': 'cin-bdg-2',
      'name': '23 Paskal XXI & IMAX',
      'address': 'Jl. Pasirkaliki No. 25-27, Kebon Jeruk, Andir, Bandung',
      'latitude': -6.9152,
      'longitude': 107.5959,
      'city': 'Bandung',
      'facilities': ['IMAX', 'Premiere', 'Dolby Atmos'],
    },
    {
      'id': 'cin-bdg-3',
      'name': 'Cihampelas Walk XXI',
      'address': 'Jl. Cihampelas No. 160, Cipaganti, Coblong, Bandung',
      'latitude': -6.8938,
      'longitude': 107.6042,
      'city': 'Bandung',
      'facilities': ['Premiere', 'Studio 1-5', 'Dolby Atmos'],
    },
    {
      'id': 'cin-bdg-4',
      'name': 'Trans Studio Mall XXI',
      'address': 'Jl. Gatot Subroto No. 289, Cibangkong, Batununggal, Bandung',
      'latitude': -6.9261,
      'longitude': 107.6366,
      'city': 'Bandung',
      'facilities': ['Premiere', 'Studio 1-5', 'Dolby Atmos'],
    },

    // ── SURABAYA ────────────────────────────────────────────────────────────
    {
      'id': 'cin-sby-1',
      'name': 'Tunjungan Plaza XXI & IMAX',
      'address': 'Jl. Basuki Rahmat No. 8-12, Kedungdoro, Tegalsari, Surabaya',
      'latitude': -7.2618,
      'longitude': 112.7388,
      'city': 'Surabaya',
      'facilities': ['IMAX', 'Premiere', 'Dolby Atmos'],
    },
    {
      'id': 'cin-sby-2',
      'name': 'Pakuwon Mall IMAX & Premiere',
      'address': 'Jl. Mayjen Yono Suwoyo No. 2, Babatan, Wiyung, Surabaya',
      'latitude': -7.2891,
      'longitude': 112.6756,
      'city': 'Surabaya',
      'facilities': ['IMAX Laser', 'Premiere', 'Studio 1-6'],
    },
    {
      'id': 'cin-sby-3',
      'name': 'Galaxy Mall XXI',
      'address': 'Jl. Dharmahusada Indah Timur No. 35-37, Mulyorejo, Surabaya',
      'latitude': -7.2715,
      'longitude': 112.7801,
      'city': 'Surabaya',
      'facilities': ['Premiere', 'Studio 1-5', 'Dolby Atmos'],
    },
    {
      'id': 'cin-sby-4',
      'name': 'Ciputra World XXI',
      'address': 'Jl. Mayjen Sungkono No. 89, Gunung Sari, Dukuhpakis, Surabaya',
      'latitude': -7.2917,
      'longitude': 112.7188,
      'city': 'Surabaya',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-6'],
    },

    // ── SEMARANG ────────────────────────────────────────────────────────────
    {
      'id': 'cin-smg-1',
      'name': 'Paragon Mall XXI Semarang',
      'address': 'Jl. Pemuda No. 118, Sekayu, Semarang Tengah',
      'latitude': -6.9822,
      'longitude': 110.4172,
      'city': 'Semarang',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-5'],
    },
    {
      'id': 'cin-smg-2',
      'name': 'Queen City Mall XXI',
      'address': 'Jl. Pemuda No. 35, Pandansari, Semarang Tengah',
      'latitude': -6.9744,
      'longitude': 110.4239,
      'city': 'Semarang',
      'facilities': ['Dolby Atmos', 'Studio 1-5'],
    },

    // ── SURAKARTA / SOLO ────────────────────────────────────────────────────
    {
      'id': 'cin-slo-1',
      'name': 'The Park XXI Solo Baru',
      'address': 'Jl. Ir. Soekarno, Madegondo, Grogol, Sukoharjo, Solo',
      'latitude': -7.5996,
      'longitude': 110.8192,
      'city': 'Solo',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-5'],
    },
    {
      'id': 'cin-slo-2',
      'name': 'Solo Paragon XXI',
      'address': 'Jl. Yosodipuro No. 133, Mangkubumen, Banjarsari, Solo',
      'latitude': -7.5612,
      'longitude': 110.8118,
      'city': 'Solo',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-5'],
    },

    // ── BALI ────────────────────────────────────────────────────────────────
    {
      'id': 'cin-dps-1',
      'name': 'Beachwalk XXI Premiere',
      'address': 'Jl. Pantai Kuta, Badung, Bali',
      'latitude': -8.7181,
      'longitude': 115.1689,
      'city': 'Bali',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-3'],
    },
    {
      'id': 'cin-dps-2',
      'name': 'Living World Denpasar Cinepolis',
      'address': 'Jl. Gatot Subroto Timur, Tonja, Denpasar Utara, Bali',
      'latitude': -8.6358,
      'longitude': 115.2346,
      'city': 'Bali',
      'facilities': ['VIP', 'Macro XE', 'Regular 2D'],
    },

    // ── MEDAN ───────────────────────────────────────────────────────────────
    {
      'id': 'cin-mdn-1',
      'name': 'Centre Point XXI Medan',
      'address': 'Jl. Timor Blok H No. 1, Gang Buntu, Medan Timur',
      'latitude': 3.5925,
      'longitude': 98.6811,
      'city': 'Medan',
      'facilities': ['IMAX', 'Premiere', 'Dolby Atmos'],
    },
    {
      'id': 'cin-mdn-2',
      'name': 'Sun Plaza XXI Medan',
      'address': 'Jl. KH. Zainul Arifin No. 7, Madras Hulu, Medan Polonia',
      'latitude': 3.5831,
      'longitude': 98.6705,
      'city': 'Medan',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-6'],
    },
  ];

  /// Mengambil semua bioskop dari Supabase / Hive Cache / Fallback Seed
  Future<({List<CinemaModel> cinemas, bool fromCache})> getAllCinemas({
    bool forceRefresh = false,
  }) async {
    // 1. Cek cache Hive jika tidak forceRefresh
    if (!forceRefresh) {
      try {
        final cached = await _storage.getCachedCinemas();
        if (cached != null && cached.isNotEmpty) {
          final list = cached.map((e) => CinemaModel.fromJson(e)).toList();
          return (cinemas: list, fromCache: true);
        }
      } catch (e) {
        debugPrint('[CinemaService] Error reading Hive cache: $e');
      }
    }

    // 2. Fetch online dari Supabase database
    try {
      final response =
          await _supabase.client.from('cinemas').select().order('name');

      if (response.isNotEmpty) {
        final jsonList =
            response.map((e) => Map<String, dynamic>.from(e)).toList();

        // Simpan ke Hive cache
        await _storage.cacheCinemas(jsonList);

        final list = jsonList.map((e) => CinemaModel.fromJson(e)).toList();
        return (cinemas: list, fromCache: false);
      }
    } catch (e) {
      debugPrint('[CinemaService] Supabase fetch error: $e');
    }

    // 3. Fallback jika offline: periksa apakah ada cache lama
    try {
      final cached = await _storage.getCachedCinemas();
      if (cached != null && cached.isNotEmpty) {
        final list = cached.map((e) => CinemaModel.fromJson(e)).toList();
        return (cinemas: list, fromCache: true);
      }
    } catch (e) {
      debugPrint('[CinemaService] Error reading Hive fallback cache: $e');
    }

    // 4. Fallback terakhir: seed data lokal lengkap multi-kota
    final fallbackList =
        seedCinemas.map((e) => CinemaModel.fromJson(e)).toList();
    return (cinemas: fallbackList, fromCache: true);
  }

  /// Menghitung jarak bioskop dan mengembalikan N bioskop terdekat (default: 3)
  List<CinemaModel> getNearestCinemas(
    List<CinemaModel> cinemas, {
    required double userLat,
    required double userLng,
    int limit = 3,
  }) {
    final sorted = getCinemasSortedByDistance(
      cinemas,
      userLat: userLat,
      userLng: userLng,
    );
    return sorted.take(limit).toList();
  }

  /// Menghitung jarak seluruh bioskop ke koordinat pengguna dengan formula Haversine,
  /// mengurutkannya secara ascending (km), dan memfilter berdasarkan radius (PB-043, PB-045).
  List<CinemaModel> getCinemasSortedByDistance(
    List<CinemaModel> cinemas, {
    required double userLat,
    required double userLng,
    double? maxRadiusKm,
  }) {
    if (cinemas.isEmpty) return [];

    // Hitung jarak ke user untuk masing-masing bioskop
    final listWithDistance = cinemas.map((cinema) {
      final distance = cinema.calculateDistanceFrom(userLat, userLng);
      return cinema.copyWith(distanceKm: distance);
    }).toList();

    // Filter radius jika diset
    final filtered = maxRadiusKm != null
        ? listWithDistance
            .where((c) => (c.distanceKm ?? double.infinity) <= maxRadiusKm)
            .toList()
        : listWithDistance;

    // Urutkan ascending berdasarkan jarak terkecil
    filtered.sort((a, b) {
      final distA = a.distanceKm ?? double.infinity;
      final distB = b.distanceKm ?? double.infinity;
      return distA.compareTo(distB);
    });

    return filtered;
  }
}
