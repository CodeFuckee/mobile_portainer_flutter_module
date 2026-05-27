import '../services/harmonyos_platform.dart';
import '../utils/platform_detector.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    _initialized = true;
  }

  Future<void> showAndroid(String title, String body) async {}
}
