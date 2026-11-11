package app.lockin.lockin_spike

import android.Manifest
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), SensorEventListener {
    private var faceDown = false
    private var proximityCovered = false
    private var proximityLock: PowerManager.WakeLock? = null

    private val sensors by lazy { getSystemService(Context.SENSOR_SERVICE) as SensorManager }
    private val proximity: Sensor? by lazy { sensors.getDefaultSensor(Sensor.TYPE_PROXIMITY) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        EventChannel(messenger, "lockin/device_use/events").setStreamHandler(DeviceEvents)
        MethodChannel(messenger, "lockin/device_use").setMethodCallHandler { call, result ->
            when (call.method) {
                "setFaceDownMode" -> result.success(setFaceDownMode(call.arguments as? Boolean ?: false))
                "startSession" -> {
                    requestNotificationPermission()
                    startForegroundService(Intent(this, LockInService::class.java))
                    result.success(true)
                }
                "stopSession" -> {
                    stopService(Intent(this, LockInService::class.java))
                    result.success(true)
                }
                "openBatterySettings" -> {
                    startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
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

    override fun onDestroy() {
        setFaceDownMode(false)
        super.onDestroy()
    }

    private fun snapshot(): Map<String, Any?> {
        val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        return mapOf(
            "platform" to "android",
            "passcodeSet" to km.isDeviceSecure,
            "proximitySupported" to (proximity != null &&
                pm.isWakeLockLevelSupported(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK)),
            "proximityCovered" to proximityCovered,
            "battery" to DeviceEvents.batteryLevel(this),
            "batteryOptimized" to !pm.isIgnoringBatteryOptimizations(packageName),
            "model" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "system" to "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})",
        )
    }

    /** Face-down mode: keep the app in front, let the proximity sensor turn the screen off. */
    private fun setFaceDownMode(on: Boolean): Boolean {
        val sensor = proximity
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (on == faceDown) return true
        if (on) {
            if (sensor == null || !pm.isWakeLockLevelSupported(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK)) {
                return false
            }
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            proximityLock = pm.newWakeLock(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK, "lockin:facedown")
                .also { it.acquire(4 * 60 * 60 * 1000L) } // safety cap: 4 h
            sensors.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)
            faceDown = true
        } else {
            sensors.unregisterListener(this)
            proximityLock?.let { if (it.isHeld) it.release() }
            proximityLock = null
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            faceDown = false
        }
        return true
    }

    override fun onSensorChanged(event: SensorEvent) {
        val sensor = proximity ?: return
        val covered = event.values[0] < sensor.maximumRange
        if (covered != proximityCovered) {
            proximityCovered = covered
            DeviceEvents.emit(this, if (covered) "proximityCovered" else "proximityUncovered")
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
        }
    }
}
