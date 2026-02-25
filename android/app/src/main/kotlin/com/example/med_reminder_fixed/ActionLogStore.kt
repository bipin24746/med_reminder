package com.example.med_reminder_fixed

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object ActionLogStore {
    private const val PREFS = "med_action_logs"
    private const val KEY = "logs_json"
    private const val MAX = 500

    fun addTaken(
        context: Context,
        streamId: Int,
        title: String,
        body: String,
        scheduledAt: Long = 0L
    ) {
        add(
            context = context,
            action = "TAKEN",
            streamId = streamId,
            title = title,
            body = body,
            reason = "",
            scheduledAt = scheduledAt
        )
    }

    fun addSkipped(
        context: Context,
        streamId: Int,
        title: String,
        body: String,
        reason: String,
        scheduledAt: Long = 0L
    ) {
        add(
            context = context,
            action = "SKIP_NOW",
            streamId = streamId,
            title = title,
            body = body,
            reason = reason,
            scheduledAt = scheduledAt
        )
    }

    private fun add(
        context: Context,
        action: String,
        streamId: Int,
        title: String,
        body: String,
        reason: String,
        scheduledAt: Long
    ) {
        val sp = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val raw = sp.getString(KEY, "[]") ?: "[]"
        val arr = try { JSONArray(raw) } catch (_: Throwable) { JSONArray() }

        val obj = JSONObject().apply {
            put("ts", System.currentTimeMillis())
            put("scheduledAt", scheduledAt)
            put("action", action)
            put("streamId", streamId)
            put("title", title)
            put("body", body)
            put("reason", reason)
        }

        // newest first
        val out = JSONArray()
        out.put(obj)
        for (i in 0 until arr.length()) {
            out.put(arr.getJSONObject(i))
            if (out.length() >= MAX) break
        }

        sp.edit().putString(KEY, out.toString()).apply()
    }

    fun fetch(context: Context): String {
        val sp = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return sp.getString(KEY, "[]") ?: "[]"
    }
}