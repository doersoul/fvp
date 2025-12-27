import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrientationUtils {
  static Future<void> setOrientationPortrait() async {
    return SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  static Future<void> setOrientationLandscape() async {
    DeviceOrientation orientation = DeviceOrientation.landscapeRight;
    if (Platform.isAndroid) {
      orientation = DeviceOrientation.landscapeLeft;
    }

    return SystemChrome.setPreferredOrientations([orientation]);
  }

  static Future<void> hideSystemBar() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [],
    );
  }

  static Future<void> showSystemBar() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        // status bar
        systemStatusBarContrastEnforced: false,
        // for android
        statusBarColor: Colors.transparent,
        // for ios
        statusBarBrightness: Brightness.light,
        // for android
        statusBarIconBrightness: Brightness.light,
        // navigation bar
        systemNavigationBarContrastEnforced: false,
        // for android
        systemNavigationBarColor: Colors.transparent,
        // for android
        systemNavigationBarIconBrightness: Brightness.dark,
        // for android
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }
}
