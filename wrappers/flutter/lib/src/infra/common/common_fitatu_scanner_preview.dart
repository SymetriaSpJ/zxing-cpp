import 'package:fitatu_barcode_scanner/fitatu_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../pigeon.dart';
import '../../scanner_preview_mixin.dart';

class CommonFitatuScannerPreview extends StatefulWidget {
  const CommonFitatuScannerPreview({
    super.key,
    required this.options,
    required this.onResult,
    this.onError,
    this.onChanged,
    this.overlayBuilder,
  });

  final ScannerOptions options;
  final FitatuBarcodeScannerResultCallback onResult;
  final FitatuBarcodeScannerErrorCallback? onError;
  final VoidCallback? onChanged;
  final PreviewOverlayBuilder? overlayBuilder;

  @override
  State<CommonFitatuScannerPreview> createState() => _CommonFitatuScannerPreviewState();
}

class _CommonFitatuScannerPreviewState extends State<CommonFitatuScannerPreview> with ScannerPreviewMixin, WidgetsBindingObserver {
  late MobileScannerController controller;
  bool isStarted = false;
  bool resumeFromBackground = false;
  int startRetryCount = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    controller = MobileScannerController(autoStart: false);
    startScanner();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeScanner();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before the controller was initialized.

    switch (state) {
      case AppLifecycleState.resumed:
        resumeFromBackground = false;
        startScanner();
        break;
      case AppLifecycleState.paused:
        resumeFromBackground = true;
        break;
      case AppLifecycleState.inactive:
        if (!resumeFromBackground) {
          stopScanner();
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
    return LayoutBuilder(
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
                  widget.onResult(FitatuBarcodeScannerResult(code: null, format: FitatuBarcodeFormat.none));
                } else {
                  final barcode = barcodes.first;
                  final rawBarcode = barcode.rawValue;

                  widget.onResult(
                    FitatuBarcodeScannerResult(
                      code: rawBarcode,
                      format: switch (barcode.format) {
                        BarcodeFormat.unknown => FitatuBarcodeFormat.unknowm,
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
                      },
                    ),
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
    );
  }

  @override
  Future<void> setTorchEnabled({required bool isEnabled}) async {
    try {
      await controller.toggleTorch();
    } on Exception catch (e) {
      setException(e);
    } finally {
      torchChangeListener();
      safeSetState();
    }
  }

  @override
  bool isTorchEnabled() => controller.torchEnabled;

  Future<void> startScanner() async {
    try {
      isStarted = true;
      await controller.start();
      await controller.resetZoomScale();
      setException(null);
      startRetryCount = 0;
    } on Exception catch (e) {
      isStarted = false;
      if (startRetryCount < 1) {
        startRetryCount++;
        await stopScanner();
        await startScanner();
      } else {
        setException(e);
      }
    } finally {
      safeSetState();
    }
  }

  Future<void> stopScanner() async {
    try {
      isStarted = false;
      await controller.stop();
    } on Exception catch (e) {
      setException(e);
    } finally {
      safeSetState();
    }
  }

  void disposeScanner() {
    try {
      isStarted = false;
      controller.dispose();
    } on Exception catch (e) {
      setException(e);
    }
  }

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
