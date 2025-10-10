// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/siswa_service.dart';
import '../models/user.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'nilai_screen.dart';
import 'materi_screen.dart';
import 'notifikasi_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final SiswaService _siswaService = SiswaService();

  Future<User>? _userFuture;
  Future<Map<String, dynamic>>? _dashboardFuture;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadNotificationCount();
  }

  Future<void> _loadData() async {
    setState(() {
      _userFuture = _authService.getProfile();
      _dashboardFuture = _siswaService.getDashboard();
    });
  }

  Future<void> _loadNotificationCount() async {
    try {
      final notifications = await _siswaService.getNotifikasi(
        page: 1,
        limit: 100,
      );
      setState(() {
        _unreadNotificationCount = notifications.where((n) => !n.isRead).length;
      });
    } catch (e) {
      // Gagal load notifikasi, set ke 0
      setState(() {
        _unreadNotificationCount = 0;
      });
    }
  }

  // Handle saat token terbukti tidak valid (401 Unauthorized)
  Future<void> _handleUnauthorized() async {
    await _authService.logout();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );

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

  // Navigasi ke tab tertentu di MainNavigation
  void _navigateToTab(int tabIndex) {
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(tabIndex);
    }
  }

  // Navigasi ke halaman notifikasi
  void _navigateToNotifications() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotifikasiScreen()),
    );

    // Refresh notification count setelah kembali dari halaman notifikasi
    if (result == true) {
      _loadNotificationCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains('401')) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _handleUnauthorized(),
              );
              return const Center(child: CircularProgressIndicator());
            }
            return _buildErrorView(error);
          }

          if (snapshot.hasData) {
            final user = snapshot.data!;
            return _buildHomeContent(user);
          }

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
              onPressed: _loadData,
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
      onRefresh: () async {
        await _loadData();
        await _loadNotificationCount();
      },
      child: CustomScrollView(
        slivers: [
          // Header Section dengan notifikasi
          _buildEnhancedHeader(currentUser),
          // Dashboard Content
          SliverToBoxAdapter(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _dashboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  final error = snapshot.error.toString();
                  if (error.contains('401')) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _handleUnauthorized(),
                    );
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildErrorCard(error),
                  );
                }

                if (snapshot.hasData) {
                  return _buildDashboardContent(snapshot.data!);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
          // Menu Utama Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Menu Utama',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: [
                      _buildMenuCard(
                        icon: Icons.book_outlined,
                        title: 'Materi',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF26A69A), Color(0xFF00897B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MateriScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        icon: Icons.grade,
                        title: 'Nilai',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7043), Color(0xFFE64A19)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NilaiScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        icon: Icons.qr_code_scanner,
                        title: 'Presensi',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => _navigateToTab(1),
                      ),
                      _buildMenuCard(
                        icon: Icons.calendar_today,
                        title: 'Jadwal',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => _navigateToTab(2),
                      ),
                      _buildMenuCard(
                        icon: Icons.assignment,
                        title: 'Tugas',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => _navigateToTab(3),
                      ),
                      _buildMenuCard(
                        icon: Icons.person,
                        title: 'Profil',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFAB47BC), Color(0xFF8E24AA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => _navigateToTab(4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Header dengan layout yang lebih baik dan tombol notifikasi
  Widget _buildEnhancedHeader(User currentUser) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Header dengan greeting dan notifikasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bagian kiri: Greeting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentUser.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Bagian kanan: Tombol Notifikasi
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        child: Material(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: _navigateToNotifications,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  if (_unreadNotificationCount > 0)
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 20,
                                        ),
                                        child: Text(
                                          _unreadNotificationCount > 99
                                              ? '99+'
                                              : _unreadNotificationCount
                                                    .toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper untuk greeting berdasarkan waktu
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi 👋';
    } else if (hour < 15) {
      return 'Selamat Siang ☀️';
    } else if (hour < 18) {
      return 'Selamat Sore 🌤️';
    } else {
      return 'Selamat Malam 🌙';
    }
  }

  // Dashboard content dengan jadwal, tugas, dan statistik
  Widget _buildDashboardContent(Map<String, dynamic> data) {
    final siswaData = data['siswa'];
    final jadwalMendatang = data['jadwalMendatang'];
    final tugasMendatang = data['tugasMendatang'] as List<dynamic>;
    final statistikPresensi = data['statistikPresensi'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Kelas dengan design lebih modern
          if (siswaData['kelas'] != null)
            _buildEnhancedKelasCard(siswaData['kelas']),
          const SizedBox(height: 24),

          // Jadwal Mendatang
          _buildSectionHeader('Jadwal Mendatang', Icons.schedule),
          const SizedBox(height: 12),
          _buildEnhancedJadwalCard(jadwalMendatang),
          const SizedBox(height: 24),

          // Tugas Mendatang
          _buildSectionHeader('Tugas Mendatang', Icons.assignment_outlined),
          const SizedBox(height: 12),
          _buildEnhancedTugasList(tugasMendatang),
          const SizedBox(height: 24),

          // Statistik Presensi
          _buildSectionHeader(
            'Statistik Presensi Bulan Ini',
            Icons.analytics_outlined,
          ),
          const SizedBox(height: 12),
          _buildEnhancedStatistikPresensi(statistikPresensi),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Section header yang lebih menarik
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  // Enhanced Card untuk info kelas
  Widget _buildEnhancedKelasCard(Map<String, dynamic> kelas) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kelas Anda',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kelas['nama'] ?? '-',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${kelas['tingkat'] ?? ''} ${kelas['jurusan'] ?? ''}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Card untuk jadwal mendatang
  Widget _buildEnhancedJadwalCard(dynamic jadwal) {
    if (jadwal == null) {
      return _buildEmptyStateCard(
        'Tidak ada jadwal mendatang',
        Icons.event_busy,
      );
    }

    final mataPelajaran = jadwal['mataPelajaran'];
    final guru = jadwal['guru'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mataPelajaran['nama'] ?? '-',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        guru['name'] ?? '-',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    Icons.calendar_today,
                    _capitalizeFirst(jadwal['hari'] ?? '-'),
                  ),
                  Container(width: 1, height: 24, color: Colors.grey[300]),
                  _buildInfoItem(
                    Icons.access_time,
                    '${jadwal['jamMulai']} - ${jadwal['jamSelesai']}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced List tugas mendatang
  Widget _buildEnhancedTugasList(List<dynamic> tugasList) {
    if (tugasList.isEmpty) {
      return _buildEmptyStateCard(
        'Tidak ada tugas mendatang',
        Icons.assignment_turned_in,
      );
    }

    return Column(
      children: tugasList.take(3).map((tugas) {
        final mataPelajaran = tugas['mataPelajaran'];
        final deadline = DateTime.parse(tugas['deadline']);
        final daysLeft = deadline.difference(DateTime.now()).inDays;
        final isUrgent = daysLeft <= 2;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUrgent
                  ? Colors.red.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUrgent
                    ? Colors.red.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.assignment,
                color: isUrgent ? Colors.red : Colors.orange,
                size: 24,
              ),
            ),
            title: Text(
              tugas['judul'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                mataPelajaran['nama'] ?? '-',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isUrgent
                    ? Colors.red.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$daysLeft',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isUrgent ? Colors.red : Colors.orange,
                    ),
                  ),
                  Text(
                    'hari',
                    style: TextStyle(
                      fontSize: 10,
                      color: isUrgent ? Colors.red : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Enhanced Statistik presensi
  Widget _buildEnhancedStatistikPresensi(Map<String, dynamic> stats) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildEnhancedStatItem('Hadir', stats['hadir'] ?? 0, Colors.green),
            _buildEnhancedStatItem('Izin', stats['izin'] ?? 0, Colors.blue),
            _buildEnhancedStatItem('Sakit', stats['sakit'] ?? 0, Colors.orange),
            _buildEnhancedStatItem('Alpa', stats['alpa'] ?? 0, Colors.red),
          ],
        ),
      ),
    );
  }

  // Enhanced Item statistik
  Widget _buildEnhancedStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Info item untuk jadwal
  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Empty state card
  Widget _buildEmptyStateCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // Error card
  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            error.replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Menu card dengan gradient yang lebih modern
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper untuk capitalize first letter
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
