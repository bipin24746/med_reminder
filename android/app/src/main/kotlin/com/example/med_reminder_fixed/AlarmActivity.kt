package com.example.med_reminder_fixed

import android.app.Activity
import android.app.AlarmManager
import android.app.AlertDialog
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

    private fun activeKey(alarmId: Int) = "alarm_active_$alarmId"

    private fun repeatId(alarmId: Int): Int {
        val base = if (alarmId == 0) (System.currentTimeMillis() % 500000).toInt() else alarmId
        return base + 900000
    }

    private fun rawAlarmUri(): Uri {
        return Uri.parse("android.resource://$packageName/raw/alarm")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

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

        val alarmId = intent.getIntExtra("id", 0)
        val streamId = intent.getIntExtra("streamId", alarmId)
        val scheduledAt = intent.getLongExtra("scheduledAt", 0L)
        val openSkipDialog = intent.getBooleanExtra("openSkipDialog", false)

        val title = intent.getStringExtra("title") ?: "Medicine Reminder"
        val body = intent.getStringExtra("body") ?: "Time to take your medicine"

        // cancel notification (stop its sound if any)
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (alarmId != 0) nm.cancel(alarmId)
        } catch (_: Throwable) {}

        findViewById<TextView>(R.id.alarmTitle).text = title
        findViewById<TextView>(R.id.alarmBody).text = body

        val sp = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        val durationSec = sp.getLong("flutter.alarm_duration_sec", 300L).toInt().coerceIn(5, 60 * 60)

        // ✅ snooze seconds coming from Flutter (default 5 min)
        val snoozeSec = sp.getLong("flutter.alarm_snooze_sec", 300L).toInt().coerceIn(60, 24 * 60 * 60)
        val snoozeMin = (snoozeSec / 60).coerceAtLeast(1)

        val soundMode = sp.getString("flutter.alarm_sound_mode", "app") ?: "app"
        val pickedUri = sp.getString("flutter.alarm_picked_uri", null)

        Log.d("AlarmActivity", "alarmId=$alarmId streamId=$streamId scheduledAt=$scheduledAt duration=$durationSec snoozeSec=$snoozeSec")

        // mark active
        sp.edit().putBoolean(activeKey(alarmId), true).apply()

        startLoopingSound(soundMode, pickedUri)

        val btnTaken = findViewById<Button>(R.id.btnStop)
        val btnSnooze = findViewById<Button>(R.id.btnSnooze)
        val btnSkipNow = findViewById<Button>(R.id.btnSkipNow)

        btnTaken.text = "Taken"
        btnSnooze.text = "Snooze $snoozeMin minutes"
        btnSkipNow.text = "Skip for now"

        // AUTO timeout -> snooze repeat
        handler.postDelayed({
            stopSound()
            UserActionLog.add(this, "AUTO_TIMEOUT", streamId, alarmId, scheduledAt, title, body)
            scheduleSnoozeRepeat(alarmId, title, body, snoozeSec)
            finish()
        }, durationSec * 1000L)

        // TAKEN
        btnTaken.setOnClickListener {
            stopSound()

            // logs
            UserActionLog.add(this, "TAKEN", streamId, alarmId, scheduledAt, title, body)
            ActionLogStore.addTaken(this, streamId, title, body, scheduledAt)

            sp.edit().putBoolean(activeKey(alarmId), false).apply()
            cancelRepeats(alarmId)
            finish()
        }

        // SNOOZE
        btnSnooze.setOnClickListener {
            stopSound()
            UserActionLog.add(this, "SNOOZE", streamId, alarmId, scheduledAt, title, body, "sec=$snoozeSec")
            scheduleSnoozeRepeat(alarmId, title, body, snoozeSec)
            finish()
        }

        // SKIP NOW (popup reasons)
        btnSkipNow.setOnClickListener {
            stopSound()
            showSkipReasonDialog(
                streamId = streamId,
                scheduledAt = scheduledAt,
                notifId = alarmId,
                title = title,
                body = body
            )
        }

        if (openSkipDialog) {
            stopSound()
            handler.post {
                showSkipReasonDialog(
                    streamId = streamId,
                    scheduledAt = scheduledAt,
                    notifId = alarmId,
                    title = title,
                    body = body
                )
            }
        }
    }

    private fun showSkipReasonDialog(
        streamId: Int,
        scheduledAt: Long,
        notifId: Int,
        title: String,
        body: String
    ) {
        val reasons = arrayOf(
            "Already took it",
            "Not feeling well",
            "No medicine available",
            "Doctor told to pause",
            "Other"
        )

        AlertDialog.Builder(this)
            .setTitle("Why are you skipping this dose?")
            .setItems(reasons) { _, which ->
                val reason = reasons[which]

                // ✅ set skip window ONLY if your receiver uses it (optional)
                // If you want skip ONLY for this one dose time, keep SkipStore usage out,
                // and rely just on scheduleNext logic. For now, we just log.
                // (So no SkipStore.setSkipUntil here.)

                // ✅ store simplified logs for your Logs screen
                ActionLogStore.addSkipped(
                    context = this,
                    streamId = streamId,
                    title = title,
                    body = body,
                    reason = reason,
                    scheduledAt = scheduledAt
                )

                // ✅ your existing logger (detailed)
                UserActionLog.add(
                    context = this,
                    action = "SKIP_NOW",
                    streamId = streamId,
                    notifId = notifId,
                    scheduledAt = scheduledAt,
                    title = title,
                    body = body,
                    reason = reason
                )

                finish()
            }
            .setNegativeButton("Cancel") { dialog, _ -> dialog.dismiss() }
            .show()
    }

    private fun resolveAlarmUri(mode: String, pickedUri: String?): Uri {
        return when (mode) {
            "app" -> rawAlarmUri()
            "picked" -> pickedUri?.takeIf { it.isNotBlank() }?.let { Uri.parse(it) } ?: rawAlarmUri()
            "system" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM) ?: rawAlarmUri()
            else -> rawAlarmUri()
        }
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
            Log.e("AlarmActivity", "MediaPlayer failed: $e")
        }
    }

    private fun scheduleSnoozeRepeat(alarmId: Int, title: String, body: String, snoozeSec: Int) {
        val sp = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isActive = sp.getBoolean(activeKey(alarmId), false)
        if (!isActive) return

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val id = repeatId(alarmId)
        val triggerAt = System.currentTimeMillis() + snoozeSec * 1000L

        val receiverIntent = Intent(this, AlarmReceiver::class.java).apply {
            putExtra("title", title)
            putExtra("body", body)
            putExtra("id", id)
            putExtra("streamId", alarmId)
            putExtra("scheduledAt", triggerAt)
            putExtra("isSnooze", true)
        }

        val pi = PendingIntent.getBroadcast(
            this,
            id,
            receiverIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        }
    }

    private fun cancelRepeats(alarmId: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val id = repeatId(alarmId)

        val intent = Intent(this, AlarmReceiver::class.java)
        val pi = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )
        alarmManager.cancel(pi)
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