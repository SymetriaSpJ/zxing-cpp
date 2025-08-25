import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    input: 'pigeons/pigeons.dart',
    dartOut: 'lib/src/pigeons/fitatu_barcode_scanner.pigeon.dart',
    swiftOut: 'ios/Runner/FitatuBarcodeScannerPigeons.swift',
    kotlinOut: 'android/src/main/kotlin/com/fitatu/barcodescanner/fitatu_barcode_scanner/FitatuBarcodeScannerPigeons.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.fitatu.barcodescanner.fitatu_barcode_scanner',
      errorClassName: 'FitatuBarcodeScannerFlutterError',
    ),
  ),
)
@HostApi()
abstract class FitatuBarcodeScannerHostApi {
  void init(ScannerOptions options);
  void release();
  void setTorchEnabled(bool isEnabled);
}

@FlutterApi()
abstract class FitatuBarcodeScannerFlutterApi {
  void onTextureChanged(CameraConfig? cameraConfig);
  void onTorchStateChanged(bool isEnabled);
  void onCameraImage(CameraImage cameraImage);
  void onScanResult(String? code, FitatuBarcodeFormat format);
  void onScanError(String error);
}

enum FitatuBarcodeFormat {
  /// Aztec 2D barcode format.
  aztec,

  /// Codabar 1D barcode format, used in libraries, blood banks, parcels.
  codabar,

  /// Code 39 1D barcode format, used in automotive and defense industries.
  code39,

  /// Code 93 1D barcode format, compact and high-density, used in logistics.
  code93,

  /// Code 128 1D barcode format, high-density, used in shipping and packaging.
  code128,

  /// DataBar (RSS-14) 1D barcode format, used in retail and coupons.
  dataBar,

  /// DataBar Expanded 1D barcode format, stores more data, used for coupons.
  dataBarExpanded,

  /// Data Matrix 2D barcode format, used for marking small items.
  dataMatrix,

  /// EAN-8 1D barcode format, short version of EAN-13, used on small packages.
  ean8,

  /// EAN-13 1D barcode format, used worldwide for retail products.
  ean13,

  /// ITF (Interleaved 2 of 5) 1D barcode format, used on cartons and packaging.
  itf,

  /// MaxiCode 2D barcode format, used by UPS for package tracking.
  maxicode,

  /// PDF417 2D barcode format, used for transport, identification cards.
  pdf417,

  /// QR Code 2D barcode format, widely used for URLs, payments, and info.
  qrCode,

  /// Micro QR Code 2D barcode format, smaller version of QR Code.
  microQrCode,

  /// UPC-A 1D barcode format, used for retail products in North America.
  upcA,

  /// UPC-E 1D barcode format, compressed version of UPC-A for small packages.
  upcE,

  /// Special value that maps to the `BarcodeFormat.all` enum from the mobile_scanner package.
  /// See: https://pub.dev/documentation/mobile_scanner/latest/mobile_scanner/BarcodeFormat.html
  all,

  /// Unknown code format
  unknown,
}

class CameraConfig {
  final int textureId;
  final int previewWidth;
  final int previewHeight;

  CameraConfig(this.textureId, this.previewWidth, this.previewHeight);
}

class CameraImage {
  final CropRect cropRect;
  final int width;
  final int height;
  final int rotationDegrees;

  CameraImage({required this.cropRect, required this.width, required this.height, required this.rotationDegrees});
}

class CropRect {
  final int left;
  final int top;
  final int right;
  final int bottom;

  CropRect({required this.left, required this.top, required this.right, required this.bottom});
}

class ScannerOptions {
  final bool tryHarder;
  final bool tryRotate;
  final bool tryInvert;
  final bool qrCode;
  final double cropPercent;
  final int scanDelay;
  final int scanDelaySuccess;

  const ScannerOptions({
    required this.tryHarder,
    required this.tryRotate,
    required this.tryInvert,
    required this.qrCode,
    required this.cropPercent,
    required this.scanDelay,
    required this.scanDelaySuccess,
  });
}
