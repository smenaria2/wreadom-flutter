package `in`.wreadom.app

import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.HapticFeedbackConstants
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "in.wreadom.app/reader_privacy"
        ).setMethodCallHandler { call, result ->
            if (call.method != "setSecureReader") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val enabled = call.argument<Boolean>("enabled") ?: false
            if (enabled) {
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
            result.success(null)
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "in.wreadom.app/haptics"
        ).setMethodCallHandler { call, result ->
            if (call.method != "impact") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val args = call.arguments as? Map<*, *>
            val type = args?.get("type") as? String ?: "light"
            performNativeHaptic(type)
            result.success(null)
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "in.wreadom.app/audio_metadata"
        ).setMethodCallHandler { call, result ->
            if (call.method != "readDurationMs") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val path = call.argument<String>("path")
            val durationMs = readAudioDurationMs(path)
            result.success(durationMs)
        }
    }

    private fun readAudioDurationMs(path: String?): Long {
        if (path.isNullOrBlank()) return 0L
        val retriever = MediaMetadataRetriever()
        return try {
            if (path.startsWith("content://")) {
                retriever.setDataSource(this, Uri.parse(path))
            } else {
                retriever.setDataSource(path)
            }
            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                ?.toLongOrNull()
                ?.takeIf { it > 0L } ?: 0L
        } catch (_: Exception) {
            0L
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
                // Ignore release failures on older Android releases.
            }
        }
    }
    private fun performNativeHaptic(type: String) {
        val feedbackConstant = when (type) {
            "selection" -> HapticFeedbackConstants.KEYBOARD_TAP
            "medium" -> HapticFeedbackConstants.LONG_PRESS
            else -> HapticFeedbackConstants.VIRTUAL_KEY
        }
        window.decorView.performHapticFeedback(feedbackConstant)

        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        if (!vibrator.hasVibrator()) return
        val durationMs = when (type) {
            "selection" -> 12L
            "medium" -> 32L
            else -> 20L
        }
        val amplitude = when (type) {
            "selection" -> 60
            "medium" -> 180
            else -> 120
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(durationMs, amplitude))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(durationMs)
        }
    }
}

