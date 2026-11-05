package `in`.wreadom.app

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "in.wreadom.app/external_browser"
        ).setMethodCallHandler { call, result ->
            if (call.method != "open") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            result.success(openInBrowser(call.argument<String>("url")))
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "in.wreadom.app/upi"
        ).setMethodCallHandler { call, result ->
            if (call.method != "pay") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            result.success(openUpiChooser(call.argument<String>("uri")))
        }
    }

    // Shows the system chooser of UPI apps for a upi://pay link. Returns false
    // when no installed app can handle it.
    private fun openUpiChooser(uri: String?): Boolean {
        if (uri.isNullOrBlank()) return false
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri))
            val handlers = packageManager.queryIntentActivities(intent, 0)
            if (handlers.isEmpty()) return false
            startActivity(Intent.createChooser(intent, "Pay with"))
            true
        } catch (_: Exception) {
            false
        }
    }

    // Opens [url] in a browser app, never in this app (which owns wreadom.in).
    private fun openInBrowser(url: String?): Boolean {
        if (url.isNullOrBlank()) return false
        return try {
            val uri = Uri.parse(url)
            val probe = Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com"))
                .addCategory(Intent.CATEGORY_BROWSABLE)
            val browsers = packageManager
                .queryIntentActivities(probe, PackageManager.MATCH_ALL)
                .map { it.activityInfo.packageName }
                .filter { it != packageName }
                .distinct()
            if (browsers.isEmpty()) return false
            val defaultPkg = packageManager
                .resolveActivity(probe, PackageManager.MATCH_DEFAULT_ONLY)
                ?.activityInfo?.packageName
            val target = if (defaultPkg != null && defaultPkg in browsers) defaultPkg else browsers.first()
            startActivity(
                Intent(Intent.ACTION_VIEW, uri)
                    .addCategory(Intent.CATEGORY_BROWSABLE)
                    .setPackage(target)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            true
        } catch (_: Exception) {
            false
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
        try {
            vibrateForType(type)
        } catch (_: Exception) {
            // Haptics are best-effort; some OEM vibrator drivers throw.
        }
    }

    private fun vibrateForType(type: String) {
        val maybeVibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)
                ?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
        val vibrator = maybeVibrator ?: return

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
        when {
            // Predefined effects are tuned per device and are clearly felt.
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                val effectId = when (type) {
                    "selection" -> VibrationEffect.EFFECT_TICK
                    "medium" -> VibrationEffect.EFFECT_HEAVY_CLICK
                    else -> VibrationEffect.EFFECT_CLICK
                }
                vibrator.vibrate(VibrationEffect.createPredefined(effectId))
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O -> {
                vibrator.vibrate(VibrationEffect.createOneShot(durationMs, amplitude))
            }
            else -> {
                @Suppress("DEPRECATION")
                vibrator.vibrate(durationMs)
            }
        }
    }
}
