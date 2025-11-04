part of '../../fitatu_barcode_scanner.dart';

typedef CommonScannerController = ResourceLease<MobileScannerController>;

class _CommonFitatuScannerPreview extends StatefulWidget {
  const _CommonFitatuScannerPreview({
    super.key,
    required this.controller,
    required this.onResult,
    this.onError,
    this.onChanged,
    this.previewOverlayBuilder,
  });

  final _IOSBarcodeScanner? controller;
  final FitatuBarcodeScannerResultCallback onResult;
  final FitatuBarcodeScannerErrorCallback? onError;
  final FitatuBarcodeScannerPreviewOverlayBuilder? previewOverlayBuilder;
  final VoidCallback? onChanged;

  @override
  State<_CommonFitatuScannerPreview> createState() => _CommonFitatuScannerPreviewState();
}

class _CommonFitatuScannerPreviewState extends State<_CommonFitatuScannerPreview> with ScannerPreviewMixin {
  MobileScannerController? get controller => widget.controller?._controller;
  ScannerOptions? get options => widget.controller?.scannerOptions;

  @override
  Widget build(BuildContext context) {
    return _LifecycleAwareMobileScanner(
      controller: controller,
      options: options,
      previewOverlayBuilder: widget.previewOverlayBuilder,
      onResult: widget.onResult,
      onError: widget.onError,
      onChanged: widget.onChanged,
    );
  }

  @override
  Future<void> setTorchEnabled({required bool isEnabled}) async {
    try {
      if (isTorchEnabled() != isEnabled) {
        await controller?.toggleTorch();
      }
    } catch (e, st) {
      widget.onError?.call(FitatuBarcodeScannerException('Cannot change torch state', e), st);
    }
  }

  @override
  bool isTorchEnabled() => controller?.value.torchState == TorchState.on;
}

final class _LifecycleAwareMobileScanner extends StatefulWidget {
  _LifecycleAwareMobileScanner({
    required this.controller,
    required this.options,
    required this.previewOverlayBuilder,
    required this.onResult,
    required this.onError,
    required this.onChanged,
  }) : assert(
         controller == null || !controller.autoStart,
         'Only controllers with `autoStart=false` are supported',
       );

  final MobileScannerController? controller;
  final ScannerOptions? options;
  final FitatuBarcodeScannerPreviewOverlayBuilder? previewOverlayBuilder;
  final FitatuBarcodeScannerResultCallback onResult;
  final FitatuBarcodeScannerErrorCallback? onError;
  final VoidCallback? onChanged;

  @override
  State<_LifecycleAwareMobileScanner> createState() => _LifecycleAwareMobileScannerState();
}

class _LifecycleAwareMobileScannerState extends State<_LifecycleAwareMobileScanner> {
  final controllerStateLeaseManager = ResourceLeaseManager();
  ResourceLease<MobileScannerController>? controllerStateLease;

  void startController() {
    final controller = widget.controller;
    if (controller == null) return;

    if (controllerStateLeaseManager.hasActiveLease) {
      stopController();
    }

    controllerStateLease = controllerStateLeaseManager.lease<MobileScannerController>(
      create: () async {
        try {
          controller.addListener(onControllerChanged);

          final completer = Completer();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              completer.complete(controller.start());
            }
          });

          await completer.future;

          return controller;
        } catch (e, st) {
          widget.onError?.call(FitatuBarcodeScannerException('Cannot start controller', e), st);
        }

        return controller;
      },
      release: (controller) async {
        try {
          controller.removeListener(onControllerChanged);

          await controller.stop();
        } catch (e, st) {
          widget.onError?.call(FitatuBarcodeScannerException('Cannot release controller', e), st);
        }
      },
    );
  }

  void stopController() {
    controllerStateLease?.release();
  }

  void onControllerChanged() {
    widget.onChanged?.call();
  }

  @override
  void initState() {
    super.initState();
    startController();
  }

  @override
  void didUpdateWidget(covariant _LifecycleAwareMobileScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      stopController();
      startController();
    }
  }

  @override
  void dispose() {
    stopController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanWindowSize = constraints.maxHeight * (widget.options?.cropPercent ?? 0);
        final scanWindow = Rect.fromCenter(
          center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
          width: scanWindowSize,
          height: scanWindowSize,
        );

        final metrix = CameraPreviewMetrix(
          cropRect: scanWindow,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          rotationDegrees: 90,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            if (widget.controller case final controller?)
              _LifecycleAware(
                onPause: () => stopController(),
                onResume: () => startController(),
                child: MobileScanner(
                  controller: controller,
                  useAppLifecycleState: false,
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
                  onDetectError: (error, stackTrace) => widget.onError?.call(
                    FitatuBarcodeScannerException('onDetectError', error),
                    stackTrace,
                  ),
                  errorBuilder: (context, exception) => _ErrorWidget(
                    exception: FitatuBarcodeScannerException(
                      'MobileScanner error',
                      exception,
                    ),
                    onError: widget.onError,
                  ),
                ),
              ),
            widget.previewOverlayBuilder?.call(context, metrix) ?? PreviewOverlay(cameraPreviewMetrix: metrix),
          ],
        );
      },
    );
  }
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

class _ErrorWidget extends StatefulWidget {
  const _ErrorWidget({
    required this.exception,
    required this.onError,
  });

  final FitatuBarcodeScannerException exception;
  final FitatuBarcodeScannerErrorCallback? onError;

  @override
  State<_ErrorWidget> createState() => _ErrorWidgetState();
}

class _ErrorWidgetState extends State<_ErrorWidget> {
  @override
  void initState() {
    super.initState();
    widget.onError?.call(widget.exception, StackTrace.current);
  }

  @override
  void didUpdateWidget(covariant _ErrorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final didChanged = oldWidget.exception != widget.exception || oldWidget.onError != widget.onError;
    if (didChanged) {
      widget.onError?.call(widget.exception, StackTrace.current);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.black,
      child: kDebugMode
          ? SingleChildScrollView(
              child: Text(
                widget.exception.toString(),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white),
              ),
            )
          : Icon(
              Icons.warning,
              color: Colors.white,
            ),
    );
  }
}
