import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- WARNA UTAMA APLIKASI ---
  static const Color primaryColor = Color(0xFF005f8b);
  static const Color secondaryColor = Color(0xFF007fb9);
  static const Color accentColor = Colors.orange;
  static const Color backgroundColor = Color(0xFFf0f8ff);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;

  // --- TEMA TERANG (LIGHT THEME) ---
  static ThemeData get lightTheme {
    // 1. Buat ColorScheme dasar dari warna primer
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: backgroundColor,
      surface: surfaceColor,
    );

    // 2. Definisikan tema teks dasar menggunakan Google Fonts
    final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme);

    // 3. Gabungkan semuanya ke dalam ThemeData
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme.copyWith(
        // --- SESUAIKAN GAYA TEKS SPESIFIK JIKA PERLU ---
        // Contoh: Judul besar di header
        displaySmall: textTheme.displaySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        // Contoh: Subjudul di header
        titleMedium: textTheme.titleMedium?.copyWith(
          color: Colors.white70,
          fontSize: 16,
        ),
        // Contoh: Judul di dalam kartu/card
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface, // Warna teks di atas surface
        ),
        // Contoh: Teks body utama
        bodyLarge: textTheme.bodyLarge?.copyWith(color: Colors.black87),
        // Contoh: Label untuk input form
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: primaryColor,
          fontSize: 14,
        ),
      ),
      // --- KUSTOMISASI KOMPONEN UI LAINNYA ---
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary, // Warna ikon dan judul
        centerTitle: true,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          textStyle: textTheme.labelLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.primary.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        prefixIconColor: colorScheme.primary,
      ),
      scaffoldBackgroundColor: colorScheme.background,
    );
  }
}
