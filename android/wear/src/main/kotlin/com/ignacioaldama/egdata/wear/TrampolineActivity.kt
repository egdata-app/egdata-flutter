package com.ignacioaldama.egdata.wear

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.wear.remote.interactions.RemoteActivityHelper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.launch

/**
 * Trampoline activity that handles click actions from the Wear OS tile.
 * Opens URLs in the browser on the paired phone device.
 */
class TrampolineActivity : Activity() {

    companion object {
        const val EXTRA_ACTION = "extra_action"
        const val EXTRA_OFFER_ID = "extra_offer_id"

        const val ACTION_FREE_GAMES = "action_free_games"
        const val ACTION_OPEN_OFFER = "action_open_offer"

        private const val BASE_URL = "https://egdata.app"
    }

    private val scope = CoroutineScope(Dispatchers.Main)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val action = intent.getStringExtra(EXTRA_ACTION)
        val url = when (action) {
            ACTION_FREE_GAMES -> "$BASE_URL/free-games"
            ACTION_OPEN_OFFER -> {
                val offerId = intent.getStringExtra(EXTRA_OFFER_ID)
                if (offerId != null) "$BASE_URL/offers/$offerId" else BASE_URL
            }
            else -> BASE_URL
        }

        openUrlOnPhone(url)
    }

    private fun openUrlOnPhone(url: String) {
        val remoteActivityHelper = RemoteActivityHelper(this)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse(url)
            addCategory(Intent.CATEGORY_BROWSABLE)
        }

        scope.launch {
            try {
                remoteActivityHelper.startRemoteActivity(intent).await()
            } catch (e: Exception) {
                // Fallback: try to open on watch browser
                try {
                    startActivity(intent)
                } catch (e2: Exception) {
                    // Silently fail if no browser available
                }
            }
            finish()
        }
    }
}
