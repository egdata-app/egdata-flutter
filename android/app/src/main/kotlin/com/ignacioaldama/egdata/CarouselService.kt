package com.ignacioaldama.egdata

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.bumptech.glide.Glide
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class CarouselService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return CarouselFactory(this.applicationContext)
    }
}

class CarouselFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private var games = listOf<GameData>()
    private val imageCache = mutableMapOf<String, Bitmap>()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val widgetDataJson = prefs.getString("widget_data", null)
        if (!widgetDataJson.isNullOrEmpty()) {
            games = parseWidgetData(widgetDataJson).games
        }
    }

    override fun onDestroy() {
        imageCache.values.forEach { it.recycle() }
        imageCache.clear()
    }

    override fun getCount(): Int = games.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_carousel_card)
        
        // Reset image state
        views.setImageViewResource(R.id.carousel_background, android.R.color.transparent)
        
        if (position < 0 || position >= games.size) return views

        val game = games[position]

        // Load and set background
        val backgroundImage = getBackgroundImage(game)
        if (backgroundImage != null) {
            views.setImageViewBitmap(R.id.carousel_background, backgroundImage)
        }

        // Set position indicator
        val indicator = "${position + 1}/${games.size}"
        views.setTextViewText(R.id.carousel_indicator, indicator)

        // Set game title and end date
        views.setTextViewText(R.id.carousel_title, game.title)
        val formattedDate = formatEndDate(game.endDate)
        views.setTextViewText(R.id.carousel_date, formattedDate)

        // Set Fill-in Intent for card clicks
        val fillInIntent = Intent().apply {
            putExtra("offerId", game.id)
        }
        views.setOnClickFillInIntent(R.id.carousel_click_overlay, fillInIntent)

        return views
    }

    private fun getBackgroundImage(game: GameData): Bitmap? {
        val cacheKey = game.id
        imageCache[cacheKey]?.let { return it }

        val image = try {
            if (game.thumbnailUrl.isNullOrEmpty()) {
                return createFallbackBackground()
            }

            Glide.with(context.applicationContext)
                .asBitmap()
                .load(game.thumbnailUrl)
                .override(600, 400)
                .centerCrop()
                .diskCacheStrategy(com.bumptech.glide.load.engine.DiskCacheStrategy.RESOURCE)
                .signature(com.bumptech.glide.signature.ObjectKey(game.id + "_v1"))
                .submit()
                .get()
        } catch (e: Exception) {
            Log.e("CarouselFactory", "Error loading image: ${e.message}")
            return createFallbackBackground()
        }

        if (image != null) {
            imageCache[cacheKey] = image
        }

        return image
    }

    private fun createFallbackBackground(): Bitmap {
        val bitmap = Bitmap.createBitmap(400, 300, Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(bitmap)
        val paint = android.graphics.Paint().apply {
            shader = android.graphics.LinearGradient(
                0f, 0f, 400f, 300f,
                intArrayOf(Color.parseColor("#1A1A1A"), Color.parseColor("#0A0A0A")),
                floatArrayOf(0f, 1f),
                android.graphics.Shader.TileMode.CLAMP
            )
        }
        canvas.drawRect(0f, 0f, 400f, 300f, paint)
        return bitmap
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
    
    override fun getItemId(position: Int): Long {
        return if (position in games.indices) {
            games[position].id.hashCode().toLong()
        } else {
            position.toLong()
        }
    }
    
    override fun hasStableIds(): Boolean = true

    private fun parseWidgetData(jsonString: String): WidgetDataContainer {
        val json = JSONObject(jsonString)
        val gamesArray = json.getJSONArray("games")
        val games = mutableListOf<GameData>()
        for (i in 0 until gamesArray.length()) {
            val gameJson = gamesArray.getJSONObject(i)
            games.add(
                GameData(
                    id = gameJson.getString("id"),
                    title = gameJson.getString("title"),
                    thumbnailUrl = gameJson.optString("thumbnailUrl", null),
                    endDate = gameJson.getString("endDate")
                )
            )
        }
        return WidgetDataContainer(games, json.getString("lastUpdate"))
    }

    data class WidgetDataContainer(val games: List<GameData>, val lastUpdate: String)
    data class GameData(
        val id: String,
        val title: String,
        val thumbnailUrl: String?,
        val endDate: String
    )
}
