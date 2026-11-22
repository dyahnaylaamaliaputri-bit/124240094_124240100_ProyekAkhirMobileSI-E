// lib/views/profile/widgets/genre_radar_chart.dart
// Visualisasi chart radar spektrum selera film penonton (PB-083)

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class GenreRadarChart extends StatelessWidget {
  final Map<String, double> genreScores; // 0.0 s.d. 1.0 per genre

  const GenreRadarChart({
    super.key,
    required this.genreScores,
  });

  @override
  Widget build(BuildContext context) {
    if (genreScores.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data selera film.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.radar, color: AppColors.gold, size: 20),
              SizedBox(width: 8),
              Text(
                'Radar Selera Film Anda',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Berdasarkan riwayat pemesanan tiket & mood tontonan Anda.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            width: double.infinity,
            child: CustomPaint(
              painter: _RadarChartPainter(genreScores),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final Map<String, double> scores;

  _RadarChartPainter(this.scores);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.38;

    final keys = scores.keys.toList();
    final count = keys.length;
    if (count < 3) return;

    final angleStep = (2 * pi) / count;

    // Garis jaring konsentris (20%, 40%, 60%, 80%, 100%)
    final gridPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int step = 1; step <= 4; step++) {
      final stepRadius = radius * (step / 4.0);
      final path = Path();
      for (int i = 0; i < count; i++) {
        final angle = i * angleStep - pi / 2;
        final x = center.dx + stepRadius * cos(angle);
        final y = center.dy + stepRadius * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Jari-jari & label
    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < count; i++) {
      final angle = i * angleStep - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);

      // Label teks di luar lingkaran
      final labelX = center.dx + (radius + 20) * cos(angle);
      final labelY = center.dy + (radius + 20) * sin(angle);

      textPainter.text = TextSpan(
        text: keys[i],
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );
    }

    // Area data pengguna
    final dataPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dataPath = Path();
    for (int i = 0; i < count; i++) {
      final angle = i * angleStep - pi / 2;
      final score = (scores[keys[i]] ?? 0.0).clamp(0.0, 1.0);
      final pointRadius = radius * score;
      final x = center.dx + pointRadius * cos(angle);
      final y = center.dy + pointRadius * sin(angle);

      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, dataPaint);
    canvas.drawPath(dataPath, borderPaint);

    // Titik sudut (node)
    final nodePaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final angle = i * angleStep - pi / 2;
      final score = (scores[keys[i]] ?? 0.0).clamp(0.0, 1.0);
      final pointRadius = radius * score;
      final x = center.dx + pointRadius * cos(angle);
      final y = center.dy + pointRadius * sin(angle);
      canvas.drawCircle(Offset(x, y), 3.5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) => true;
}
