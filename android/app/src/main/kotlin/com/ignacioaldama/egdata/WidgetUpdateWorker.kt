package com.ignacioaldama.egdata

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*

/**
 * WorkManager worker for updating widget data in background
 * Runs every 15 minutes to fetch latest free games
 */
class WidgetUpdateWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            Log.d(TAG, "Widget update worker started")

            // Fetch free games from API
            val games = fetchActiveFreeGames()

            if (games.isNotEmpty()) {
                // Save to SharedPreferences - USE COMMIT for synchronous write
                // This prevents race conditions where the widget updates before data is saved
                saveWidgetData(games)

                // Trigger widget update
                triggerWidgetUpdate()

                // Update widget preview (rate-limited to once per hour)
                updateWidgetPreviewIfNeeded()

                Log.d(TAG, "Widget updated successfully with ${games.size} games")
                Result.success()
            } else {
                Log.d(TAG, "No free games available")
                Result.success()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error updating widget", e)
            Result.retry()
        }
    }

    private fun fetchActiveFreeGames(): List<GameData> {
        val url = URL("https://api.egdata.app/free-games")
        val connection = url.openConnection() as HttpURLConnection

        return try {
            connection.requestMethod = "GET"
            connection.connectTimeout = 10000
            connection.readTimeout = 10000

            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                parseAndFilterGames(response)
            } else {
                Log.e(TAG, "API request failed with code: $responseCode")
                emptyList()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching free games", e)
            emptyList()
        } finally {
            connection.disconnect()
        }
    }

    private fun parseAndFilterGames(jsonResponse: String): List<GameData> {
        val gamesArray = JSONArray(jsonResponse)
        val activeGames = mutableListOf<GameData>()
        val now = Date()

        for (i in 0 until gamesArray.length()) {
            val gameJson = gamesArray.getJSONObject(i)

            // Check if game has active giveaway
            val giveaway = gameJson.optJSONObject("giveaway") ?: continue

            val startDateStr = giveaway.getString("startDate")
            val endDateStr = giveaway.getString("endDate")

            val startDate = parseDate(startDateStr)
            val endDate = parseDate(endDateStr)

            // Filter for currently active games
            if (startDate != null && endDate != null &&
                now.after(startDate) && now.before(endDate)) {

                val id = gameJson.getString("id")
                val title = gameJson.getString("title")
                val thumbnailUrl = extractThumbnailUrl(gameJson)

                activeGames.add(
                    GameData(
                        id = id,
                        title = title,
                        thumbnailUrl = thumbnailUrl,
                        endDate = endDateStr
                    )
                )
            }
        }

        // Limit to 6 games for widget
        return activeGames.take(6)
    }

    private fun extractThumbnailUrl(gameJson: JSONObject): String? {
        val keyImages = gameJson.optJSONArray("keyImages") ?: return null

        // Priority 1: Wide images for horizontal widget layouts
        val wideTypes = listOf("OfferImageWide", "DieselStoreFrontWide", "Landscape", "featuredMedia", "Wide")
        for (type in wideTypes) {
            for (i in 0 until keyImages.length()) {
                val image = keyImages.getJSONObject(i)
                if (image.getString("type") == type) {
                    val url = image.getString("url")
                    if (url.isNotEmpty()) return url
                }
            }
        }

        // Priority 2: Standard Tall images as fallback
        val tallTypes = listOf("OfferImageTall", "DieselGameBoxTall", "Tall")
        for (type in tallTypes) {
            for (i in 0 until keyImages.length()) {
                val image = keyImages.getJSONObject(i)
                if (image.getString("type") == type) {
                    val url = image.getString("url")
                    if (url.isNotEmpty()) return url
                }
            }
        }

        // Priority 3: Thumbnail
        for (i in 0 until keyImages.length()) {
            val image = keyImages.getJSONObject(i)
            if (image.getString("type") == "Thumbnail") {
                val url = image.getString("url")
                if (url.isNotEmpty()) return url
            }
        }

        // Fallback: First image
        return if (keyImages.length() > 0) {
            keyImages.getJSONObject(0).optString("url", null)
        } else null
    }

    private fun parseDate(dateStr: String): Date? {
        return try {
            val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
            format.timeZone = TimeZone.getTimeZone("UTC")
            format.parse(dateStr)
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing date: $dateStr", e)
            null
        }
    }

    private fun saveWidgetData(games: List<GameData>) {
        val prefs = applicationContext.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        val gamesArray = JSONArray()
        games.forEach { game ->
            val gameJson = JSONObject().apply {
                put("id", game.id)
                put("title", game.title)
                put("thumbnailUrl", game.thumbnailUrl)
                put("endDate", game.endDate)
            }
            gamesArray.put(gameJson)
        }

        val widgetData = JSONObject().apply {
            put("games", gamesArray)
            put("lastUpdate", SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }.format(Date()))
        }

        // IMPORTANT: Use commit() here to ensure data is written BEFORE update is triggered
        prefs.edit()
            .putString("widget_data", widgetData.toString())
            .commit()

        Log.d(TAG, "Saved widget data with ${games.size} games")
    }

    private fun triggerWidgetUpdate() {
        // Update Glance widget (large)
        val glanceIntent = Intent(applicationContext, FreeGamesGlanceReceiver::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }

        val widgetManager = AppWidgetManager.getInstance(applicationContext)
        val glanceWidgetIds = widgetManager.getAppWidgetIds(
            ComponentName(applicationContext, FreeGamesGlanceReceiver::class.java)
        )

        glanceIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, glanceWidgetIds)
        applicationContext.sendBroadcast(glanceIntent)

        // Update small widget
        val smallIntent = Intent(applicationContext, SmallFreeGamesWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }

        val smallWidgetIds = widgetManager.getAppWidgetIds(
            ComponentName(applicationContext, SmallFreeGamesWidgetProvider::class.java)
        )

        smallIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, smallWidgetIds)
        applicationContext.sendBroadcast(smallIntent)

        Log.d(TAG, "Triggered widget update for ${glanceWidgetIds.size} Glance widgets and ${smallWidgetIds.size} small widgets")
    }

    /**
     * Updates widget preview for Android 15+ widget picker.
     * Rate-limited to once per hour to respect API limits (~2 calls/hour).
     */
    private suspend fun updateWidgetPreviewIfNeeded() {
        withContext(Dispatchers.IO) {
            try {
                val prefs = applicationContext.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                val lastPreviewUpdate = prefs.getLong("last_preview_update", 0)
                val now = System.currentTimeMillis()

                // Only update if more than 1 hour has passed
                val oneHourInMillis = 60 * 60 * 1000
                if (now - lastPreviewUpdate > oneHourInMillis) {
                    FreeGamesGlanceWidget.updateWidgetPreview(applicationContext)

                    // Save timestamp
                    prefs.edit()
                        .putLong("last_preview_update", now)
                        .apply()

                    Log.d(TAG, "Widget preview updated")
                } else {
                    Log.d(TAG, "Skipping preview update (rate limited)")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error updating widget preview", e)
            }
        }
    }

    data class GameData(
        val id: String,
        val title: String,
        val thumbnailUrl: String?,
        val endDate: String
    )

    companion object {
        private const val TAG = "WidgetUpdateWorker"
    }
}
