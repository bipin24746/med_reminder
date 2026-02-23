package com.example.med_reminder_fixed

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmSoundService : Service() {

    private var player: MediaPlayer? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_NOT_STICKY

        val id = intent.getIntExtra("id", 0)
        val streamId = intent.getIntExtra("streamId", id)
        val title = intent.getStringExtra("title") ?: "Medicine Reminder"
        val body = intent.getStringExtra("body") ?: "Time to take your medicine"

        // Alarm duration from Flutter shared prefs
        val sp = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val durationSec = sp.getLong("flutter.alarm_duration_sec", 300L).toInt().coerceIn(5, 3600)

        startForegroundMinimal(id)
        startSound()

        // Try to show the full-screen UI (some OEMs delay this until screen ON)
        try {
            val i = Intent(this, AlarmActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
                putExtras(intent.extras ?: android.os.Bundle())
                putExtra("id", id)
                putExtra("streamId", streamId)
                putExtra("title", title)
                putExtra("body", body)
            }
            startActivity(i)
        } catch (_: Throwable) {}

        handler.removeCallbacksAndMessages(null)
        handler.postDelayed({
            stopSound()
            stopForeground(true)
            stopSelf()
        }, durationSec * 1000L)

        Log.d("AlarmSoundService", "Started id=$id streamId=$streamId dur=$durationSec")
        return START_NOT_STICKY
    }

    private fun startForegroundMinimal(id: Int) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "alarm_fg_min_v1"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                channelId,
                "Alarm Running",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                lockscreenVisibility = Notification.VISIBILITY_SECRET
                setSound(null, null)
                enableVibration(false)
            }
            nm.createNotificationChannel(ch)
        }

        val notif = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Alarm running")
            .setContentText("Medicine reminder")
            .setSilent(true)
            .setOngoing(true)
            .build()

        // must be foreground
        startForeground(9000 + (id % 1000), notif)
    }

    private fun startSound() {
        try {
            stopSound()

            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            val mp = MediaPlayer()
            mp.setDataSource(this, uri)
            mp.isLooping = true
            mp.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            mp.prepare()
            mp.start()
            player = mp
        } catch (e: Throwable) {
            Log.e("AlarmSoundService", "Sound failed: $e")
        }
    }

    private fun stopSound() {
        try { player?.stop() } catch (_: Throwable) {}
        try { player?.release() } catch (_: Throwable) {}
        player = null
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        stopSound()
        super.onDestroy()
    }
}