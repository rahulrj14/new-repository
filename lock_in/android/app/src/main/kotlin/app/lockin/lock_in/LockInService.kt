package app.lockin.lock_in

import android.app.AlarmManager
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
 * Foreground service that keeps a session alive while the phone is locked
 * and listens for unlocks. Started only when the user starts a session and
 * stopped when it ends. Owns the persistent "Locked in" notification.
 */
class LockInService : Service() {
    private var registered = false

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_USER_PRESENT -> DeviceEvents.emit(context, "deviceUnlocked")
                Intent.ACTION_SCREEN_OFF -> DeviceEvents.emit(context, "deviceLocked")
                Intent.ACTION_SCREEN_ON -> {
                    // Screen on alone is not use (a notification can light it).
                    // Without a keyguard, though, the phone is usable: unlocked.
                    val km = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                    DeviceEvents.emit(context, if (km.isKeyguardLocked) "screenOnLocked" else "deviceUnlocked")
                }
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val startAt = intent?.getLongExtra(EXTRA_START, 0L) ?: 0L
        val endAt = intent?.getLongExtra(EXTRA_END, 0L) ?: 0L
        current = Session(startAt, endAt)
        startForegroundCompat(buildNotification(this, "Locked in 🔒", "Phone down. Aura up."))
        scheduleFinishAlarm(endAt)
        if (!registered) {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_USER_PRESENT)
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_SCREEN_ON)
            }
            if (Build.VERSION.SDK_INT >= 33) {
                // Other apps cannot send us fake events; system broadcasts still arrive.
                registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(receiver, filter)
            }
            registered = true
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        if (registered) {
            unregisterReceiver(receiver)
            registered = false
        }
        cancelFinishAlarm()
        current = null
        super.onDestroy()
    }

    private fun startForegroundCompat(n: Notification) {
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIFICATION_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, n)
        }
    }

    /** Inexact, no special permission: updates the notification when time is up. */
    private fun scheduleFinishAlarm(endAt: Long) {
        if (endAt <= 0L) return
        val am = getSystemService(AlarmManager::class.java)
        am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, endAt, finishIntent(this))
    }

    private fun cancelFinishAlarm() {
        getSystemService(AlarmManager::class.java).cancel(finishIntent(this))
    }

    data class Session(val startAt: Long, val endAt: Long)

    companion object {
        const val EXTRA_START = "startAt"
        const val EXTRA_END = "endAt"
        private const val CHANNEL = "session"
        private const val NOTIFICATION_ID = 1

        /** The running session, for the notification countdown. */
        @Volatile var current: Session? = null

        private fun finishIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
            context, 2,
            Intent(context, SessionFinishedReceiver::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        fun buildNotification(context: Context, title: String, text: String, finished: Boolean = false): Notification {
            val nm = context.getSystemService(NotificationManager::class.java)
            if (nm.getNotificationChannel(CHANNEL) == null) {
                nm.createNotificationChannel(
                    NotificationChannel(CHANNEL, "Session", NotificationManager.IMPORTANCE_LOW).apply {
                        description = "Shown while a Lock In session is running"
                        setShowBadge(false)
                    },
                )
            }
            val open = PendingIntent.getActivity(
                context, 0,
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_IMMUTABLE,
            )
            val b = Notification.Builder(context, CHANNEL)
                .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(open)
                .setOngoing(true)
                .setCategory(Notification.CATEGORY_SERVICE)
                // Visible on the lock screen so you can glance without unlocking.
                .setVisibility(Notification.VISIBILITY_PUBLIC)
            val s = current
            if (s != null && !finished) {
                // "I genuinely need my phone": one tap from the lock screen.
                val pass = PendingIntent.getBroadcast(
                    context, 3,
                    Intent(context, EmergencyPassReceiver::class.java),
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                )
                b.addAction(
                    Notification.Action.Builder(null, "Emergency pass 🆘", pass).build(),
                )
                // The system draws a live timer; no wakeups needed.
                b.setUsesChronometer(true).setShowWhen(true)
                if (s.endAt > 0L) {
                    b.setWhen(s.endAt).setChronometerCountDown(true)
                } else {
                    b.setWhen(s.startAt)
                }
            }
            return b.build()
        }

        /** A normal, dismissable "done" notification once the session is over. */
        fun postDone(context: Context, title: String, text: String) {
            val open = PendingIntent.getActivity(
                context, 0,
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_IMMUTABLE,
            )
            val n = Notification.Builder(context, CHANNEL)
                .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(open)
                .setAutoCancel(true)
                .build()
            context.getSystemService(NotificationManager::class.java).notify(DONE_ID, n)
        }

        fun clearDone(context: Context) {
            context.getSystemService(NotificationManager::class.java).cancel(DONE_ID)
        }

        private const val DONE_ID = 2

        fun update(context: Context, title: String, text: String, finished: Boolean = false) {
            if (current == null) return
            context.getSystemService(NotificationManager::class.java)
                .notify(NOTIFICATION_ID, buildNotification(context, title, text, finished))
        }
    }
}

/** Fires when the planned session length is over. */
class SessionFinishedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        LockInService.update(context, "Session done ✦", "Unlock to collect your aura.", finished = true)
        DeviceEvents.emit(context, "sessionTimeUp")
    }
}

/** The notification's emergency-pass button. */
class EmergencyPassReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        DeviceEvents.emit(context, "emergencyPass")
    }
}
