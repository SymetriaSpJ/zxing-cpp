# fitatu_barcode_scanner

Flutter barcode scanner implementation based on ZXing.

## Resource lease manager (camera-safe access)

This package ships a small utility to safely serialize access to heavy, exclusive resources such as camera controllers.

- `ResourceLeaseManager` provides exclusive (sequential) access via leases.
- Each lease has a `Future<T> resource` that completes when the resource is created, and a `release()`/`releaseWaiting()` to free it.
- Optional timeouts: `createTimeout` and `releaseTimeout` protect against hangs.

Example usage with a camera controller:

```dart
final leases = ResourceLeaseManager(
  createTimeout: const Duration(seconds: 10),
  releaseTimeout: const Duration(seconds: 10),
);

// Request an exclusive lease
final lease = leases.lease<CameraController>(
  create: () async {
    final controller = CameraController(description, ResolutionPreset.high);
    await controller.initialize();
    return controller;
  },
  release: (controller) => controller.dispose(),
);

// Use the resource when ready
final controller = await lease.resource;
try {
  await controller.startVideoRecording();
} finally {
  // Always release in dispose/finally
  await lease.releaseWaiting();
}
```

Notes
- The manager guarantees FIFO and single active lease at a time.
- `releaseWaiting()` completes after the resource is fully released and the lease is dequeued, so it’s safe to rely on it before acquiring another lease.

## Getting Started

To work with native plugin code:

1. Go to the `zxing-cpp/wrappers/flutter/example`
2. Run `flutter build apk --config-only`
3. Select **Open an existing Android Studio Project** in the **Welcome to Android Studio** dialog, or select **File > Open** from the menu, and select the `hello/example/android/build.gradle` file.
4. In the **Gradle Sync** dialog, select OK.
5. In the **Android Gradle Plugin Update** dialog, select **Don't remind me again for this project.**

## Pigeon

To generate pigeon interfaces run:

```bash
dart run pigeon --input=pigeons/pigeons.dart
```