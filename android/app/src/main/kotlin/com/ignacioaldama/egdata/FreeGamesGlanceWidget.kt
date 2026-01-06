package com.ignacioaldama.egdata

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color // Compose Color for UI
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
import com.bumptech.glide.Glide
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * Jetpack Glance widget for displaying Epic Games free games.
 * Includes custom bitmap processing to blur/gradient the bottom of game covers.
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
     */
    override suspend fun providePreview(context: Context, widgetCategory: Int) {
        // 1. Load Dummy Data for the Preview
        val mockGames = withContext(Dispatchers.IO) {
            val placeholderUrl = "https://cdn.egdata.app/placeholder-1080.webp"

            // Helper to get dummy bitmap with our blur effect applied
            val getDummyBitmap = {
                try {
                    val original = Glide.with(context.applicationContext)
                        .asBitmap()
                        .load(placeholderUrl)
                        .override(1000, 563)
                        .centerCrop()
                        .submit()
                        .get()

                    // Apply the blur effect to preview too!
                    applyBottomBlurAndGradient(original)
                } catch (e: Exception) {
                    // Fallback to solid color if download fails
                    val b = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
                    b.eraseColor(android.graphics.Color.DKGRAY)
                    b
                }
            }

            val bmp = getDummyBitmap()

            listOf(
                GameData("1", "Epic Game Title", null, "2024-12-31T23:59:59") to bmp,
                GameData("2", "Another Free Game", null, "2024-12-31T23:59:59") to bmp
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
        suspend fun updateWidgetPreview(context: Context) {
            try {
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

        val originalBitmap = Glide.with(context.applicationContext)
            .asBitmap()
            .load(game.thumbnailUrl)
            .override(1000, 563)
            .centerCrop()
            .submit()
            .get()

        applyBottomBlurAndGradient(originalBitmap)

    } catch (e: Exception) {
        Log.e("FreeGamesGlanceWidget", "Error loading thumbnail for ${game.title}", e)
        null
    }
}

private fun applyBottomBlurAndGradient(original: Bitmap): Bitmap {
    val width = original.width
    val height = original.height

    // 1. Config: How much of the bottom to blur
    val splitY = (height * 0.565).toInt() // Start blur at 60% down
    val sectionHeight = height - splitY

    // 2. Optimization: Scale down slightly
    val scaleFactor = 0.2f
    val smallWidth = (width * scaleFactor).toInt()
    val smallHeight = (sectionHeight * scaleFactor).toInt()

    val bottomSection = Bitmap.createBitmap(original, 0, splitY, width, sectionHeight)
    val scaledSection = Bitmap.createScaledBitmap(bottomSection, smallWidth, smallHeight, true)

    // 3. APPLY REAL BLUR
    val blurredSection = fastBlur(scaledSection, 12) ?: scaledSection

    // 4. Scale back up
    val finalBlur = Bitmap.createScaledBitmap(blurredSection, width, sectionHeight, true)

    // 5. Draw it back onto the original
    // Use Safe Config
    val safeConfig = original.config ?: Bitmap.Config.ARGB_8888
    val result = original.copy(safeConfig, true)

    val canvas = Canvas(result)
    val paint = Paint().apply { isAntiAlias = true }

    canvas.drawBitmap(finalBlur, 0f, splitY.toFloat(), paint)

    // 6. Add Gradient (Using android.graphics.Color explicitly)
    val gradientPaint = Paint()
    gradientPaint.shader = LinearGradient(
        0f, splitY.toFloat(),
        0f, height.toFloat(),
        intArrayOf(android.graphics.Color.TRANSPARENT, android.graphics.Color.BLACK),
        null,
        Shader.TileMode.CLAMP
    )
    canvas.drawRect(0f, splitY.toFloat(), width.toFloat(), height.toFloat(), gradientPaint)

    // Cleanup
    if (bottomSection != original) bottomSection.recycle()
    scaledSection.recycle()
    if (blurredSection != scaledSection) blurredSection.recycle()
    finalBlur.recycle()

    return result
}

/**
 * Stack Blur v1.0 (Fixed for Kotlin Variables)
 */
private fun fastBlur(sentBitmap: Bitmap, radius: Int): Bitmap? {
    val config = sentBitmap.config ?: Bitmap.Config.ARGB_8888
    val bitmap = sentBitmap.copy(config, true) ?: return null

    if (radius < 1) return null

    val w = bitmap.width
    val h = bitmap.height

    val pix = IntArray(w * h)
    bitmap.getPixels(pix, 0, w, 0, 0, w, h)

    val wm = w - 1
    val hm = h - 1
    val wh = w * h
    val div = radius + radius + 1

    val r = IntArray(wh)
    val g = IntArray(wh)
    val b = IntArray(wh)
    var rsum: Int
    var gsum: Int
    var bsum: Int
    var x: Int
    var y: Int
    var i: Int
    var p: Int
    var yp: Int
    var yi: Int
    val vmin = IntArray(max(w, h))

    var divsum = (div + 1) shr 1
    divsum *= divsum
    val dv = IntArray(256 * divsum)
    for (i in 0 until 256 * divsum) {
        dv[i] = (i / divsum)
    }

    var yw0 = 0
    var yi0 = 0

    val stack = Array(div) { IntArray(3) }
    var stackpointer: Int
    var stackstart: Int
    var sir: IntArray
    var rbs: Int
    val r1 = radius + 1
    var routsum: Int
    var goutsum: Int
    var boutsum: Int
    var rinsum: Int
    var ginsum: Int
    var binsum: Int

    for (y in 0 until h) {
        rinsum = 0
        ginsum = 0
        boutsum = 0
        goutsum = 0
        routsum = 0
        binsum = 0
        rsum = 0
        gsum = 0
        bsum = 0
        for (i in -radius..radius) {
            p = pix[yi0 + min(wm, max(i, 0))]
            sir = stack[i + radius]
            sir[0] = (p and 0xff0000) shr 16
            sir[1] = (p and 0x00ff00) shr 8
            sir[2] = (p and 0x0000ff)
            rbs = r1 - abs(i)
            rsum += sir[0] * rbs
            gsum += sir[1] * rbs
            bsum += sir[2] * rbs
            if (i > 0) {
                rinsum += sir[0]
                ginsum += sir[1]
                binsum += sir[2]
            } else {
                routsum += sir[0]
                goutsum += sir[1]
                boutsum += sir[2]
            }
        }
        stackpointer = radius

        for (x in 0 until w) {
            r[yi0] = dv[rsum]
            g[yi0] = dv[gsum]
            b[yi0] = dv[bsum]

            rsum -= routsum
            gsum -= goutsum
            bsum -= boutsum

            stackstart = stackpointer - radius + div
            sir = stack[stackstart % div]

            routsum -= sir[0]
            goutsum -= sir[1]
            boutsum -= sir[2]

            if (y == 0) {
                vmin[x] = min(x + radius + 1, wm)
            }
            p = pix[yw0 + vmin[x]]

            sir[0] = (p and 0xff0000) shr 16
            sir[1] = (p and 0x00ff00) shr 8
            sir[2] = (p and 0x0000ff)

            rinsum += sir[0]
            ginsum += sir[1]
            binsum += sir[2]

            rsum += rinsum
            gsum += ginsum
            bsum += binsum

            stackpointer = (stackpointer + 1) % div
            sir = stack[stackpointer % div]

            routsum += sir[0]
            goutsum += sir[1]
            boutsum += sir[2]

            rinsum -= sir[0]
            ginsum -= sir[1]
            binsum -= sir[2]

            yi0++
        }
        yw0 += w
    }
    for (x in 0 until w) {
        rinsum = 0
        ginsum = 0
        boutsum = 0
        goutsum = 0
        routsum = 0
        binsum = 0
        rsum = 0
        gsum = 0
        bsum = 0
        yp = -radius * w
        for (i in -radius..radius) {
            yi = max(0, yp) + x

            sir = stack[i + radius]

            sir[0] = r[yi]
            sir[1] = g[yi]
            sir[2] = b[yi]

            rbs = r1 - abs(i)

            rsum += r[yi] * rbs
            gsum += g[yi] * rbs
            bsum += b[yi] * rbs

            if (i > 0) {
                rinsum += sir[0]
                ginsum += sir[1]
                binsum += sir[2]
            } else {
                routsum += sir[0]
                goutsum += sir[1]
                boutsum += sir[2]
            }

            if (i < hm) {
                yp += w
            }
        }
        yi = x
        stackpointer = radius
        for (y in 0 until h) {
            // Preserve Alpha channel (0xff000000)
            pix[yi] = (0xff000000.toInt() and pix[yi]) or (dv[rsum] shl 16) or (dv[gsum] shl 8) or dv[bsum]

            rsum -= routsum
            gsum -= goutsum
            bsum -= boutsum

            stackstart = stackpointer - radius + div
            sir = stack[stackstart % div]

            routsum -= sir[0]
            goutsum -= sir[1]
            boutsum -= sir[2]

            if (x == 0) {
                vmin[y] = min(y + r1, hm) * w
            }
            p = x + vmin[y]

            sir[0] = r[p]
            sir[1] = g[p]
            sir[2] = b[p]

            rinsum += sir[0]
            ginsum += sir[1]
            binsum += sir[2]

            rsum += rinsum
            gsum += ginsum
            bsum += binsum

            stackpointer = (stackpointer + 1) % div
            sir = stack[stackpointer]

            routsum += sir[0]
            goutsum += sir[1]
            boutsum += sir[2]

            rinsum -= sir[0]
            ginsum -= sir[1]
            binsum -= sir[2]

            yi += w
        }
    }

    bitmap.setPixels(pix, 0, w, 0, 0, w, h)
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