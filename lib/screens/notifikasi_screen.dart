// lib/screens/notifikasi_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/siswa_service.dart';
import '../models/notifikasi.dart';
import '../utils/app_theme.dart';
import 'notifikasi_detail_screen.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  final SiswaService _siswaService = SiswaService();
  List<Notifikasi> _notifikasiList = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadNotifikasi();
  }

  Future<void> _loadNotifikasi({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _notifikasiList.clear();
      });
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifikasi = await _siswaService.getNotifikasi(
        page: _currentPage,
        limit: 20,
      );

      setState(() {
        if (refresh) {
          _notifikasiList = notifikasi;
        } else {
          _notifikasiList.addAll(notifikasi);
        }
        _isLoading = false;
        _hasMore = notifikasi.length >= 20;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _markAsRead(String notifikasiId) async {
    try {
      await _siswaService.markNotifikasiAsRead(notifikasiId);

      setState(() {
        final index = _notifikasiList.indexWhere((n) => n.id == notifikasiId);
        if (index != -1) {
          _notifikasiList[index] = Notifikasi(
            id: _notifikasiList[index].id,
            tipe: _notifikasiList[index].tipe,
            judul: _notifikasiList[index].judul,
            pesan: _notifikasiList[index].pesan,
            isRead: true,
            createdAt: _notifikasiList[index].createdAt,
            resourceId: _notifikasiList[index].resourceId,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menandai notifikasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _siswaService.markNotifikasiAsRead('all');

      setState(() {
        _notifikasiList = _notifikasiList.map((n) {
          return Notifikasi(
            id: n.id,
            tipe: n.tipe,
            judul: n.judul,
            pesan: n.pesan,
            isRead: true,
            createdAt: n.createdAt,
            resourceId: n.resourceId,
          );
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi telah ditandai dibaca'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menandai semua notifikasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadMore() {
    if (!_isLoading && _hasMore) {
      setState(() {
        _currentPage++;
      });
      _loadNotifikasi();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifikasiList.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, color: Colors.white, size: 20),
              label: const Text(
                'Tandai Semua',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _buildBody(unreadCount),
    );
  }

  Widget _buildBody(int unreadCount) {
    if (_isLoading && _notifikasiList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _notifikasiList.isEmpty) {
      return _buildErrorView();
    }

    if (_notifikasiList.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: () => _loadNotifikasi(refresh: true),
      child: Column(
        children: [
          // Header dengan counter
          if (unreadCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.accentColor.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$unreadCount notifikasi belum dibaca',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // List notifikasi
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels ==
                    scrollInfo.metrics.maxScrollExtent) {
                  _loadMore();
                }
                return false;
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _notifikasiList.length + (_hasMore ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == _notifikasiList.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return _buildNotifikasiCard(_notifikasiList[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifikasiCard(Notifikasi notifikasi) {
    final icon = _getNotifikasiIcon(notifikasi.tipe);
    final color = _getNotifikasiColor(notifikasi.tipe);

    return Dismissible(
      key: Key(notifikasi.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          _notifikasiList.removeWhere((n) => n.id == notifikasi.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifikasi dihapus'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          if (!notifikasi.isRead) {
            _markAsRead(notifikasi.id);
          }
          // Navigasi ke halaman detail notifikasi
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  NotifikasiDetailScreen(notifikasiId: notifikasi.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: notifikasi.isRead ? Colors.white : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notifikasi.isRead
                  ? Colors.grey[200]!
                  : color.withOpacity(0.3),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notifikasi.judul,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notifikasi.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notifikasi.isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notifikasi.pesan,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(notifikasi.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak Ada Notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda akan menerima notifikasi di sini',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
              'Gagal Memuat Notifikasi',
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
              onPressed: () => _loadNotifikasi(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotifikasiIcon(String tipe) {
    switch (tipe) {
      case 'tugas_baru':
        return Icons.assignment_outlined;
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
        return Colors.orange;
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm', 'id').format(date);
    }
  }
}
