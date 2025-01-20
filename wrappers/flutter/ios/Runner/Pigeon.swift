// Autogenerated from Pigeon (v10.0.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon

import Foundation
#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#else
#error("Unsupported platform.")
#endif

private func wrapResult(_ result: Any?) -> [Any?] {
  return [result]
}

private func wrapError(_ error: Any) -> [Any?] {
  if let flutterError = error as? FlutterError {
    return [
      flutterError.code,
      flutterError.message,
      flutterError.details
    ]
  }
  return [
    "\(error)",
    "\(type(of: error))",
    "Stacktrace: \(Thread.callStackSymbols)"
  ]
}

private func nilOrValue<T>(_ value: Any?) -> T? {
  if value is NSNull { return nil }
  return value as! T?
}

/// Generated class from Pigeon that represents data sent in messages.
struct CameraConfig {
  var textureId: Int64
  var previewWidth: Int64
  var previewHeight: Int64

  static func fromList(_ list: [Any?]) -> CameraConfig? {
    let textureId = list[0] is Int64 ? list[0] as! Int64 : Int64(list[0] as! Int32)
    let previewWidth = list[1] is Int64 ? list[1] as! Int64 : Int64(list[1] as! Int32)
    let previewHeight = list[2] is Int64 ? list[2] as! Int64 : Int64(list[2] as! Int32)

    return CameraConfig(
      textureId: textureId,
      previewWidth: previewWidth,
      previewHeight: previewHeight
    )
  }
  func toList() -> [Any?] {
    return [
      textureId,
      previewWidth,
      previewHeight,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct CameraImage {
  var cropRect: CropRect
  var width: Int64
  var height: Int64
  var rotationDegrees: Int64

  static func fromList(_ list: [Any?]) -> CameraImage? {
    let cropRect = CropRect.fromList(list[0] as! [Any?])!
    let width = list[1] is Int64 ? list[1] as! Int64 : Int64(list[1] as! Int32)
    let height = list[2] is Int64 ? list[2] as! Int64 : Int64(list[2] as! Int32)
    let rotationDegrees = list[3] is Int64 ? list[3] as! Int64 : Int64(list[3] as! Int32)

    return CameraImage(
      cropRect: cropRect,
      width: width,
      height: height,
      rotationDegrees: rotationDegrees
    )
  }
  func toList() -> [Any?] {
    return [
      cropRect.toList(),
      width,
      height,
      rotationDegrees,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct CropRect {
  var left: Int64
  var top: Int64
  var right: Int64
  var bottom: Int64

  static func fromList(_ list: [Any?]) -> CropRect? {
    let left = list[0] is Int64 ? list[0] as! Int64 : Int64(list[0] as! Int32)
    let top = list[1] is Int64 ? list[1] as! Int64 : Int64(list[1] as! Int32)
    let right = list[2] is Int64 ? list[2] as! Int64 : Int64(list[2] as! Int32)
    let bottom = list[3] is Int64 ? list[3] as! Int64 : Int64(list[3] as! Int32)

    return CropRect(
      left: left,
      top: top,
      right: right,
      bottom: bottom
    )
  }
  func toList() -> [Any?] {
    return [
      left,
      top,
      right,
      bottom,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct ScannerOptions {
  var tryHarder: Bool
  var tryRotate: Bool
  var tryInvert: Bool
  var qrCode: Bool
  var cropPercent: Double
  var scanDelay: Int64
  var scanDelaySuccess: Int64

  static func fromList(_ list: [Any?]) -> ScannerOptions? {
    let tryHarder = list[0] as! Bool
    let tryRotate = list[1] as! Bool
    let tryInvert = list[2] as! Bool
    let qrCode = list[3] as! Bool
    let cropPercent = list[4] as! Double
    let scanDelay = list[5] is Int64 ? list[5] as! Int64 : Int64(list[5] as! Int32)
    let scanDelaySuccess = list[6] is Int64 ? list[6] as! Int64 : Int64(list[6] as! Int32)

    return ScannerOptions(
      tryHarder: tryHarder,
      tryRotate: tryRotate,
      tryInvert: tryInvert,
      qrCode: qrCode,
      cropPercent: cropPercent,
      scanDelay: scanDelay,
      scanDelaySuccess: scanDelaySuccess
    )
  }
  func toList() -> [Any?] {
    return [
      tryHarder,
      tryRotate,
      tryInvert,
      qrCode,
      cropPercent,
      scanDelay,
      scanDelaySuccess,
    ]
  }
}
private class FitatuBarcodeScannerHostApiCodecReader: FlutterStandardReader {
  override func readValue(ofType type: UInt8) -> Any? {
    switch type {
      case 128:
        return ScannerOptions.fromList(self.readValue() as! [Any?])
      default:
        return super.readValue(ofType: type)
    }
  }
}

private class FitatuBarcodeScannerHostApiCodecWriter: FlutterStandardWriter {
  override func writeValue(_ value: Any) {
    if let value = value as? ScannerOptions {
      super.writeByte(128)
      super.writeValue(value.toList())
    } else {
      super.writeValue(value)
    }
  }
}

private class FitatuBarcodeScannerHostApiCodecReaderWriter: FlutterStandardReaderWriter {
  override func reader(with data: Data) -> FlutterStandardReader {
    return FitatuBarcodeScannerHostApiCodecReader(data: data)
  }

  override func writer(with data: NSMutableData) -> FlutterStandardWriter {
    return FitatuBarcodeScannerHostApiCodecWriter(data: data)
  }
}

class FitatuBarcodeScannerHostApiCodec: FlutterStandardMessageCodec {
  static let shared = FitatuBarcodeScannerHostApiCodec(readerWriter: FitatuBarcodeScannerHostApiCodecReaderWriter())
}

/// Generated protocol from Pigeon that represents a handler of messages from Flutter.
protocol FitatuBarcodeScannerHostApi {
  func init(options: ScannerOptions) throws
  func release() throws
  func setTorchEnabled(isEnabled: Bool) throws
}

/// Generated setup class from Pigeon to handle messages through the `binaryMessenger`.
class FitatuBarcodeScannerHostApiSetup {
  /// The codec used by FitatuBarcodeScannerHostApi.
  static var codec: FlutterStandardMessageCodec { FitatuBarcodeScannerHostApiCodec.shared }
  /// Sets up an instance of `FitatuBarcodeScannerHostApi` to handle messages through the `binaryMessenger`.
  static func setUp(binaryMessenger: FlutterBinaryMessenger, api: FitatuBarcodeScannerHostApi?) {
    let initChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.FitatuBarcodeScannerHostApi.init", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      initChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let optionsArg = args[0] as! ScannerOptions
        do {
          try api.init(options: optionsArg)
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      initChannel.setMessageHandler(nil)
    }
    let releaseChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.FitatuBarcodeScannerHostApi.release", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      releaseChannel.setMessageHandler { _, reply in
        do {
          try api.release()
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      releaseChannel.setMessageHandler(nil)
    }
    let setTorchEnabledChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.FitatuBarcodeScannerHostApi.setTorchEnabled", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      setTorchEnabledChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let isEnabledArg = args[0] as! Bool
        do {
          try api.setTorchEnabled(isEnabled: isEnabledArg)
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      setTorchEnabledChannel.setMessageHandler(nil)
    }
  }
}
private class FitatuBarcodeScannerFlutterApiCodecReader: FlutterStandardReader {
  override func readValue(ofType type: UInt8) -> Any? {
    switch type {
      case 128:
        return CameraConfig.fromList(self.readValue() as! [Any?])
      case 129:
        return CameraImage.fromList(self.readValue() as! [Any?])
      case 130:
        return CropRect.fromList(self.readValue() as! [Any?])
      default:
        return super.readValue(ofType: type)
    }
  }
}

private class FitatuBarcodeScannerFlutterApiCodecWriter: FlutterStandardWriter {
  override func writeValue(_ value: Any) {
    if let value = value as? CameraConfig {
      super.writeByte(128)
      super.writeValue(value.toList())
    } else if let value = value as? CameraImage {
      super.writeByte(129)
      super.writeValue(value.toList())
    } else if let value = value as? CropRect {
      super.writeByte(130)
      super.writeValue(value.toList())
    } else {
      super.writeValue(value)
    }
  }
}

private class FitatuBarcodeScannerFlutterApiCodecReaderWriter: FlutterStandardReaderWriter {
  override func reader(with data: Data) -> FlutterStandardReader {
    return FitatuBarcodeScannerFlutterApiCodecReader(data: data)
  }

  override func writer(with data: NSMutableData) -> FlutterStandardWriter {
    return FitatuBarcodeScannerFlutterApiCodecWriter(data: data)
  }
}

class FitatuBarcodeScannerFlutterApiCodec: FlutterStandardMessageCodec {
  static let shared = FitatuBarcodeScannerFlutterApiCodec(readerWriter: FitatuBarcodeScannerFlutterApiCodecReaderWriter())
}

/// Generated class from Pigeon that represents Flutter messages that can be called from Swift.
class FitatuBarcodeScannerFlutterApi {
  private let binaryMessenger: FlutterBinaryMessenger
  init(binaryMessenger: FlutterBinaryMessenger){
    self.binaryMessenger = binaryMessenger
  }
  var codec: FlutterStandardMessageCodec {
    return FitatuBarcodeScannerFlutterApiCodec.shared
  }
  func onTextureChanged(cameraConfig cameraConfigArg: CameraConfig?, completion: @escaping () -> Void) {
    let channel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.FitatuBarcodeScannerFlutterApi.onTextureChanged", binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([cameraConfigArg] as [Any?]) { _ in
      completion()
    }
  }
  func onTorchStateChanged(isEnabled isEnabledArg: Bool, completion: @escaping () -> Void) {
    let channel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.FitatuBarcodeScannerFlutterApi.onTorchStateChanged", binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([isEnabledArg] as [Any?]) { _ in
      completion()
    }
  }
  func onCameraImage(cameraImage cameraImageArg: CameraImage, completion: @escaping () -> Void) {
    let channel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.FitatuBarcodeScannerFlutterApi.onCameraImage", binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([cameraImageArg] as [Any?]) { _ in
      completion()
    }
  }
  func result(code codeArg: String?, completion: @escaping () -> Void) {
    let channel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.FitatuBarcodeScannerFlutterApi.result", binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([codeArg] as [Any?]) { _ in
      completion()
    }
  }
  func onScanError(error errorArg: String, completion: @escaping () -> Void) {
    let channel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.FitatuBarcodeScannerFlutterApi.onScanError", binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([errorArg] as [Any?]) { _ in
      completion()
    }
  }
}
