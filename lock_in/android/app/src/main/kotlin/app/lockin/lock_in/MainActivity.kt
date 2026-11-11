package app.lockin.lock_in

import android.Manifest
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        EventChannel(messenger, "lockin/device_use/events").setStreamHandler(DeviceEvents)
        MethodChannel(messenger, "lockin/device_use").setMethodCallHandler { call, result ->
            when (call.method) {
                "startSession" -> {
                    requestNotificationPermission()
                    LockInService.clearDone(this)
                    val startAt = (call.argument<Number>("startAt") ?: 0).toLong()
                    val endAt = (call.argument<Number>("endAt") ?: 0).toLong()
                    startForegroundService(
                        Intent(this, LockInService::class.java)
                            .putExtra(LockInService.EXTRA_START, startAt)
                            .putExtra(LockInService.EXTRA_END, endAt),
                    )
                    result.success(true)
                }
                "updateNotification" -> {
                    LockInService.update(
                        this,
                        call.argument<String>("title") ?: "Locked in 🔒",
                        call.argument<String>("text") ?: "",
                    )
                    result.success(true)
                }
                "stopSession" -> {
                    stopService(Intent(this, LockInService::class.java))
                    val title = call.argument<String>("doneTitle")
                    if (title != null) LockInService.postDone(this, title, call.argument<String>("doneText") ?: "")
                    result.success(true)
                }
                "openAppSettings" -> {
                    // On Xiaomi/Samsung/etc. this page holds "Battery saver: No restrictions"
                    // and "Autostart", which stop the phone killing the session.
                    startActivity(
                        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                            .setData(Uri.fromParts("package", packageName, null)),
                    )
                    result.success(true)
                }
                "snapshot" -> result.success(snapshot())
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        DeviceEvents.emit(this, "appActive")
    }

    override fun onPause() {
        DeviceEvents.emit(this, "appInactive")
        super.onPause()
    }

    private fun snapshot(): Map<String, Any?> {
        val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        return mapOf(
            "platform" to "android",
            "passcodeSet" to km.isDeviceSecure,
            "batteryOptimized" to !pm.isIgnoringBatteryOptimizations(packageName),
            "manufacturer" to Build.MANUFACTURER,
        )
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
        }
    }
}
