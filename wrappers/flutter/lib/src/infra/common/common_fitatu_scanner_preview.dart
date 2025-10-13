part of '../../fitatu_barcode_scanner.dart';

typedef CommonScannerController = ResourceLease<MobileScannerController>;

class _CommonFitatuScannerPreview extends StatefulWidget {
  const _CommonFitatuScannerPreview({
    super.key,
    required this.controller,
    required this.onResult,
    this.onError,
    this.onChanged,
    this.overlayBuilder,
  });

  final _IOSBarcodeScanner? controller;
  final FitatuBarcodeScannerResultCallback onResult;
  final FitatuBarcodeScannerErrorCallback? onError;
  final VoidCallback? onChanged;
  final PreviewOverlayBuilder? overlayBuilder;

  @override
  State<_CommonFitatuScannerPreview> createState() => _CommonFitatuScannerPreviewState();
}

class _CommonFitatuScannerPreviewState extends State<_CommonFitatuScannerPreview> with ScannerPreviewMixin {
  MobileScannerController? get controller => widget.controller?._controller;
  ScannerOptions? get options => widget.controller?.scannerOptions;

  Future<void> startController(MobileScannerController? controller) async {
    if (controller == null || controller.value.isStarting) return;
    await controller.start();
    await controller.resetZoomScale();
  }

  @override
  void initState() {
    super.initState();
    unawaited(startController(controller));
  }

  @override
  void didUpdateWidget(covariant _CommonFitatuScannerPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      unawaited(startController(controller));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _LifecycleAware(
      onPause: controller?.stop,
      onResume: () => startController(controller),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scanWindowSize = constraints.maxHeight * (options?.cropPercent ?? 0);
          final scanWindow = Rect.fromCenter(
            center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
            width: scanWindowSize,
            height: scanWindowSize,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              if (controller case final controller?)
                MobileScanner(
                  controller: controller,
                  scanWindow: scanWindow,
                  onDetect: (response) {
                    final barcodes = response.barcodes.where((b) => b.rawValue != null).whereType<Barcode>().toList();
                    if (barcodes.isEmpty) {
                      widget.onResult(FitatuBarcodeScannerResult(null, FitatuBarcodeFormat.unknown));
                    } else {
                      final barcode = barcodes.first;
                      final rawBarcode = barcode.rawValue;

                      widget.onResult(
                        FitatuBarcodeScannerResult(rawBarcode, switch (barcode.format) {
                          BarcodeFormat.unknown => FitatuBarcodeFormat.unknown,
                          BarcodeFormat.all => FitatuBarcodeFormat.all,
                          BarcodeFormat.code128 => FitatuBarcodeFormat.code128,
                          BarcodeFormat.code39 => FitatuBarcodeFormat.code39,
                          BarcodeFormat.code93 => FitatuBarcodeFormat.code93,
                          BarcodeFormat.codabar => FitatuBarcodeFormat.codabar,
                          BarcodeFormat.dataMatrix => FitatuBarcodeFormat.dataMatrix,
                          BarcodeFormat.ean13 => FitatuBarcodeFormat.ean13,
                          BarcodeFormat.ean8 => FitatuBarcodeFormat.ean8,
                          BarcodeFormat.itf => FitatuBarcodeFormat.itf,
                          BarcodeFormat.qrCode => FitatuBarcodeFormat.qrCode,
                          BarcodeFormat.upcA => FitatuBarcodeFormat.upcA,
                          BarcodeFormat.upcE => FitatuBarcodeFormat.upcE,
                          BarcodeFormat.pdf417 => FitatuBarcodeFormat.pdf417,
                          BarcodeFormat.aztec => FitatuBarcodeFormat.aztec,
                        }),
                      );
                    }
                  },
                ),
              Builder(
                builder: (context) {
                  final metrix = CameraPreviewMetrix(
                    cropRect: scanWindow,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    rotationDegrees: 90,
                  );

                  return widget.overlayBuilder?.call(context, metrix) ?? PreviewOverlay(cameraPreviewMetrix: metrix);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Future<void> setTorchEnabled({required bool isEnabled}) async {
    try {
      await controller?.toggleTorch();
    } on Exception catch (e) {
      setException(e);
    } finally {
      torchChangeListener();
      safeSetState();
    }
  }

  @override
  bool isTorchEnabled() => controller?.torchEnabled ?? false;

  void safeSetState() {
    if (mounted) {
      setState(() {});
    }
  }

  void setException(Exception? exception) {
    widget.onError?.call(exception?.toString());
  }

  void torchChangeListener() => widget.onChanged?.call();
}

class _LifecycleAware extends StatefulWidget {
  const _LifecycleAware({required this.child, this.onResume, this.onPause});

  final VoidCallback? onResume;
  final VoidCallback? onPause;
  final Widget child;

  @override
  State<_LifecycleAware> createState() => _LifecycleAwareState();
}

class _LifecycleAwareState extends State<_LifecycleAware> with WidgetsBindingObserver {
  bool isStarted = false;
  bool resumeFromBackground = false;
  int startRetryCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        resumeFromBackground = false;
        widget.onResume?.call();
        break;
      case AppLifecycleState.paused:
        resumeFromBackground = true;
        break;
      case AppLifecycleState.inactive:
        if (!resumeFromBackground) {
          widget.onPause?.call();
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
