package com.ignacioaldama.egdata

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.bumptech.glide.Glide
import com.bumptech.glide.load.resource.bitmap.RoundedCorners
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class WidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return WidgetFactory(this.applicationContext)
    }
}

class WidgetFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private var games = listOf<GameData>()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val widgetDataJson = prefs.getString("widget_data", null)
        if (!widgetDataJson.isNullOrEmpty()) {
            games = parseWidgetData(widgetDataJson).games
        }
    }

    override fun onDestroy() {}
    override fun getCount(): Int = games.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_game_row)
        val game = games[position]

        views.setTextViewText(R.id.game_title, game.title)
        
        val formattedDate = formatEndDate(game.endDate)
        views.setTextViewText(R.id.game_date, formattedDate)

        // Set Fill-in Intent for item clicks
        val fillInIntent = Intent().apply {
            val extras = Bundle().apply {
                putString("offerId", game.id)
            }
            putExtras(extras)
        }
        views.setOnClickFillInIntent(R.id.row_container, fillInIntent)

        if (!game.thumbnailUrl.isNullOrEmpty()) {
            try {
                val radius = (8 * context.resources.displayMetrics.density).toInt()
                val bitmap = Glide.with(context.applicationContext)
                    .asBitmap()
                    .load(game.thumbnailUrl)
                    .override(150, 200)
                    .centerCrop()
                    .transform(RoundedCorners(radius))
                    .diskCacheStrategy(com.bumptech.glide.load.engine.DiskCacheStrategy.RESOURCE)
                    .signature(com.bumptech.glide.signature.ObjectKey("rounded_$radius"))
                    .submit()
                    .get()
                views.setImageViewBitmap(R.id.game_thumbnail, bitmap)
            } catch (e: Exception) {
                Log.e("WidgetFactory", "Error loading thumbnail", e)
            }
        }
        return views
    }

    private fun formatEndDate(isoDate: String): String {
        return try {
            val parser = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
            val formatter = SimpleDateFormat("MMM dd", Locale.US)
            val date = parser.parse(isoDate)
            "Ends ${formatter.format(date)}"
        } catch (e: Exception) {
            "Ends soon"
        }
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true

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
