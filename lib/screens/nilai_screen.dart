// lib/screens/nilai_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../services/siswa_service.dart';
import '../models/nilai.dart';

class NilaiScreen extends StatefulWidget {
  const NilaiScreen({super.key});

  @override
  State<NilaiScreen> createState() => _NilaiScreenState();
}

class _NilaiScreenState extends State<NilaiScreen> {
  final SiswaService _siswaService = SiswaService();

  // State variables
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Data
  List<RingkasanNilai> _ringkasanList = [];
  String? _selectedTahunAjaran;
  String? _selectedSemester;
  Map<String, dynamic>? _statistikData;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load ringkasan nilai untuk mendapatkan daftar semester
      final ringkasan = await _siswaService.getRingkasanNilai();

      setState(() {
        _ringkasanList = ringkasan;

        // Set semester terbaru sebagai default
        if (ringkasan.isNotEmpty) {
          _selectedTahunAjaran = ringkasan.first.tahunAjaran;
          _selectedSemester = ringkasan.first.semester;
        }
      });

      // Load statistik untuk semester yang dipilih
      if (_selectedTahunAjaran != null && _selectedSemester != null) {
        await _loadStatistikNilai();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _loadStatistikNilai() async {
    if (_selectedTahunAjaran == null || _selectedSemester == null) return;

    try {
      final statistik = await _siswaService.getStatistikNilai(
        _selectedTahunAjaran!,
        _selectedSemester!,
      );

      setState(() {
        _statistikData = statistik;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat statistik: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _onSemesterChanged(String tahunAjaran, String semester) async {
    setState(() {
      _selectedTahunAjaran = tahunAjaran;
      _selectedSemester = semester;
      _isLoading = true;
    });

    await _loadStatistikNilai();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nilai Akademik',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _hasError
          ? _buildErrorState()
          : _ringkasanList.isEmpty
          ? _buildEmptyState()
          : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text('Memuat data nilai...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Data',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Data Nilai',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nilai akademik Anda akan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: _statistikData != null
                ? _buildNilaiList()
                : const Center(
                    child: Text('Pilih semester untuk melihat nilai'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final rataRata = _statistikData?['rataRataKeseluruhan'] ?? 0.0;
    final perMataPelajaran =
        _statistikData?['perMataPelajaran'] as List<StatistikNilai>? ?? [];

    // Hitung nilai tertinggi dan terendah
    double nilaiTertinggi = 0;
    double nilaiTerendah = 100;

    for (var stat in perMataPelajaran) {
      if (stat.nilaiTertinggi > nilaiTertinggi) {
        nilaiTertinggi = stat.nilaiTertinggi;
      }
      if (stat.nilaiTerendah < nilaiTerendah) {
        nilaiTerendah = stat.nilaiTerendah;
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Dropdown periode
            _buildPeriodeDropdown(),
            const SizedBox(height: 24),
            // Statistik nilai
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.assessment,
                  label: 'Rata-rata',
                  value: rataRata.toStringAsFixed(1),
                ),
                _buildStatItem(
                  icon: Icons.book,
                  label: 'Mapel',
                  value: perMataPelajaran.length.toString(),
                ),
                _buildStatItem(
                  icon: Icons.trending_up,
                  label: 'Tertinggi',
                  value: perMataPelajaran.isNotEmpty
                      ? nilaiTertinggi.toStringAsFixed(0)
                      : '0',
                ),
                _buildStatItem(
                  icon: Icons.trending_down,
                  label: 'Terendah',
                  value: perMataPelajaran.isNotEmpty
                      ? nilaiTerendah.toStringAsFixed(0)
                      : '0',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodeDropdown() {
    // Buat daftar periode unik
    final periodeList = _ringkasanList
        .map((r) => '${r.tahunAjaran}|${r.semester}')
        .toSet()
        .toList();

    final selectedValue =
        _selectedTahunAjaran != null && _selectedSemester != null
        ? '$_selectedTahunAjaran|$_selectedSemester'
        : (periodeList.isNotEmpty ? periodeList.first : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: DropdownButton<String>(
        value: selectedValue,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppTheme.primaryColor,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        items: periodeList.map((String value) {
          final parts = value.split('|');
          final tahunAjaran = parts[0];
          final semester = parts[1];
          final label = '$tahunAjaran - ${semester.toUpperCase()}';

          return DropdownMenuItem<String>(value: value, child: Text(label));
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            final parts = newValue.split('|');
            _onSemesterChanged(parts[0], parts[1]);
          }
        },
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNilaiList() {
    final perMataPelajaran =
        _statistikData?['perMataPelajaran'] as List<StatistikNilai>? ?? [];

    if (perMataPelajaran.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Nilai',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nilai untuk semester ini belum tersedia',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: perMataPelajaran.length,
      itemBuilder: (context, index) {
        final statistik = perMataPelajaran[index];
        return _buildNilaiCard(context, statistik, index);
      },
    );
  }

  Widget _buildNilaiCard(
    BuildContext context,
    StatistikNilai statistik,
    int index,
  ) {
    // Warna berbeda untuk setiap mata pelajaran
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    final color = colors[index % colors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetailDialog(context, statistik, color),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon mata pelajaran
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.menu_book, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  // Nama mapel
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statistik.namaMataPelajaran,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${statistik.jumlahPenilaian} Penilaian',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Nilai rata-rata dan grade
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        statistik.rataRata.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getGrade(statistik.rataRata),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Range nilai
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNilaiDetail(
                    'Tertinggi',
                    statistik.nilaiTertinggi.toStringAsFixed(0),
                  ),
                  Container(height: 30, width: 1, color: Colors.grey[300]),
                  _buildNilaiDetail(
                    'Rata-rata',
                    statistik.rataRata.toStringAsFixed(1),
                  ),
                  Container(height: 30, width: 1, color: Colors.grey[300]),
                  _buildNilaiDetail(
                    'Terendah',
                    statistik.nilaiTerendah.toStringAsFixed(0),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNilaiDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _getGrade(double nilai) {
    if (nilai >= 90) return 'A';
    if (nilai >= 80) return 'B';
    if (nilai >= 70) return 'C';
    if (nilai >= 60) return 'D';
    return 'E';
  }

  void _showDetailDialog(
    BuildContext context,
    StatistikNilai statistik,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon dan nama mapel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.menu_book, color: color, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  statistik.namaMataPelajaran,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  statistik.kodeMataPelajaran,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Detail nilai
                _buildDetailRow(
                  'Nilai Tertinggi',
                  statistik.nilaiTertinggi.toStringAsFixed(1),
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  'Rata-rata',
                  statistik.rataRata.toStringAsFixed(1),
                  isBold: true,
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  'Nilai Terendah',
                  statistik.nilaiTerendah.toStringAsFixed(1),
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  'Jumlah Penilaian',
                  statistik.jumlahPenilaian.toString(),
                ),
                const SizedBox(height: 16),
                // Grade badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Grade: ${_getGrade(statistik.rataRata)}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Breakdown per jenis nilai
                if (statistik.jenisNilai.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rincian Nilai:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...statistik.jenisNilai.map((jn) {
                    final jenis = jn['jenis'] ?? '';
                    final nilai = jn['nilai'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatJenisPenilaian(jenis),
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          Text(
                            nilai.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                // Tombol tutup
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isBold ? AppTheme.primaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatJenisPenilaian(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'tugas':
        return 'Tugas';
      case 'uts':
        return 'UTS';
      case 'uas':
        return 'UAS';
      case 'praktik':
        return 'Praktik';
      case 'harian':
        return 'Harian';
      default:
        return jenis;
    }
  }
}
