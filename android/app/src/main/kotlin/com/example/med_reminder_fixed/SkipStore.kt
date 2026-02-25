package com.example.med_reminder_fixed

import android.content.Context

/**
 * Stores per-stream skip-until time using SharedPreferences.
 * If now < skipUntil, we skip ringing this stream (only when receiver checks it).
 */
object SkipStore {
    private const val PREFS = "med_skip_store"

    private fun keyUntil(streamId: Int) = "skip_until_$streamId"
    private fun keyReason(streamId: Int) = "skip_reason_$streamId"

    fun setSkipUntil(context: Context, streamId: Int, untilMillis: Long, reason: String? = null) {
        val sp = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        sp.edit()
            .putLong(keyUntil(streamId), untilMillis)
            .putString(keyReason(streamId), reason ?: "")
            .apply()
    }

    fun getSkipUntil(context: Context, streamId: Int): Long {
        val sp = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return sp.getLong(keyUntil(streamId), 0L)
    }

    fun getSkipReason(context: Context, streamId: Int): String {
        val sp = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return sp.getString(keyReason(streamId), "") ?: ""
    }

    fun clearSkip(context: Context, streamId: Int) {
        val sp = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        sp.edit()
            .remove(keyUntil(streamId))
            .remove(keyReason(streamId))
            .apply()
    }

    fun shouldSkipNow(context: Context, streamId: Int): Boolean {
        val until = getSkipUntil(context, streamId)
        return until > 0L && System.currentTimeMillis() < until
    }
}