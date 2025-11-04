package com.fitatu.barcodescanner.fitatu_barcode_scanner

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Rect
import android.graphics.SurfaceTexture
import android.hardware.camera2.CameraMetadata
import android.hardware.camera2.CaptureRequest
import android.view.Surface
import androidx.camera.camera2.interop.Camera2Interop
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.core.SurfaceRequest
import androidx.camera.core.TorchState
import androidx.camera.core.resolutionselector.AspectRatioStrategy
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.zxingcpp.BarcodeReader
import io.flutter.view.TextureRegistry
import java.util.concurrent.Executors


class FitatuBarcodeScanner(
	private val lifecycleOwner: LifecycleOwner,
	private val context: Context,
	private val textureRegistry: TextureRegistry,
	private val flutterApi: FitatuBarcodeScannerFlutterApi,
) : FitatuBarcodeScannerHostApi {

	private val barcodeReader by lazy { BarcodeReader() }

	/**
	 * Target resolution defines expected resolution used by camera preview and image analysis.
	 * This is not guarantee that camera will use this resolution. If camera doesn't support this
	 * resolution then the closest one will be picked
	 */
	private var camera: Camera? = null
	private var cameraProvider: ProcessCameraProvider? = null
	private var options: ScannerOptions? = null

	private lateinit var surfaceTexture: SurfaceTexture

	override fun init(options: ScannerOptions) {
		this.options = options
		barcodeReader.options = BarcodeReader.Options(
			formats = if (options.qrCode) setOf(
				BarcodeReader.Format.QR_CODE, BarcodeReader.Format.MICRO_QR_CODE
			) else emptySet(),
			tryHarder = options.tryHarder,
			tryInvert = options.tryInvert,
			tryRotate = options.tryRotate,
		)

		ProcessCameraProvider.getInstance(context).apply {
			addListener(
				{
					if (isCancelled) return@addListener
					cameraProvider = get().apply {
						val result = configureCamera(options, this)
						if (result.isFailure) {
							flutterApi.onTextureChanged(null) {}
						}
					}
				}, ContextCompat.getMainExecutor(context)
			)
		}
	}

	override fun setTorchEnabled(isEnabled: Boolean) {
		camera?.cameraControl?.enableTorch(isEnabled)
	}

	@SuppressLint("UnsafeOptInUsageError")
	private fun configureCamera(
		options: ScannerOptions, processCameraProvider: ProcessCameraProvider,
	) = processCameraProvider.runCatching {
		val resolutionSelector = ResolutionSelector
			.Builder()
			.setAspectRatioStrategy(AspectRatioStrategy.RATIO_16_9_FALLBACK_AUTO_STRATEGY)
			.build()

		val imageAnalysis = ImageAnalysis.Builder()
			.apply {
				Camera2Interop.Extender(this).apply {
					setCaptureRequestOption(
						CaptureRequest.CONTROL_SCENE_MODE,
						CameraMetadata.CONTROL_SCENE_MODE_BARCODE
					)
					// Those values are copied from zxingcpp android example.
					// This should reduce motion blur and improve barcode reading
					setCaptureRequestOption(CaptureRequest.SENSOR_SENSITIVITY, 1600)
//                    setCaptureRequestOption(CaptureRequest.CONTROL_AE_EXPOSURE_COMPENSATION, -8)
				}
			}
			.setResolutionSelector(resolutionSelector)
			.setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
			.build()
			.apply {
				var previousCameraImage: CameraImage? = null

				setAnalyzer(Executors.newSingleThreadExecutor()) { image ->
					val cropSize = image.height.times(options.cropPercent).toInt()
					val cropRect = Rect(
						(image.width - cropSize) / 2,
						(image.height - cropSize) / 2,
						(image.width - cropSize) / 2 + cropSize,
						(image.height - cropSize) / 2 + cropSize
					)
					image.setCropRect(cropRect)

					val cameraImage = CameraImage(
						cropRect = CropRect(
							left = cropRect.left.toLong(),
							top = cropRect.top.toLong(),
							right = cropRect.right.toLong(),
							bottom = cropRect.bottom.toLong()
						),
						width = image.width.toLong(),
						height = image.height.toLong(),
						rotationDegrees = image.imageInfo.rotationDegrees.toLong()
					)

					if (previousCameraImage != cameraImage) {
						previousCameraImage = cameraImage
						ContextCompat.getMainExecutor(context).execute {
							flutterApi.onCameraImage(cameraImage) {}
						}
					}

					try {
						val result = barcodeReader.read(image)
						val code = result?.text?.trim()?.takeIf { it.isNotBlank() } ?: return@setAnalyzer
						val format = when (result.format) {
							BarcodeReader.Format.AZTEC -> FitatuBarcodeFormat.AZTEC
							BarcodeReader.Format.CODABAR -> FitatuBarcodeFormat.CODABAR
							BarcodeReader.Format.CODE_39 -> FitatuBarcodeFormat.CODE39
							BarcodeReader.Format.CODE_93 -> FitatuBarcodeFormat.CODE93
							BarcodeReader.Format.CODE_128 -> FitatuBarcodeFormat.CODE128
							BarcodeReader.Format.DATA_BAR -> FitatuBarcodeFormat.DATA_BAR
							BarcodeReader.Format.DATA_BAR_EXPANDED -> FitatuBarcodeFormat.DATA_BAR_EXPANDED
							BarcodeReader.Format.DATA_MATRIX -> FitatuBarcodeFormat.DATA_MATRIX
							BarcodeReader.Format.EAN_8 -> FitatuBarcodeFormat.EAN8
							BarcodeReader.Format.EAN_13 -> FitatuBarcodeFormat.EAN13
							BarcodeReader.Format.ITF -> FitatuBarcodeFormat.ITF
							BarcodeReader.Format.MAXICODE -> FitatuBarcodeFormat.MAXICODE
							BarcodeReader.Format.PDF_417 -> FitatuBarcodeFormat.PDF417
							BarcodeReader.Format.QR_CODE -> FitatuBarcodeFormat.QR_CODE
							BarcodeReader.Format.MICRO_QR_CODE -> FitatuBarcodeFormat.MICRO_QR_CODE
							BarcodeReader.Format.UPC_A -> FitatuBarcodeFormat.UPC_A
							BarcodeReader.Format.UPC_E -> FitatuBarcodeFormat.UPC_E
							BarcodeReader.Format.NONE -> FitatuBarcodeFormat.UNKNOWN
						}

						ContextCompat.getMainExecutor(context).execute {
							flutterApi.onScanResult(code, format) {}
						}
					} catch (e: Exception) {
						ContextCompat.getMainExecutor(context).execute {
							flutterApi.onScanError(e.toString()) {}
						}
					}
				}
			}

		val preview = Preview.Builder()
			.setResolutionSelector(resolutionSelector)
			.build()

		val cameraSelector = CameraSelector.Builder()
			.requireLensFacing(CameraSelector.LENS_FACING_BACK)
			.build()

		unbindAll()
		camera = bindToLifecycle(lifecycleOwner, cameraSelector, imageAnalysis, preview).apply {
			cameraInfo.torchState.observe(lifecycleOwner) {
				flutterApi.onTorchStateChanged(it == TorchState.ON) {}
			}
		}

		var previousCameraConfig: CameraConfig? = null


		preview.setSurfaceProvider { request ->
			val (textureId, surfaceTexture) = constructSurfaceTexture()
			surfaceTexture.setDefaultBufferSize(
				request.resolution.width, request.resolution.height
			)
			this@FitatuBarcodeScanner.surfaceTexture = surfaceTexture
			val flutterSurface = Surface(this@FitatuBarcodeScanner.surfaceTexture)

			request.provideSurface(
				flutterSurface, Executors.newSingleThreadExecutor()
			) {
				flutterSurface.release()
				when (it.resultCode) {
					SurfaceRequest.Result.RESULT_REQUEST_CANCELLED, SurfaceRequest.Result.RESULT_WILL_NOT_PROVIDE_SURFACE, SurfaceRequest.Result.RESULT_SURFACE_ALREADY_PROVIDED, SurfaceRequest.Result.RESULT_SURFACE_USED_SUCCESSFULLY -> {
					}

					else -> {
						flutterApi.onTextureChanged(null) {}
					}
				}
			}

			val cameraConfig = CameraConfig(
				textureId,
				request.resolution.width.toLong(),
				request.resolution.height.toLong()
			)

			if (previousCameraConfig != cameraConfig) {
				previousCameraConfig = cameraConfig
				flutterApi.onTextureChanged(cameraConfig) {}
			}
		}
	}

	/**
	 * Construct [Surface] for camera preview
	 *
	 * @return Pair of surface id and [Surface]
	 */
	private fun constructSurfaceTexture(): Pair<Long, SurfaceTexture> {
		val entry = textureRegistry.createSurfaceTexture()
		return entry.id() to entry.surfaceTexture()
	}

	override fun release() {
		cameraProvider?.unbindAll()
	}
}
