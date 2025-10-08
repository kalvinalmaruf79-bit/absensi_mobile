// lib/widgets/smk_navbar.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Widget Navbar yang dapat digunakan kembali di seluruh aplikasi
/// Menggunakan NavigationBar Material 3 dengan tema SMKScan
class SMKNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const SMKNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        indicatorColor: AppTheme.primaryColor.withOpacity(0.1),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 8,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            );
          }
          return Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: AppTheme.primaryColor, size: 28);
          }
          return IconThemeData(color: Colors.grey[600], size: 24);
        }),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onTap,
        animationDuration: const Duration(milliseconds: 400),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Absensi',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
