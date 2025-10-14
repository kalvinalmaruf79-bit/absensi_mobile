// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/splash_screen.dart'; // TAMBAHAN: Import splash screen
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale Indonesia
  await initializeDateFormatting('id', null);
  Intl.defaultLocale = 'id';

  // Inisialisasi OneSignal
  print('🚀 Memulai inisialisasi OneSignal...');
  await NotificationService.initOneSignal();

  // Tunggu sebentar untuk memastikan OneSignal ready
  await Future.delayed(const Duration(seconds: 2));

  // Cek status login
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getString('token') != null;

  // Jika sudah login, coba sync device
  if (isLoggedIn) {
    print('👤 User sudah login, melakukan sync device...');
    await NotificationService.syncDevice();
  }

  // PERUBAHAN: Tidak lagi pass isLoggedIn ke MyApp
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMKScan - Sistem Akademik Sekolah',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Localization delegates
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Supported locales
      supportedLocales: const [
        Locale('id'), // Indonesia
        Locale('en'), // English
      ],

      // Default locale
      locale: const Locale('id'),

      // PERUBAHAN: Home sekarang langsung ke SplashScreen
      home: const SplashScreen(),

      // Routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainNavigation(),
      },
    );
  }
}
