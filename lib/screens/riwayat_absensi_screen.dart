// lib/screens/riwayat_absensi_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../services/siswa_service.dart';
import '../models/absensi.dart';

class RiwayatAbsensiScreen extends StatefulWidget {
  const RiwayatAbsensiScreen({super.key});

  @override
  State<RiwayatAbsensiScreen> createState() => _RiwayatAbsensiScreenState();
}

class _RiwayatAbsensiScreenState extends State<RiwayatAbsensiScreen> {
  final SiswaService _siswaService = SiswaService();
  final ScrollController _scrollController = ScrollController();

  List<Absensi> _absensiList = [];
  Map<String, dynamic>? _statistik;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String? _errorMessage;

  int _currentPage = 1;
  final int _limit = 15;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMoreData = true;
    });

    try {
      // Load riwayat dan statistik secara paralel
      final results = await Future.wait([
        _siswaService.getRiwayatPresensi(page: 1, limit: _limit),
        _siswaService.getStatistikPresensi(),
      ]);

      final riwayatData = results[0];
      final statistikData = results[1];

      setState(() {
        _absensiList = riwayatData['docs'] as List<Absensi>;
        _statistik = statistikData;
        _hasMoreData = riwayatData['hasNextPage'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final riwayatData = await _siswaService.getRiwayatPresensi(
        page: nextPage,
        limit: _limit,
      );

      setState(() {
        _absensiList.addAll(riwayatData['docs'] as List<Absensi>);
        _hasMoreData = riwayatData['hasNextPage'] ?? false;
        _currentPage = nextPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Statistik Header
                  SliverToBoxAdapter(child: _buildStatistikCard()),

                  // List Riwayat
                  if (_absensiList.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == _absensiList.length) {
                              return _buildLoadingMoreIndicator();
                            }
                            return _buildAbsensiCard(
                              _absensiList[index],
                              index,
                            );
                          },
                          childCount:
                              _absensiList.length + (_isLoadingMore ? 1 : 0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistikCard() {
    if (_statistik == null) return const SizedBox();

    final hadir = _statistik!['hadir'] ?? 0;
    final izin = _statistik!['izin'] ?? 0;
    final sakit = _statistik!['sakit'] ?? 0;
    final alpa = _statistik!['alpa'] ?? 0;
    final total = _statistik!['total'] ?? 0;
    final persentaseHadir = _statistik!['persentaseHadir'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistik Kehadiran',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Persentase Hadir - Large Display
          Center(
            child: Column(
              children: [
                Text(
                  '${persentaseHadir.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Tingkat Kehadiran',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Detail Statistik
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Hadir', hadir, Colors.green[300]!),
                    _buildStatItem('Izin', izin, Colors.blue[300]!),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Sakit', sakit, Colors.orange[300]!),
                    _buildStatItem('Alpa', alpa, Colors.red[300]!),
                  ],
                ),
                const Divider(height: 24, color: Colors.white30),
                Text(
                  'Total: $total hari',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Riwayat Absensi',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Riwayat absensi Anda akan muncul di sini',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsensiCard(Absensi absensi, int index) {
    final statusColor = _getStatusColor(absensi.keterangan);
    final statusIcon = _getStatusIcon(absensi.keterangan);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDetailDialog(absensi),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status Badge
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 30),
                ),
                const SizedBox(width: 16),

                // Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        absensi.namaMataPelajaran,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTanggal(absensi.tanggal),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (absensi.waktuMasuk != null)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatWaktu(absensi.waktuMasuk!),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    absensi.keterangan.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Color _getStatusColor(String keterangan) {
    switch (keterangan.toLowerCase()) {
      case 'hadir':
        return Colors.green;
      case 'izin':
        return Colors.blue;
      case 'sakit':
        return Colors.orange;
      case 'alpa':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String keterangan) {
    switch (keterangan.toLowerCase()) {
      case 'hadir':
        return Icons.check_circle;
      case 'izin':
        return Icons.info;
      case 'sakit':
        return Icons.local_hospital;
      case 'alpa':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatTanggal(String tanggal) {
    try {
      final date = DateTime.parse(tanggal);
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return tanggal;
    }
  }

  String _formatWaktu(DateTime waktu) {
    return DateFormat('HH:mm', 'id_ID').format(waktu);
  }

  void _showDetailDialog(Absensi absensi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _getStatusIcon(absensi.keterangan),
              color: _getStatusColor(absensi.keterangan),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Detail Absensi', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Mata Pelajaran', absensi.namaMataPelajaran),
              const Divider(),
              _buildDetailRow('Tanggal', _formatTanggal(absensi.tanggal)),
              const Divider(),
              if (absensi.waktuMasuk != null) ...[
                _buildDetailRow(
                  'Waktu Masuk',
                  _formatWaktu(absensi.waktuMasuk!),
                ),
                const Divider(),
              ],
              _buildDetailRow('Status', absensi.keterangan.toUpperCase()),
              const Divider(),
              _buildDetailRow('Kelas', absensi.namaKelas),
              if (absensi.isManualEntry) ...[
                const Divider(),
                _buildDetailRow('Tipe', 'Input Manual oleh Guru'),
              ],
              if (absensi.isFromQRCode) ...[
                const Divider(),
                _buildDetailRow('Tipe', 'Scan QR Code'),
              ],
              if (absensi.isFromPengajuan) ...[
                const Divider(),
                _buildDetailRow('Tipe', 'Pengajuan Izin/Sakit'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
