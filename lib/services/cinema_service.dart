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

    // ── BOGOR & BEKASI ──────────────────────────────────────────────────────
    {
      'id': 'cin-bgr-1',
      'name': 'Botani Square XXI Bogor',
      'address': 'Jl. Raya Pajajaran No. 40, Tegallega, Bogor Tengah',
      'latitude': -6.6015,
      'longitude': 106.8065,
      'city': 'Bogor',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-6'],
    },
    {
      'id': 'cin-bgr-2',
      'name': 'AEON Mall Sentul City XXI',
      'address': 'Jl. MH. Thamrin, Citaringgul, Babakan Madang, Bogor',
      'latitude': -6.5656,
      'longitude': 106.8548,
      'city': 'Bogor',
      'facilities': ['IMAX', 'Premiere', 'Dolby Atmos'],
    },
    {
      'id': 'cin-bks-1',
      'name': 'Summarecon Mall Bekasi XXI',
      'address': 'Jl. Boulevard Ahmad Yani, Marga Mulya, Bekasi Utara',
      'latitude': -6.2261,
      'longitude': 107.0011,
      'city': 'Bekasi',
      'facilities': ['IMAX', 'Premiere', 'Dolby Atmos'],
    },
    {
      'id': 'cin-bks-2',
      'name': 'Grand Metropolitan XXI Bekasi',
      'address': 'Jl. KH. Noer Ali, Pekayon Jaya, Bekasi Selatan',
      'latitude': -6.2485,
      'longitude': 106.9923,
      'city': 'Bekasi',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-5'],
    },

    // ── MALANG, CIREBON, PURWOKERTO ─────────────────────────────────────────
    {
      'id': 'cin-mlg-1',
      'name': 'Araya XXI Malang',
      'address': 'Jl. Blimbing Indah Megah No. 2, Purwodadi, Malang',
      'latitude': -7.9392,
      'longitude': 112.6484,
      'city': 'Malang',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-5'],
    },
    {
      'id': 'cin-mlg-2',
      'name': 'CGV Malang City Point',
      'address': 'Jl. Terusan Dieng No. 32, Pisang Candi, Malang',
      'latitude': -7.9771,
      'longitude': 112.6152,
      'city': 'Malang',
      'facilities': ['SphereX', 'Gold Class', 'Regular 2D'],
    },
    {
      'id': 'cin-crb-1',
      'name': 'CSB XXI Cirebon',
      'address': 'Jl. Dr. Cipto Mangunkusumo No. 26, Pekiringan, Cirebon',
      'latitude': -6.7186,
      'longitude': 108.5503,
      'city': 'Cirebon',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-6'],
    },
    {
      'id': 'cin-pwt-1',
      'name': 'CGV Rita Supermall Purwokerto',
      'address': 'Jl. Jend. Sudirman No. 296, Sokanegara, Purwokerto',
      'latitude': -7.4243,
      'longitude': 109.2302,
      'city': 'Purwokerto',
      'facilities': ['Satin Class', 'Dolby Atmos', 'Regular 2D'],
    },

    // ── SUMATERA (PALEMBANG, PADANG, PEKANBARU, BATAM, LAMPUNG) ─────────────
    {
      'id': 'cin-plg-1',
      'name': 'Palembang Icon Cinepolis',
      'address': 'Jl. POM IX, Lorok Pakjo, Ilir Barat I, Palembang',
      'latitude': -2.9761,
      'longitude': 104.7458,
      'city': 'Palembang',
      'facilities': ['VIP', 'Macro XE', 'Dolby Atmos'],
    },
    {
      'id': 'cin-plg-2',
      'name': 'PIM XXI Palembang',
      'address': 'Jl. Letkol Iskandar No. 18, Bukit Kecil, Palembang',
      'latitude': -2.9813,
      'longitude': 104.7565,
      'city': 'Palembang',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-6'],
    },
    {
      'id': 'cin-pdg-1',
      'name': 'Plaza Andalas XXI Padang',
      'address': 'Jl. Pemuda No. 1, Olo, Padang Barat, Padang',
      'latitude': -0.9537,
      'longitude': 100.3547,
      'city': 'Padang',
      'facilities': ['Dolby Atmos', 'Studio 1-5'],
    },
    {
      'id': 'cin-pku-1',
      'name': 'SKA XXI Pekanbaru',
      'address': 'Jl. Soekarno-Hatta, Delima, Tampan, Pekanbaru',
      'latitude': 0.5004,
      'longitude': 101.4197,
      'city': 'Pekanbaru',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-6'],
    },
    {
      'id': 'cin-btm-1',
      'name': 'Grand Batam XXI',
      'address': 'Jl. Pembangunan, Batu Selicin, Lubuk Baja, Batam',
      'latitude': 1.1301,
      'longitude': 104.0117,
      'city': 'Batam',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-7'],
    },
    {
      'id': 'cin-lpg-1',
      'name': 'Boemi Kedaton XXI Lampung',
      'address': 'Jl. Teuku Umar No. 1, Kedaton, Bandar Lampung',
      'latitude': -5.3822,
      'longitude': 105.2597,
      'city': 'Lampung',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-6'],
    },

    // ── SULAWESI & KALIMANTAN ───────────────────────────────────────────────
    {
      'id': 'cin-mks-1',
      'name': 'Panakkukang XXI Makassar',
      'address': 'Jl. Boulevard, Masale, Panakkukang, Makassar',
      'latitude': -5.1578,
      'longitude': 119.4472,
      'city': 'Makassar',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-6'],
    },
    {
      'id': 'cin-mks-2',
      'name': 'Nipah Mall XXI Makassar',
      'address': 'Jl. Urip Sumoharjo, Panaikang, Panakkukang, Makassar',
      'latitude': -5.1388,
      'longitude': 119.4494,
      'city': 'Makassar',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-5'],
    },
    {
      'id': 'cin-bpn-1',
      'name': 'E-Walk XXI Balikpapan',
      'address': 'Jl. Jend. Sudirman No. 47, Damai, Balikpapan Selatan',
      'latitude': -1.2747,
      'longitude': 116.8583,
      'city': 'Balikpapan',
      'facilities': ['IMAX', 'Premiere', 'Dolby Atmos'],
    },
    {
      'id': 'cin-bjm-1',
      'name': 'Duta Mall XXI Banjarmasin',
      'address': 'Jl. Ahmad Yani KM 2, Sungai Baru, Banjarmasin Tengah',
      'latitude': -3.3239,
      'longitude': 114.6025,
      'city': 'Banjarmasin',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-6'],
    },
    {
      'id': 'cin-mdc-1',
      'name': 'Mantos XXI Manado',
      'address': 'Jl. Piere Tendean Boulevard, Sario, Manado',
      'latitude': 1.4664,
      'longitude': 124.8286,
      'city': 'Manado',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-6'],
    },
    {
      'id': 'cin-ptk-1',
      'name': 'Ayani Mega Mall XXI Pontianak',
      'address': 'Jl. Jend. Ahmad Yani, Parit Tokaya, Pontianak Selatan',
      'latitude': -0.0522,
      'longitude': 109.3497,
      'city': 'Pontianak',
      'facilities': ['Premiere', 'Dolby Atmos', 'Studio 1-6'],
    },
  ];

  /// Menggabungkan data seed multi-kota dengan daftar bioskop dari Supabase/cache
  /// agar seluruh kota di Indonesia selalu tersedia dan tidak tertimpa cache lama.
  List<CinemaModel> _mergeWithSeed(List<CinemaModel> remoteOrCached) {
    final merged = <CinemaModel>[];
    final seenNames = <String>{};

    // Utamakan seedCinemas terlebih dahulu (Cinemate Plaza tetap #1)
    for (final s in seedCinemas) {
      final cinema = CinemaModel.fromJson(s);
      if (seenNames.add(cinema.name.toLowerCase())) {
        merged.add(cinema);
      }
    }
    for (final c in remoteOrCached) {
      if (seenNames.add(c.name.toLowerCase())) {
        merged.add(c);
      }
    }
    return merged;
  }

  /// Mengambil semua bioskop dari Supabase / Hive Cache / Fallback Seed
  Future<({List<CinemaModel> cinemas, bool fromCache})> getAllCinemas({
    bool forceRefresh = false,
  }) async {
    // 1. Cek cache Hive jika tidak forceRefresh & jumlahnya sudah lengkap multi-kota
    if (!forceRefresh) {
      try {
        final cached = await _storage.getCachedCinemas();
        if (cached != null && cached.length >= seedCinemas.length) {
          final list = cached.map((e) => CinemaModel.fromJson(e)).toList();
          return (cinemas: list, fromCache: true);
        }
      } catch (e) {
        debugPrint('[CinemaService] Error reading Hive cache: $e');
      }
    }

    // 2. Fetch online dari Supabase database lalu gabungkan dengan seed semua kota
    try {
      final response =
          await _supabase.client.from('cinemas').select().order('name');

      if (response.isNotEmpty) {
        final remoteList = response
            .map((e) => CinemaModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final merged = _mergeWithSeed(remoteList);

        await _storage.cacheCinemas(merged.map((e) => e.toJson()).toList());
        return (cinemas: merged, fromCache: false);
      }
    } catch (e) {
      debugPrint('[CinemaService] Supabase fetch error: $e');
    }

    // 3. Fallback offline: gabungkan seed lengkap multi-kota
    final fallbackList =
        seedCinemas.map((e) => CinemaModel.fromJson(e)).toList();
    try {
      await _storage.cacheCinemas(fallbackList.map((e) => e.toJson()).toList());
    } catch (_) {}
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
