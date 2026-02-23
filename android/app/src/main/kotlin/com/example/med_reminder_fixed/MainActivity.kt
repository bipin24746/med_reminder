package com.example.med_reminder_fixed

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "alarm_native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "schedule" -> {
                        val id = call.argument<Int>("id") ?: 0
                        val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                        val title = call.argument<String>("title") ?: "Medicine Reminder"
                        val body = call.argument<String>("body") ?: "Take your medicine"

                        val extras = call.argument<HashMap<String, Any>>("extras") ?: hashMapOf()

                        scheduleExact(
                            context = this,
                            id = id,
                            triggerAtMillis = triggerAtMillis,
                            title = title,
                            body = body,
                            extras = extras
                        )

                        result.success(null)
                    }

                    "cancel" -> {
                        val id = call.argument<Int>("id") ?: 0
                        cancelAlarm(this, id)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun scheduleExact(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        title: String,
        body: String,
        extras: Map<String, Any>
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("title", title)
            putExtra("body", body)

            // ✅ occurrence time used by "Skip now"
            putExtra("scheduledAt", triggerAtMillis)

            for ((k, v) in extras) {
                when (v) {
                    is Int -> putExtra(k, v)
                    is Long -> putExtra(k, v)
                    is Double -> putExtra(k, v)
                    is Boolean -> putExtra(k, v)
                    is String -> putExtra(k, v)
                }
            }
        }

        val pi = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
        }
    }

    private fun cancelAlarm(context: Context, id: Int) {
        val intent = Intent(context, AlarmReceiver::class.java)
        val pi = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pi)
    }
}