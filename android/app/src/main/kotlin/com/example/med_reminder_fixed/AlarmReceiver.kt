package com.example.med_reminder_fixed

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val title = intent.getStringExtra("title") ?: "Medicine Reminder"
        val body = intent.getStringExtra("body") ?: "Time to take your medicine"
        val id = intent.getIntExtra("id", (System.currentTimeMillis() % Int.MAX_VALUE).toInt())

        // ✅ Keep CPU awake briefly so we can post notif + launch activity
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wl = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "med:alarm")
        wl.acquire(15_000)

        try {
            // Alarm screen
            val activityIntent = Intent(context, AlarmActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("id", id)           // ✅ ADD THIS
                putExtra("title", title)
                putExtra("body", body)
            }

            val fullScreenPI = PendingIntent.getActivity(
                context,
                id,
                activityIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            // Actions: STOP/SNOOZE (optional; keep if you already created AlarmActionReceiver)
            val stopIntent = Intent(context, AlarmActionReceiver::class.java).apply {
                putExtra("action", "STOP")
                putExtra("id", id)
                putExtra("title", title)
                putExtra("body", body)
            }
            val stopPI = PendingIntent.getBroadcast(
                context,
                id + 100001,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            val snoozeIntent = Intent(context, AlarmActionReceiver::class.java).apply {
                putExtra("action", "SNOOZE")
                putExtra("id", id)
                putExtra("title", title)
                putExtra("body", body)
            }
            val snoozePI = PendingIntent.getBroadcast(
                context,
                id + 100002,
                snoozeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // ✅ NEW channel id to avoid old cached silent channel
            val channelId = "med_alarm_channel_sound_v4"

            // ✅ Use system alarm sound (fallback)
            val alarmSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val attrs = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()

                val ch = NotificationChannel(
                    channelId,
                    "Medicine Alarm",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    setSound(alarmSound, attrs) // ✅ SOUND ON NOTIFICATION
                }
                nm.createNotificationChannel(ch)
            }

            val builder = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setAutoCancel(true)
                .setFullScreenIntent(fullScreenPI, true)
                .addAction(0, "SNOOZE 5 MIN", snoozePI)
                .addAction(0, "STOP", stopPI)

            // ✅ For Android < 8 sound must be set here
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                builder.setSound(alarmSound)
            }

            nm.notify(id, builder.build())

            // ✅ Also try direct start (some devices allow)
            try { context.startActivity(activityIntent) } catch (_: Throwable) {}

        } finally {
            try { wl.release() } catch (_: Throwable) {}
        }
    }
}
