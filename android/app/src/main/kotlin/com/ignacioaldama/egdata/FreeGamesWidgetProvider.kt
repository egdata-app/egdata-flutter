package com.ignacioaldama.egdata

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

class FreeGamesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.game_list)
        }
        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }

    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int, newOptions: Bundle) {
        updateWidget(context, appWidgetManager, widgetId)
        appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.game_list)
        super.onAppWidgetOptionsChanged(context, appWidgetManager, widgetId, newOptions)
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
        try {
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)

            Log.d("FreeGamesWidget", "Widget $widgetId size: ${minWidth}x${minHeight} dp")

            // Always use the large layout with ListView for all sizes
            val layout = R.layout.widget_large
            Log.d("FreeGamesWidget", "Using layout: large (ListView)")

            val views = RemoteViews(context.packageName, layout)

            // 1. Template for individual item clicks (ListView)
            val clickIntent = Intent(context, MainActivity::class.java).apply {
                action = "com.ignacioaldama.egdata.ACTION_OPEN_OFFER"
            }
            val clickPendingIntent = PendingIntent.getActivity(
                context, 0, clickIntent,
                PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            views.setPendingIntentTemplate(R.id.game_list, clickPendingIntent)

            // 2. Default click for the whole widget (fallback)
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 1, intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            views.setOnClickPendingIntent(R.id.header, pendingIntent)

            // Setup ListView for all widget sizes
            setupListView(context, views, widgetId)

            appWidgetManager.updateAppWidget(widgetId, views)
        } catch (e: Exception) {
            Log.e("FreeGamesWidget", "Error updating widget", e)
        }
    }

    private fun setupListView(context: Context, views: RemoteViews, widgetId: Int) {
        val serviceIntent = Intent(context, WidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
        }
        views.setRemoteAdapter(R.id.game_list, serviceIntent)
        views.setEmptyView(R.id.game_list, R.id.empty_text)
    }

    private fun updateStaticWidget(context: Context, views: RemoteViews, layout: Int) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val widgetDataJson = prefs.getString("widget_data", null)
        if (widgetDataJson.isNullOrEmpty()) return

        val games = parseWidgetData(widgetDataJson).games
        if (games.isEmpty()) return

        // Both small and medium widgets use game_count TextView
        val text = when {
            games.size == 1 -> games.first().title
            else -> "${games.size} Free Games"
        }
        views.setTextViewText(R.id.game_count, text)
    }

    private fun parseWidgetData(jsonString: String): WidgetDataContainer {
        val json = JSONObject(jsonString)
        val gamesArray = json.getJSONArray("games")
        val games = mutableListOf<GameData>()
        for (i in 0 until gamesArray.length()) {
            val gameJson = gamesArray.getJSONObject(i)
            games.add(GameData(
                id = gameJson.getString("id"),
                title = gameJson.getString("title"),
                thumbnailUrl = gameJson.optString("thumbnailUrl", null),
                endDate = gameJson.getString("endDate")
            ))
        }
        return WidgetDataContainer(games, json.getString("lastUpdate"))
    }

    data class WidgetDataContainer(val games: List<GameData>, val lastUpdate: String)
    data class GameData(val id: String, val title: String, val thumbnailUrl: String?, val endDate: String)
}
