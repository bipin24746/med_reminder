package com.example.med_reminder_fixed

import android.content.Context

object DoseHandledStore {
    private const val PREF = "dose_handled_store"
    private fun key(id: Int) = "handled_$id"

    fun markHandled(context: Context, id: Int) {
        context.getSharedPreferences(PREF, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(key(id), true)
            .apply()
    }

    fun isHandled(context: Context, id: Int): Boolean {
        return context.getSharedPreferences(PREF, Context.MODE_PRIVATE)
            .getBoolean(key(id), false)
    }
}