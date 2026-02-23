package com.example.med_reminder_fixed

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // ✅ After reboot, alarms are cleared by Android.
        // You must reschedule from persisted DB.
        //
        // Best practice:
        // - Start a small service / worker to read DB and reschedule.
        //
        // For now we do nothing here because you didn't provide a native DB reader.
        // If you want, I can add a simple WorkManager task that calls into Flutter
        // via a headless engine OR implement native SQLite read.
    }
}