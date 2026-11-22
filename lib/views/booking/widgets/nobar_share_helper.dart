// lib/views/booking/widgets/nobar_share_helper.dart
// Helper format pesan dan kartu ajakan nonton bareng (PB-081)

import 'package:share_plus/share_plus.dart';

class NobarShareHelper {
  NobarShareHelper._();

  /// Format teks undangan nobar sinematik
  static String formatInvitationMessage({
    required String movieTitle,
    required String cinemaName,
    required String showDate,
    required String showTime,
    String? studio,
    List<String>? seats,
    String? bookingCode,
  }) {
    final seatText = (seats != null && seats.isNotEmpty)
        ? '\n💺 Kursi: ${seats.join(", ")}'
        : '';
    final studioText = studio != null ? ' ($studio)' : '';
    final codeText =
        bookingCode != null ? '\n🎟️ Ref Booking: $bookingCode' : '';

    return '🍿 *Ayo Nonton Bareng di Cinemate!* 🎬\n\n'
        'Halo! Aku mau ngajak kamu nonton film:\n'
        '🎞️ *"$movieTitle"*\n'
        '📍 Bioskop: $cinemaName$studioText\n'
        '📅 Jadwal: $showDate | ⏰ $showTime WIB'
        '$seatText$codeText\n\n'
        'Pesan tiket dan snack kamu langsung di aplikasi Cinemate yuk! ✨';
  }

  /// Bagikan undangan langsung via share_plus
  static Future<void> shareInvitation({
    required String movieTitle,
    required String cinemaName,
    required String showDate,
    required String showTime,
    String? studio,
    List<String>? seats,
    String? bookingCode,
  }) async {
    final message = formatInvitationMessage(
      movieTitle: movieTitle,
      cinemaName: cinemaName,
      showDate: showDate,
      showTime: showTime,
      studio: studio,
      seats: seats,
      bookingCode: bookingCode,
    );

    try {
      // ignore: deprecated_member_use
      await Share.share(
        message,
        subject: 'Ajakan Nonton Bareng: $movieTitle',
      );
    } catch (_) {
      // Fallback diam jika share dibatalkan
    }
  }
}
