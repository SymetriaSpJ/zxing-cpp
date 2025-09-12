import 'package:fitatu_barcode_scanner/fitatu_barcode_scanner.dart';
import 'package:flutter/widgets.dart';
import 'dart:math';

class PreviewOverlay extends StatefulWidget {
  const PreviewOverlay({
    super.key,
    required this.cameraPreviewMetrix,
    this.theme,
  });

  final CameraPreviewMetrix cameraPreviewMetrix;
  final PreviewOverlayThemeData? theme;

  @override
  State<PreviewOverlay> createState() => _PreviewOverlayState();
}

class _PreviewOverlayState extends State<PreviewOverlay> with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.theme ?? PreviewOverlayTheme.of(context);

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        if (widget.cameraPreviewMetrix.hasSize) {
          return CustomPaint(
            painter: _PreviewOverlayPainter(
              metrix: widget.cameraPreviewMetrix,
              theme: currentTheme,
              animation: animationController.value,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _PreviewOverlayPainter extends CustomPainter {
  final CameraPreviewMetrix metrix;
  final PreviewOverlayThemeData theme;
  final Paint overlayPaint;
  final Paint laserPaint;
  final Paint cropRectBorderPaint;

  final double animation;

  _PreviewOverlayPainter({
    required this.metrix,
    required this.theme,
    required this.animation,
  }) : overlayPaint = Paint()..color = theme.overlayColor,
       laserPaint = Paint()
         ..style = PaintingStyle.stroke
         ..color = theme.laserLineColor.withValues(alpha: animation)
         ..strokeWidth = theme.laserLineThickness,
       cropRectBorderPaint = Paint()
         ..style = PaintingStyle.stroke
         ..color = theme.cropRectBorderColor
         ..strokeWidth = theme.cropRectBorderThickness;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (min(size.width, size.height) / metrix.height);
    final offset = (max(size.width, size.height) - (metrix.width * scale).toInt()) / 2;

    final cropRect = Rect.fromLTRB(
      metrix.cropRect.left.toDouble(),
      metrix.cropRect.top.toDouble(),
      metrix.cropRect.right.toDouble(),
      metrix.cropRect.bottom.toDouble(),
    );

    final RRect roundedCropRect = RRect.fromRectAndRadius(
      cropRect,
      Radius.circular(theme.cropRectBorderRadius),
    );

    canvas.save();
    if (metrix.rotationDegrees == 90) {
      canvas.translate(size.width, 0);
      canvas.rotate(_degreesToRadians(90));
    }
    canvas.translate(offset, 0);
    canvas.scale(scale, scale);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(
          Rect.fromCenter(
            center: Offset((metrix.width - 1) / 2, metrix.height / 2),
            width: size.height / scale,
            height: size.width / scale,
          ),
        ),
        Path()..addRRect(roundedCropRect),
      ),
      overlayPaint,
    );

    if (theme.showCropRectBorder) {
      canvas.drawRRect(roundedCropRect, cropRectBorderPaint);
    }

    if (theme.showLaserLine && !metrix.cropRect.isEmpty) {
      canvas.drawLine(cropRect.bottomCenter, cropRect.topCenter, laserPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PreviewOverlayPainter oldDelegate) {
    return oldDelegate.metrix != metrix || oldDelegate.theme != theme || animation != oldDelegate.animation;
  }

  double _degreesToRadians(num degrees) => degrees * pi / 180;
}
