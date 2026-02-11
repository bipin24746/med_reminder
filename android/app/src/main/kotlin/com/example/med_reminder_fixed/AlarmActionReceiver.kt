package com.example.med_reminder_fixed

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AlarmActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.getStringExtra("action") ?: return
        val id = intent.getIntExtra("id", 0)
        val title = intent.getStringExtra("title") ?: "Medicine Reminder"
        val body = intent.getStringExtra("body") ?: "Time to take your medicine"

        // ✅ Tell AlarmActivity (if open) to stop sound + close
        val stopUiIntent = Intent("com.example.med_reminder_fixed.ALARM_ACTION").apply {
            putExtra("action", action) // STOP or SNOOZE
        }
        context.sendBroadcast(stopUiIntent)

        // Cancel current notification
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(id)

        if (action == "STOP") return

        // ✅ Snooze exactly 5 minutes
        if (action == "SNOOZE") {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val snoozeId = (System.currentTimeMillis() % Int.MAX_VALUE).toInt()

            val receiverIntent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra("id", snoozeId)
                putExtra("title", title)
                putExtra("body", body)
            }

            val pi = PendingIntent.getBroadcast(
                context,
                snoozeId,
                receiverIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            val showIntent = Intent(context, AlarmActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("id", snoozeId)
                putExtra("title", title)
                putExtra("body", body)
            }

            val showPI = PendingIntent.getActivity(
                context,
                snoozeId,
                showIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            val triggerAt = System.currentTimeMillis() + 5 * 60 * 1000L

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                alarmManager.setAlarmClock(AlarmManager.AlarmClockInfo(triggerAt, showPI), pi)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            }
        }
    }
}
