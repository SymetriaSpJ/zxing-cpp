## 5.2.0
* Android: bumped CameraX to `1.5.1`, leveraging `ResolutionSelector` for a consistent 16:9 analyzer/preview pipeline.
* Android: cache and diff camera textures/images so Flutter only rebuilds when the feed really changes; fire `onChanged` after the first frame to keep overlays in sync.
* API: regenerate the Pigeon bindings with v26.0.1, drop empty barcode readings, and surface `onScanResult` with a non-null `code`.

## 5.1.0
* Breaking: `FitatuBarcodeScannerErrorCallback` now receives a `FitatuBarcodeScannerException` and `StackTrace`; iOS `MobileScanner` errors surface through the callback.
* Guarded the iOS `MobileScannerController` lifecycle to prevent duplicate start/stop calls, restart on resume, and report failures via the preview error builder.
* Renamed `PreviewOverlayBuilder` to `FitatuBarcodeScannerPreviewOverlayBuilder` to match the plugin API.

## 5.0.5
* Fixed initialization of the `CommonFitatuScannerPreview` widget. Prevented multiple calls to `start`
* Added `fvm` to the project
* Bumped flutter from `3.35.1` to `3.35.5`
* Bumbed `mobile_scanner` from `7.1.2` to `7.1.3`

## 5.0.4
* Fixed CMakeLists.txt due to problems with 16KB page size

## 5.0.3
* Migrated to 16KB page size (Android)

## 5.0.2
* Bumped `minSdkVersion` from `21` to `24` 
* Set `ndkVersion` to `27.0.12077973`
* Bumped AGP to `8.13.1`
* Updated `mobile_scanner` package to `7.1.2`
* Updated `pigeon` package to `26.0.1`

## 5.0.1
* Update zxing-cpp to current master due to 16KB page support

## 5.0.0
Lease manager for camera and heavy resources

- New: ResourceLeaseManager — provides exclusive (sequential) access to hardware resources via leases.
  - Adds optional timeouts: `createTimeout` and `releaseTimeout` to guard against hangs.
  - `releaseWaiting()` now completes after the resource is fully released and the lease is dequeued.
- Docs: Added detailed documentation for the lease manager and lease handle.
- Tests: Added unit tests for ResourceLeaseManager covering lifecycle, FIFO, timeouts, and queue limits.

Widget changes (FitatuBarcodeScannerPreview)
- API: constructor now expects `controllerLease: ResourceLease<FitatuBarcodeScannerController>` providing exclusive access to the camera controller.
- Internals: unifies Android/iOS previews behind a single widget; Android uses zxing, iOS uses `MobileScannerController` under the hood.

## 4.0.0
* Renamed `FitatuBarcodeScannerFlutterApi.result` to `FitatuBarcodeScannerFlutterApi.onScanResult`
* The `FitatuBarcodeScannerFlutterApi.onScanResult` now returns `FitatuBarcodeScannerResult` instead of `String`. It contains additional informations like `format`

## 3.1.0
 * Update dependencies to the highest version compatible with Flutter 3.27.3
 * Pull changes form origin repository [zxing-cpp](https://github.com/zxing-cpp/zxing-cpp) from tag v2.3.0
 * Update AGP to 8.2.2

## 2.1.5
 * Default camera overlay
 * Lock orientation to portrait Up
 * Update CameraX preview and analysis config to imporve scanning barcodes
 * Ignore debounce properties
 * Fix not working torch on mobile_scanner lib
 * Catch exceptions and pass to error callbacks

## 2.1.1
 * Fix problem with scanning barcodes placed far from camera 

## 2.0.0
 * Initial release
