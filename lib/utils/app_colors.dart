// lib/utils/app_colors.dart
// Palet warna tema sinema gelap (Dark Cinema Theme - Netflix/Spotify inspired)

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // prevent instantiation

  // ── Primary (Single Hero Accent) ──────────────────────────────────────────
  static const Color primary = Color(0xFFE50914); // Merah bioskop utama
  static const Color primaryDark = Color(0xFFB20710); // Merah lebih gelap
  static const Color primaryLight = Color(0xFFFF4D55); // Aksen merah lembut

  // ── Background & Neutral Charcoal Surfaces ────────────────────────────────
  static const Color background = Color(0xFF0A0A0A); // Hitam pekat sinema
  static const Color surface = Color(0xFF141414); // Permukaan netral gelap
  static const Color card = Color(0xFF1C1C1C); // Kartu elevasi halus
  static const Color cardLight = Color(0xFF262626); // Permukaan interaktif/hover

  // ── Text Hierarchy (WCAG AA on Dark Charcoal) ────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3B3); // Abu-abu terang bersih
  static const Color textDisabled = Color(0xFF737373); // Abu-abu redup terbaca
  static const Color textHint = Color(0xFF8E8E8E); // Hint text >= 4.5:1 di inputFill

  // ── Accent ────────────────────────────────────────────────────────────────
  static const Color gold = Color(0xFFFFD700); // Khusus ikon rating bintang
  static const Color goldDark = Color(0xFFB89600); // Emas gelap

  // ── Muted Semantic Status (Selaras tema gelap, tanpa warna neon) ──────────
  static const Color success = Color(0xFF46D369); // Hijau matte terkendali
  static const Color warning = Color(0xFFE5A93C); // Kuning amber lembut
  static const Color error = Color(0xFFE5484D); // Merah error terbaca
  static const Color info = Color(0xFFA1A1AA); // Perak netral untuk info

  // ── UI Elements (Hairline Neutral Borders & Inputs) ───────────────────────
  static const Color divider = Color(0xFF262626);
  static const Color border = Color(0xFF2E2E2E);
  static const Color inputFill = Color(0xFF181818);
  static const Color shimmer = Color(0xFF1A1A1A);
  static const Color shimmerHighlight = Color(0xFF292929);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [card, cardLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
