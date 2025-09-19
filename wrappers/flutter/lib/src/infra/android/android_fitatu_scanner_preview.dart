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
  _FitatuBarcodeScanner? get scanner => widget.controller?._scanner;
  late CameraPreviewMetrix metrix;
  late CameraConfig? cameraConfig;
  late CameraImage? cameraImage;

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
      oldController?.removeListener(_onScannerChanged);
      _setupScanner();
    }
  }

  void _setupScanner() {
    scanner?.addListener(_onScannerChanged);
    scanner?.onResult = widget.onResult;
    scanner?.onError = widget.onError;
    _onScannerChanged();
  }

  void _onScannerChanged() {
    if (mounted) {
      setState(() {});
    }

    cameraConfig = scanner?.cameraConfig;
    final image = cameraImage = scanner?._cameraImage;

    metrix = image != null
        ? CameraPreviewMetrix(
            cropRect: Rect.fromLTRB(
              image.cropRect.left.toDouble(),
              image.cropRect.top.toDouble(),
              image.cropRect.right.toDouble(),
              image.cropRect.bottom.toDouble(),
            ),
            width: image.width.toDouble(),
            height: image.height.toDouble(),
            rotationDegrees: image.rotationDegrees,
          )
        : CameraPreviewMetrix(
            cropRect: Rect.zero,
            width: 0,
            height: 0,
            rotationDegrees: 0,
          );

    widget.onChanged?.call();
  }

  @override
  void dispose() {
    scanner?.removeListener(_onScannerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (cameraConfig case final config?)
          ClipRect(
            child: ConstrainedBox(
              constraints: const BoxConstraints.expand(),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox.fromSize(
                  size: Size(
                    math.min(config.previewHeight, config.previewWidth).toDouble(),
                    math.max(config.previewHeight, config.previewWidth).toDouble(),
                  ),
                  child: Texture(
                    key: ValueKey(cameraConfig),
                    textureId: config.textureId,
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
    scanner?.setTorchEnabled(isEnabled);
  }

  @override
  bool isTorchEnabled() => scanner?.isTorchEnabled ?? false;
}
