package com.ignacioaldama.egdata

import android.content.Intent
import android.os.Build
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
    private val WEAR_CHANNEL = "com.ignacioaldama.egdata/wear"
    private val NOTIFICATION_CHANNEL = "com.ignacioaldama.egdata/notification"
    private var pendingOfferId: String? = null
    private var pendingAction: String? = null
    private lateinit var wearableService: WearableService
    private lateinit var notificationHelper: NotificationTestHelper

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        wearableService = WearableService(this)
        notificationHelper = NotificationTestHelper(this)
        scheduleWidgetUpdates()
        handleIntent(intent)

        // Trigger the widget preview generation when the app starts (Android 15+ only)
        lifecycleScope.launch {
            try {
                // setWidgetPreviews is only available on Android 15 (API 35) and above
                if (Build.VERSION.SDK_INT >= 35) {
                    val manager = GlanceAppWidgetManager(context)
                    // Trigger preview for both large and small widgets
                    manager.setWidgetPreviews(FreeGamesGlanceReceiver::class)
                    manager.setWidgetPreviews(SmallFreeGamesGlanceReceiver::class)
                }
            } catch (e: Exception) {
                // This might fail if rate-limited, which is fine.
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

        // Widget channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingOfferId" -> {
                    result.success(pendingOfferId)
                    pendingOfferId = null // Clear after reading
                }
                "getPendingAction" -> {
                    val response = mapOf(
                        "action" to pendingAction,
                        "offerId" to pendingOfferId
                    )
                    result.success(response)
                    pendingAction = null
                    pendingOfferId = null
                }
                else -> result.notImplemented()
            }
        }

        // Notification channel for testing custom notifications
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            lifecycleScope.launch {
                try {
                    when (call.method) {
                        "testFreeGameNotification" -> {
                            val offerId = call.argument<String>("offerId")
                            if (offerId != null) {
                                notificationHelper.triggerTestNotification(offerId)
                                result.success(true)
                            } else {
                                result.error("INVALID_ARGUMENT", "offerId is required", null)
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
        }

        // Wear OS channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WEAR_CHANNEL).setMethodCallHandler { call, result ->
            lifecycleScope.launch {
                try {
                    when (call.method) {
                        "getConnectedDevices" -> {
                            val devices = wearableService.getConnectedWearDevices()
                            result.success(devices.map { mapOf(
                                "id" to it.id,
                                "displayName" to it.displayName,
                                "isNearby" to it.isNearby
                            )})
                        }
                        "getDevicesWithApp" -> {
                            val deviceIds = wearableService.getDevicesWithAppInstalled()
                            result.success(deviceIds)
                        }
                        "openPlayStoreOnWatch" -> {
                            val nodeId = call.argument<String>("nodeId")
                            Log.d("MainActivity", "openPlayStoreOnWatch called with nodeId: $nodeId")
                            if (nodeId != null) {
                                val success = wearableService.openPlayStoreOnWatch(nodeId)
                                Log.d("MainActivity", "openPlayStoreOnWatch result: $success")
                                result.success(success)
                            } else {
                                Log.e("MainActivity", "openPlayStoreOnWatch: nodeId is null")
                                result.error("INVALID_ARGUMENT", "nodeId is required", null)
                            }
                        }
                        "triggerTileRefresh" -> {
                            val success = wearableService.triggerTileRefresh()
                            result.success(success)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
        }
    }

    private fun handleIntent(intent: Intent) {
        Log.d("MainActivity", "handleIntent: action=${intent.action}, data=${intent.data}, extras=${intent.extras}")

        // Handle widget action
        if (intent.action == "com.ignacioaldama.egdata.ACTION_OPEN_OFFER") {
            pendingOfferId = intent.getStringExtra("offerId")
            Log.d("MainActivity", "Received offerId from widget: $pendingOfferId")
        }

        // Handle deep links from Wear OS tile (egdata:// scheme)
        if (intent.action == Intent.ACTION_VIEW && intent.data?.scheme == "egdata") {
            val uri = intent.data
            Log.d("MainActivity", "Received deep link from wear tile: $uri")
            when (uri?.host) {
                "offer" -> {
                    // egdata://offer/{offerId}
                    pendingOfferId = uri.pathSegments.firstOrNull()
                    pendingAction = "open_offer"
                    Log.d("MainActivity", "Deep link: open offer $pendingOfferId")
                }
                "free-games" -> {
                    // egdata://free-games
                    pendingAction = "free_games"
                    Log.d("MainActivity", "Deep link: open free games")
                }
                "home" -> {
                    // egdata://home - just open the app
                    Log.d("MainActivity", "Deep link: open home")
                }
            }
            return
        }

        // Handle wear tile actions (via extras) - legacy fallback
        val action = intent.getStringExtra("action")
        if (action != null) {
            Log.d("MainActivity", "Received action from wear tile (extras): $action")
            when (action) {
                "free_games" -> {
                    pendingAction = "free_games"
                }
                "open_offer" -> {
                    pendingOfferId = intent.getStringExtra("offerId")
                    pendingAction = "open_offer"
                    Log.d("MainActivity", "Received offerId from wear tile: $pendingOfferId")
                }
            }
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
