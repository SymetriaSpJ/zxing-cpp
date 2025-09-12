import 'package:fitatu_barcode_scanner/fitatu_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../scanner_preview_mixin.dart';

typedef CommonScannerController = ResourceLease<MobileScannerController>;

class CommonFitatuScannerPreview extends StatefulWidget {
  const CommonFitatuScannerPreview({
    super.key,
    required this.controller,
    required this.options,
    required this.onResult,
    this.onError,
    this.onChanged,
    this.overlayBuilder,
  });

  final CommonScannerController controller;
  final ScannerOptions options;
  final FitatuBarcodeScannerResultCallback onResult;
  final FitatuBarcodeScannerErrorCallback? onError;
  final VoidCallback? onChanged;
  final PreviewOverlayBuilder? overlayBuilder;

  @override
  State<CommonFitatuScannerPreview> createState() => _CommonFitatuScannerPreviewState();
}

class _CommonFitatuScannerPreviewState extends State<CommonFitatuScannerPreview> with ScannerPreviewMixin {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MobileScannerController>(
      future: widget.controller.resource,
      builder: (context, snapshot) {
        final controller = snapshot.data;
        if (controller == null) return SizedBox.shrink();

        return _LifecycleAware(
          onInit: () => startController(controller),
          onPause: controller.stop,
          onResume: controller.start,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scanWindowSize = constraints.maxHeight * widget.options.cropPercent;
              final scanWindow = Rect.fromCenter(
                center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
                width: scanWindowSize,
                height: scanWindowSize,
              );

              return Stack(
                fit: StackFit.expand,
                children: [
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
      },
    );
  }

  Future<void> startController(MobileScannerController controller) async {
    await controller.start();
    await controller.resetZoomScale();
  }

  @override
  Future<void> setTorchEnabled({required bool isEnabled}) async {
    try {
      await widget.controller.value?.toggleTorch();
    } on Exception catch (e) {
      setException(e);
    } finally {
      torchChangeListener();
      safeSetState();
    }
  }

  @override
  bool isTorchEnabled() => widget.controller.value?.torchEnabled ?? false;

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
  const _LifecycleAware({required this.child, this.onInit, this.onResume, this.onPause});

  final VoidCallback? onInit;
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
    WidgetsBinding.instance.addObserver(this);
    widget.onInit?.call();
    super.initState();
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
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
