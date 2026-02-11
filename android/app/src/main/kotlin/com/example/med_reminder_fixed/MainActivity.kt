package com.example.med_reminder_fixed

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val ALARM_NATIVE = "alarm_native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ✅ 1) alarm_native channel (schedule/cancel/openAlarmActivity)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_NATIVE)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "schedule" -> {
                        val id = call.argument<Int>("id") ?: 0
                        val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                        val title = call.argument<String>("title") ?: "Medicine Reminder"
                        val body = call.argument<String>("body") ?: "Time to take your medicine"
                        scheduleExact(this, id, triggerAtMillis, title, body)
                        result.success(true)
                    }

                    "cancel" -> {
                        val id = call.argument<Int>("id") ?: 0
                        cancel(this, id)
                        result.success(true)
                    }

                    // ✅ This fixes your "openNow" test button in Flutter
                    "openAlarmActivity" -> {
                        val title = call.argument<String>("title") ?: "Medicine Reminder"
                        val body = call.argument<String>("body") ?: "Time to take your medicine"

                        val i = Intent(this, AlarmActivity::class.java).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                            putExtra("title", title)
                            putExtra("body", body)
                        }
                        startActivity(i)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }

        // ✅ 2) app_settings channel (permissions/settings shortcuts)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "openAlarmPermission" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                    data = Uri.parse("package:$packageName")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                            }
                            result.success(true)
                        } catch (e: Throwable) {
                            result.error("ERR", e.toString(), null)
                        }
                    }

                    "openAppBattery" -> {
                        try {
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Throwable) {
                            result.error("ERR", e.toString(), null)
                        }
                    }

                    "openNotificationSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Throwable) {
                            result.error("ERR", e.toString(), null)
                        }
                    }

                    "openOverlayPermission" -> {
                        try {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Throwable) {
                            result.error("ERR", e.toString(), null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ✅ Alarm scheduling (AlarmClock)
    private fun scheduleExact(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        title: String,
        body: String
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("title", title)
            putExtra("body", body)
            putExtra("id", id)
        }

        val pi = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val showIntent = Intent(context, AlarmActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("title", title)
            putExtra("body", body)
        }

        val showPI = PendingIntent.getActivity(
            context,
            id,
            showIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            alarmManager.setAlarmClock(AlarmManager.AlarmClockInfo(triggerAtMillis, showPI), pi)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
        }
    }

    private fun cancel(context: Context, id: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java)

        val pi = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )
        alarmManager.cancel(pi)
    }
}
