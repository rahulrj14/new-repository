package app.lockin.lockin_spike

import android.content.Context
import android.os.BatteryManager
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Process-wide bus for device-use signals. The foreground service and the
 * activity both emit here; Dart listens through an EventChannel.
 * Everything stays in memory on the device.
 */
object DeviceEvents : EventChannel.StreamHandler {
    private val main = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null
    private val buffer = ArrayDeque<Map<String, Any>>()
    private const val MAX_BUFFER = 500

    fun emit(context: Context, signal: String) {
        val event = mapOf(
            "signal" to signal,
            "t" to System.currentTimeMillis(),
            "battery" to batteryLevel(context),
        )
        main.post {
            val s = sink
            if (s != null) {
                s.success(event)
            } else {
                if (buffer.size >= MAX_BUFFER) buffer.removeFirst()
                buffer.addLast(event)
            }
        }
    }

    fun batteryLevel(context: Context): Double {
        val bm = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val pct = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        return if (pct in 0..100) pct / 100.0 else -1.0
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        while (buffer.isNotEmpty()) events.success(buffer.removeFirst())
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }
}
