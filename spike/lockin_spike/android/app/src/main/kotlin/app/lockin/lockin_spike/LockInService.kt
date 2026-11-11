package app.lockin.lockin_spike

import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * Foreground service that keeps the session alive while the phone is locked
 * and listens for unlocks. Started only when the user taps Start; stopped
 * when they tap Stop. Shows the persistent "Locked in" notification.
 */
class LockInService : Service() {
    private var registered = false

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                // Keyguard dismissed: the person is using their phone.
                Intent.ACTION_USER_PRESENT -> DeviceEvents.emit(context, "deviceUnlocked")
                Intent.ACTION_SCREEN_OFF -> DeviceEvents.emit(context, "deviceLocked")
                Intent.ACTION_SCREEN_ON -> {
                    // Screen on alone is not use (a notification can light it up).
                    // But if there is no keyguard (lock delay not passed, or no
                    // lock screen), screen on means the phone is usable: unlocked.
                    val km = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                    if (km.isKeyguardLocked) {
                        DeviceEvents.emit(context, "screenOnLocked")
                    } else {
                        DeviceEvents.emit(context, "deviceUnlocked")
                    }
                }
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startInForeground()
        if (!registered) {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_USER_PRESENT)
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_SCREEN_ON)
            }
            // System broadcasts; registered at runtime because USER_PRESENT
            // cannot be received through the manifest on Android 8+.
            if (Build.VERSION.SDK_INT >= 33) {
                // NOT_EXPORTED: other apps cannot send us fake events;
                // system broadcasts are still delivered.
                registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(receiver, filter)
            }
            registered = true
            DeviceEvents.emit(this, "serviceStarted")
        }
        // If Android kills the service, do not silently restart it: a restart
        // would have lost the session state anyway, and the log should show it.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        if (registered) {
            unregisterReceiver(receiver)
            registered = false
        }
        DeviceEvents.emit(this, "serviceStopped")
        super.onDestroy()
    }

    private fun startInForeground() {
        val nm = getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(CHANNEL) == null) {
            val ch = NotificationChannel(CHANNEL, "Session", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Shown while a Lock In session is running"
                setShowBadge(false)
            }
            nm.createNotificationChannel(ch)
        }
        val open = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = Notification.Builder(this, CHANNEL)
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setContentTitle("Locked in")
            .setContentText("Session running. Keep your phone down.")
            .setContentIntent(open)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .build()
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    companion object {
        private const val CHANNEL = "session"
        private const val NOTIFICATION_ID = 1
    }
}
