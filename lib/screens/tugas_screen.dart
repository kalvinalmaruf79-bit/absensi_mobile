import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../utils/app_theme.dart';
import '../services/siswa_service.dart';
import '../models/tugas.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen Tugas - Improved dengan Tab Baru
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
    _tabController = TabController(length: 4, vsync: this);
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
      // Load semua status tugas
      final allTugas = await _siswaService.getTugasSiswaByStatus(status: 'all');

      setState(() {
        _allTugas = allTugas;
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

      case 'submitted':
        return _allTugas.where((tugas) {
          final submission = tugas.getSubmissionBySiswa(_currentUserId);
          return submission != null && submission.nilai == null;
        }).toList();

      case 'graded':
        return _allTugas.where((tugas) {
          final submission = tugas.getSubmissionBySiswa(_currentUserId);
          return submission != null && submission.nilai != null;
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
                      color: Colors.white.withValues(alpha: 0.3),
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
                      fontSize: 13,
                    ),
                    isScrollable: true,
                    tabs: [
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.pending_actions, size: 18),
                            const SizedBox(width: 6),
                            Text('Aktif (${_filterTugas('active').length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.upload_file, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Dikumpulkan (${_filterTugas('submitted').length})',
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.grade, size: 18),
                            const SizedBox(width: 6),
                            Text('Dinilai (${_filterTugas('graded').length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.warning, size: 18),
                            const SizedBox(width: 6),
                            Text('Terlambat (${_filterTugas('late').length})'),
                          ],
                        ),
                      ),
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
                  _buildTaskList('submitted'),
                  _buildTaskList('graded'),
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
            Icon(_getEmptyIcon(type), size: 100, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _getEmptyTitle(type),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptySubtitle(type),
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

  IconData _getEmptyIcon(String type) {
    switch (type) {
      case 'submitted':
        return Icons.cloud_upload;
      case 'graded':
        return Icons.check_circle_outline;
      case 'late':
        return Icons.schedule;
      default:
        return Icons.assignment_outlined;
    }
  }

  String _getEmptyTitle(String type) {
    switch (type) {
      case 'active':
        return 'Tidak ada tugas aktif';
      case 'submitted':
        return 'Belum ada tugas dikumpulkan';
      case 'graded':
        return 'Belum ada tugas dinilai';
      case 'late':
        return 'Tidak ada tugas terlambat';
      default:
        return 'Tidak ada data';
    }
  }

  String _getEmptySubtitle(String type) {
    switch (type) {
      case 'active':
        return 'Tugas yang perlu dikumpulkan akan muncul di sini';
      case 'submitted':
        return 'Tugas yang sudah dikumpulkan tapi belum dinilai';
      case 'graded':
        return 'Tugas yang sudah dinilai akan muncul di sini';
      case 'late':
        return 'Jangan sampai terlambat mengumpulkan tugas!';
      default:
        return '';
    }
  }

  Widget _buildTaskCard(Tugas tugas, String type) {
    final submission = tugas.getSubmissionBySiswa(_currentUserId);
    final daysUntilDeadline = tugas.deadline.difference(DateTime.now()).inDays;

    String priority = 'low';
    if (daysUntilDeadline <= 2 && !tugas.isDeadlinePassed) {
      priority = 'high';
    } else if (daysUntilDeadline <= 5 && !tugas.isDeadlinePassed) {
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
            color: Colors.black.withValues(alpha: 0.05),
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
                    if (type == 'active')
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          priorityIcon,
                          color: priorityColor,
                          size: 20,
                        ),
                      ),
                    if (type == 'submitted')
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.pending,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                    if (type == 'graded')
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 20,
                        ),
                      ),
                    if (type == 'late')
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.warning,
                          color: AppTheme.errorColor,
                          size: 20,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tugas.judul,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
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
                    if (type == 'graded' && submission?.nilai != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getNilaiColor(submission!.nilai!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${submission.nilai}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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
                    if (type == 'submitted' && submission != null)
                      TextButton.icon(
                        onPressed: () => _reuploadTugas(tugas),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Ubah'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
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

  Color _getNilaiColor(double nilai) {
    if (nilai >= 85) return AppTheme.successColor;
    if (nilai >= 75) return Colors.blue;
    if (nilai >= 60) return Colors.orange;
    return AppTheme.errorColor;
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
                          color: AppTheme.primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
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
                            color: submission.nilai != null
                                ? AppTheme.successColor.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: submission.nilai != null
                                  ? AppTheme.successColor.withValues(alpha: 0.3)
                                  : Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    submission.nilai != null
                                        ? Icons.check_circle
                                        : Icons.pending,
                                    color: submission.nilai != null
                                        ? AppTheme.successColor
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    submission.nilai != null
                                        ? 'Sudah Dinilai'
                                        : 'Menunggu Penilaian',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: submission.nilai != null
                                          ? AppTheme.successColor
                                          : Colors.orange,
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
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _getNilaiColor(
                                          submission.nilai!,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.grade,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Nilai Anda',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          '${submission.nilai}',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: _getNilaiColor(
                                              submission.nilai!,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (submission.feedback != null &&
                                    submission.feedback!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.comment,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Feedback Guru:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          submission.feedback!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ] else ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 18,
                                        color: Colors.blue[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Anda masih bisa mengubah jawaban sebelum dinilai',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                      if (type == 'submitted' && submission != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _reuploadTugas(tugas);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Ubah Jawaban'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result == null) return;

      final platformFile = result.files.single;

      if (platformFile.path == null || platformFile.path!.isEmpty) {
        if (!mounted) return;
        _showErrorSnackBar('Tidak dapat membaca file. Coba lagi.');
        return;
      }

      final file = File(platformFile.path!);

      if (!await file.exists()) {
        if (!mounted) return;
        _showErrorSnackBar('File tidak ditemukan.');
        return;
      }

      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

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

      final message = await _siswaService.submitTugas(
        tugasId: tugas.id,
        file: file,
      );

      if (!mounted) return;
      Navigator.pop(context);

      _showSuccessSnackBar(message);
      await _loadTugasData();
    } catch (e) {
      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      String errorMessage = e.toString().replaceAll('Exception: ', '');

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

  Future<void> _reuploadTugas(Tugas tugas) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Jawaban?'),
        content: const Text(
          'Apakah Anda yakin ingin mengubah jawaban tugas ini? File lama akan diganti dengan file baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Ubah'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result == null) return;

      final platformFile = result.files.single;

      if (platformFile.path == null || platformFile.path!.isEmpty) {
        if (!mounted) return;
        _showErrorSnackBar('Tidak dapat membaca file. Coba lagi.');
        return;
      }

      final file = File(platformFile.path!);

      if (!await file.exists()) {
        if (!mounted) return;
        _showErrorSnackBar('File tidak ditemukan.');
        return;
      }

      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

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
                      'Mengubah jawaban tugas...',
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

      final message = await _siswaService.resubmitTugas(
        tugasId: tugas.id,
        file: file,
      );

      if (!mounted) return;
      Navigator.pop(context);

      _showSuccessSnackBar(message);
      await _loadTugasData();
    } catch (e) {
      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      String errorMessage = e.toString().replaceAll('Exception: ', '');

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
        errorMessage = 'Tugas tidak ditemukan atau belum pernah dikumpulkan.';
      } else if (errorMessage.contains('413')) {
        errorMessage = 'Ukuran file terlalu besar. Maksimal 20MB.';
      } else if (errorMessage.contains('sudah dinilai')) {
        errorMessage = 'Tugas sudah dinilai, tidak dapat diubah lagi.';
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
