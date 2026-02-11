package com.example.med_reminder_fixed

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class AlarmLaunchService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val id = intent?.getIntExtra("id", 0) ?: 0
        val title = intent?.getStringExtra("title") ?: "Medicine Reminder"
        val body = intent?.getStringExtra("body") ?: "Time to take your medicine"

        // Minimal foreground notif (low importance) just to allow launch
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "alarm_fg_channel_v1"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                channelId,
                "Alarm Foreground",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                lockscreenVisibility = Notification.VISIBILITY_SECRET
                setSound(null, null)
            }
            nm.createNotificationChannel(ch)
        }

        val notif = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Alarm running")
            .setContentText("Launching alarm screen…")
            .setOngoing(true)
            .setSilent(true)
            .build()

        startForeground(9991, notif)

        // Launch AlarmActivity
        try {
            val i = Intent(this, AlarmActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("id", id)
                putExtra("title", title)
                putExtra("body", body)
            }
            startActivity(i)
        } catch (_: Throwable) {
        }

        stopForeground(true)
        stopSelf()
        return START_NOT_STICKY
    }
}
