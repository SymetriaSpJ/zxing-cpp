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
  final PreviewOverlayBuilder? overlayBuilder;

  @override
  State<_AndroidFitatuScannerPreview> createState() => _AndroidFitatuScannerPreviewState();
}

class _AndroidFitatuScannerPreviewState extends State<_AndroidFitatuScannerPreview> with ScannerPreviewMixin {
  _FitatuBarcodeScanner? get _scanner => widget.controller?._scanner;

  @override
  void initState() {
    super.initState();
    _setupScanner();
  }

  @override
  void didUpdateWidget(covariant _AndroidFitatuScannerPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.controller, widget.controller)) {
      final oldController = widget.controller?._scanner;
      oldController?.removeListener(_scannerListener);
      _setupScanner();
    }
  }

  void _setupScanner() {
    _scanner?.addListener(_scannerListener);
    _scanner?.onResult = widget.onResult;
    _scanner?.onError = widget.onError;
  }

  void _scannerListener() {
    if (mounted) {
      setState(() {});
    }
    widget.onChanged?.call();
  }

  @override
  void dispose() {
    _scanner?.removeListener(_scannerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraConfig = _scanner?.cameraConfig;
    final cameraImage = _scanner?.cameraImage;

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
        : CameraPreviewMetrix(
            cropRect: Rect.zero,
            width: 0,
            height: 0,
            rotationDegrees: 0,
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        if (cameraConfig != null)
          ClipRect(
            child: ConstrainedBox(
              constraints: const BoxConstraints.expand(),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox.fromSize(
                  size: Size(
                    math.min(cameraConfig.previewHeight, cameraConfig.previewWidth).toDouble(),
                    math.max(cameraConfig.previewHeight, cameraConfig.previewWidth).toDouble(),
                  ),
                  child: Texture(
                    key: ValueKey(cameraConfig),
                    textureId: cameraConfig.textureId,
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox.expand(
            child: ColoredBox(color: PreviewOverlayTheme.of(context).overlayColor),
          ),
        widget.overlayBuilder?.call(context, metrix) ?? PreviewOverlay(cameraPreviewMetrix: metrix),
      ],
    );
  }

  @override
  void setTorchEnabled({required bool isEnabled}) {
    _scanner?.setTorchEnabled(isEnabled);
  }

  @override
  bool isTorchEnabled() => _scanner?.isTorchEnabled ?? false;
}
