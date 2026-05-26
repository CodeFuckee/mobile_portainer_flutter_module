import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_portainer_flutter_module/utils/toast_utils.dart';
import 'platform_detector.dart';

class NotifyUtils {
  static void showNotify(BuildContext context, String message) {
    if (PlatformDetector.isOhos) {
      ToastUtils.show(message);
    } else if (Platform.isAndroid) {
      ToastUtils.show(message);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
