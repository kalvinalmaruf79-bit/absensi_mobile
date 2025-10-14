// lib/screens/notifikasi_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/siswa_service.dart';
import '../utils/app_theme.dart';

class NotifikasiDetailScreen extends StatefulWidget {
  final String notifikasiId;

  const NotifikasiDetailScreen({super.key, required this.notifikasiId});

  @override
  State<NotifikasiDetailScreen> createState() => _NotifikasiDetailScreenState();
}

class _NotifikasiDetailScreenState extends State<NotifikasiDetailScreen> {
  final SiswaService _siswaService = SiswaService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _detailData;

  @override
  void initState() {
    super.initState();
    _loadDetailNotifikasi();
  }

  Future<void> _loadDetailNotifikasi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _siswaService.getDetailNotifikasi(widget.notifikasiId);
      setState(() {
        _detailData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Notifikasi'), centerTitle: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_detailData == null) {
      return const Center(child: Text('Data tidak ditemukan'));
    }

    final notifikasiData = _detailData!['notifikasi'];
    final detailResource = _detailData!['detailResource'];

    final tipe = notifikasiData['tipe'] as String;
    final judul = notifikasiData['judul'] as String;
    final pesan = notifikasiData['pesan'] as String;
    final createdAt = DateTime.parse(notifikasiData['createdAt']);

    final icon = _getNotifikasiIcon(tipe);
    final color = _getNotifikasiColor(tipe);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan icon dan tipe
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 48),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getTipeLabel(tipe),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Konten utama
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul
                Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Waktu
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(createdAt),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Divider
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 24),

                // Pesan
                const Text(
                  'Pesan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    pesan,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[800],
                      height: 1.6,
                    ),
                  ),
                ),

                // Detail Resource jika ada
                if (detailResource != null) ...[
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 24),
                  _buildDetailResource(detailResource, color),
                ],

                const SizedBox(height: 32),

                // Tombol aksi
                if (detailResource != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _handleNavigateToResource(detailResource);
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: Text(_getActionLabel(tipe)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailResource(
    Map<String, dynamic> detailResource,
    Color color,
  ) {
    final type = detailResource['type'] as String;
    final data = detailResource['data'] as Map<String, dynamic>;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                'Detail ${_getResourceTypeLabel(type)}',
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildResourceDetails(type, data),
        ],
      ),
    );
  }

  List<Widget> _buildResourceDetails(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'tugas':
        return [
          _buildDetailRow('Judul', data['judul']),
          _buildDetailRow('Mata Pelajaran', data['mataPelajaran']?['nama']),
          _buildDetailRow('Guru', data['guru']?['name']),
          _buildDetailRow(
            'Deadline',
            data['deadline'] != null
                ? DateFormat(
                    'dd MMM yyyy, HH:mm',
                    'id',
                  ).format(DateTime.parse(data['deadline']))
                : '-',
          ),
          if (data['deskripsi'] != null &&
              data['deskripsi'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Deskripsi:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data['deskripsi'].toString(),
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ];

      case 'nilai':
        return [
          _buildDetailRow('Mata Pelajaran', data['mataPelajaran']?['nama']),
          _buildDetailRow('Jenis Penilaian', data['jenisPenilaian']),
          _buildDetailRow('Nilai', data['nilai']?.toString()),
          _buildDetailRow('Guru', data['guru']?['name']),
          if (data['tugas'] != null)
            _buildDetailRow('Tugas', data['tugas']?['judul']),
          if (data['catatan'] != null &&
              data['catatan'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Catatan:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data['catatan'].toString(),
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ];

      case 'pengumuman':
        return [
          _buildDetailRow('Judul', data['judul']),
          if (data['kategori'] != null)
            _buildDetailRow('Kategori', data['kategori']),
          if (data['prioritas'] != null)
            _buildDetailRow('Prioritas', data['prioritas']),
          _buildDetailRow('Pembuat', data['pembuat']?['name']),
          if (data['konten'] != null &&
              data['konten'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Konten:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data['konten'].toString(),
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ];

      case 'jadwal':
        return [
          _buildDetailRow('Mata Pelajaran', data['mataPelajaran']?['nama']),
          _buildDetailRow('Guru', data['guru']?['name']),
          if (data['hari'] != null)
            _buildDetailRow('Hari', data['hari'].toString().toUpperCase()),
          if (data['jamMulai'] != null && data['jamSelesai'] != null)
            _buildDetailRow(
              'Waktu',
              '${data['jamMulai']} - ${data['jamSelesai']}',
            ),
        ];

      default:
        return [
          Text(
            'Detail tidak tersedia',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ];
    }
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 13)),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Detail',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDetailNotifikasi,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigateToResource(Map<String, dynamic> detailResource) {
    final type = detailResource['type'] as String;
    final data = detailResource['data'] as Map<String, dynamic>;
    final resourceId = data['_id'] as String?;

    if (resourceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID resource tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Implementasi navigasi berdasarkan tipe resource
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigasi ke $type: $resourceId'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _getResourceTypeLabel(String type) {
    switch (type) {
      case 'tugas':
        return 'Tugas';
      case 'nilai':
        return 'Nilai';
      case 'pengumuman':
        return 'Pengumuman';
      case 'jadwal':
        return 'Jadwal';
      default:
        return 'Resource';
    }
  }

  String _getTipeLabel(String tipe) {
    switch (tipe) {
      case 'tugas_baru':
        return 'TUGAS BARU';
      case 'tugas_diubah':
        return 'TUGAS DIPERBARUI';
      case 'tugas_dihapus':
        return 'TUGAS DIHAPUS';
      case 'nilai_baru':
        return 'NILAI BARU';
      case 'pengumuman_baru':
        return 'PENGUMUMAN';
      case 'pengingat_presensi':
        return 'PENGINGAT';
      case 'presensi_alpa':
        return 'PERINGATAN';
      default:
        return 'NOTIFIKASI';
    }
  }

  String _getActionLabel(String tipe) {
    switch (tipe) {
      case 'tugas_baru':
      case 'tugas_diubah':
        return 'Lihat Detail Tugas';
      case 'nilai_baru':
        return 'Lihat Nilai';
      case 'pengumuman_baru':
        return 'Baca Pengumuman';
      case 'pengingat_presensi':
        return 'Buka Presensi';
      case 'presensi_alpa':
        return 'Lihat Riwayat Presensi';
      default:
        return 'Lihat Detail';
    }
  }

  IconData _getNotifikasiIcon(String tipe) {
    switch (tipe) {
      case 'tugas_baru':
        return Icons.assignment_outlined;
      case 'tugas_diubah':
        return Icons.edit_outlined;
      case 'tugas_dihapus':
        return Icons.delete_outline;
      case 'nilai_baru':
        return Icons.grade_outlined;
      case 'pengumuman_baru':
        return Icons.campaign_outlined;
      case 'pengingat_presensi':
        return Icons.alarm_outlined;
      case 'presensi_alpa':
        return Icons.warning_amber_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotifikasiColor(String tipe) {
    switch (tipe) {
      case 'tugas_baru':
      case 'tugas_diubah':
        return Colors.orange;
      case 'tugas_dihapus':
        return Colors.red;
      case 'nilai_baru':
        return Colors.blue;
      case 'pengumuman_baru':
        return Colors.purple;
      case 'pengingat_presensi':
        return Colors.green;
      case 'presensi_alpa':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin, ${DateFormat('HH:mm', 'id').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return DateFormat('EEEE, dd MMMM yyyy • HH:mm', 'id').format(date);
    }
  }
}
