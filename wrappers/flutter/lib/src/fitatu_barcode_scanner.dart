import 'package:fitatu_barcode_scanner/src/pigeons/fitatu_barcode_scanner.pigeon.dart';
import 'package:flutter/foundation.dart';

typedef FitatuBarcodeScannerErrorCallback = void Function(String? error);
typedef FitatuBarcodeScannerResultCallback = void Function(FitatuBarcodeScannerResult result);

class FitatuBarcodeScanner extends FitatuBarcodeScannerHostApi with ChangeNotifier implements FitatuBarcodeScannerFlutterApi {
  FitatuBarcodeScanner({required this.onResult, required this.onError}) {
    FitatuBarcodeScannerFlutterApi.setUp(this);
  }

  final _api = FitatuBarcodeScannerHostApi();

  final FitatuBarcodeScannerResultCallback onResult;
  final FitatuBarcodeScannerErrorCallback? onError;
  var _isTorchEnabled = false;
  bool get isTorchEnabled => _isTorchEnabled;
  CameraConfig? _cameraConfig;
  CameraConfig? get cameraConfig => _cameraConfig;
  FitatuBarcodeScannerResult? _result;
  FitatuBarcodeScannerResult? get result => _result;
  String? _error;
  String? get error => _error;
  CameraImage? _cameraImage;
  CameraImage? get cameraImage => _cameraImage;

  var _isDisposed = false;

  @override
  void dispose() async {
    _isDisposed = true;
    await release();
    super.dispose();
  }

  @override
  Future<void> release() async {
    _cameraConfig = null;
    notifyListeners();
    await _api.release();
  }

  @override
  Future<void> init(ScannerOptions options) {
    return _api.init(options);
  }

  @override
  void onTextureChanged(CameraConfig? cameraConfig) {
    _cameraConfig = cameraConfig;
    notifyListeners();
  }

  @override
  void onScanResult(String? code, FitatuBarcodeFormat format) {
    _result = FitatuBarcodeScannerResult(code, format);
    onResult(_result!);
    _error = null;
    notifyListeners();
  }

  @override
  Future<void> setTorchEnabled(bool isEnabled) => _api.setTorchEnabled(isEnabled);

  @override
  void onTorchStateChanged(bool isEnabled) {
    _isTorchEnabled = isEnabled;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void onScanError(String error) {
    _error = error;
    onError?.call(error);
    notifyListeners();
  }

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
