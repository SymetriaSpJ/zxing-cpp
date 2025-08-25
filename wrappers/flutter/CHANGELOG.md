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