import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart'; // Impor layanan notifikasi

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
      title: 'Sistem Akademik Sekolah',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Tentukan halaman awal berdasarkan status login
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
      // Definisikan rute untuk navigasi
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
