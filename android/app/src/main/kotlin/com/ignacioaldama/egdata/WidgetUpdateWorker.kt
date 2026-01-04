package com.ignacioaldama.egdata

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*

/**
 * WorkManager worker for updating widget data in background
 * Runs every 6 hours to fetch latest free games
 */
class WidgetUpdateWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    override fun doWork(): Result {
        return try {
            Log.d(TAG, "Widget update worker started")

            // Fetch free games from API
            val games = fetchActiveFreeGames()

            if (games.isNotEmpty()) {
                // Save to SharedPreferences
                saveWidgetData(games)

                // Trigger widget update
                triggerWidgetUpdate()

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

        // Priority 1: OfferImageTall (New Vertical format)
        for (i in 0 until keyImages.length()) {
            val image = keyImages.getJSONObject(i)
            if (image.getString("type") == "OfferImageTall") {
                return image.getString("url")
            }
        }

        // Priority 2: DieselGameBoxTall
        for (i in 0 until keyImages.length()) {
            val image = keyImages.getJSONObject(i)
            if (image.getString("type") == "DieselGameBoxTall") {
                return image.getString("url")
            }
        }

        // Priority 3: Thumbnail
        for (i in 0 until keyImages.length()) {
            val image = keyImages.getJSONObject(i)
            if (image.getString("type") == "Thumbnail") {
                return image.getString("url")
            }
        }

        // Fallback: First image
        return if (keyImages.length() > 0) {
            keyImages.getJSONObject(0).getString("url")
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

        prefs.edit()
            .putString("widget_data", widgetData.toString())
            .apply()

        Log.d(TAG, "Saved widget data with ${games.size} games")
    }

    private fun triggerWidgetUpdate() {
        val intent = Intent(applicationContext, FreeGamesWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }

        val widgetManager = AppWidgetManager.getInstance(applicationContext)
        val widgetIds = widgetManager.getAppWidgetIds(
            ComponentName(applicationContext, FreeGamesWidgetProvider::class.java)
        )

        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
        applicationContext.sendBroadcast(intent)

        Log.d(TAG, "Triggered widget update for ${widgetIds.size} widgets")
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
