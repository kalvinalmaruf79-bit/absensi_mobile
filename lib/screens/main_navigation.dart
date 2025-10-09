// lib/screens/main_navigation.dart
import 'package:absensi_mobile/screens/profil_screen.dart';
import 'package:absensi_mobile/screens/tugas_screen.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'absensi_screen.dart';
import 'jadwal_screen.dart';

/// Halaman navigasi utama aplikasi SMKScan
/// Menggunakan IndexedStack untuk menyimpan state tiap tab
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // Inisialisasi screen hanya sekali untuk performa lebih baik
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onNavigateToTab: _onTabTapped),
      const AbsensiScreen(),
      const JadwalScreen(),
      const TugasScreen(),
      const ProfilScreen(),
    ];
  }

  // Daftar label untuk setiap tab
  final List<String> _labels = const [
    'Beranda',
    'Absensi',
    'Jadwal',
    'Tugas',
    'Profil',
  ];

  void _onTabTapped(int index) {
    if (index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent back button from going to login
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: AppTheme.primaryColor.withOpacity(0.15),
              backgroundColor: AppTheme.surfaceColor,
              elevation: 0,
              height: 70,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  );
                }
                return TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                );
              }),
              iconTheme: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const IconThemeData(
                    color: AppTheme.primaryColor,
                    size: 28,
                  );
                }
                return IconThemeData(color: Colors.grey[600], size: 24);
              }),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onTabTapped,
              animationDuration: const Duration(milliseconds: 400),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: _labels[0],
                ),
                NavigationDestination(
                  icon: const Icon(Icons.qr_code_scanner_outlined),
                  selectedIcon: const Icon(Icons.qr_code_scanner),
                  label: _labels[1],
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_today_outlined),
                  selectedIcon: const Icon(Icons.calendar_today),
                  label: _labels[2],
                ),
                NavigationDestination(
                  icon: const Icon(Icons.assignment_outlined),
                  selectedIcon: const Icon(Icons.assignment),
                  label: _labels[3],
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: _labels[4],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
