// lib/services/notification_service.dart
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:absensi_mobile/services/siswa_service.dart';

class NotificationService {
  static const String _oneSignalAppId = "7bd26472-b53d-488f-9ca0-a0157a27663c";
  static bool _isInitialized = false;

  static Future<void> initOneSignal() async {
    if (_isInitialized) {
      print('⚠️ OneSignal sudah diinisialisasi sebelumnya');
      return;
    }

    try {
      print('🔔 Memulai inisialisasi OneSignal...');

      // Set log level untuk debugging
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // Initialize OneSignal
      OneSignal.initialize(_oneSignalAppId);

      // Request permission
      final permissionGranted = await OneSignal.Notifications.requestPermission(
        true,
      );
      print(
        '📱 Izin notifikasi: ${permissionGranted ? "Diberikan" : "Ditolak"}',
      );

      // Get current subscription state
      final subscriptionState = OneSignal.User.pushSubscription.optedIn;
      print(
        '📡 Status subscription: ${subscriptionState == true ? "Subscribed" : "Not subscribed"}',
      );

      // Listener untuk perubahan subscription state
      OneSignal.User.pushSubscription.addObserver((state) async {
        final String? playerId = state.current.id;
        final bool isSubscribed = state.current.optedIn;

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔔 PUSH SUBSCRIPTION STATE CHANGED');
        print('Player ID: ${playerId ?? "null"}');
        print('Is Subscribed: $isSubscribed');
        print('Token: ${state.current.token ?? "null"}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        if (playerId != null && playerId.isNotEmpty && isSubscribed) {
          try {
            print('📤 Mengirim Player ID ke backend...');
            await SiswaService().registerDeviceToken(playerId);
            print('✅ Player ID berhasil didaftarkan ke backend');
          } catch (e) {
            print('❌ Gagal mendaftarkan Player ID ke backend: $e');
          }
        } else {
          print('⚠️ Player ID tidak valid atau user belum subscribe');
        }
      });

      // Listener untuk notifikasi yang diklik
      OneSignal.Notifications.addClickListener((event) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('👆 NOTIFICATION CLICKED');
        print('Notification ID: ${event.notification.notificationId}');
        print('Title: ${event.notification.title}');
        print('Body: ${event.notification.body}');
        print('Additional Data: ${event.notification.additionalData}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        final resourceId = event.notification.additionalData?['resourceId'];
        final type = event.notification.additionalData?['type'];

        if (resourceId != null) {
          print('🎯 Navigasi ke resource: $type - $resourceId');
          // TODO: Implementasi navigasi berdasarkan type
        }
      });

      // Listener untuk notifikasi yang diterima saat app di foreground
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📬 NOTIFICATION RECEIVED (FOREGROUND)');
        print('Notification ID: ${event.notification.notificationId}');
        print('Title: ${event.notification.title}');
        print('Body: ${event.notification.body}');
        print('Additional Data: ${event.notification.additionalData}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        // Tampilkan notifikasi
        event.notification.display();
      });

      // Listener untuk permission changes
      OneSignal.Notifications.addPermissionObserver((granted) {
        print('🔔 Permission changed: ${granted ? "Granted" : "Denied"}');
      });

      _isInitialized = true;
      print('✅ OneSignal berhasil diinisialisasi');

      // Log current player ID
      final currentPlayerId = OneSignal.User.pushSubscription.id;
      print('📱 Current Player ID: ${currentPlayerId ?? "Belum tersedia"}');
    } catch (e) {
      print('❌ Error inisialisasi OneSignal: $e');
      rethrow;
    }
  }

  /// Force sync dengan OneSignal server
  static Future<void> syncDevice() async {
    try {
      print('🔄 Melakukan sync dengan OneSignal...');
      final playerId = OneSignal.User.pushSubscription.id;

      if (playerId != null && playerId.isNotEmpty) {
        await SiswaService().registerDeviceToken(playerId);
        print('✅ Sync berhasil');
      } else {
        print('⚠️ Player ID belum tersedia untuk sync');
      }
    } catch (e) {
      print('❌ Error sync device: $e');
    }
  }

  /// Get current player ID
  static String? getCurrentPlayerId() {
    return OneSignal.User.pushSubscription.id;
  }

  /// Check if notifications are enabled
  static bool isNotificationEnabled() {
    return OneSignal.User.pushSubscription.optedIn ?? false;
  }
}
