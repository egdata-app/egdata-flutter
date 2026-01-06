package com.ignacioaldama.egdata

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.lifecycle.lifecycleScope
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ignacioaldama.egdata/widget"
    private var pendingOfferId: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        scheduleWidgetUpdates()
        handleIntent(intent)

        // Trigger the widget preview generation when the app starts
        lifecycleScope.launch {
            try {
                val manager = GlanceAppWidgetManager(context)
                // Trigger preview for both large and small widgets
                manager.setWidgetPreviews(FreeGamesGlanceReceiver::class)
                manager.setWidgetPreviews(SmallFreeGamesGlanceReceiver::class)
            } catch (e: Exception) {
                // This might fail on older Android versions or if rate-limited, which is fine.
                Log.e("MainActivity", "Failed to set widget previews", e)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        sendOfferToFlutter()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getPendingOfferId") {
                result.success(pendingOfferId)
                pendingOfferId = null // Clear after reading
            } else {
                result.notImplemented()
            }
        }
    }

    private fun handleIntent(intent: Intent) {
        Log.d("MainActivity", "handleIntent: action=${intent.action}")
        if (intent.action == "com.ignacioaldama.egdata.ACTION_OPEN_OFFER") {
            pendingOfferId = intent.getStringExtra("offerId")
            Log.d("MainActivity", "Received offerId from widget: $pendingOfferId")
        }
    }

    private fun sendOfferToFlutter() {
        if (pendingOfferId != null) {
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                MethodChannel(it, CHANNEL).invokeMethod("onOfferSelected", pendingOfferId)
                pendingOfferId = null
            }
        }
    }

    private fun scheduleWidgetUpdates() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val updateRequest = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(15, TimeUnit.MINUTES)
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "widget_update",
            ExistingPeriodicWorkPolicy.KEEP,
            updateRequest
        )
    }
}
