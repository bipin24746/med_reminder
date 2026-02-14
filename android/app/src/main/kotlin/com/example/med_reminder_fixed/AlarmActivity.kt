package com.example.med_reminder_fixed

import android.app.Activity
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

class AlarmActivity : Activity() {

    private var player: MediaPlayer? = null
    private val handler = Handler(Looper.getMainLooper())

    // Keys to persist "active until STOP" across repeats
    private fun activeKey(alarmId: Int) = "alarm_active_$alarmId"

    // One stable repeat id per alarm instance
    private fun repeatId(alarmId: Int): Int {
        // If alarmId is already huge, keep safe
        val base = if (alarmId == 0) (System.currentTimeMillis() % 500000).toInt() else alarmId
        return base + 900000
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ✅ Wake screen + show over lockscreen (Android 9–15)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        setContentView(R.layout.activity_alarm)

        // extras
        val alarmId = intent.getIntExtra("id", 0)
        val title = intent.getStringExtra("title") ?: "Medicine Reminder"
        val body = intent.getStringExtra("body") ?: "Time to take your medicine"

        // ✅ cancel notification to stop its sound
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (alarmId != 0) nm.cancel(alarmId)
        } catch (_: Throwable) {}

        findViewById<TextView>(R.id.alarmTitle).text = title
        findViewById<TextView>(R.id.alarmBody).text = body

        // settings from Flutter shared_preferences
        val sp = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val durationSec = sp.getLong("flutter.alarm_duration_sec", 300L).toInt().coerceIn(5, 60 * 60)
        val soundMode = sp.getString("flutter.alarm_sound_mode", "system") ?: "system"
        val pickedUri = sp.getString("flutter.alarm_picked_uri", null)

        Log.d("AlarmActivity", "alarmId=$alarmId duration=$durationSec mode=$soundMode picked=$pickedUri")

        // ✅ Mark this alarm as ACTIVE (until user presses STOP)
        sp.edit().putBoolean(activeKey(alarmId), true).apply()

        startLoopingSound(soundMode, pickedUri)

        // ✅ auto-stop after duration
        handler.postDelayed({
            stopSound()

            // ✅ If not STOPPED, schedule next ring in 5 minutes
            scheduleNextRepeat(alarmId, title, body)

            finish()
        }, durationSec * 1000L)

        // STOP (stops forever)
        findViewById<Button>(R.id.btnStop).setOnClickListener {
            stopSound()

            val sp2 = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            sp2.edit().putBoolean(activeKey(alarmId), false).apply()

            cancelRepeats(alarmId)

            finish()
        }

        // SNOOZE (5 minutes) => same as "repeat in 5"
        findViewById<Button>(R.id.btnSnooze).setOnClickListener {
            stopSound()
            scheduleNextRepeat(alarmId, title, body) // 5 minutes
            finish()
        }
    }

    private fun resolveAlarmUri(mode: String, pickedUri: String?): Uri {
        return when (mode) {
            "picked" -> pickedUri?.takeIf { it.isNotBlank() }?.let { Uri.parse(it) }
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            "system" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            else -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        } ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
    }

    private fun startLoopingSound(mode: String, pickedUri: String?) {
        val uri = resolveAlarmUri(mode, pickedUri)

        try {
            stopSound()

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
            Log.e("AlarmActivity", "MediaPlayer play failed: $e")

            // fallback system alarm
            try {
                stopSound()
                val fallback = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                val mp2 = MediaPlayer()
                mp2.setDataSource(this, fallback)
                mp2.isLooping = true
                mp2.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                mp2.prepare()
                mp2.start()
                player = mp2
            } catch (e2: Throwable) {
                Log.e("AlarmActivity", "Fallback sound failed: $e2")
            }
        }
    }

    // ✅ schedule next ring in 5 minutes if alarm still active
    private fun scheduleNextRepeat(alarmId: Int, title: String, body: String) {
        val sp = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isActive = sp.getBoolean(activeKey(alarmId), false)
        if (!isActive) {
            Log.d("AlarmActivity", "Not scheduling repeat because alarm is inactive")
            return
        }

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val id = repeatId(alarmId)

        val receiverIntent = Intent(this, AlarmReceiver::class.java).apply {
            putExtra("title", title)
            putExtra("body", body)
            putExtra("id", id)
        }

        val pi = PendingIntent.getBroadcast(
            this,
            id,
            receiverIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                        PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val triggerAt = System.currentTimeMillis() + 5 * 60 * 1000L

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        }

        Log.d("AlarmActivity", "✅ Next repeat scheduled id=$id at=$triggerAt")
    }

    // ✅ stop future repeats
    private fun cancelRepeats(alarmId: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val id = repeatId(alarmId)

        val intent = Intent(this, AlarmReceiver::class.java)
        val pi = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                        PendingIntent.FLAG_IMMUTABLE else 0)
        )
        alarmManager.cancel(pi)

        Log.d("AlarmActivity", "✅ Repeats cancelled id=$id")
    }

    private fun stopSound() {
        try { player?.stop() } catch (_: Throwable) {}
        try { player?.release() } catch (_: Throwable) {}
        player = null
    }

    override fun onDestroy() {
        stopSound()
        super.onDestroy()
    }
}
