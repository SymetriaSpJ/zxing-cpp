import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:fitatu_barcode_scanner/fitatu_barcode_scanner.dart';
import 'package:fitatu_barcode_scanner/src/infra/android/camera_permissions_guard.dart';
import 'package:fitatu_barcode_scanner/src/pigeons/fitatu_barcode_scanner.pigeon.dart';
import 'package:fitatu_barcode_scanner/src/scanner_preview_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

part 'infra/android/android_fitatu_scanner_preview.dart';
part 'infra/common/common_fitatu_scanner_preview.dart';
part 'infra/fitatu_barcode_scanner_preview.dart';

typedef FitatuBarcodeScannerErrorCallback = void Function(String? error);
typedef FitatuBarcodeScannerResultCallback = void Function(FitatuBarcodeScannerResult result);

class _FitatuBarcodeScanner extends FitatuBarcodeScannerHostApi with ChangeNotifier implements FitatuBarcodeScannerFlutterApi {
  _FitatuBarcodeScanner() {
    FitatuBarcodeScannerFlutterApi.setUp(this);
  }

  final _api = FitatuBarcodeScannerHostApi();

  FitatuBarcodeScannerResultCallback? onResult;
  FitatuBarcodeScannerErrorCallback? onError;
  bool _isTorchEnabled = false;
  bool get isTorchEnabled => _isTorchEnabled;
  CameraConfig? _cameraConfig;
  CameraConfig? get cameraConfig => _cameraConfig;
  FitatuBarcodeScannerResult? _result;
  FitatuBarcodeScannerResult? get result => _result;
  String? _error;
  String? get error => _error;
  CameraImage? _cameraImage;
  CameraImage? get cameraImage => _cameraImage;

  @override
  Future<void> release() async {
    _isTorchEnabled = false;
    _cameraConfig = null;
    _result = null;
    _error = null;
    _cameraImage = null;
    notifyListeners();
    await _api.release();
  }

  @override
  Future<void> init(ScannerOptions options) {
    return _api.init(options);
  }

  @protected
  @override
  void onTextureChanged(CameraConfig? cameraConfig) {
    _cameraConfig = cameraConfig;
    notifyListeners();
  }

  @protected
  @override
  void onScanResult(String? code, FitatuBarcodeFormat format) {
    _result = FitatuBarcodeScannerResult(code, format);
    _error = null;
    onResult?.call(_result!);
    notifyListeners();
  }

  @override
  Future<void> setTorchEnabled(bool isEnabled) => _api.setTorchEnabled(isEnabled);

  @protected
  @override
  void onTorchStateChanged(bool isEnabled) {
    _isTorchEnabled = isEnabled;
    notifyListeners();
  }

  @protected
  @override
  void onScanError(String error) {
    _error = error;
    onError?.call(error);
    notifyListeners();
  }

  @protected
  @override
  void onCameraImage(CameraImage cameraImage) {
    _cameraImage = cameraImage;
    notifyListeners();
  }
}

@immutable
class FitatuBarcodeScannerResult {
  const FitatuBarcodeScannerResult(this.code, this.format);

  final String? code;
  final FitatuBarcodeFormat format;

  @override
  int get hashCode => Object.hash(code, format);

  @override
  bool operator ==(Object other) => other is FitatuBarcodeScannerResult && other.hashCode == hashCode;
}

sealed class FitatuBarcodeScannerController {
  const FitatuBarcodeScannerController(this.scannerOptions);

  final ScannerOptions scannerOptions;

  static Future<FitatuBarcodeScannerController> platform(ScannerOptions options) async {
    if (Platform.isAndroid) {
      final scanner = _FitatuBarcodeScanner();
      await scanner.init(options);
      return _AndroidBarcodeScanner(options, scanner);
    } else if (Platform.isIOS) {
      return _IOSBarcodeScanner(options);
    }

    throw FitatuBarcodeScannerException.unsupportedPlatform();
  }

  Future<void> disposeController();
}

final class _AndroidBarcodeScanner extends FitatuBarcodeScannerController {
  _AndroidBarcodeScanner(super.options, this._scanner);

  late final _FitatuBarcodeScanner _scanner;

  @override
  Future<void> disposeController() async => _scanner.release();
}

final class _IOSBarcodeScanner extends FitatuBarcodeScannerController {
  _IOSBarcodeScanner(super.options, {bool autoStart = false}) : _controller = MobileScannerController(autoStart: autoStart);

  final MobileScannerController _controller;

  @override
  Future<void> disposeController() => _controller.dispose();
}

final class FitatuBarcodeScannerException implements Exception {
  const FitatuBarcodeScannerException([this.message]);
  FitatuBarcodeScannerException.unsupportedPlatform() : message = 'Unsupported platform - ${Platform.operatingSystem}';

  final String? message;

  @override
  String toString() {
    return '$FitatuBarcodeScannerException: ${message ?? 'unknown'}';
  }
}
