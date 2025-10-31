import 'package:flutter/material.dart';

import 'package:fitatu_barcode_scanner/fitatu_barcode_scanner.dart';

final _resourceLease = ResourceLeaseManager();

final class ScanExample extends StatefulWidget {
  const ScanExample({super.key});

  @override
  State<ScanExample> createState() => _ScanExampleState();
}

class _ScanExampleState extends State<ScanExample> {
  bool tryHarder = false;
  bool tryRotate = true;
  bool tryInvert = true;
  bool qrCode = false;
  bool started = false;
  bool enableTorch = false;
  bool fullscreen = false;
  double cropPercent = 0.8;
  FitatuBarcodeScannerResult? result;
  Object? exception;
  late final ResourceLease<FitatuBarcodeScannerController> controllerLease;
  late final _previewKey = GlobalKey<FitatuBarcodeScannerPreviewState>();

  @override
  void initState() {
    super.initState();
    controllerLease = _resourceLease.lease(
      create: () => Future.value(
        FitatuBarcodeScannerController.platform(
          ScannerOptions(
            tryHarder: tryHarder,
            tryRotate: tryRotate,
            tryInvert: tryInvert,
            qrCode: qrCode,
            cropPercent: cropPercent,
            scanDelay: 50,
            scanDelaySuccess: 300,
          ),
        ),
      ),
      release: (controller) => controller.disposeController(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    controllerLease.release();
  }

  @override
  Widget build(BuildContext context) {
    final preview = Material(
      child: Stack(
        children: [
          FitatuBarcodeScannerPreview(
            key: _previewKey,
            controllerLease: controllerLease,
            onResult: (value) {
              if (value.code == null) return;
              setState(() {
                result = value;
                exception = null;
              });
            },
            onError: (exception, stackTrace) {
              setState(() {
                result = null;
                this.exception = exception;
              });
            },
            onChanged: () {
              setState(() {
                enableTorch = _previewKey.currentState?.isTorchEnabled() ?? false;
              });
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(minWidth: 200, minHeight: 20),
                  color: Colors.white.withValues(alpha: 0.5),
                  child: Column(
                    children: [
                      if (result == null)
                        Text('<no results>')
                      else if (result case final result?) ...[
                        Text(
                          result.code ?? '<no code>',
                          style: const TextStyle(color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'format: ${result.format.name}',
                          style: const TextStyle(color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(minWidth: 200, minHeight: 20),
                  color: Colors.white.withValues(alpha: 0.5),
                  child: Text(
                    exception?.toString() ?? '<no exceptions>',
                    style: const TextStyle(color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              onPressed: () {
                setState(() {
                  enableTorch = !enableTorch;
                });
                _previewKey.currentState?.setTorchEnabled(isEnabled: enableTorch);
              },
              icon: Icon(enableTorch ? Icons.flash_off : Icons.flash_on),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: IconButton(
              icon: Icon(fullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
              onPressed: () {
                setState(() {
                  fullscreen = !fullscreen;
                });
              },
            ),
          ),
        ],
      ),
    );

    return fullscreen
        ? preview
        : DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('FitatuBarcodeScanner example app'),
                bottom: const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.camera)),
                    Tab(icon: Icon(Icons.settings)),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  if (started)
                    preview
                  else
                    MaterialButton(child: const Text('Tap to start'), onPressed: () => setState(() => started = true)),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: tryHarder,
                          title: const Text('tryHarder'),
                          onChanged: (value) => setState(() => tryHarder = !tryHarder),
                        ),
                        SwitchListTile(
                          value: tryRotate,
                          title: const Text('tryRotate'),
                          onChanged: (value) => setState(() => tryRotate = !tryRotate),
                        ),
                        SwitchListTile(
                          value: tryInvert,
                          title: const Text('tryInvert'),
                          onChanged: (value) => setState(() => tryInvert = !tryInvert),
                        ),
                        SwitchListTile(value: qrCode, title: const Text('qrCode'), onChanged: (value) => setState(() => qrCode = !qrCode)),
                        Slider(
                          value: cropPercent,
                          max: 1,
                          divisions: 10,
                          label: cropPercent.toString(),
                          onChanged: (value) {
                            if (value < 0.1) return;
                            setState(() {
                              cropPercent = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
