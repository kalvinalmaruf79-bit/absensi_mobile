// lib/screens/absensi_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../services/absensi_service.dart';
import '../models/absensi.dart';
import '../utils/app_theme.dart';
import '../helpers/location_helper.dart';

class AbsensiScreen extends StatefulWidget {
  const AbsensiScreen({super.key});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  final AbsensiService _absensiService = AbsensiService();

  bool _isLoadingHistory = false;
  bool _isCheckingLocation = false;
  List<Absensi> _todayAbsensi = [];
  Position? _currentPosition;
  String? _locationError;
  bool _locationWarning = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _checkLocationPermission();
    await _loadTodayHistory();
  }

  // ==================== LOCATION HANDLING ====================

  Future<void> _checkLocationPermission() async {
    setState(() {
      _isCheckingLocation = true;
      _locationError = null;
      _locationWarning = false;
    });

    final result = await LocationHelper.checkAndGetLocation();

    setState(() {
      _isCheckingLocation = false;

      if (result.success && result.hasPosition) {
        _currentPosition = result.position;
        if (result.isWarning) {
          _locationWarning = true;
          _locationError = result.errorMessage;
        }
      } else {
        _locationError = result.errorMessage;
      }
    });
  }

  // ==================== LOAD HISTORY ====================

  Future<void> _loadTodayHistory() async {
    setState(() => _isLoadingHistory = true);

    try {
      final response = await _absensiService.getRiwayatPresensi(
        page: 1,
        limit: 50,
      );

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayList = response.docs
          .where((abs) => abs.tanggal == today)
          .toList();

      setState(() {
        _todayAbsensi = todayList;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
      if (mounted) {
        _showErrorSnackbar('Gagal memuat riwayat: ${e.toString()}');
      }
    }
  }

  // ==================== QR SCANNER ====================

  Future<void> _openQRScanner() async {
    if (_currentPosition == null) {
      if (_locationError != null && _locationError!.contains('permanen')) {
        _showPermissionDialog();
      } else {
        _showErrorDialog(
          'Lokasi Belum Tersedia',
          'Mohon tunggu hingga lokasi Anda terdeteksi, atau coba refresh lokasi.',
        );
      }
      return;
    }

    if (!_currentPosition!.isAccuracyGood && !_locationWarning) {
      final proceed = await _showAccuracyWarningDialog();
      if (!proceed) return;
    }

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null && result.isNotEmpty) {
      await _processCheckIn(result);
    }
  }

  Future<bool> _showAccuracyWarningDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning, color: AppTheme.accentColor),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Akurasi Kurang Baik')),
              ],
            ),
            content: Text(
              'Akurasi GPS Anda: ${_currentPosition!.accuracy.toStringAsFixed(1)}m\n\n'
              'Presensi mungkin gagal jika Anda di luar radius. '
              'Disarankan menunggu hingga akurasi < 20m.\n\n'
              'Lanjutkan presensi?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Lanjutkan'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Izin Lokasi Diperlukan'),
        content: const Text(
          'Aplikasi memerlukan akses lokasi untuk presensi.\n\n'
          'Buka pengaturan untuk mengaktifkan izin lokasi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await LocationHelper.openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  // ==================== MANUAL CODE INPUT ====================

  Future<void> _openManualCodeInput() async {
    final TextEditingController codeController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.password, color: AppTheme.accentColor),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Input Kode Absensi')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan kode absensi yang diberikan oleh guru:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Contoh: ABC123',
                prefixIcon: const Icon(Icons.vpn_key),
                filled: true,
                fillColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context);
                  _processCheckInWithCode(value);
                }
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Pastikan kode yang Anda masukkan sesuai dengan yang ditampilkan guru.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              codeController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.isNotEmpty) {
                Navigator.pop(context);
                _processCheckInWithCode(codeController.text);
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  // ==================== CHECK-IN PROCESS ====================

  Future<void> _processCheckIn(String kodeSesi) async {
    if (_currentPosition == null) {
      _showErrorSnackbar('Lokasi tidak tersedia');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              const Text(
                'Memproses presensi...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final message = await _absensiService.checkIn(
        kodeSesi,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (mounted) Navigator.pop(context);

      if (mounted) {
        _showSuccessDialog(message);
        await _loadTodayHistory();
      }
    } on AbsensiException catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        if (e.isValidationError || e.isForbiddenError) {
          _showErrorDialog('Presensi Gagal', e.message);
        } else if (e.isNetworkError) {
          _showErrorDialog('Koneksi Bermasalah', e.message);
        } else {
          _showErrorSnackbar(e.message);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        _showErrorSnackbar('Terjadi kesalahan: ${e.toString()}');
      }
    }
  }

  Future<void> _processCheckInWithCode(String kodeAbsen) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              const Text(
                'Memproses presensi...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final message = await _absensiService.checkInWithCode(kodeAbsen);

      if (mounted) Navigator.pop(context);

      if (mounted) {
        _showSuccessDialog(message);
        await _loadTodayHistory();
      }
    } on AbsensiException catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        if (e.isValidationError || e.isForbiddenError) {
          _showErrorDialog('Presensi Gagal', e.message);
        } else if (e.isNetworkError) {
          _showErrorDialog('Koneksi Bermasalah', e.message);
        } else {
          _showErrorSnackbar(e.message);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        _showErrorSnackbar('Terjadi kesalahan: ${e.toString()}');
      }
    }
  }

  // ==================== UI HELPERS ====================

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Berhasil!')),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error,
                color: AppTheme.errorColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await _checkLocationPermission();
          await _loadTodayHistory();
        },
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildLocationStatus(),
                  const SizedBox(height: 20),
                  _buildCheckinOptions(),
                  const SizedBox(height: 24),
                  _buildTodayHistory(),
                  const SizedBox(height: 24),
                  _buildQuickStats(),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Presensi',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationStatus() {
    if (_isCheckingLocation) {
      return _buildStatusCard(
        icon: Icons.location_searching,
        title: 'Mencari Lokasi...',
        subtitle: 'Mohon tunggu sebentar',
        color: AppTheme.accentColor,
        trailing: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_locationError != null && !_locationWarning) {
      return _buildStatusCard(
        icon: Icons.location_off,
        title: 'Lokasi Tidak Tersedia',
        subtitle: _locationError!,
        color: AppTheme.errorColor,
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _checkLocationPermission,
          color: AppTheme.errorColor,
        ),
      );
    }

    if (_currentPosition != null) {
      final accuracyStatus = _currentPosition!.accuracyStatus;
      final isGood = _currentPosition!.isAccuracyGood;

      return _buildStatusCard(
        icon: isGood ? Icons.location_on : Icons.location_searching,
        title: 'Lokasi Terdeteksi',
        subtitle:
            'Akurasi: ${_currentPosition!.accuracy.toStringAsFixed(1)}m ($accuracyStatus)',
        color: isGood ? AppTheme.successColor : AppTheme.accentColor,
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _checkLocationPermission,
          color: isGood ? AppTheme.successColor : AppTheme.accentColor,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildCheckinOptions() {
    return Column(
      children: [
        _buildCheckinButton(
          icon: Icons.qr_code_scanner,
          title: 'Scan QR Code',
          subtitle: 'Scan kode QR dari guru',
          onPressed: _openQRScanner,
          color: AppTheme.primaryColor,
          enabled: _currentPosition != null && _locationError == null,
        ),
        const SizedBox(height: 12),
        _buildCheckinButton(
          icon: Icons.vpn_key,
          title: 'Input Kode Manual',
          subtitle: 'Masukkan kode absensi manual',
          onPressed: _openManualCodeInput,
          color: AppTheme.accentColor,
          enabled: true,
        ),
      ],
    );
  }

  Widget _buildCheckinButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    required Color color,
    required bool enabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey[400]!, Colors.grey[500]!],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: enabled
                ? color.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Hari Ini',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (_isLoadingHistory)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_todayAbsensi.isEmpty && !_isLoadingHistory)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada presensi hari ini',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._todayAbsensi.map((absensi) => _buildHistoryItem(absensi)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Absensi absensi) {
    final color = _getStatusColor(absensi.keterangan);
    final icon = _getStatusIcon(absensi.keterangan);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  absensi.namaMataPelajaran,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      absensi.waktuMasuk != null
                          ? DateFormat('HH:mm').format(absensi.waktuMasuk!)
                          : 'Manual',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    if (absensi.isManualEntry) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Manual',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              absensi.keterangan.toUpperCase(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final hadir = _todayAbsensi.where((a) => a.keterangan == 'hadir').length;
    final izin = _todayAbsensi.where((a) => a.keterangan == 'izin').length;
    final sakit = _todayAbsensi.where((a) => a.keterangan == 'sakit').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Hari Ini',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle,
                  label: 'Hadir',
                  value: hadir.toString(),
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.event_note,
                  label: 'Izin',
                  value: izin.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_hospital,
                  label: 'Sakit',
                  value: sakit.toString(),
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return AppTheme.successColor;
      case 'izin':
        return Colors.blue;
      case 'sakit':
        return AppTheme.accentColor;
      case 'alpa':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return Icons.check_circle;
      case 'izin':
        return Icons.event_note;
      case 'sakit':
        return Icons.local_hospital;
      case 'alpa':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}

// ==================== QR SCANNER SCREEN ====================

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _hasScanned = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() => _hasScanned = true);
        Navigator.pop(context, code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code Presensi'),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: () {
              cameraController.toggleTorch();
              setState(() {});
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(controller: cameraController, onDetect: _onDetect),

          // Overlay dengan cutout
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Frame border
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Corner indicators
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),
                ],
              ),
            ),
          ),

          // Instruksi
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Arahkan kamera ke QR Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'yang ditampilkan oleh guru',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y < 0
                ? BorderSide(color: AppTheme.primaryColor, width: 4)
                : BorderSide.none,
            bottom: alignment.y > 0
                ? BorderSide(color: AppTheme.primaryColor, width: 4)
                : BorderSide.none,
            left: alignment.x < 0
                ? BorderSide(color: AppTheme.primaryColor, width: 4)
                : BorderSide.none,
            right: alignment.x > 0
                ? BorderSide(color: AppTheme.primaryColor, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
