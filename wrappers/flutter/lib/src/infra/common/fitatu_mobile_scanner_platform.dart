// ignore_for_file: implementation_imports

import 'package:flutter/foundation.dart';
import 'package:flutter/src/services/system_chrome.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';

final class FitatuMobileScannerPlatform extends MethodChannelMobileScanner {
  FitatuMobileScannerPlatform({this.workingOrientation = DeviceOrientation.portraitUp});

  /// Orientation value returned by the platform stream; defaults to portrait.
  final DeviceOrientation workingOrientation;

  @nonVirtual
  @override
  Stream<DeviceOrientation> get deviceOrientationChangedStream => Stream.value(workingOrientation);
}
