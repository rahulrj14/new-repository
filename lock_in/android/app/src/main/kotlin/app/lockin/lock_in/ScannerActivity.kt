package app.lockin.lock_in

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.PlanarYUVLuminanceSource
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.qrcode.QRCodeReader
import java.util.concurrent.Executors

/**
 * Fully offline QR scanner: CameraX for frames, ZXing (pure Java) to decode.
 * No ML Kit, no Play Services, no network. Frames are analysed in memory
 * and dropped; nothing is saved. Only accepts Lock In codes.
 */
class ScannerActivity : ComponentActivity() {
    private val executor = Executors.newSingleThreadExecutor()
    private val reader = QRCodeReader()
    private val hints = mapOf(
        DecodeHintType.POSSIBLE_FORMATS to listOf(BarcodeFormat.QR_CODE),
        DecodeHintType.TRY_HARDER to true,
    )
    @Volatile private var done = false
    private lateinit var preview: PreviewView

    private val askCamera = registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) startCamera() else finishWith(null)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        preview = PreviewView(this)
        val root = FrameLayout(this).apply { setBackgroundColor(Color.BLACK) }
        root.addView(preview, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        val hint = TextView(this).apply {
            text = "Point at your friend's Lock In code"
            setTextColor(Color.WHITE)
            textSize = 18f
            setPadding(48, 48, 48, 48)
            gravity = Gravity.CENTER
            setBackgroundColor(0x88000000.toInt())
        }
        root.addView(hint, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.TOP))
        val close = Button(this).apply {
            text = "Cancel"
            setOnClickListener { finishWith(null) }
        }
        root.addView(
            close,
            FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL)
                .apply { bottomMargin = 96 },
        )
        setContentView(root)
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            startCamera()
        } else {
            askCamera.launch(Manifest.permission.CAMERA)
        }
    }

    private fun startCamera() {
        val future = ProcessCameraProvider.getInstance(this)
        future.addListener({
            val provider = future.get()
            val p = Preview.Builder().build().also { it.setSurfaceProvider(preview.surfaceProvider) }
            val analysis = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()
            analysis.setAnalyzer(executor) { image -> analyse(image) }
            provider.unbindAll()
            provider.bindToLifecycle(this, CameraSelector.DEFAULT_BACK_CAMERA, p, analysis)
        }, ContextCompat.getMainExecutor(this))
    }

    private fun analyse(image: ImageProxy) {
        try {
            if (done) return
            val plane = image.planes[0]
            val buf = plane.buffer
            val data = ByteArray(buf.remaining()).also { buf.get(it) }
            val source = PlanarYUVLuminanceSource(
                data, plane.rowStride, image.height, 0, 0, image.width, image.height, false,
            )
            val text = reader.decode(BinaryBitmap(HybridBinarizer(source)), hints).text
            if (text.startsWith("lockin:")) {
                done = true
                runOnUiThread { finishWith(text) }
            }
        } catch (_: Exception) {
            // No code in this frame.
        } finally {
            reader.reset()
            image.close()
        }
    }

    private fun finishWith(text: String?) {
        if (text != null) setResult(RESULT_OK, Intent().putExtra(EXTRA, text)) else setResult(RESULT_CANCELED)
        finish()
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }

    companion object {
        const val EXTRA = "code"
    }
}
