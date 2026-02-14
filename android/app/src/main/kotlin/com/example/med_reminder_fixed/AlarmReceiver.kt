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
        val body = intent.getStringExtra("body") ?: "Take your medicine"
        val id = intent.getIntExtra("id", (System.currentTimeMillis() % Int.MAX_VALUE).toInt())

        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager

        // CPU wake
        val cpuWl = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "med:cpu")
        cpuWl.acquire(20_000)

        // Screen wake (best effort)
        val screenFlags =
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP
        val screenWl = pm.newWakeLock(screenFlags, "med:screen")
        screenWl.acquire(8_000)

        try {
            // Alarm screen
            val activityIntent = Intent(context, AlarmActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("id", id)
                putExtra("title", title)
                putExtra("body", body)
            }

            val fullScreenPI = PendingIntent.getActivity(
                context,
                id,
                activityIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            PendingIntent.FLAG_IMMUTABLE else 0)
            )

            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Channel
            val channelId = "med_alarm_channel_sound_v4"
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
                    setSound(alarmSound, attrs)
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
                .setAutoCancel(false)
                .setFullScreenIntent(fullScreenPI, true)

            // Android < 8 sound
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                builder.setSound(alarmSound)
            }

            // Show notification
            nm.notify(id, builder.build())

            // Force open screen (best effort)
            try { context.startActivity(activityIntent) } catch (_: Throwable) {}

        } finally {
            try { cpuWl.release() } catch (_: Throwable) {}
            try { screenWl.release() } catch (_: Throwable) {}
        }
    }
}
