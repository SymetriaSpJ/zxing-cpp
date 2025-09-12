import 'dart:io';

import 'package:fitatu_barcode_scanner/fitatu_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../scanner_preview_mixin.dart';
import 'android/android_fitatu_scanner_preview.dart';
import 'android/camera_permissions_guard.dart';
import 'common/common_fitatu_scanner_preview.dart';

typedef PreviewOverlayBuilder = Widget Function(BuildContext context, CameraPreviewMetrix metrix);

class FitatuBarcodeScannerPreview extends StatefulWidget {
  const FitatuBarcodeScannerPreview({
    super.key,
    required this.options,
    required this.onResult,
    this.commonScannerController,
    this.onError,
    this.onChanged,
    this.previewOverlayBuilder,
    this.theme = const PreviewOverlayThemeData(),
  });

  final CommonScannerController? commonScannerController;
  final ScannerOptions options;
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

    if (widget.commonScannerController case final controller?) {
      preview = CommonFitatuScannerPreview(
        key: _key,
        controller: controller,
        onResult: widget.onResult,
        options: widget.options,
        onChanged: widget.onChanged,
        onError: widget.onError,
        overlayBuilder: widget.previewOverlayBuilder,
      );
    } else if (Platform.isAndroid) {
      preview = CameraPermissionsGuard(
        child: AndroidFitatuScannerPreview(
          key: _key,
          onResult: widget.onResult,
          options: widget.options,
          onChanged: widget.onChanged,
          onError: widget.onError,
          overlayBuilder: widget.previewOverlayBuilder,
        ),
      );
    } else {
      throw UnimplementedError(
        'Unsupported platform - ${Platform.operatingSystem}. Use `commonScannerControler`',
      );
    }

    return PreviewOverlayTheme(themeData: widget.theme, child: preview);
  }

  @override
  void setTorchEnabled({required bool isEnabled}) {
    _key.currentState?.setTorchEnabled(isEnabled: isEnabled);
  }

  @override
  bool isTorchEnabled() => _key.currentState?.isTorchEnabled() ?? false;
}
