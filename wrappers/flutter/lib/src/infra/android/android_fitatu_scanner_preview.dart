part of '../../fitatu_barcode_scanner.dart';

class _AndroidFitatuScannerPreview extends StatefulWidget {
  const _AndroidFitatuScannerPreview({
    required this.controller,
    required this.onResult,
    this.onChanged,
    this.onError,
    this.overlayBuilder,
    super.key,
  });

  final _AndroidBarcodeScanner? controller;
  final FitatuBarcodeScannerResultCallback onResult;
  final FitatuBarcodeScannerErrorCallback? onError;
  final VoidCallback? onChanged;
  final FitatuBarcodeScannerPreviewOverlayBuilder? overlayBuilder;

  @override
  State<_AndroidFitatuScannerPreview> createState() => _AndroidFitatuScannerPreviewState();
}

class _AndroidFitatuScannerPreviewState extends State<_AndroidFitatuScannerPreview> with ScannerPreviewMixin {
  late _PreviewConfig _previewConfig;

  @override
  void initState() {
    super.initState();
    _setupScanner(widget.controller?._scanner);
  }

  @override
  void didUpdateWidget(covariant _AndroidFitatuScannerPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldScanner = oldWidget.controller?._scanner;
    final newScanner = widget.controller?._scanner;

    if (!identical(oldScanner, newScanner)) {
      oldScanner?.removeListener(_onScannerChanged);
      oldScanner?.onResult = null;
      oldScanner?.onError = null;
      _setupScanner(newScanner);
    }
  }

  void _setupScanner(_FitatuBarcodeScanner? scanner) {
    if (scanner != null) {
      scanner.addListener(_onScannerChanged);
      scanner.onResult = widget.onResult;
      scanner.onError = widget.onError;
    }
    _setPreviewConfig(scanner);
  }

  void _onScannerChanged() {
    _setPreviewConfig(widget.controller?._scanner);
    // Notify listeners after the first frame because the camera updates before
    // the widgets mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onChanged?.call();
      }
    });
  }

  void _setPreviewConfig(_FitatuBarcodeScanner? scanner) {
    final cameraImage = scanner?._cameraImage;
    final metrix = cameraImage != null
        ? CameraPreviewMetrix(
            cropRect: Rect.fromLTRB(
              cameraImage.cropRect.left.toDouble(),
              cameraImage.cropRect.top.toDouble(),
              cameraImage.cropRect.right.toDouble(),
              cameraImage.cropRect.bottom.toDouble(),
            ),
            width: cameraImage.width.toDouble(),
            height: cameraImage.height.toDouble(),
            rotationDegrees: cameraImage.rotationDegrees,
          )
        : CameraPreviewMetrix(cropRect: Rect.zero, width: 0, height: 0, rotationDegrees: 0);

    _previewConfig = _PreviewConfig(metrix, scanner?.cameraConfig);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller?._scanner.removeListener(_onScannerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_previewConfig.cameraConfig case final cameraConfig?)
          ClipRect(
            child: ConstrainedBox(
              constraints: const BoxConstraints.expand(),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox.fromSize(
                  size: _previewConfig.textureSize,
                  child: Texture(key: ValueKey(cameraConfig), textureId: cameraConfig.textureId),
                ),
              ),
            ),
          )
        else
          SizedBox.expand(child: ColoredBox(color: PreviewOverlayTheme.of(context).overlayColor)),
        widget.overlayBuilder?.call(context, _previewConfig.metrix) ?? PreviewOverlay(cameraPreviewMetrix: _previewConfig.metrix),
      ],
    );
  }

  @override
  void setTorchEnabled({required bool isEnabled}) {
    widget.controller?._scanner.setTorchEnabled(isEnabled);
  }

  @override
  bool isTorchEnabled() => widget.controller?._scanner.isTorchEnabled ?? false;
}

final class _PreviewConfig {
  const _PreviewConfig(this.metrix, this.cameraConfig);

  final CameraPreviewMetrix metrix;
  final CameraConfig? cameraConfig;

  Size get textureSize {
    if (cameraConfig case final cameraConfig?) {
      return Size(
        math.min(cameraConfig.previewHeight, cameraConfig.previewWidth).toDouble(),
        math.max(cameraConfig.previewHeight, cameraConfig.previewWidth).toDouble(),
      );
    }

    return Size.zero;
  }

  @override
  int get hashCode => Object.hash(metrix, cameraConfig);

  @override
  bool operator ==(Object other) => other is _PreviewConfig && other.hashCode == hashCode;
}
