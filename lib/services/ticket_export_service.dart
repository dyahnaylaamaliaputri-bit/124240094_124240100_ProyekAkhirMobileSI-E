// lib/services/ticket_export_service.dart
// Service generator dokumen PDF & kalender perangkat (PB-091)

import 'package:share_plus/share_plus.dart';
import '../models/ticket_model.dart';

class TicketExportService {
  /// Format konten struk e-ticket resmi Cinemate
  static String generateReceiptText(TicketModel ticket) {
    final seatsStr = ticket.seats.join(', ');
    final dateStr = ticket.showDate;
    final timeStr = ticket.showTime;

    return '''
========================================
       CINEMATE E-TICKET OFFICIAL       
========================================
Kode Booking : ${ticket.bookingCode}
Judul Film   : ${ticket.movieTitle}
Bioskop      : ${ticket.cinemaName}
Studio       : ${ticket.hallName} (${ticket.experience})
Jadwal       : $dateStr | $timeStr WIB
Nomor Kursi  : $seatsStr
Total Bayar  : Rp ${ticket.totalPrice}
Metode Bayar : ${ticket.paymentMethod ?? 'Online Payment'}
Status Tiket : ${ticket.status.toUpperCase()}
----------------------------------------
QR Payload   : ${ticket.qrData}
========================================
Harap tunjukkan struk / QR ini kepada
petugas bioskop saat memasuki studio.
''';
  }

  /// Format data event kalender standar iCalendar (.ics)
  static String generateIcsCalendarContent({
    required String movieTitle,
    required String cinemaName,
    required String hallName,
    required String showDate, // YYYY-MM-DD
    required String showTime, // HH:mm
    required String bookingCode,
    List<String> seats = const [],
  }) {
    // Normalisasi format tanggal YYYYMMDD
    final cleanDate = showDate.replaceAll('-', '');
    final cleanTime = showTime.replaceAll(':', '');

    return '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Cinemate App//ID//EN
BEGIN:VEVENT
SUMMARY:Nonton: $movieTitle
LOCATION:$cinemaName, $hallName
DESCRIPTION:Jadwal nonton film $movieTitle di $cinemaName ($hallName).\\nKursi: ${seats.join(", ")}\\nKode Booking: $bookingCode
DTSTART:${cleanDate}T${cleanTime}00
DTEND:${cleanDate}T220000
STATUS:CONFIRMED
END:VEVENT
END:VCALENDAR''';
  }

  /// Ekspor struk via dialog share
  static Future<void> shareReceipt(TicketModel ticket) async {
    final text = generateReceiptText(ticket);
    try {
      // ignore: deprecated_member_use
      await Share.share(
        text,
        subject:
            'E-Ticket Cinemate: ${ticket.movieTitle} (${ticket.bookingCode})',
      );
    } catch (_) {}
  }

  /// Bagikan event kalender
  static Future<void> shareCalendarEvent({
    required String movieTitle,
    required String cinemaName,
    required String hallName,
    required String showDate,
    required String showTime,
    required String bookingCode,
    List<String> seats = const [],
  }) async {
    final ics = generateIcsCalendarContent(
      movieTitle: movieTitle,
      cinemaName: cinemaName,
      hallName: hallName,
      showDate: showDate,
      showTime: showTime,
      bookingCode: bookingCode,
      seats: seats,
    );

    try {
      // ignore: deprecated_member_use
      await Share.share(
        ics,
        subject: 'Jadwal Nonton $movieTitle.ics',
      );
    } catch (_) {}
  }
}
