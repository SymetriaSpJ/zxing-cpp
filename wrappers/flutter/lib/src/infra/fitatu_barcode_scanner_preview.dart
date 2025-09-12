part of '../fitatu_barcode_scanner.dart';

typedef PreviewOverlayBuilder = Widget Function(BuildContext context, CameraPreviewMetrix metrix);

class FitatuBarcodeScannerPreview extends StatefulWidget {
  const FitatuBarcodeScannerPreview({
    super.key,
    required this.controllerLease,
    required this.onResult,
    this.onError,
    this.onChanged,
    this.previewOverlayBuilder,
    this.theme = const PreviewOverlayThemeData(),
  });

  final ResourceLease<FitatuBarcodeScannerController> controllerLease;
  final FitatuBarcodeScannerResultCallback onResult;
  final FitatuBarcodeScannerErrorCallback? onError;
  final VoidCallback? onChanged;
  final PreviewOverlayBuilder? previewOverlayBuilder;
  final PreviewOverlayThemeData theme;

  @override
  State<FitatuBarcodeScannerPreview> createState() => FitatuBarcodeScannerPreviewState();
}

class FitatuBarcodeScannerPreviewState extends State<FitatuBarcodeScannerPreview> with ScannerPreviewMixin {
  late final _key = GlobalKey<ScannerPreviewMixin>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  @override
  Widget build(BuildContext context) {
    late Widget preview;

    return FutureBuilder(
      future: widget.controllerLease.resource,
      builder: (context, snapshot) {
        final controller = snapshot.data;

        if (Platform.isAndroid) {
          preview = CameraPermissionsGuard(
            child: _AndroidFitatuScannerPreview(
              key: _key,
              controller: controller != null ? controller as _AndroidBarcodeScanner : null,
              onResult: widget.onResult,
              onChanged: widget.onChanged,
              onError: widget.onError,
              overlayBuilder: widget.previewOverlayBuilder,
            ),
          );
        } else if (Platform.isIOS) {
          preview = _CommonFitatuScannerPreview(
            key: _key,
            controller: controller != null ? controller as _IOSBarcodeScanner : null,
            onResult: widget.onResult,
            onChanged: widget.onChanged,
            onError: widget.onError,
            overlayBuilder: widget.previewOverlayBuilder,
          );
        } else {
          throw FitatuBarcodeScannerException.unsupportedPlatform();
        }

        return PreviewOverlayTheme(themeData: widget.theme, child: preview);
      },
    );
  }

  @override
  void setTorchEnabled({required bool isEnabled}) {
    _key.currentState?.setTorchEnabled(isEnabled: isEnabled);
  }

  @override
  bool isTorchEnabled() => _key.currentState?.isTorchEnabled() ?? false;
}
