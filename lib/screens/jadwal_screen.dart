import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/siswa_service.dart';
import '../services/common_service.dart';
import '../models/jadwal.dart';

/// Screen Jadwal - Menampilkan jadwal pelajaran siswa dari API
class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  final SiswaService _siswaService = SiswaService();
  final CommonService _commonService = CommonService();

  int _selectedDay = DateTime.now().weekday - 1; // 0 = Senin
  bool _isLoading = true;
  String? _errorMessage;

  // Data jadwal per hari
  Map<String, List<Jadwal>> _jadwalData = {};

  // Parameter untuk mengambil jadwal (dari pengaturan aktif)
  // PERBAIKAN: Gunakan nullable String dengan default null
  String? _tahunAjaran;
  String? _semester;

  final List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  final List<String> _daysKey = [
    'senin',
    'selasa',
    'rabu',
    'kamis',
    'jumat',
    'sabtu',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Memuat pengaturan tahun ajaran dan semester aktif dari CommonService
  Future<void> _loadSettings() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      print('Loading settings from CommonService...');
      final settings = await _commonService.getGlobalSettings();

      print('Settings received: $settings');

      setState(() {
        _tahunAjaran = settings['tahunAjaranAktif'] ?? '2024/2025';
        _semester = settings['semesterAktif'] ?? 'Ganjil';
      });

      print('Tahun Ajaran: $_tahunAjaran');
      print('Semester: $_semester');

      // Setelah mendapatkan settings, muat jadwal
      await _loadJadwal();
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _errorMessage =
            'Gagal memuat pengaturan: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  /// Memuat jadwal dari API
  Future<void> _loadJadwal() async {
    // PERBAIKAN: Cek apakah tahunAjaran dan semester sudah tersedia
    if (_tahunAjaran == null || _semester == null) {
      setState(() {
        _errorMessage = 'Tahun ajaran atau semester belum dimuat';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print(
        'Loading jadwal with tahunAjaran=$_tahunAjaran, semester=$_semester',
      );

      final jadwalData = await _siswaService.getJadwalSiswa(
        _tahunAjaran!,
        _semester!,
      );

      print('Jadwal data received: ${jadwalData.keys.toList()}');
      jadwalData.forEach((day, schedules) {
        print('$day: ${schedules.length} jadwal');
      });

      setState(() {
        _jadwalData = jadwalData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading jadwal: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Mendapatkan jadwal untuk hari yang dipilih
  List<Jadwal> _getSelectedDaySchedule() {
    final dayKey = _daysKey[_selectedDay];
    return _jadwalData[dayKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadJadwal,
        child: CustomScrollView(
          slivers: [
            // AppBar dengan gradient
            _buildAppBar(),

            // Konten utama
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Info tahun ajaran dan semester
                  // PERBAIKAN: Tampilkan hanya jika data sudah tersedia
                  if (_tahunAjaran != null && _semester != null)
                    _buildSemesterInfo(),
                  const SizedBox(height: 20),
                  // Selector hari
                  _buildDaySelector(),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Konten berdasarkan status loading
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(child: _buildErrorWidget())
            else if (_getSelectedDaySchedule().isEmpty)
              SliverFillRemaining(child: _buildEmptyWidget())
            else
              _buildScheduleList(),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Jadwal Pelajaran',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
          ),
          child: Stack(
            children: [
              // Background icon
              Positioned(
                right: -30,
                top: -30,
                child: Icon(
                  Icons.calendar_today,
                  size: 200,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              // Konten
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 60,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cek jadwal pelajaranmu',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.secondaryColor.withValues(alpha: 0.15),
              AppTheme.primaryColor.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school,
                size: 24,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tahun Ajaran & Semester',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_tahunAjaran - Semester $_semester',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedDay == index;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _selectedDay = index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Text(
                    _days[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleList() {
    final schedules = _getSelectedDaySchedule();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return _buildScheduleCard(schedules[index]);
        }, childCount: schedules.length),
      ),
    );
  }

  Widget _buildScheduleCard(Jadwal jadwal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Aksi ketika kartu jadwal diklik
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Waktu dengan badge
                Container(
                  width: 80,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.15),
                        AppTheme.secondaryColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppTheme.primaryColor,
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        jadwal.jamMulai,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        jadwal.jamSelesai,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.secondaryColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Detail pelajaran
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jadwal.mataPelajaran['nama'] ?? 'Mata Pelajaran',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                      ),
                      const SizedBox(height: 6),
                      if (jadwal.mataPelajaran['kode'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Kode: ${jadwal.mataPelajaran['kode']}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.accentColor,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              jadwal.guru['name'] ?? 'Guru',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.room, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            jadwal.kelas['nama'] ?? 'Kelas',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Indikator navigasi
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Gagal Memuat Jadwal',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Terjadi kesalahan saat memuat jadwal',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadSettings,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200]?.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            Text(
              'Tidak Ada Jadwal',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada jadwal untuk hari ${_days[_selectedDay]}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedDay = (_selectedDay + 1) % _days.length;
                });
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Lihat Hari Berikutnya'),
            ),
          ],
        ),
      ),
    );
  }
}
