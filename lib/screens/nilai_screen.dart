// lib/screens/nilai_screen.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class NilaiScreen extends StatefulWidget {
  const NilaiScreen({super.key});

  @override
  State<NilaiScreen> createState() => _NilaiScreenState();
}

class _NilaiScreenState extends State<NilaiScreen> {
  String selectedSemester = 'Semester 1';

  // Dummy data nilai
  final List<Map<String, dynamic>> dummyNilai = [
    {
      'mataPelajaran': 'Matematika',
      'guru': 'Budi Santoso, S.Pd',
      'tugas': 85,
      'uts': 88,
      'uas': 90,
      'nilaiAkhir': 88,
      'predikat': 'A',
      'color': Colors.blue,
    },
    {
      'mataPelajaran': 'Bahasa Indonesia',
      'guru': 'Siti Nurhaliza, M.Pd',
      'tugas': 90,
      'uts': 85,
      'uas': 88,
      'nilaiAkhir': 88,
      'predikat': 'A',
      'color': Colors.green,
    },
    {
      'mataPelajaran': 'Bahasa Inggris',
      'guru': 'John Smith, S.Pd',
      'tugas': 82,
      'uts': 80,
      'uas': 85,
      'nilaiAkhir': 82,
      'predikat': 'B+',
      'color': Colors.orange,
    },
    {
      'mataPelajaran': 'Fisika',
      'guru': 'Ahmad Dahlan, M.Si',
      'tugas': 78,
      'uts': 75,
      'uas': 80,
      'nilaiAkhir': 78,
      'predikat': 'B',
      'color': Colors.purple,
    },
    {
      'mataPelajaran': 'Kimia',
      'guru': 'Dewi Lestari, S.Si',
      'tugas': 88,
      'uts': 90,
      'uas': 92,
      'nilaiAkhir': 90,
      'predikat': 'A',
      'color': Colors.teal,
    },
    {
      'mataPelajaran': 'Biologi',
      'guru': 'Ratna Sari, M.Pd',
      'tugas': 85,
      'uts': 83,
      'uas': 87,
      'nilaiAkhir': 85,
      'predikat': 'A-',
      'color': Colors.indigo,
    },
  ];

  double get rataRata {
    if (dummyNilai.isEmpty) return 0;
    final total = dummyNilai.fold<double>(
      0,
      (sum, item) => sum + (item['nilaiAkhir'] as int).toDouble(),
    );
    return total / dummyNilai.length;
  }

  int get nilaiTertinggi {
    if (dummyNilai.isEmpty) return 0;
    return dummyNilai
        .map((e) => e['nilaiAkhir'] as int)
        .reduce((a, b) => a > b ? a : b);
  }

  int get nilaiTerendah {
    if (dummyNilai.isEmpty) return 0;
    return dummyNilai
        .map((e) => e['nilaiAkhir'] as int)
        .reduce((a, b) => a < b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nilai Akademik'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header dengan statistik
          Container(
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
                  // Dropdown semester
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: selectedSemester,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: AppTheme.primaryColor,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                      items:
                          [
                            'Semester 1',
                            'Semester 2',
                            'Semester 3',
                            'Semester 4',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedSemester = newValue!;
                        });
                      },
                    ),
                  ),
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
                        value: dummyNilai.length.toString(),
                      ),
                      _buildStatItem(
                        icon: Icons.trending_up,
                        label: 'Tertinggi',
                        value: nilaiTertinggi.toString(),
                      ),
                      _buildStatItem(
                        icon: Icons.trending_down,
                        label: 'Terendah',
                        value: nilaiTerendah.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // List nilai
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: dummyNilai.length,
              itemBuilder: (context, index) {
                final nilai = dummyNilai[index];
                return _buildNilaiCard(context, nilai);
              },
            ),
          ),
        ],
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNilaiCard(BuildContext context, Map<String, dynamic> nilai) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetailDialog(context, nilai),
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
                      color: (nilai['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book,
                      color: nilai['color'] as Color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Nama mapel dan guru
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nilai['mataPelajaran'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nilai['guru'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Nilai akhir dan predikat
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        nilai['nilaiAkhir'].toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: nilai['color'] as Color,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (nilai['color'] as Color).withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          nilai['predikat'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: nilai['color'] as Color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Nilai detail (Tugas, UTS, UAS)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNilaiDetail('Tugas', nilai['tugas']),
                  _buildNilaiDetail('UTS', nilai['uts']),
                  _buildNilaiDetail('UAS', nilai['uas']),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNilaiDetail(String label, int value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showDetailDialog(BuildContext context, Map<String, dynamic> nilai) {
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
                    color: (nilai['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.menu_book,
                    color: nilai['color'] as Color,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  nilai['mataPelajaran'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  nilai['guru'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Detail nilai
                _buildDetailRow('Nilai Tugas', nilai['tugas'].toString()),
                const Divider(height: 24),
                _buildDetailRow('Nilai UTS', nilai['uts'].toString()),
                const Divider(height: 24),
                _buildDetailRow('Nilai UAS', nilai['uas'].toString()),
                const Divider(height: 24),
                _buildDetailRow(
                  'Nilai Akhir',
                  nilai['nilaiAkhir'].toString(),
                  isBold: true,
                ),
                const SizedBox(height: 16),
                // Predikat badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        nilai['color'] as Color,
                        (nilai['color'] as Color).withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Predikat: ${nilai['predikat']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Tombol tutup
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
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
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isBold ? AppTheme.primaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }
}
