package com.ignacioaldama.egdata

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.wear.remote.interactions.RemoteActivityHelper
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Service for detecting and communicating with Wear OS devices.
 */
class WearableService(private val context: Context) {

    companion object {
        private const val TAG = "WearableService"
        private const val WEAR_CAPABILITY = "egdata_wear_app"
        // Same package as main app (required for embedded wear apps)
        private const val WEAR_APP_PACKAGE = "com.ignacioaldama.egdata"
    }

    private val remoteActivityHelper = RemoteActivityHelper(context)

    /**
     * Check if any Wear OS devices are connected.
     * Returns a list of connected devices.
     */
    suspend fun getConnectedWearDevices(): List<WearDevice> {
        return try {
            val nodeClient = Wearable.getNodeClient(context)
            val nodes = nodeClient.connectedNodes.await()
            nodes.map { node ->
                WearDevice(
                    id = node.id,
                    displayName = node.displayName,
                    isNearby = node.isNearby
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting connected wear devices", e)
            emptyList()
        }
    }

    /**
     * Check if the EGData wear app is installed on any connected device.
     * Returns a list of node IDs that have the app installed.
     */
    suspend fun getDevicesWithAppInstalled(): List<String> {
        return try {
            val capabilityClient = Wearable.getCapabilityClient(context)
            val capabilityInfo = capabilityClient
                .getCapability(WEAR_CAPABILITY, CapabilityClient.FILTER_REACHABLE)
                .await()
            capabilityInfo.nodes.map { node -> node.id }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking wear app capability", e)
            emptyList()
        }
    }

    /**
     * Open the Play Store on the watch to install the app.
     * Uses RemoteActivityHelper to directly launch the Play Store on the target device.
     * Includes a 10-second timeout as this may hang on emulators.
     */
    suspend fun openPlayStoreOnWatch(nodeId: String): Boolean {
        Log.d(TAG, "openPlayStoreOnWatch called with nodeId: $nodeId")
        return try {
            val intent = Intent(Intent.ACTION_VIEW)
                .addCategory(Intent.CATEGORY_BROWSABLE)
                .setData(Uri.parse("market://details?id=$WEAR_APP_PACKAGE"))

            Log.d(TAG, "Starting remote activity with intent: ${intent.data}")

            val result = remoteActivityHelper.startRemoteActivity(
                targetIntent = intent,
                targetNodeId = nodeId
            )

            Log.d(TAG, "Awaiting remote activity result (10s timeout)...")
            val completed = withTimeoutOrNull(10_000L) {
                result.await()
                true
            }

            if (completed == true) {
                Log.d(TAG, "Successfully opened Play Store on watch $nodeId")
                true
            } else {
                Log.w(TAG, "Timeout waiting for remote activity on $nodeId (may not work on emulators)")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error opening Play Store on watch: ${e.javaClass.simpleName}: ${e.message}", e)
            false
        }
    }

    /**
     * Send a message to all connected watches to trigger a tile refresh.
     */
    suspend fun triggerTileRefresh(): Boolean {
        return try {
            val messageClient = Wearable.getMessageClient(context)
            val nodes = getConnectedWearDevices()

            var success = true
            for (device in nodes) {
                try {
                    messageClient.sendMessage(device.id, "/refresh_tile", byteArrayOf()).await()
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending refresh to ${device.id}", e)
                    success = false
                }
            }
            success
        } catch (e: Exception) {
            Log.e(TAG, "Error triggering tile refresh", e)
            false
        }
    }

    data class WearDevice(
        val id: String,
        val displayName: String,
        val isNearby: Boolean
    )
}
