package com.example.med_reminder_fixed

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CH_ALARM_NATIVE = "alarm_native"
    private val CH_ALARM_SETTINGS = "alarm_settings"

    private var pendingToneResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ✅ Channel 1: schedule/cancel alarms
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CH_ALARM_NATIVE)
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

                    // OPTIONAL: if you call NativeAlarmService.openNow()
                    "openAlarmActivity" -> {
                        val title = call.argument<String>("title") ?: "Medicine Reminder"
                        val body = call.argument<String>("body") ?: "Time to take your medicine"

                        val i = Intent(this, AlarmActivity::class.java).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                            putExtra("id", (System.currentTimeMillis() % Int.MAX_VALUE).toInt())
                            putExtra("title", title)
                            putExtra("body", body)
                        }
                        startActivity(i)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }

        // ✅ Channel 2: pick alarm tone (FIXES MissingPluginException)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CH_ALARM_SETTINGS)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickAlarmTone" -> {
                        if (pendingToneResult != null) {
                            result.error("BUSY", "Tone picker already open", null)
                            return@setMethodCallHandler
                        }
                        pendingToneResult = result

                        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Select Alarm Tone")
                        }

                        startActivityForResult(intent, REQ_PICK_TONE)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQ_PICK_TONE) {
            val res = pendingToneResult
            pendingToneResult = null

            if (res == null) return

            if (resultCode != RESULT_OK) {
                res.success("") // user cancelled
                return
            }

            val uri: Uri? =
                data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)

            res.success(uri?.toString() ?: "")
        }
    }

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
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                        PendingIntent.FLAG_IMMUTABLE else 0)
        )

        // Strong scheduling
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
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
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                        PendingIntent.FLAG_IMMUTABLE else 0)
        )
        alarmManager.cancel(pi)
    }

    companion object {
        private const val REQ_PICK_TONE = 9901
    }
}
