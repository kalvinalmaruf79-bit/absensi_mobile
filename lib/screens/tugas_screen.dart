import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../utils/app_theme.dart';
import '../services/siswa_service.dart';
import '../models/tugas.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen Tugas - Terintegrasi dengan Backend
class TugasScreen extends StatefulWidget {
  const TugasScreen({super.key});

  @override
  State<TugasScreen> createState() => _TugasScreenState();
}

class _TugasScreenState extends State<TugasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SiswaService _siswaService = SiswaService();

  List<Tugas> _allTugas = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
    _loadTugasData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load user ID dari SharedPreferences
  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      setState(() {
        _currentUserId = userId;
      });
    } catch (e) {
      print('Error loading user ID: $e');
    }
  }

  Future<void> _loadTugasData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashboardData = await _siswaService.getDashboard();
      final tugasMendatang = dashboardData['tugasMendatang'] as List<dynamic>?;

      if (tugasMendatang != null) {
        _allTugas = tugasMendatang.map((json) => Tugas.fromJson(json)).toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  List<Tugas> _filterTugas(String type) {
    switch (type) {
      case 'active':
        return _allTugas.where((tugas) {
          return !tugas.isDeadlinePassed &&
              !tugas.hasSubmittedBy(_currentUserId);
        }).toList();

      case 'completed':
        return _allTugas.where((tugas) {
          return tugas.hasSubmittedBy(_currentUserId);
        }).toList();

      case 'late':
        return _allTugas.where((tugas) {
          return tugas.isDeadlinePassed &&
              !tugas.hasSubmittedBy(_currentUserId);
        }).toList();

      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Tugas & PR',
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
                      Icons.assignment,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: AppTheme.primaryColor,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.accentColor,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Aktif'),
                      Tab(text: 'Selesai'),
                      Tab(text: 'Terlambat'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorWidget()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskList('active'),
                  _buildTaskList('completed'),
                  _buildTaskList('late'),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadTugasData,
        backgroundColor: AppTheme.accentColor,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
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
            Icon(Icons.error_outline, size: 80, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTugasData,
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

  Widget _buildTaskList(String type) {
    final tasks = _filterTugas(type);

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'completed'
                  ? Icons.check_circle_outline
                  : Icons.assignment_outlined,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'active'
                  ? 'Tidak ada tugas aktif'
                  : type == 'completed'
                  ? 'Belum ada tugas selesai'
                  : 'Tidak ada tugas terlambat',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'active'
                  ? 'Tugas akan muncul di sini'
                  : type == 'completed'
                  ? 'Tugas yang sudah dikumpulkan akan muncul di sini'
                  : 'Jangan sampai terlambat mengumpulkan tugas!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTugasData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return _buildTaskCard(tasks[index], type);
        },
      ),
    );
  }

  Widget _buildTaskCard(Tugas tugas, String type) {
    final daysUntilDeadline = tugas.deadline.difference(DateTime.now()).inDays;
    String priority = 'low';
    if (daysUntilDeadline <= 2) {
      priority = 'high';
    } else if (daysUntilDeadline <= 5) {
      priority = 'medium';
    }

    Color priorityColor = priority == 'high'
        ? AppTheme.errorColor
        : priority == 'medium'
        ? AppTheme.accentColor
        : AppTheme.successColor;

    IconData priorityIcon = priority == 'high'
        ? Icons.priority_high
        : priority == 'medium'
        ? Icons.remove
        : Icons.arrow_downward;

    final deadlineStr = DateFormat(
      'dd MMM yyyy, HH:mm',
      'id',
    ).format(tugas.deadline);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTaskDetail(context, tugas, type),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(priorityIcon, color: priorityColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tugas.judul,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: type == 'completed'
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tugas.namaMataPelajaran,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (type == 'completed')
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.successColor,
                        size: 28,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tugas.deskripsi,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: type == 'late'
                          ? AppTheme.errorColor
                          : AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Deadline: $deadlineStr',
                        style: TextStyle(
                          fontSize: 12,
                          color: type == 'late'
                              ? AppTheme.errorColor
                              : Colors.grey[700],
                          fontWeight: type == 'late'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (type == 'active')
                      TextButton.icon(
                        onPressed: () => _uploadTugas(tugas),
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: const Text('Upload'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accentColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
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
    );
  }

  void _showTaskDetail(BuildContext context, Tugas tugas, String type) {
    final submission = tugas.getSubmissionBySiswa(_currentUserId);
    final deadlineStr = DateFormat(
      'dd MMMM yyyy, HH:mm',
      'id',
    ).format(tugas.deadline);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tugas.judul,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              Icons.class_,
                              'Mata Pelajaran',
                              tugas.namaMataPelajaran,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.person,
                              'Guru',
                              tugas.namaGuru,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.calendar_today,
                              'Deadline',
                              deadlineStr,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.schedule,
                              'Semester',
                              '${tugas.semester} - ${tugas.tahunAjaran}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Deskripsi:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tugas.deskripsi,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                      if (submission != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.successColor.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.successColor,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Sudah Dikumpulkan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.successColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'File: ${submission.fileName}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dikumpulkan: ${DateFormat('dd MMM yyyy, HH:mm', 'id').format(submission.submittedAt)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                              if (submission.nilai != null) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.grade,
                                      color: AppTheme.accentColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Nilai: ${submission.nilai}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                                if (submission.feedback != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Feedback: ${submission.feedback}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (type == 'active')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _uploadTugas(tugas);
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Tugas'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Text(
                '$label: ',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _uploadTugas(Tugas tugas) async {
    try {
      // Pick file dengan validasi extension
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result == null) {
        // User cancelled
        return;
      }

      final platformFile = result.files.single;

      // Validasi file path
      if (platformFile.path == null || platformFile.path!.isEmpty) {
        if (!mounted) return;
        _showErrorSnackBar('Tidak dapat membaca file. Coba lagi.');
        return;
      }

      final file = File(platformFile.path!);

      // Check if file exists
      if (!await file.exists()) {
        if (!mounted) return;
        _showErrorSnackBar('File tidak ditemukan.');
        return;
      }

      // Check file size
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      print('File selected: ${platformFile.name}');
      print('File size: ${fileSizeMB.toStringAsFixed(2)} MB');

      if (fileSize > 20 * 1024 * 1024) {
        if (!mounted) return;
        _showErrorSnackBar(
          'Ukuran file terlalu besar (${fileSizeMB.toStringAsFixed(1)} MB). Maksimal 20 MB.',
        );
        return;
      }

      if (fileSize == 0) {
        if (!mounted) return;
        _showErrorSnackBar('File kosong atau rusak.');
        return;
      }

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      'Mengunggah tugas...',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      platformFile.name,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Upload
      final message = await _siswaService.submitTugas(
        tugasId: tugas.id,
        file: file,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show success message
      _showSuccessSnackBar(message);

      // Reload data
      await _loadTugasData();
    } catch (e) {
      print('Upload error: $e');

      if (!mounted) return;

      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Parse and show error message
      String errorMessage = e.toString().replaceAll('Exception: ', '');

      // Customize error messages
      if (errorMessage.contains('401')) {
        errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
      } else if (errorMessage.contains('SocketException') ||
          errorMessage.contains('NetworkException')) {
        errorMessage = 'Tidak ada koneksi internet. Periksa koneksi Anda.';
      } else if (errorMessage.contains('TimeoutException') ||
          errorMessage.contains('timeout')) {
        errorMessage =
            'Upload timeout. Coba lagi atau gunakan file yang lebih kecil.';
      } else if (errorMessage.contains('404')) {
        errorMessage = 'Tugas tidak ditemukan.';
      } else if (errorMessage.contains('413')) {
        errorMessage = 'Ukuran file terlalu besar. Maksimal 20MB.';
      }

      _showErrorSnackBar(errorMessage);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
