package com.example.med_reminder_fixed

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

object UserActionLog {

    private const val SP_NAME = "med_user_action_log"
    private const val KEY = "events"
    private const val TAG = "MedLog"

    private fun sp(context: Context) =
        context.getSharedPreferences(SP_NAME, Context.MODE_PRIVATE)

    /**
     * action: TAKEN | SNOOZE | SKIP_NOW | AUTO_TIMEOUT | RING_SHOWN | SKIP_NOW_OPENED
     */
    fun add(
        context: Context,
        action: String,
        streamId: Int,
        notifId: Int,
        scheduledAt: Long,
        title: String?,
        body: String?,
        reason: String? = null
    ) {
        try {
            val now = System.currentTimeMillis()

            val obj = JSONObject().apply {
                put("ts", now)
                put("action", action)
                put("streamId", streamId)
                put("notifId", notifId)
                put("scheduledAt", scheduledAt)
                put("title", title ?: "")
                put("body", body ?: "")
                if (!reason.isNullOrBlank()) put("reason", reason)
            }

            val raw = sp(context).getString(KEY, "[]") ?: "[]"
            val arr = JSONArray(raw)

            // keep last 300 logs
            while (arr.length() >= 300) arr.remove(0)

            arr.put(obj)
            sp(context).edit().putString(KEY, arr.toString()).apply()

            Log.d(TAG, "LOG action=$action streamId=$streamId notifId=$notifId scheduledAt=$scheduledAt reason=$reason")
        } catch (e: Throwable) {
            Log.e(TAG, "Failed to log action: $e")
        }
    }

    fun getAllJson(context: Context): String {
        return sp(context).getString(KEY, "[]") ?: "[]"
    }

    fun clear(context: Context) {
        sp(context).edit().remove(KEY).apply()
    }
}