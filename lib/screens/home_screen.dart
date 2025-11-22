// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/siswa_service.dart';
import '../models/user.dart';
import '../models/pengumuman.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'nilai_screen.dart';
import 'materi_screen.dart';
import 'notifikasi_screen.dart';
import 'pengumuman_screen.dart';
import 'riwayat_absensi_screen.dart'; // TAMBAHKAN INI

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
  Future<List<Pengumuman>>? _pengumumanFuture;
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
      _pengumumanFuture = _siswaService.getPengumuman();
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
      setState(() {
        _unreadNotificationCount = 0;
      });
    }
  }

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

  void _navigateToTab(int tabIndex) {
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(tabIndex);
    }
  }

  void _navigateToNotifications() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotifikasiScreen()),
    );

    if (result == true) {
      _loadNotificationCount();
    }
  }

  void _navigateToPengumuman() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PengumumanScreen()),
    );
  }

  // TAMBAHKAN METHOD INI
  void _navigateToRiwayatAbsensi() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RiwayatAbsensiScreen()),
    );
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

  Widget _buildHomeContent(User currentUser) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
        await _loadNotificationCount();
      },
      child: CustomScrollView(
        slivers: [
          _buildCompactHeader(currentUser),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildCompactMenuSection(),
                FutureBuilder<Map<String, dynamic>>(
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
                _buildPengumumanSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader(User currentUser) {
    return SliverAppBar(
      expandedHeight: 140.0,
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentUser.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: _navigateToNotifications,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 22,
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
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          _unreadNotificationCount > 99
                                              ? '99+'
                                              : _unreadNotificationCount
                                                    .toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
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

  Widget _buildCompactMenuSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Menu Utama',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
            padding: EdgeInsets.zero,
            children: [
              _buildCompactMenuCard(
                icon: Icons.book_outlined,
                title: 'Materi',
                color: const Color(0xFF26A69A),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MateriScreen(),
                    ),
                  );
                },
              ),
              _buildCompactMenuCard(
                icon: Icons.grade,
                title: 'Nilai',
                color: const Color(0xFFFF7043),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NilaiScreen(),
                    ),
                  );
                },
              ),
              _buildCompactMenuCard(
                icon: Icons.qr_code_scanner,
                title: 'Presensi',
                color: const Color(0xFF42A5F5),
                onTap: () => _navigateToTab(1),
              ),
              _buildCompactMenuCard(
                icon: Icons.calendar_today,
                title: 'Jadwal',
                color: const Color(0xFF66BB6A),
                onTap: () => _navigateToTab(2),
              ),
              _buildCompactMenuCard(
                icon: Icons.assignment,
                title: 'Tugas',
                color: const Color(0xFFEF5350),
                onTap: () => _navigateToTab(3),
              ),
              _buildCompactMenuCard(
                icon: Icons.campaign,
                title: 'Pengumuman',
                color: const Color(0xFFFFB300),
                onTap: _navigateToPengumuman,
              ),
              _buildCompactMenuCard(
                icon: Icons.history,
                title: 'Riwayat',
                color: const Color(0xFF8D6E63),
                onTap: _navigateToRiwayatAbsensi, // UBAH INI
              ),
              _buildCompactMenuCard(
                icon: Icons.person,
                title: 'Profil',
                color: const Color(0xFFAB47BC),
                onTap: () => _navigateToTab(5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          if (siswaData['kelas'] != null)
            _buildEnhancedKelasCard(siswaData['kelas']),
          const SizedBox(height: 20),

          _buildSectionHeader('Jadwal Mendatang', Icons.schedule),
          const SizedBox(height: 12),
          _buildEnhancedJadwalCard(jadwalMendatang),
          const SizedBox(height: 20),

          _buildSectionHeader('Tugas Mendatang', Icons.assignment_outlined),
          const SizedBox(height: 12),
          _buildEnhancedTugasList(tugasMendatang),
          const SizedBox(height: 20),

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

  Widget _buildPengumumanSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Pengumuman Terbaru', Icons.campaign),
              TextButton(
                onPressed: _navigateToPengumuman,
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Pengumuman>>(
            future: _pengumumanFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildEmptyStateCard(
                  'Gagal memuat pengumuman',
                  Icons.error_outline,
                );
              }

              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final pengumumanList = snapshot.data!.take(3).toList();
                return Column(
                  children: pengumumanList
                      .map((pengumuman) => _buildPengumumanCard(pengumuman))
                      .toList(),
                );
              }

              return _buildEmptyStateCard(
                'Belum ada pengumuman',
                Icons.campaign_outlined,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPengumumanCard(Pengumuman pengumuman) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PengumumanDetailScreen(pengumumanId: pengumuman.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.campaign,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pengumuman.judul,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pengumuman.isi,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(pengumuman.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} menit yang lalu';
      }
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari yang lalu';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedKelasCard(Map<String, dynamic> kelas) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kelas Anda',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kelas['nama'] ?? '-',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${kelas['tingkat'] ?? ''} ${kelas['jurusan'] ?? ''}',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mataPelajaran['nama'] ?? '-',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        guru['name'] ?? '-',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    Icons.calendar_today,
                    _capitalizeFirst(jadwal['hari'] ?? '-'),
                  ),
                  Container(width: 1, height: 20, color: Colors.grey[300]),
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
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUrgent
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUrgent
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.assignment,
                color: isUrgent ? Colors.red : Colors.orange,
                size: 20,
              ),
            ),
            title: Text(
              tugas['judul'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                mataPelajaran['nama'] ?? '-',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isUrgent
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
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
                      fontSize: 16,
                      color: isUrgent ? Colors.red : Colors.orange,
                    ),
                  ),
                  Text(
                    'hari',
                    style: TextStyle(
                      fontSize: 9,
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

  Widget _buildEnhancedStatistikPresensi(Map<String, dynamic> stats) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
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

  Widget _buildEnhancedStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 14),
          const Text(
            'Gagal memuat dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            error.replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
