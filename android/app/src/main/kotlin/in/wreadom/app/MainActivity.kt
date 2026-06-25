package `in`.wreadom.app

import android.content.Context
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
