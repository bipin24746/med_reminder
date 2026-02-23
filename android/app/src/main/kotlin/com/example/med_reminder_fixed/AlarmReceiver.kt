package com.example.med_reminder_fixed

import android.app.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import java.util.Calendar

class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val title = intent.getStringExtra("title") ?: "Medicine Reminder"
        val body = intent.getStringExtra("body") ?: "Take your medicine"

        // ✅ stable streamId (main alarm stream)
        val streamId = intent.getIntExtra(
            "streamId",
            intent.getIntExtra("id", (System.currentTimeMillis() % Int.MAX_VALUE).toInt())
        )

        // notifId can differ for snooze
        val notifId = intent.getIntExtra("id", streamId)
        val isSnooze = intent.getBooleanExtra("isSnooze", false)

        // ✅ occurrence time
        val scheduledAt = intent.getLongExtra("scheduledAt", 0L)

        // ✅ Skip ONLY this occurrence
        if (!isSnooze && SkipStore.isSkipped(context, streamId, scheduledAt)) {
            scheduleNext(context, intent, streamId)
            return
        }

        // ✅ Read snooze seconds from Settings
        val sp = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val snoozeSec = sp.getLong("flutter.alarm_snooze_sec", 300L).coerceIn(60L, 24 * 60 * 60L)
        val snoozeMin = (snoozeSec / 60).toInt().coerceAtLeast(1)

        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager

        val cpuWl = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "med:cpu")
        cpuWl.acquire(20_000)

        val screenFlags = PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP
        val screenWl = pm.newWakeLock(screenFlags, "med:screen")
        screenWl.acquire(8_000)

        try {
            val activityIntent = Intent(context, AlarmActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtras(intent.extras ?: android.os.Bundle())
                putExtra("id", notifId)
                putExtra("streamId", streamId)
                putExtra("title", title)
                putExtra("body", body)
                putExtra("scheduledAt", scheduledAt)
                putExtra("snoozeSec", snoozeSec)
            }

            val fullScreenPI = PendingIntent.getActivity(
                context,
                notifId,
                activityIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val channelId = "med_alarm_channel_sound_v5"
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

            // ✅ TAKEN
            val stopIntent = Intent(context, AlarmActionReceiver::class.java).apply {
                putExtra("action", "STOP")
                putExtra("id", notifId)
                putExtra("streamId", streamId)
                putExtra("title", title)
                putExtra("body", body)
                putExtra("scheduledAt", scheduledAt)
                putExtra("snoozeSec", snoozeSec)
            }
            val stopPI = PendingIntent.getBroadcast(
                context,
                notifId + 100000,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            // ✅ SNOOZE
            val snoozeIntent = Intent(context, AlarmActionReceiver::class.java).apply {
                putExtra("action", "SNOOZE")
                putExtra("id", notifId)
                putExtra("streamId", streamId)
                putExtra("title", title)
                putExtra("body", body)
                putExtra("scheduledAt", scheduledAt)
                putExtra("snoozeSec", snoozeSec)
            }
            val snoozePI = PendingIntent.getBroadcast(
                context,
                notifId + 200000,
                snoozeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            // ✅ SKIP NOW (popup reason)
            val skipNowIntent = Intent(context, AlarmActionReceiver::class.java).apply {
                putExtra("action", "SKIP_NOW")
                putExtra("id", notifId)
                putExtra("streamId", streamId)
                putExtra("title", title)
                putExtra("body", body)
                putExtra("scheduledAt", scheduledAt)
                putExtra("snoozeSec", snoozeSec)
            }
            val skipNowPI = PendingIntent.getBroadcast(
                context,
                notifId + 300000,
                skipNowIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

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
                .addAction(0, "Snooze $snoozeMin min", snoozePI)
                .addAction(0, "Skip now", skipNowPI)
                .addAction(0, "Taken", stopPI)

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                builder.setSound(alarmSound)
            }

            nm.notify(notifId, builder.build())

            // try launch activity
            try { context.startActivity(activityIntent) } catch (_: Throwable) {}

            // schedule next (only for stream alarms, not snooze)
            if (!isSnooze) {
                scheduleNext(context, intent, streamId)
            }

        } finally {
            try { cpuWl.release() } catch (_: Throwable) {}
            try { screenWl.release() } catch (_: Throwable) {}
        }
    }

    private fun scheduleNext(context: Context, intent: Intent, streamId: Int) {
        val title = intent.getStringExtra("title") ?: "Medicine Reminder"
        val body = intent.getStringExtra("body") ?: "Take your medicine"

        val freqType = intent.getIntExtra("freqType", 0)
        val hour = intent.getIntExtra("hour", 8)
        val minute = intent.getIntExtra("minute", 0)
        val intervalHours = intent.getIntExtra("intervalHours", 8)
        val weeklyMask = intent.getIntExtra("weeklyMask", 0b1111111)
        val monthlyDay = intent.getIntExtra("monthlyDay", 1)

        val now = Calendar.getInstance()

        fun nextDaily(): Long {
            val cal = Calendar.getInstance().apply {
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                if (timeInMillis <= now.timeInMillis) add(Calendar.DAY_OF_YEAR, 1)
            }
            return cal.timeInMillis
        }

        fun nextInterval(): Long {
            val cal = Calendar.getInstance().apply {
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                add(Calendar.HOUR_OF_DAY, intervalHours.coerceIn(1, 24))
            }
            return cal.timeInMillis
        }

        fun nextWeekly(): Long {
            fun flutterDow(calDow: Int): Int {
                return when (calDow) {
                    Calendar.MONDAY -> 1
                    Calendar.TUESDAY -> 2
                    Calendar.WEDNESDAY -> 3
                    Calendar.THURSDAY -> 4
                    Calendar.FRIDAY -> 5
                    Calendar.SATURDAY -> 6
                    else -> 7
                }
            }

            val base = Calendar.getInstance().apply {
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            for (i in 0..14) {
                val candidate = (base.clone() as Calendar).apply {
                    add(Calendar.DAY_OF_YEAR, i)
                    set(Calendar.HOUR_OF_DAY, hour)
                    set(Calendar.MINUTE, minute)
                }
                val dow = flutterDow(candidate.get(Calendar.DAY_OF_WEEK))
                val bit = 1 shl (dow - 1)
                if ((weeklyMask and bit) != 0 && candidate.timeInMillis > now.timeInMillis) {
                    return candidate.timeInMillis
                }
            }
            return nextDaily()
        }

        fun nextMonthly(): Long {
            val cal = Calendar.getInstance().apply {
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            fun build(monthOffset: Int): Long {
                val c = (cal.clone() as Calendar).apply {
                    add(Calendar.MONTH, monthOffset)
                    set(Calendar.DAY_OF_MONTH, 1)
                    val maxDay = getActualMaximum(Calendar.DAY_OF_MONTH)
                    set(Calendar.DAY_OF_MONTH, monthlyDay.coerceIn(1, maxDay))
                    set(Calendar.HOUR_OF_DAY, hour)
                    set(Calendar.MINUTE, minute)
                }
                return c.timeInMillis
            }

            val thisMonth = build(0)
            if (thisMonth > now.timeInMillis) return thisMonth
            return build(1)
        }

        val nextAt = when (freqType) {
            1 -> nextInterval()
            2 -> nextWeekly()
            3 -> nextMonthly()
            else -> nextDaily()
        }

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val nextIntent = Intent(context, AlarmReceiver::class.java).apply {
            putExtras(intent.extras ?: android.os.Bundle())
            putExtra("id", streamId)
            putExtra("streamId", streamId)
            putExtra("title", title)
            putExtra("body", body)
            putExtra("isSnooze", false)
            putExtra("scheduledAt", nextAt) // ✅ next occurrence time
        }

        val pi = PendingIntent.getBroadcast(
            context,
            streamId,
            nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val showIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }

        val showPi = PendingIntent.getActivity(
            context,
            streamId + 500000,
            showIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            alarmManager.setAlarmClock(AlarmManager.AlarmClockInfo(nextAt, showPi), pi)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, nextAt, pi)
        }
    }
}