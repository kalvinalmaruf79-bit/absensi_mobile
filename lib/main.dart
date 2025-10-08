// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

void main() async {
  // Pastikan widget Flutter sudah siap sebelum menjalankan kode lain
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi OneSignal
  await NotificationService.initOneSignal();

  // Cek status login
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getString('token') != null;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMKScan - Sistem Akademik Sekolah',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Menggunakan tema dari AppTheme
      // Tentukan halaman awal berdasarkan status login
      home: isLoggedIn ? const MainNavigation() : const LoginScreen(),
      // Definisikan rute untuk navigasi
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainNavigation(),
      },
    );
  }
}
