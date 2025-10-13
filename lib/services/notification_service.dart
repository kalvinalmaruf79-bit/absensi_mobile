// lib/services/notification_service.dart
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  // Ganti dengan App ID OneSignal Anda
  static const String _oneSignalAppId = "7bd26472-b53d-488f-9ca0-a0157a27663c";

  // Inisialisasi OneSignal
  static Future<void> initOneSignal() async {
    // Menghapus log yang berlebihan
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Inisialisasi OneSignal dengan App ID Anda
    OneSignal.initialize(_oneSignalAppId);

    // Meminta izin notifikasi dari pengguna (penting untuk iOS)
    OneSignal.Notifications.requestPermission(true);

    // Menangani saat notifikasi dibuka
    OneSignal.Notifications.addClickListener((event) {
      print('NOTIFICATION CLICKED: ${event.notification.jsonRepresentation()}');
      // Di sini Anda bisa menambahkan logika navigasi berdasarkan
      // data tambahan (additionalData) dari notifikasi.
      // Contoh: jika notifikasi tentang tugas baru, buka halaman tugas.
      final resourceId = event.notification.additionalData?['resourceId'];
      if (resourceId != null) {
        print('Navigasi ke resource dengan ID: $resourceId');
        // Navigator.push(context, MaterialPageRoute(builder: (context) => DetailTugasScreen(id: resourceId)));
      }
    });

    // Menangani saat notifikasi diterima saat aplikasi terbuka
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print(
        'NOTIFICATION RECEIVED IN FOREGROUND: ${event.notification.jsonRepresentation()}',
      );
      // Mencegah notifikasi ditampilkan (jika perlu)
      event.preventDefault();

      // Anda bisa menampilkan dialog atau snackbar kustom di sini
      // sebagai ganti notifikasi sistem.

      // Untuk tetap menampilkan notifikasi, panggil display()
      event.notification.display();
    });
  }
}
