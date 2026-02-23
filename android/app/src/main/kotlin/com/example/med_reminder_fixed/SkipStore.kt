package com.example.med_reminder_fixed

import android.content.Context

object SkipStore {

    private fun sp(context: Context) =
        context.getSharedPreferences("med_skip_store", Context.MODE_PRIVATE)

    private fun key(streamId: Int, scheduledAt: Long) = "skipped_${streamId}_$scheduledAt"
    private fun reasonKey(streamId: Int, scheduledAt: Long) = "skipped_reason_${streamId}_$scheduledAt"

    fun markSkipped(context: Context, streamId: Int, scheduledAt: Long, reason: String) {
        if (scheduledAt <= 0L) return
        sp(context).edit()
            .putBoolean(key(streamId, scheduledAt), true)
            .putString(reasonKey(streamId, scheduledAt), reason)
            .apply()
    }

    fun isSkipped(context: Context, streamId: Int, scheduledAt: Long): Boolean {
        if (scheduledAt <= 0L) return false
        return sp(context).getBoolean(key(streamId, scheduledAt), false)
    }
}