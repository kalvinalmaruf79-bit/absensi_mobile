// lib/helpers/materi_helper.dart
import '../models/materi.dart';

/// Helper class untuk siswa mengolah data materi
/// TIDAK perlu service terpisah untuk mata pelajaran
class MateriHelper {
  /// Extract unique mata pelajaran dari list materi
  /// Untuk dropdown filter atau kategori
  static List<MateriMataPelajaran> getUniqueMataPelajaran(
    List<Materi> materiList,
  ) {
    final Map<String, MateriMataPelajaran> mapelMap = {};

    for (final materi in materiList) {
      mapelMap[materi.mataPelajaran.id] = materi.mataPelajaran;
    }

    return mapelMap.values.toList()..sort((a, b) => a.nama.compareTo(b.nama));
  }

  /// Count materi per mata pelajaran
  static Map<String, int> countMateriPerMapel(List<Materi> materiList) {
    final Map<String, int> count = {};

    for (final materi in materiList) {
      final mapelNama = materi.mataPelajaran.nama;
      count[mapelNama] = (count[mapelNama] ?? 0) + 1;
    }

    return count;
  }

  /// Group materi by mata pelajaran
  static Map<String, List<Materi>> groupByMataPelajaran(
    List<Materi> materiList,
  ) {
    final Map<String, List<Materi>> grouped = {};

    for (final materi in materiList) {
      final mapelNama = materi.mataPelajaran.nama;
      if (!grouped.containsKey(mapelNama)) {
        grouped[mapelNama] = [];
      }
      grouped[mapelNama]!.add(materi);
    }

    return grouped;
  }

  /// Get materi statistics per mata pelajaran
  static Map<String, dynamic> getMapelStatistics(
    List<Materi> materiList,
    String mataPelajaranId,
  ) {
    final filtered = materiList
        .where((m) => m.mataPelajaran.id == mataPelajaranId)
        .toList();

    int totalFiles = 0;
    int totalLinks = 0;
    int newMateri = 0;

    for (final materi in filtered) {
      totalFiles += materi.files.length;
      totalLinks += materi.links.length;

      final now = DateTime.now();
      final diff = now.difference(materi.createdAt);
      if (diff.inDays <= 7) {
        newMateri++;
      }
    }

    return {
      'totalMateri': filtered.length,
      'totalFiles': totalFiles,
      'totalLinks': totalLinks,
      'newMateri': newMateri,
      'mataPelajaran': filtered.isNotEmpty
          ? filtered.first.mataPelajaran
          : null,
    };
  }
}
