package com.fitatu.barcodescanner.fitatu_barcode_scanner

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.SurfaceTexture
import android.graphics.YuvImage
import android.hardware.camera2.CameraMetadata
import android.hardware.camera2.CaptureRequest
import android.view.Surface
import androidx.camera.camera2.interop.Camera2Interop
import androidx.camera.core.AspectRatio
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.core.SurfaceRequest
import androidx.camera.core.TorchState
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.zxingcpp.BarcodeReader
import io.flutter.view.TextureRegistry
import java.io.ByteArrayOutputStream
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
        options: ScannerOptions, processCameraProvider: ProcessCameraProvider
    ) = processCameraProvider.runCatching {
        val imageAnalysis = ImageAnalysis.Builder()
            .apply {
                Camera2Interop.Extender(this).apply {
                    setCaptureRequestOption(
                        CaptureRequest.CONTROL_SCENE_MODE,
                        CameraMetadata.CONTROL_SCENE_MODE_BARCODE
                    )
                    setCaptureRequestOption(CaptureRequest.SENSOR_SENSITIVITY, 1600)
                    setCaptureRequestOption(CaptureRequest.CONTROL_AE_EXPOSURE_COMPENSATION, -8)
                }
            }
            .setTargetAspectRatio(AspectRatio.RATIO_16_9)
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
            .apply {
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

                    ContextCompat.getMainExecutor(context).execute {
                        flutterApi.onCameraImage(cameraImage) {}
                    }

                    try {
                        val result = barcodeReader.read(image)
                        val code = result?.text?.trim()?.takeIf { it.isNotBlank() }
                        ContextCompat.getMainExecutor(context).execute {
                            flutterApi.result(code) {}
                        }
                    } catch (e: Exception) {
                        ContextCompat.getMainExecutor(context).execute {
                            flutterApi.onScanError(e.toString()) {}
                        }
                    }
                }
            }


        val preview = Preview.Builder()
            .setTargetAspectRatio(AspectRatio.RATIO_16_9)
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
            flutterApi.onTextureChanged(
                CameraConfig(
                    textureId,
                    request.resolution.width.toLong(),
                    request.resolution.height.toLong()
                )
            ) {}
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

    private fun createBitmap(imageProxy: ImageProxy): Bitmap = imageProxy.run {
        val yBuffer = planes[0].buffer // Y
        val vuBuffer = planes[2].buffer // VU

        val ySize = yBuffer.remaining()
        val vuSize = vuBuffer.remaining()

        val nv21 = ByteArray(ySize + vuSize)

        yBuffer.get(nv21, 0, ySize)
        vuBuffer.get(nv21, ySize, vuSize)

        val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
        val outputStream = ByteArrayOutputStream()
        yuvImage.compressToJpeg(cropRect, 75, outputStream)
        val imageBytes = outputStream.toByteArray()

        BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size).run {
            val bmpGrayscale = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmpGrayscale)
            val paint = Paint()

            val contrast = 5f
            val brightness = 128f

            val cm = ColorMatrix(
                floatArrayOf(
                    contrast, 0f, 0f, 0f, brightness,
                    0f, contrast, 0f, 0f, brightness,
                    0f, 0f, contrast, 0f, brightness,
                    0f, 0f, 0f, 1f, 0f
                )
            ).apply { setSaturation(0f) }

            val f = ColorMatrixColorFilter(cm)
            paint.colorFilter = f

            val matrix = Matrix().apply { postRotate(imageInfo.rotationDegrees.toFloat()) }
            val rotatedBitmap = Bitmap.createBitmap(this, 0, 0, width, height, matrix, true)

            canvas.drawBitmap(rotatedBitmap, 0f, 0f, paint)

            rotatedBitmap
        }
    }
}