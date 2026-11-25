// lib/views/ticket/widgets/ticket_export_dialog.dart
// Dialog ekspor struk tiket resmi & kalender pengingat (PB-091)

import 'package:flutter/material.dart';
import '../../../models/ticket_model.dart';
import '../../../services/ticket_export_service.dart';
import '../../../utils/app_colors.dart';

class TicketExportDialog extends StatelessWidget {
  final TicketModel ticket;

  const TicketExportDialog({super.key, required this.ticket});

  static void show(BuildContext context, TicketModel ticket) {
    showDialog(
      context: context,
      builder: (_) => TicketExportDialog(ticket: ticket),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ekspor & Simpan Tiket',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${ticket.movieTitle} (${ticket.bookingCode})',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Opsi 1: Bagikan Struk E-Ticket Resmi
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.picture_as_pdf_outlined,
                    color: AppColors.textPrimary),
              ),
              title: const Text(
                'Bagikan Struk / E-Ticket',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Ekspor struk teks & QR booking resmi',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                TicketExportService.shareReceipt(ticket);
              },
            ),

            const Divider(color: Colors.white10),

            // Opsi 2: Simpan ke Kalender HP
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.event_available_outlined,
                    color: AppColors.textPrimary),
              ),
              title: const Text(
                'Simpan ke Kalender (.ics)',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Sinkronkan jadwal nonton ke Google/Apple Calendar',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                TicketExportService.shareCalendarEvent(
                  movieTitle: ticket.movieTitle,
                  cinemaName: ticket.cinemaName,
                  hallName: ticket.hallName,
                  showDate: ticket.showDate,
                  showTime: ticket.showTime,
                  bookingCode: ticket.bookingCode,
                  seats: ticket.seats,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
