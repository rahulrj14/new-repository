package app.lockin.lock_in

import android.Manifest
import android.app.KeyguardManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingPrepare: MethodChannel.Result? = null
    private var pendingScan: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        LockInBle.init(this)

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
                "openUrl" -> {
                    try {
                        startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(call.argument<String>("url"))))
                    } catch (_: Exception) {
                        // No browser: nothing to do.
                    }
                    result.success(null)
                }
                "openAutostart" -> result.success(openAutostart())
                "openBatteryList" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                    } catch (_: Exception) {
                        openAppDetails()
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "lockin/ble/events").setStreamHandler(LockInBle)
        MethodChannel(messenger, "lockin/ble").setMethodCallHandler { call, result ->
            when (call.method) {
                "prepare" -> prepareBluetooth(result)
                "scanQr" -> {
                    pendingScan?.success(null)
                    pendingScan = result
                    @Suppress("DEPRECATION")
                    startActivityForResult(Intent(this, ScannerActivity::class.java), REQ_SCAN)
                }
                "startHost" -> {
                    LockInBle.startHost(call.argument<ByteArray>("key")!!)
                    result.success(null)
                }
                "startJoin" -> {
                    LockInBle.startJoin(call.argument<ByteArray>("key")!!)
                    result.success(null)
                }
                "send" -> {
                    LockInBle.send(call.argument<String>("peer")!!, call.argument<ByteArray>("bytes")!!)
                    result.success(null)
                }
                "stopAdvertising" -> {
                    LockInBle.stopAdvertising()
                    result.success(null)
                }
                "disconnect" -> {
                    LockInBle.disconnect(call.argument<String>("peer")!!)
                    result.success(null)
                }
                "stop" -> {
                    LockInBle.stop()
                    result.success(null)
                }
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

    // ---------------------------------------------------------- bluetooth

    /** The minimum each Android version needs. No location on Android 12+. */
    private fun blePermissions(): Array<String> = if (Build.VERSION.SDK_INT >= 31) {
        arrayOf(
            Manifest.permission.BLUETOOTH_SCAN, // declared neverForLocation
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.BLUETOOTH_ADVERTISE,
        )
    } else {
        // Android 8–11 only allow BLE scanning with this permission. We never
        // read or store location; it is only how older Android gates scanning.
        arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
    }

    private fun prepareBluetooth(result: MethodChannel.Result) {
        val adapter = getSystemService(BluetoothManager::class.java)?.adapter
        if (adapter == null || !packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            result.success("unsupported")
            return
        }
        val missing = blePermissions().filter { checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED }
        if (missing.isNotEmpty()) {
            pendingPrepare = result
            requestPermissions(missing.toTypedArray(), REQ_BLE)
            return
        }
        finishPrepare(result)
    }

    private fun finishPrepare(result: MethodChannel.Result) {
        val adapter = getSystemService(BluetoothManager::class.java)?.adapter
        if (adapter == null) {
            result.success("unsupported")
            return
        }
        if (Build.VERSION.SDK_INT < 31) {
            val lm = getSystemService(LocationManager::class.java)
            val on = if (Build.VERSION.SDK_INT >= 28) lm.isLocationEnabled else true
            if (!on) {
                result.success("location_off")
                return
            }
        }
        if (!adapter.isEnabled) {
            pendingPrepare = result
            @Suppress("DEPRECATION")
            startActivityForResult(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE), REQ_ENABLE)
            return
        }
        result.success(null)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQ_BLE) return
        val r = pendingPrepare ?: return
        pendingPrepare = null
        if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
            finishPrepare(r)
        } else {
            r.success("permission_denied")
        }
    }

    @Deprecated("Activity result API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            REQ_ENABLE -> {
                val r = pendingPrepare ?: return
                pendingPrepare = null
                r.success(if (resultCode == RESULT_OK) null else "bluetooth_off")
            }
            REQ_SCAN -> {
                val r = pendingScan ?: return
                pendingScan = null
                r.success(if (resultCode == RESULT_OK) data?.getStringExtra(ScannerActivity.EXTRA) else null)
            }
        }
    }

    // --------------------------------------------------------- keep alive

    /** Known phone-maker screens that stop background apps being killed. */
    private val autostartScreens = listOf(
        "com.miui.securitycenter" to "com.miui.permcenter.autostart.AutoStartManagementActivity",
        "com.coloros.safecenter" to "com.coloros.safecenter.permission.startup.StartupAppListActivity",
        "com.oplus.safecenter" to "com.oplus.safecenter.startupapp.StartupAppListActivity",
        "com.vivo.permissionmanager" to "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
        "com.iqoo.secure" to "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager",
        "com.huawei.systemmanager" to "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
        "com.samsung.android.lool" to "com.samsung.android.sm.battery.ui.BatteryActivity",
    )

    private fun openAutostart(): String {
        for ((pkg, cls) in autostartScreens) {
            try {
                startActivity(Intent().setComponent(android.content.ComponentName(pkg, cls)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return "autostart"
            } catch (_: Exception) {
                // Not this phone maker; try the next.
            }
        }
        openAppDetails()
        return "app_settings"
    }

    private fun openAppDetails() {
        startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).setData(Uri.fromParts("package", packageName, null)),
        )
    }

    // --------------------------------------------------------------- misc

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
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQ_NOTIF)
        }
    }

    companion object {
        private const val REQ_NOTIF = 1
        private const val REQ_BLE = 42
        private const val REQ_ENABLE = 43
        private const val REQ_SCAN = 44
    }
}
