package com.ignacioaldama.egdata

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.glance.appwidget.GlanceAppWidgetManager
import com.bumptech.glide.Glide
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

/**
 * Jetpack Glance widget for displaying Epic Games free games
 */
class FreeGamesGlanceWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        // 1. LOAD DATA & IMAGES IN BACKGROUND
        val games = withContext(Dispatchers.IO) {
            val rawGames = loadGamesFromPreferences(context)
            rawGames.map { game ->
                val bitmap = loadGameThumbnail(context, game)
                game to bitmap
            }
        }

        // 2. RENDER UI
        provideContent {
            GlanceTheme {
                FreeGamesContent(context, games)
            }
        }
    }

    /**
     * GENERATED PREVIEW (Android 15+)
     * This provides the live UI for the Widget Picker.
     * Note: This requires Glance 1.2.0 or higher.
     */
    override suspend fun providePreview(context: Context, widgetCategory: Int) {
        // 1. Load Dummy Data for the Preview
        val mockGames = withContext(Dispatchers.IO) {
            val placeholderUrl = "https://cdn.egdata.app/placeholder-1080.webp"
            val placeholderBitmap = try {
                Glide.with(context.applicationContext)
                    .asBitmap()
                    .load(placeholderUrl)
                    .override(1000, 563)
                    .centerCrop()
                    .submit()
                    .get()
            } catch (e: Exception) {
                // Fallback to solid color if download fails
                val b = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
                b.eraseColor(android.graphics.Color.DKGRAY)
                b
            }

            listOf(
                GameData("1", "Epic Game Title", null, "2024-12-31T23:59:59") to placeholderBitmap,
                GameData("2", "Another Free Game", null, "2024-12-31T23:59:59") to placeholderBitmap
            )
        }

        // 2. Render the Preview Content
        provideContent {
            GlanceTheme {
                FreeGamesContent(context, mockGames)
            }
        }
    }

    companion object {
        /**
         * Updates the widget preview shown in the Android 15+ widget picker.
         * This tells the system to run providePreview() and cache the result.
         */
        suspend fun updateWidgetPreview(context: Context) {
            try {
                // We reference the receiver that hosts this widget
                GlanceAppWidgetManager(context).setWidgetPreviews(FreeGamesGlanceReceiver::class)
            } catch (e: Exception) {
                Log.e("FreeGamesGlanceWidget", "Failed to update widget preview", e)
            }
        }
    }
}

@Composable
fun FreeGamesContent(context: Context, games: List<Pair<GameData, Bitmap?>>) {
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProvider(Color(0xFF0A0A0A)))
    ) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .padding(10.dp)
        ) {
            WidgetHeader(context)
            Spacer(modifier = GlanceModifier.height(12.dp))

            if (games.isEmpty()) {
                EmptyState()
            } else {
                LazyColumn(
                    modifier = GlanceModifier.fillMaxSize()
                ) {
                    items(games) { itemPair ->
                        val game = itemPair.first
                        val bitmap = itemPair.second

                        Box(
                            modifier = GlanceModifier
                                .fillMaxWidth()
                                .padding(bottom = 12.dp)
                        ) {
                            GameCard(context, game, bitmap)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun WidgetHeader(context: Context) {
    val headerIntent = Intent(context, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }

    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .clickable(actionStartActivity(headerIntent)),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Image(
            provider = ImageProvider(R.mipmap.ic_launcher),
            contentDescription = "App icon",
            modifier = GlanceModifier.size(24.dp)
        )

        Spacer(modifier = GlanceModifier.width(10.dp))

        Column {
            Text(
                text = "egdata.app",
                style = TextStyle(
                    color = ColorProvider(Color(0xFF00D4FF)),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold
                )
            )
            Text(
                text = "Free This Week",
                style = TextStyle(
                    color = ColorProvider(Color.White),
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold
                )
            )
        }
    }
}

@Composable
fun GameCard(context: Context, game: GameData, bitmap: Bitmap?) {
    val clickIntent = Intent(context, MainActivity::class.java).apply {
        action = "com.ignacioaldama.egdata.ACTION_OPEN_OFFER"
        putExtra("offerId", game.id)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }

    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .height(150.dp)
            .background(ColorProvider(Color(0xFF1A1A1A)))
            .cornerRadius(12.dp)
            .clickable(actionStartActivity(clickIntent)),
        contentAlignment = Alignment.BottomStart
    ) {
        if (bitmap != null) {
            Image(
                provider = ImageProvider(bitmap),
                contentDescription = "Game cover",
                contentScale = ContentScale.Crop,
                modifier = GlanceModifier.fillMaxSize()
            )
        }

        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ColorProvider(Color(0x99000000)))
        ) {}

        Column(
            modifier = GlanceModifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.Bottom
        ) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.Bottom
            ) {
                Column(
                    modifier = GlanceModifier.defaultWeight()
                ) {
                    Text(
                        text = game.title,
                        style = TextStyle(
                            color = ColorProvider(Color.White),
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold
                        ),
                        maxLines = 2
                    )
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    Text(
                        text = formatEndDate(game.endDate),
                        style = TextStyle(
                            color = ColorProvider(Color(0xDDFFFFFF)),
                            fontSize = 12.sp
                        )
                    )
                }

                Spacer(modifier = GlanceModifier.width(8.dp))

                Box(
                    modifier = GlanceModifier
                        .background(ColorProvider(Color(0xFF00D4FF)))
                        .cornerRadius(4.dp)
                        .padding(horizontal = 8.dp, vertical = 4.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "FREE",
                        style = TextStyle(
                            color = ColorProvider(Color.Black),
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )
                }
            }
        }
    }
}

@Composable
fun EmptyState() {
    Box(
        modifier = GlanceModifier.fillMaxSize().padding(20.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "No free games right now.\nCheck back later!",
            style = TextStyle(
                color = ColorProvider(Color(0xFF888888)),
                fontSize = 14.sp,
                textAlign = androidx.glance.text.TextAlign.Center
            )
        )
    }
}

private fun loadGamesFromPreferences(context: Context): List<GameData> {
    return try {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val widgetDataJson = prefs.getString("widget_data", null)
        if (!widgetDataJson.isNullOrEmpty()) {
            parseWidgetData(widgetDataJson).games
        } else {
            emptyList()
        }
    } catch (e: Exception) {
        Log.e("FreeGamesGlanceWidget", "Error loading games", e)
        emptyList()
    }
}

private fun loadGameThumbnail(context: Context, game: GameData): Bitmap? {
    return try {
        if (game.thumbnailUrl.isNullOrEmpty()) return null

        Glide.with(context.applicationContext)
            .asBitmap()
            .load(game.thumbnailUrl)
            .override(1000, 563)
            .centerCrop()
            .submit()
            .get()
    } catch (e: Exception) {
        Log.e("FreeGamesGlanceWidget", "Error loading thumbnail for ${game.title}", e)
        null
    }
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
data class GameData(val id: String, val title: String, val thumbnailUrl: String?, val endDate: String)
