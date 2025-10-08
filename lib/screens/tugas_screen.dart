import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Screen Tugas - Placeholder untuk fitur manajemen tugas
class TugasScreen extends StatefulWidget {
  const TugasScreen({super.key});

  @override
  State<TugasScreen> createState() => _TugasScreenState();
}

class _TugasScreenState extends State<TugasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // AppBar dengan gradient
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
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTaskList('active'),
            _buildTaskList('completed'),
            _buildTaskList('late'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fitur tambah tugas akan segera tersedia'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        },
        backgroundColor: AppTheme.accentColor,
        icon: const Icon(Icons.add),
        label: const Text('Tugas Baru'),
      ),
    );
  }

  Widget _buildTaskList(String type) {
    // Data dummy untuk placeholder
    List<Map<String, dynamic>> tasks = [];

    if (type == 'active') {
      tasks = [
        {
          'title': 'Tugas Matematika - Integral',
          'subject': 'Matematika',
          'deadline': '15 Oktober 2025',
          'priority': 'high',
          'description': 'Kerjakan soal integral halaman 45-48',
        },
        {
          'title': 'Project Web Portfolio',
          'subject': 'Pemrograman Web',
          'deadline': '18 Oktober 2025',
          'priority': 'medium',
          'description':
              'Buat website portfolio pribadi dengan HTML, CSS, dan JavaScript',
        },
        {
          'title': 'Essay Bahasa Indonesia',
          'subject': 'Bahasa Indonesia',
          'deadline': '20 Oktober 2025',
          'priority': 'low',
          'description':
              'Tulis essay tentang pendidikan karakter min. 500 kata',
        },
      ];
    } else if (type == 'completed') {
      tasks = [
        {
          'title': 'Laporan Praktikum Database',
          'subject': 'Basis Data',
          'deadline': '8 Oktober 2025',
          'priority': 'high',
          'description': 'Laporan hasil praktikum normalisasi database',
        },
        {
          'title': 'PR Fisika Bab 3',
          'subject': 'Fisika',
          'deadline': '5 Oktober 2025',
          'priority': 'medium',
          'description': 'Soal latihan gerak parabola',
        },
      ];
    } else {
      tasks = [
        {
          'title': 'Tugas Kelompok PKK',
          'subject': 'PKK',
          'deadline': '1 Oktober 2025',
          'priority': 'high',
          'description': 'Presentasi proposal usaha',
        },
      ];
    }

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada tugas',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return _buildTaskCard(tasks[index], type);
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, String type) {
    Color priorityColor = task['priority'] == 'high'
        ? AppTheme.errorColor
        : task['priority'] == 'medium'
        ? AppTheme.accentColor
        : AppTheme.successColor;

    IconData priorityIcon = task['priority'] == 'high'
        ? Icons.priority_high
        : task['priority'] == 'medium'
        ? Icons.remove
        : Icons.arrow_downward;

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
          onTap: () {
            _showTaskDetail(context, task);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                            task['title'],
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
                              task['subject'],
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

                // Deskripsi
                Text(
                  task['description'],
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

                // Footer
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
                    Text(
                      'Deadline: ${task['deadline']}',
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
                    const Spacer(),
                    if (type == 'active')
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Fitur tandai selesai akan segera tersedia',
                              ),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Selesai'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.successColor,
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

  void _showTaskDetail(BuildContext context, Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.class_,
                        'Mata Pelajaran',
                        task['subject'],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Deadline',
                        task['deadline'],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.priority_high,
                        'Prioritas',
                        task['priority'] == 'high'
                            ? 'Tinggi'
                            : task['priority'] == 'medium'
                            ? 'Sedang'
                            : 'Rendah',
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
                        task['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Fitur edit tugas akan segera tersedia',
                                    ),
                                    backgroundColor: AppTheme.accentColor,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                side: const BorderSide(
                                  color: AppTheme.primaryColor,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Tugas ditandai selesai'),
                                    backgroundColor: AppTheme.successColor,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Selesai'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
      ],
    );
  }
}
