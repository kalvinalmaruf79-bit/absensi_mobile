// lib/services/materi_service.dart
import 'dart:async'; // <-- PERBAIKAN: Import yang ditambahkan
import 'dart:io';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import '../models/materi.dart';

class MateriService {
  final ApiService _apiService = ApiService();

  /// Mengambil semua materi untuk siswa (published only, filtered by kelas siswa)
  Future<Map<String, dynamic>> getMateriSiswa({
    int page = 1,
    int limit = 10,
    String? mataPelajaranId,
  }) async {
    try {
      String endpoint = 'materi/siswa?page=$page&limit=$limit';

      if (mataPelajaranId != null && mataPelajaranId.isNotEmpty) {
        endpoint += '&mataPelajaranId=$mataPelajaranId';
      }

      final response = await _apiService.get(endpoint);

      return {
        'docs': (response['docs'] as List)
            .map((json) => Materi.fromJson(json))
            .toList(),
        'totalDocs': response['totalDocs'] ?? 0,
        'limit': response['limit'] ?? limit,
        'page': response['page'] ?? page,
        'totalPages': response['totalPages'] ?? 0,
        'hasNextPage': response['hasNextPage'] ?? false,
        'hasPrevPage': response['hasPrevPage'] ?? false,
      };
    } catch (e) {
      throw Exception('Gagal memuat materi siswa: $e');
    }
  }

  /// Mengambil materi berdasarkan mata pelajaran (with pagination)
  Future<Map<String, dynamic>> getMateriByMataPelajaran({
    required String mataPelajaranId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        'materi/mata-pelajaran/$mataPelajaranId?page=$page&limit=$limit',
      );

      return {
        'docs': (response['docs'] as List)
            .map((json) => Materi.fromJson(json))
            .toList(),
        'totalDocs': response['totalDocs'] ?? 0,
        'limit': response['limit'] ?? limit,
        'page': response['page'] ?? page,
        'totalPages': response['totalPages'] ?? 0,
        'hasNextPage': response['hasNextPage'] ?? false,
        'hasPrevPage': response['hasPrevPage'] ?? false,
      };
    } catch (e) {
      throw Exception('Gagal memuat materi: $e');
    }
  }

  /// Mengambil materi berdasarkan kelas dan mata pelajaran
  Future<List<Materi>> getMateriByKelas({
    required String kelasId,
    required String mataPelajaranId,
  }) async {
    try {
      final response = await _apiService.get(
        'materi?kelasId=$kelasId&mataPelajaranId=$mataPelajaranId',
      );

      final List<dynamic> data = response;
      return data.map((json) => Materi.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal memuat materi: $e');
    }
  }

  /// Mengambil detail materi berdasarkan ID
  Future<Materi> getMateriById(String materiId) async {
    try {
      final response = await _apiService.get('materi/$materiId');
      return Materi.fromJson(response);
    } catch (e) {
      throw Exception('Gagal memuat detail materi: $e');
    }
  }

  /// Download file materi dengan retry mechanism
  Future<File> downloadMateriFile({
    required String url,
    required String fileName,
    required String savePath,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < maxRetries) {
      try {
        print('Download attempt ${retryCount + 1} for: $fileName');
        print('URL: $url');
        print('Save path: $savePath/$fileName');

        final token = await _apiService.getToken();

        Map<String, String> headers = {'Accept': '*/*'};

        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }

        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(
              const Duration(seconds: 120),
              onTimeout: () {
                throw TimeoutException(
                  'Download timeout. Periksa koneksi internet Anda.',
                );
              },
            );

        print('Response status: ${response.statusCode}');
        print('Response headers: ${response.headers}');

        if (response.statusCode == 200) {
          // Pastikan directory exists
          final directory = Directory(savePath);
          if (!await directory.exists()) {
            await directory.create(recursive: true);
            print('Directory created: $savePath');
          }

          final file = File('$savePath/$fileName');

          // Write file
          await file.writeAsBytes(response.bodyBytes);

          // Verify file exists and has content
          if (await file.exists()) {
            final fileSize = await file.length();
            print('File downloaded successfully. Size: $fileSize bytes');

            if (fileSize == 0) {
              throw Exception('File downloaded but is empty');
            }

            return file;
          } else {
            throw Exception('File was not created');
          }
        } else if (response.statusCode == 404) {
          throw Exception('File tidak ditemukan di server (404)');
        } else if (response.statusCode == 403) {
          throw Exception('Akses ditolak. Anda tidak memiliki izin (403)');
        } else if (response.statusCode == 401) {
          throw Exception(
            'Sesi Anda telah berakhir. Silakan login kembali (401)',
          );
        } else {
          throw Exception(
            'Gagal mendownload file. Status: ${response.statusCode}',
          );
        }
      } on SocketException catch (e) {
        lastException = Exception(
          'Tidak ada koneksi internet. Periksa koneksi Anda.',
        );
        print('SocketException: $e');
      } on http.ClientException catch (e) {
        lastException = Exception(
          'Gagal terhubung ke server. Coba lagi nanti.',
        );
        print('ClientException: $e');
      } on TimeoutException catch (e) {
        lastException = Exception(
          'Download timeout. Periksa koneksi internet Anda.',
        );
        print('TimeoutException: $e');
      } on FileSystemException catch (e) {
        lastException = Exception(
          'Gagal menyimpan file. Periksa izin penyimpanan.',
        );
        print('FileSystemException: $e');
      } catch (e) {
        lastException = e is Exception
            ? e
            : Exception('Gagal mendownload file: $e');
        print('Unknown error: $e');
      }

      retryCount++;
      if (retryCount < maxRetries) {
        print('Retrying in 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    // If all retries failed
    throw lastException ??
        Exception('Gagal mendownload file setelah $maxRetries percobaan');
  }

  /// Get file size dari URL (untuk preview sebelum download)
  Future<int?> getFileSize(String url) async {
    try {
      final token = await _apiService.getToken();

      Map<String, String> headers = {};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.head(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final contentLength = response.headers['content-length'];
        if (contentLength != null) {
          return int.tryParse(contentLength);
        }
      }
      return null;
    } catch (e) {
      print('Error getting file size: $e');
      return null;
    }
  }

  /// Format file size untuk display
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Search materi by keyword (client-side filtering)
  List<Materi> searchMateri(List<Materi> materiList, String keyword) {
    if (keyword.isEmpty) {
      return materiList;
    }

    final lowerKeyword = keyword.toLowerCase();

    return materiList.where((materi) {
      final judulMatch = materi.judul.toLowerCase().contains(lowerKeyword);
      final deskripsiMatch = materi.deskripsi.toLowerCase().contains(
        lowerKeyword,
      );
      final guruMatch = materi.guru.name.toLowerCase().contains(lowerKeyword);
      final mapelMatch = materi.mataPelajaran.nama.toLowerCase().contains(
        lowerKeyword,
      );

      return judulMatch || deskripsiMatch || guruMatch || mapelMatch;
    }).toList();
  }

  /// Sort materi by date
  List<Materi> sortMateriByDate(
    List<Materi> materiList, {
    bool ascending = false,
  }) {
    final sorted = List<Materi>.from(materiList);
    sorted.sort((a, b) {
      if (ascending) {
        return a.createdAt.compareTo(b.createdAt);
      } else {
        return b.createdAt.compareTo(a.createdAt);
      }
    });
    return sorted;
  }

  /// Filter materi by mata pelajaran (client-side)
  List<Materi> filterByMataPelajaran(
    List<Materi> materiList,
    String mataPelajaranId,
  ) {
    return materiList
        .where((materi) => materi.mataPelajaran.id == mataPelajaranId)
        .toList();
  }

  /// Group materi by mata pelajaran
  Map<String, List<Materi>> groupByMataPelajaran(List<Materi> materiList) {
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

  /// Check if materi has downloadable files
  bool hasDownloadableFiles(Materi materi) {
    return materi.files.isNotEmpty;
  }

  /// Get all file types in a materi
  List<String> getFileTypes(Materi materi) {
    return materi.files
        .map((file) => file.fileExtension.toUpperCase())
        .toSet()
        .toList();
  }

  /// Count total materi by mata pelajaran
  Map<String, int> countByMataPelajaran(List<Materi> materiList) {
    final Map<String, int> count = {};

    for (final materi in materiList) {
      final mapelNama = materi.mataPelajaran.nama;
      count[mapelNama] = (count[mapelNama] ?? 0) + 1;
    }

    return count;
  }

  /// Get recent materi (last N items)
  List<Materi> getRecentMateri(List<Materi> materiList, {int limit = 5}) {
    final sorted = sortMateriByDate(materiList, ascending: false);
    return sorted.take(limit).toList();
  }

  /// Check if materi is new (uploaded within last 7 days)
  bool isNewMateri(Materi materi) {
    final now = DateTime.now();
    final difference = now.difference(materi.createdAt);
    return difference.inDays <= 7;
  }

  /// Get materi statistics
  Map<String, dynamic> getMateriStatistics(List<Materi> materiList) {
    int totalFiles = 0;
    int totalLinks = 0;
    int newMateri = 0;

    for (final materi in materiList) {
      totalFiles += materi.files.length;
      totalLinks += materi.links.length;
      if (isNewMateri(materi)) {
        newMateri++;
      }
    }

    return {
      'totalMateri': materiList.length,
      'totalFiles': totalFiles,
      'totalLinks': totalLinks,
      'newMateri': newMateri,
      'averageFilesPerMateri': materiList.isEmpty
          ? 0.0
          : totalFiles / materiList.length,
      'averageLinksPerMateri': materiList.isEmpty
          ? 0.0
          : totalLinks / materiList.length,
    };
  }
}
