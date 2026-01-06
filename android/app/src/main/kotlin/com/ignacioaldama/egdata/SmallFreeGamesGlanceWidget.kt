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
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
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
import com.bumptech.glide.Glide
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

/**
 * Small Jetpack Glance widget for displaying Epic Games free games.
 * Mimics a carousel look with a clean, minimal UI.
 */
class SmallFreeGamesGlanceWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val data = withContext(Dispatchers.IO) {
            val games = loadGamesFromPreferences(context)
            if (games.isNotEmpty()) {
                val game = games[0]
                val bitmap = loadGameThumbnail(context, game)
                Triple(game, bitmap, games.size)
            } else null
        }

        provideContent {
            GlanceTheme {
                SmallWidgetContent(context, data)
            }
        }
    }

    override suspend fun providePreview(context: Context, widgetCategory: Int) {
        val mockData = withContext(Dispatchers.IO) {
            val placeholderUrl = "https://cdn.egdata.app/placeholder-1080.webp"
            val placeholderBitmap = try {
                Glide.with(context.applicationContext)
                    .asBitmap()
                    .load(placeholderUrl)
                    .override(600, 400)
                    .centerCrop()
                    .submit()
                    .get()
            } catch (e: Exception) {
                val b = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
                b.eraseColor(android.graphics.Color.DKGRAY)
                b
            }
            Triple(
                GameData("1", "Epic Game Title", null, "2024-12-31T23:59:59"),
                placeholderBitmap,
                3
            )
        }

        provideContent {
            GlanceTheme {
                SmallWidgetContent(context, mockData)
            }
        }
    }

    companion object {
        suspend fun updateWidgetPreview(context: Context) {
            try {
                GlanceAppWidgetManager(context).setWidgetPreviews(SmallFreeGamesGlanceReceiver::class)
            } catch (e: Exception) {
                Log.e("SmallWidget", "Failed to update preview", e)
            }
        }
    }
}

@Composable
fun SmallWidgetContent(context: Context, data: Triple<GameData, Bitmap?, Int>?) {
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProvider(Color(0xFF0A0A0A)))
    ) {
        if (data == null) {
            EmptySmallState()
        } else {
            val (game, bitmap, totalCount) = data
            SmallGameCard(context, game, bitmap, totalCount)
        }
    }
}

@Composable
fun SmallGameCard(context: Context, game: GameData, bitmap: Bitmap?, totalCount: Int) {
    val clickIntent = Intent(context, MainActivity::class.java).apply {
        action = "com.ignacioaldama.egdata.ACTION_OPEN_OFFER"
        putExtra("offerId", game.id)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .clickable(actionStartActivity(clickIntent))
    ) {
        // 1. Background Image
        if (bitmap != null) {
            Image(
                provider = ImageProvider(bitmap),
                contentDescription = "Game cover",
                contentScale = ContentScale.Crop,
                modifier = GlanceModifier.fillMaxSize()
            )
        }

        // 2. Dark Overlay
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ColorProvider(Color(0x99000000)))
        ) {}

        // 3. Badges & Indicators (Top Row)
        Row(
            modifier = GlanceModifier.fillMaxWidth().padding(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // FREE badge (Top Left)
            Box(
                modifier = GlanceModifier
                    .background(ColorProvider(Color(0xFF00D4FF)))
                    .cornerRadius(4.dp)
                    .padding(horizontal = 6.dp, vertical = 2.dp)
            ) {
                Text(
                    text = "FREE",
                    style = TextStyle(
                        color = ColorProvider(Color.Black),
                        fontSize = 9.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }
            
            Spacer(modifier = GlanceModifier.defaultWeight())
            
            // Slide Indicator (Top Right)
            Box(
                modifier = GlanceModifier
                    .background(ColorProvider(Color(0x66000000)))
                    .cornerRadius(12.dp)
                    .padding(horizontal = 8.dp, vertical = 2.dp)
            ) {
                Text(
                    text = "1 / $totalCount",
                    style = TextStyle(
                        color = ColorProvider(Color.White),
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Medium
                    )
                )
            }
        }

        // 4. Game Info (Bottom)
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .padding(8.dp),
            contentAlignment = Alignment.BottomStart
        ) {
            Column {
                Text(
                    text = game.title,
                    style = TextStyle(
                        color = ColorProvider(Color.White),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold
                    ),
                    maxLines = 1
                )
                
                Text(
                    text = formatEndDate(game.endDate),
                    style = TextStyle(
                        color = ColorProvider(Color(0xCCFFFFFF)),
                        fontSize = 11.sp
                    )
                )
            }
        }
    }
}

@Composable
fun EmptySmallState() {
    Box(
        modifier = GlanceModifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "No games available",
            style = TextStyle(color = ColorProvider(Color.Gray), fontSize = 12.sp)
        )
    }
}

private fun loadGamesFromPreferences(context: Context): List<GameData> {
    return try {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val widgetDataJson = prefs.getString("widget_data", null) ?: return emptyList()
        val json = JSONObject(widgetDataJson)
        val gamesArray = json.getJSONArray("games")
        val games = mutableListOf<GameData>()
        for (i in 0 until gamesArray.length()) {
            val gameJson = gamesArray.getJSONObject(i)
            games.add(GameData(
                gameJson.getString("id"),
                gameJson.getString("title"),
                gameJson.optString("thumbnailUrl", null),
                gameJson.getString("endDate")
            ))
        }
        games
    } catch (e: Exception) {
        emptyList()
    }
}

private fun loadGameThumbnail(context: Context, game: GameData): Bitmap? {
    return try {
        if (game.thumbnailUrl.isNullOrEmpty()) return null
        Glide.with(context.applicationContext)
            .asBitmap()
            .load(game.thumbnailUrl)
            .override(600, 400)
            .centerCrop()
            .submit()
            .get()
    } catch (e: Exception) {
        null
    }
}

private fun formatEndDate(isoDate: String): String {
    return try {
        val parser = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
        val formatter = SimpleDateFormat("MMM dd", Locale.US)
        parser.parse(isoDate)?.let { "Ends ${formatter.format(it)}" } ?: "Ends soon"
    } catch (e: Exception) {
        "Ends soon"
    }
}
