package com.ignacioaldama.egdata

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.glance.appwidget.action.ActionTrampolineActivity

/** Keeps restored or malformed legacy widget launches from crashing at startup. */
class SafeWidgetTrampolineActivity : ActionTrampolineActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // These are the routing extras used by the pinned Glance dependency.
        // A valid widget click is passed unchanged to Glance. If its target was
        // lost, open the home screen; there is no reliable offer ID to recover.
        @Suppress("DEPRECATION")
        val target = intent.getParcelableExtra<Intent>("ACTION_INTENT")
        if (target == null) {
            Log.w("WidgetTrampoline", "Widget launch had no target; opening egdata.app")
            intent.putExtra("ACTION_INTENT", Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            })
            intent.putExtra("ACTION_TYPE", "ACTIVITY")
        }
        super.onCreate(savedInstanceState)
    }
}
