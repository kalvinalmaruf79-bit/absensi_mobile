// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  Future<User>? _userFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _userFuture = _authService.getProfile();
    });
  }

  // Handle saat token terbukti tidak valid (401 Unauthorized)
  Future<void> _handleUnauthorized() async {
    // Tunggu proses logout selesai
    await _authService.logout();

    if (mounted) {
      // Navigasi ke LoginScreen dan hapus semua halaman sebelumnya
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );

      // Tampilkan notifikasi setelah frame berikutnya selesai dirender
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi Anda telah berakhir. Silakan login kembali.'),
            backgroundColor: AppTheme.accentColor,
            duration: Duration(seconds: 4),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error State
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            // Cek spesifik untuk error 401 (Unauthorized)
            if (error.contains('401')) {
              // Panggil fungsi untuk handle logout
              // Menggunakan addPostFrameCallback agar tidak memanggil setState saat build
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _handleUnauthorized(),
              );
              // Tampilkan UI loading sementara proses navigasi
              return const Center(child: CircularProgressIndicator());
            }
            // Tampilkan UI untuk error lainnya (koneksi, server down, dll)
            return _buildErrorView(error);
          }

          // 3. Success State
          if (snapshot.hasData) {
            final user = snapshot.data!;
            return _buildHomeContent(user);
          }

          // Fallback jika tidak ada data sama sekali
          return _buildErrorView('Data pengguna tidak ditemukan.');
        },
      ),
    );
  }

  // Widget untuk tampilan error
  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadUserData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk konten home
  Widget _buildHomeContent(User currentUser) {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: CustomScrollView(
        slivers: [
          // Header Section
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Beranda',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Selamat Datang,',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser.name,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Menu Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu Utama',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildMenuCard(
                        icon: Icons.qr_code_scanner,
                        title: 'Absensi',
                        subtitle: 'Scan QR Code',
                        color: Colors.blue,
                        onTap: () {
                          // TODO: Navigasi ke halaman Absensi
                        },
                      ),
                      _buildMenuCard(
                        icon: Icons.calendar_today,
                        title: 'Jadwal',
                        subtitle: 'Lihat jadwal',
                        color: Colors.green,
                        onTap: () {
                          // TODO: Navigasi ke halaman Jadwal
                        },
                      ),
                      _buildMenuCard(
                        icon: Icons.assignment,
                        title: 'Tugas',
                        subtitle: 'Kelola tugas',
                        color: Colors.orange,
                        onTap: () {
                          // TODO: Navigasi ke halaman Tugas
                        },
                      ),
                      _buildMenuCard(
                        icon: Icons.person,
                        title: 'Profil',
                        subtitle: 'Info akun',
                        color: Colors.purple,
                        onTap: () {
                          // TODO: Navigasi ke halaman Profil
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
