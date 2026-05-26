import 'dart:io';

class PlatformDetector {
  /// 检测当前是否为鸿蒙系统
  static bool get isOhos => Platform.operatingSystem == 'ohos';

  /// 检测当前是否为 Android
  static bool get isAndroid => Platform.isAndroid;

  /// 检测当前是否为 iOS
  static bool get isIOS => Platform.isIOS;
}
