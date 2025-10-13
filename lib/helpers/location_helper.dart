// lib/utils/location_helper.dart
import 'package:geolocator/geolocator.dart';

/// Helper class untuk menangani geolocation dengan error handling yang robust
class LocationHelper {
  /// Check dan request location permission
  /// Returns: (success, errorMessage, position)
  static Future<LocationResult> checkAndGetLocation() async {
    try {
      // Step 1: Check apakah layanan lokasi aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error(
          'Layanan lokasi tidak aktif. Silakan aktifkan GPS di pengaturan device Anda.',
        );
      }

      // Step 2: Check permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // Step 3: Request permission jika belum diberikan
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult.error(
            'Izin akses lokasi ditolak. Aplikasi memerlukan akses lokasi untuk presensi.',
          );
        }
      }

      // Step 4: Check permanent denial
      if (permission == LocationPermission.deniedForever) {
        return LocationResult.error(
          'Izin akses lokasi ditolak secara permanen.\n\n'
          'Untuk mengaktifkan:\n'
          '1. Buka Pengaturan > Aplikasi > SMKScan\n'
          '2. Pilih Izin > Lokasi\n'
          '3. Pilih "Izinkan saat aplikasi digunakan"',
        );
      }

      // Step 5: Get current position dengan akurasi tinggi
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Step 6: Validasi akurasi
      if (position.accuracy > 50) {
        return LocationResult.warning(
          position,
          'Akurasi lokasi kurang baik (${position.accuracy.toStringAsFixed(1)}m). '
          'Presensi mungkin gagal jika di luar radius.',
        );
      }

      return LocationResult.success(position);
    } catch (e) {
      // Handle berbagai jenis error
      if (e.toString().contains('timeout')) {
        return LocationResult.error(
          'Waktu tunggu GPS habis. Pastikan Anda berada di area terbuka dan GPS aktif.',
        );
      }

      return LocationResult.error('Gagal mendapatkan lokasi: ${e.toString()}');
    }
  }

  /// Hitung jarak antara dua koordinat menggunakan Haversine formula
  /// Returns: jarak dalam meter
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check apakah lokasi dalam radius tertentu
  static bool isWithinRadius(
    Position userPosition,
    double targetLat,
    double targetLon,
    double radiusInMeters,
  ) {
    final distance = calculateDistance(
      userPosition.latitude,
      userPosition.longitude,
      targetLat,
      targetLon,
    );
    return distance <= radiusInMeters;
  }

  /// Get status lokasi dalam bentuk user-friendly text
  static String getAccuracyStatus(double accuracy) {
    if (accuracy <= 10) {
      return 'Sangat Baik';
    } else if (accuracy <= 20) {
      return 'Baik';
    } else if (accuracy <= 50) {
      return 'Cukup';
    } else {
      return 'Kurang Baik';
    }
  }

  /// Get warna indicator berdasarkan akurasi
  static String getAccuracyColor(double accuracy) {
    if (accuracy <= 10) {
      return 'green';
    } else if (accuracy <= 20) {
      return 'lightGreen';
    } else if (accuracy <= 50) {
      return 'orange';
    } else {
      return 'red';
    }
  }

  /// Open app settings untuk permission
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open location settings
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}

/// Result class untuk location operation
class LocationResult {
  final bool success;
  final String? errorMessage;
  final Position? position;
  final bool isWarning;

  LocationResult._({
    required this.success,
    this.errorMessage,
    this.position,
    this.isWarning = false,
  });

  factory LocationResult.success(Position position) {
    return LocationResult._(success: true, position: position);
  }

  factory LocationResult.error(String message) {
    return LocationResult._(success: false, errorMessage: message);
  }

  factory LocationResult.warning(Position position, String message) {
    return LocationResult._(
      success: true,
      position: position,
      errorMessage: message,
      isWarning: true,
    );
  }

  bool get hasPosition => position != null;
  bool get hasError => errorMessage != null;
}

/// Extension untuk Position - tambahan helper methods
extension PositionExtension on Position {
  /// Get formatted coordinates
  String get formattedCoordinates {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Get accuracy status text
  String get accuracyStatus {
    return LocationHelper.getAccuracyStatus(accuracy);
  }

  /// Check if accuracy is good enough for attendance
  bool get isAccuracyGood => accuracy <= 50;
}
