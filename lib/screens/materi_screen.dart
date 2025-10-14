// lib/screens/materi_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import '../utils/app_theme.dart';
import '../models/materi.dart';
import '../services/materi_service.dart';
import '../helpers/materi_helper.dart';

class MateriScreen extends StatefulWidget {
  const MateriScreen({super.key});

  @override
  State<MateriScreen> createState() => _MateriScreenState();
}

class _MateriScreenState extends State<MateriScreen> {
  final MateriService _materiService = MateriService();

  List<Materi> _allMateri = [];
  List<Materi> _filteredMateri = [];
  List<MateriMataPelajaran> _mataPelajaranList = [];

  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedMataPelajaranId;
  String _searchQuery = '';
  String _sortBy = 'terbaru'; // terbaru, terlama, nama

  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadMateri();
  }

  Future<void> _loadMateri({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _allMateri.clear();
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _materiService.getMateriSiswa(
        page: _currentPage,
        limit: 10,
        mataPelajaranId: _selectedMataPelajaranId,
      );

      setState(() {
        if (_currentPage == 1) {
          _allMateri = response['docs'] as List<Materi>;
        } else {
          _allMateri.addAll(response['docs'] as List<Materi>);
        }

        _hasMore = response['hasNextPage'] as bool;

        // Extract mata pelajaran list
        _mataPelajaranList = MateriHelper.getUniqueMataPelajaran(_allMateri);

        _applyFiltersAndSort();
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    List<Materi> result = List.from(_allMateri);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      result = _materiService.searchMateri(result, _searchQuery);
    }

    // Sort
    if (_sortBy == 'terbaru') {
      result = _materiService.sortMateriByDate(result, ascending: false);
    } else if (_sortBy == 'terlama') {
      result = _materiService.sortMateriByDate(result, ascending: true);
    } else if (_sortBy == 'nama') {
      result.sort((a, b) => a.judul.compareTo(b.judul));
    }

    setState(() {
      _filteredMateri = result;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadMateri();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materi Pembelajaran'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filter & Urutkan',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadMateri(isRefresh: true),
        child: Column(
          children: [
            _buildHeader(colorScheme),
            _buildSearchBar(theme),
            Expanded(child: _buildContent(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    final stats = _materiService.getMateriStatistics(_allMateri);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.folder,
              label: 'Total',
              value: stats['totalMateri'].toString(),
            ),
            _buildStatItem(
              icon: Icons.attach_file,
              label: 'File',
              value: stats['totalFiles'].toString(),
            ),
            _buildStatItem(
              icon: Icons.link,
              label: 'Link',
              value: stats['totalLinks'].toString(),
            ),
            _buildStatItem(
              icon: Icons.new_releases,
              label: 'Baru',
              value: stats['newMateri'].toString(),
            ),
          ],
        ),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari materi...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _applyFiltersAndSort();
                    });
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFiltersAndSort();
          });
        },
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredMateri.isEmpty) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredMateri.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredMateri.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return _buildMateriCard(_filteredMateri[index], theme);
        },
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
            Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Materi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadMateri(isRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Tidak ada hasil pencarian'
                : 'Belum ada materi',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _applyFiltersAndSort();
                });
              },
              child: const Text('Hapus Pencarian'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMateriCard(Materi materi, ThemeData theme) {
    final isNew = _materiService.isNewMateri(materi);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showMateriDetail(materi),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon mata pelajaran
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.book,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info materi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                materi.judul,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isNew)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'BARU',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          materi.mataPelajaran.nama,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Deskripsi
              Text(
                materi.deskripsi,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // File dan Link badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (materi.hasFiles)
                    _buildBadge(
                      icon: Icons.attach_file,
                      label: '${materi.totalFiles} File',
                      color: Colors.blue,
                    ),
                  if (materi.hasLinks)
                    _buildBadge(
                      icon: Icons.link,
                      label: '${materi.totalLinks} Link',
                      color: Colors.green,
                    ),
                ],
              ),
              const Divider(height: 24),
              // Footer info
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      materi.guru.name,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    materi.formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showMateriDetail(Materi materi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _MateriDetailSheet(materi: materi, materiService: _materiService),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Filter & Urutkan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  // Mata Pelajaran Filter
                  const Text(
                    'Mata Pelajaran',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedMataPelajaranId,
                      decoration: InputDecoration(
                        hintText: 'Semua Mata Pelajaran',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      dropdownColor: Colors.white,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.primaryColor,
                      ),
                      selectedItemBuilder: (BuildContext context) {
                        return [
                          const Text('Semua Mata Pelajaran'),
                          ..._mataPelajaranList.map(
                            (mapel) => Text(mapel.nama),
                          ),
                        ];
                      },
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Row(
                            children: [
                              if (_selectedMataPelajaranId == null)
                                Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              if (_selectedMataPelajaranId == null)
                                const SizedBox(width: 8),
                              Text(
                                'Semua Mata Pelajaran',
                                style: TextStyle(
                                  color: _selectedMataPelajaranId == null
                                      ? AppTheme.primaryColor
                                      : Colors.black87,
                                  fontWeight: _selectedMataPelajaranId == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._mataPelajaranList.map((mapel) {
                          final isSelected =
                              _selectedMataPelajaranId == mapel.id;
                          return DropdownMenuItem<String>(
                            value: mapel.id,
                            child: Row(
                              children: [
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                if (isSelected) const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    mapel.nama,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.black87,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          _selectedMataPelajaranId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Sort By
                  const Text(
                    'Urutkan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(
                          'Terbaru',
                          style: TextStyle(
                            color: _sortBy == 'terbaru'
                                ? Colors.white
                                : AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: _sortBy == 'terbaru',
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: AppTheme.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        side: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1.5,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            _sortBy = 'terbaru';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text(
                          'Terlama',
                          style: TextStyle(
                            color: _sortBy == 'terlama'
                                ? Colors.white
                                : AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: _sortBy == 'terlama',
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: AppTheme.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        side: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1.5,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            _sortBy = 'terlama';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text(
                          'Nama A-Z',
                          style: TextStyle(
                            color: _sortBy == 'nama'
                                ? Colors.white
                                : AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: _sortBy == 'nama',
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: AppTheme.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        side: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1.5,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            _sortBy = 'nama';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _loadMateri(isRefresh: true);
                        });
                      },
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Detail Sheet Widget
class _MateriDetailSheet extends StatelessWidget {
  final Materi materi;
  final MateriService materiService;

  const _MateriDetailSheet({required this.materi, required this.materiService});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Icon dan badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.book,
                          color: AppTheme.primaryColor,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              materi.mataPelajaran.nama,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              materi.kelas.nama,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Judul
                  Text(
                    materi.judul,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 32),
                  // Info detail
                  _buildInfoRow(Icons.person, 'Pengajar', materi.guru.name),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Diunggah',
                    materi.formattedDate,
                  ),
                  const SizedBox(height: 16),
                  // Deskripsi
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    materi.deskripsi,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Files
                  if (materi.hasFiles) ...[
                    const Text(
                      'File Materi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...materi.files.map(
                      (file) => _buildFileItem(context, file),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Links
                  if (materi.hasLinks) ...[
                    const Text(
                      'Link Referensi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...materi.links.map(
                      (link) => _buildLinkItem(context, link),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, MateriFile file) {
    final icon = _getFileIcon(file.fileExtension);
    final color = _getFileColor(file.fileExtension);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          file.fileName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          file.fileExtension.toUpperCase(),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => _downloadFile(context, file),
        ),
      ),
    );
  }

  Widget _buildLinkItem(BuildContext context, MateriLink link) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: const Icon(Icons.link, color: Colors.blue, size: 20),
        ),
        title: Text(
          link.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          link.url,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.open_in_new, size: 20),
        onTap: () => _openLink(context, link.url),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Request storage permission dengan support Android 13+
  Future<bool> _requestStoragePermission(BuildContext context) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      // Android 13+ (API 33+) tidak perlu permission storage
      if (androidInfo.version.sdkInt >= 33) {
        return true;
      }

      // Android 11-12 (API 30-32)
      if (androidInfo.version.sdkInt >= 30) {
        final status = await Permission.manageExternalStorage.request();
        if (status.isGranted) {
          return true;
        }
      }

      // Android 10 dan dibawah (API <= 29)
      final status = await Permission.storage.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting permission: $e');
      return false;
    }
  }

  /// Get download directory berdasarkan versi Android
  Future<Directory?> _getDownloadDirectory() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      // Android 10+ gunakan app-specific directory
      if (androidInfo.version.sdkInt >= 29) {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadsDir = Directory(
            '${directory.path}/Downloads/SMKScan/Materi',
          );
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          return downloadsDir;
        }
      } else {
        // Android 9 dan dibawah
        final directory = Directory(
          '/storage/emulated/0/Download/SMKScan/Materi',
        );
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory;
      }
    } catch (e) {
      print('Error getting download directory: $e');
    }
    return null;
  }

  Future<void> _downloadFile(BuildContext context, MateriFile file) async {
    try {
      // Request permission
      final hasPermission = await _requestStoragePermission(context);
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin penyimpanan diperlukan untuk mengunduh file'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text('Mengunduh ${file.fileName}...')),
              ],
            ),
            duration: const Duration(hours: 1),
          ),
        );
      }

      // Get download directory
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        throw Exception('Tidak dapat mengakses folder download');
      }

      // Download file
      final downloadedFile = await materiService.downloadMateriFile(
        url: file.url,
        fileName: file.fileName,
        savePath: directory.path,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'File berhasil diunduh!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lokasi: ${directory.path}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Buka',
              textColor: Colors.white,
              onPressed: () => _openFile(context, downloadedFile.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _openFile(BuildContext context, String filePath) async {
    try {
      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak dapat membuka file';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File tersimpan di: $filePath'),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openLink(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak dapat membuka link';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka link: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
