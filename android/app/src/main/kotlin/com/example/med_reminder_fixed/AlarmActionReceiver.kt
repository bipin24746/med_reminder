package com.example.med_reminder_fixed

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AlarmActionReceiver : BroadcastReceiver() {

    private fun snoozeReqId(streamId: Int): Int = streamId + 900000

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.getStringExtra("action") ?: return

        val notifId = intent.getIntExtra("id", 0)
        val streamId = intent.getIntExtra("streamId", notifId)
        val scheduledAt = intent.getLongExtra("scheduledAt", 0L)

        val title = intent.getStringExtra("title") ?: "Medicine Reminder"
        val body = intent.getStringExtra("body") ?: "Time to take your medicine"

        val snoozeSecFromIntent = intent.getLongExtra("snoozeSec", 0L)

        val sp = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val snoozeSec = (if (snoozeSecFromIntent > 0) snoozeSecFromIntent
        else sp.getLong("flutter.alarm_snooze_sec", 300L)).coerceIn(60L, 24 * 60 * 60L)

        // cancel this notification
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (notifId != 0) nm.cancel(notifId)

        if (action == "STOP") {
            UserActionLog.add(context, "TAKEN", streamId, notifId, scheduledAt, title, body)
            return
        }

        if (action == "SKIP_NOW") {
            UserActionLog.add(context, "SKIP_NOW_OPENED", streamId, notifId, scheduledAt, title, body)

            val launch = Intent(context, AlarmLaunchService::class.java).apply {
                putExtras(intent.extras ?: android.os.Bundle())
                putExtra("openSkipDialog", true)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(launch)
            } else {
                context.startService(launch)
            }
            return
        }

        if (action == "SNOOZE") {
            UserActionLog.add(context, "SNOOZE", streamId, notifId, scheduledAt, title, body, "sec=$snoozeSec")

            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val reqId = snoozeReqId(streamId)

            val triggerAt = System.currentTimeMillis() + snoozeSec * 1000L

            val receiverIntent = Intent(context, AlarmReceiver::class.java).apply {
                putExtras(intent.extras ?: android.os.Bundle())
                putExtra("id", reqId)
                putExtra("streamId", streamId)
                putExtra("title", title)
                putExtra("body", body)
                putExtra("isSnooze", true)
                putExtra("scheduledAt", triggerAt)
                putExtra("snoozeSec", snoozeSec)
            }

            val pi = PendingIntent.getBroadcast(
                context,
                reqId,
                receiverIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            }
        }
    }
}