package com.ignacioaldama.egdata.wear

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.content.ComponentName
import android.content.Intent
import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.DimensionBuilders.sp
import androidx.wear.protolayout.DimensionBuilders.expand
import androidx.wear.protolayout.DimensionBuilders.wrap
import androidx.wear.protolayout.LayoutElementBuilders.*
import androidx.wear.protolayout.ModifiersBuilders.*
import androidx.wear.protolayout.ResourceBuilders.*
import androidx.wear.protolayout.TimelineBuilders.*
import androidx.wear.tiles.RequestBuilders.*
import androidx.wear.tiles.TileBuilders.*
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.guava.future
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONArray
import java.io.ByteArrayOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

class FreeGamesTileService : TileService() {

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build()

    // Cache for game images
    private var cachedGames: List<FreeGame> = emptyList()
    private val gameImages = mutableMapOf<String, ByteArray>()
    private var resourcesVersion = "2"

    companion object {
        private const val API_URL = "https://api.egdata.app/free-games"
        private const val RES_GRADIENT_BG = "gradient_bg"
        private const val IMAGE_WIDTH = 40
        private const val IMAGE_HEIGHT = 53 // 3:4 aspect ratio

        // Phone app package and actions
        private const val PHONE_APP_PACKAGE = "com.ignacioaldama.egdata"
        private const val ACTION_OPEN_FREE_GAMES = "com.ignacioaldama.egdata.ACTION_OPEN_FREE_GAMES"
        private const val ACTION_OPEN_OFFER = "com.ignacioaldama.egdata.ACTION_OPEN_OFFER"

        // Colors - matching app's Unreal Engine inspired theme
        private const val COLOR_BACKGROUND = 0xFF0A0A0A.toInt()
        private const val COLOR_SURFACE = 0xFF1A1A1A.toInt()
        private const val COLOR_PRIMARY = 0xFF00D4FF.toInt()
        private const val COLOR_TEXT_PRIMARY = 0xFFFFFFFF.toInt()
        private const val COLOR_TEXT_SECONDARY = 0xFF9CA3AF.toInt()
        private const val COLOR_SUCCESS = 0xFF10B981.toInt()
        private const val COLOR_CARD_BG = 0xFF141414.toInt()
        private const val COLOR_BORDER = 0xFF2A2A2A.toInt()
    }

    override fun onTileRequest(requestParams: TileRequest): ListenableFuture<Tile> {
        return serviceScope.future {
            val freeGames = fetchFreeGames()

            // Download images for each game
            gameImages.clear()
            freeGames.forEach { game ->
                game.imageUrl?.let { url ->
                    downloadImage(url)?.let { imageData ->
                        gameImages[game.id] = imageData
                    }
                }
            }

            // Update cache and version
            cachedGames = freeGames
            resourcesVersion = "v${System.currentTimeMillis()}"

            buildTile(freeGames)
        }
    }

    override fun onTileResourcesRequest(requestParams: ResourcesRequest): ListenableFuture<Resources> {
        return serviceScope.future {
            val builder = Resources.Builder()
                .setVersion(resourcesVersion)
                .addIdToImageMapping(
                    RES_GRADIENT_BG,
                    ImageResource.Builder()
                        .setAndroidResourceByResId(
                            AndroidImageResourceByResId.Builder()
                                .setResourceId(R.drawable.gradient_background)
                                .build()
                        )
                        .build()
                )

            // Add game images
            gameImages.forEach { (gameId, imageData) ->
                builder.addIdToImageMapping(
                    "game_$gameId",
                    ImageResource.Builder()
                        .setInlineResource(
                            InlineImageResource.Builder()
                                .setData(imageData)
                                .setWidthPx(IMAGE_WIDTH * 2)  // Higher res for quality
                                .setHeightPx(IMAGE_HEIGHT * 2)
                                .build()
                        )
                        .build()
                )
            }

            builder.build()
        }
    }

    private fun downloadImage(url: String): ByteArray? {
        return try {
            val request = Request.Builder().url(url).build()
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) return null

                val bytes = response.body?.bytes() ?: return null
                val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null

                // Scale and compress as JPEG for RGB_565 compatibility
                val scaled = Bitmap.createScaledBitmap(bitmap, IMAGE_WIDTH * 2, IMAGE_HEIGHT * 2, true)
                val stream = ByteArrayOutputStream()
                scaled.compress(Bitmap.CompressFormat.JPEG, 85, stream)

                bitmap.recycle()
                scaled.recycle()

                stream.toByteArray()
            }
        } catch (e: Exception) {
            null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
    }

    private fun fetchFreeGames(): List<FreeGame> {
        return try {
            val request = Request.Builder()
                .url(API_URL)
                .build()

            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) return emptyList()

                val json = response.body?.string() ?: return emptyList()
                parseFreeGames(json)
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun parseFreeGames(json: String): List<FreeGame> {
        val currentGames = mutableListOf<FreeGame>()
        val upcomingGames = mutableListOf<FreeGame>()
        val now = System.currentTimeMillis()

        try {
            val jsonArray = JSONArray(json)
            for (i in 0 until jsonArray.length()) {
                val gameObj = jsonArray.getJSONObject(i)

                // Dates are nested inside the "giveaway" object
                val giveaway = gameObj.optJSONObject("giveaway") ?: continue
                val startDateStr = giveaway.optString("startDate", "")
                val endDateStr = giveaway.optString("endDate", "")

                // Parse dates
                val startMillis = parseDate(startDateStr)
                val endMillis = parseDate(endDateStr)

                if (startMillis == null || endMillis == null) continue

                val id = gameObj.optString("id", "")
                val title = gameObj.optString("title", "Unknown Game")
                val imageUrl = getVerticalImageUrl(gameObj)

                // Currently active free games
                if (now >= startMillis && now < endMillis) {
                    currentGames.add(FreeGame(
                        id = id,
                        title = title,
                        startDate = startMillis,
                        endDate = endMillis,
                        imageUrl = imageUrl,
                        isUpcoming = false
                    ))
                }
                // Upcoming free games (starting within next 14 days)
                else if (now < startMillis && startMillis - now < 14 * 24 * 60 * 60 * 1000L) {
                    upcomingGames.add(FreeGame(
                        id = id,
                        title = title,
                        startDate = startMillis,
                        endDate = endMillis,
                        imageUrl = imageUrl,
                        isUpcoming = true
                    ))
                }
            }
        } catch (e: Exception) {
            // Return empty list on parse error
        }

        // Return current games first (max 3), then upcoming (max 2) to fit on screen
        return currentGames.take(3) + upcomingGames.take(2)
    }

    private fun getVerticalImageUrl(gameObj: org.json.JSONObject): String? {
        val keyImages = gameObj.optJSONArray("keyImages") ?: return null

        // Prefer OfferImageTall, then Thumbnail
        var tallImage: String? = null
        var thumbnail: String? = null

        for (i in 0 until keyImages.length()) {
            val img = keyImages.optJSONObject(i) ?: continue
            val type = img.optString("type", "")
            val url = img.optString("url", "")

            when (type) {
                "OfferImageTall" -> tallImage = url
                "Thumbnail" -> thumbnail = url
            }
        }

        return tallImage ?: thumbnail
    }

    private fun parseDate(dateStr: String): Long? {
        if (dateStr.isEmpty()) return null
        return try {
            val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
            format.parse(dateStr)?.time
        } catch (e: Exception) {
            null
        }
    }

    private fun buildTile(games: List<FreeGame>): Tile {
        val layout = if (games.isEmpty()) {
            buildEmptyLayout()
        } else {
            buildGamesLayout(games)
        }

        val timeline = Timeline.Builder()
            .addTimelineEntry(
                TimelineEntry.Builder()
                    .setLayout(Layout.Builder().setRoot(layout).build())
                    .build()
            )
            .build()

        return Tile.Builder()
            .setResourcesVersion(resourcesVersion)
            .setFreshnessIntervalMillis(TimeUnit.MINUTES.toMillis(30))
            .setTileTimeline(timeline)
            .build()
    }

    private fun buildEmptyLayout(): LayoutElement {
        return Box.Builder()
            .setWidth(expand())
            .setHeight(expand())
            .setModifiers(
                Modifiers.Builder()
                    .setBackground(
                        Background.Builder()
                            .setColor(argb(COLOR_BACKGROUND))
                            .build()
                    )
                    .build()
            )
            // Gradient overlay
            .addContent(
                Image.Builder()
                    .setResourceId(RES_GRADIENT_BG)
                    .setWidth(expand())
                    .setHeight(expand())
                    .build()
            )
            .addContent(
                Column.Builder()
                    .setWidth(wrap())
                    .setHeight(wrap())
                    .setHorizontalAlignment(HORIZONTAL_ALIGN_CENTER)
                    .addContent(
                        Text.Builder()
                            .setText("No Free Games")
                            .setFontStyle(
                                FontStyle.Builder()
                                    .setSize(sp(16f))
                                    .setColor(argb(COLOR_TEXT_PRIMARY))
                                    .setWeight(FONT_WEIGHT_MEDIUM)
                                    .build()
                            )
                            .build()
                    )
                    .addContent(Spacer.Builder().setHeight(dp(6f)).build())
                    .addContent(
                        Text.Builder()
                            .setText("Check back later")
                            .setFontStyle(
                                FontStyle.Builder()
                                    .setSize(sp(12f))
                                    .setColor(argb(COLOR_TEXT_SECONDARY))
                                    .build()
                            )
                            .build()
                    )
                    .build()
            )
            .build()
    }

    private fun buildGamesLayout(games: List<FreeGame>): LayoutElement {
        val columnBuilder = Column.Builder()
            .setWidth(expand())
            .setHeight(wrap())
            .setHorizontalAlignment(HORIZONTAL_ALIGN_CENTER)

        // Header with accent styling - tappable to open free games page
        columnBuilder.addContent(
            Box.Builder()
                .setWidth(wrap())
                .setHeight(wrap())
                .setModifiers(
                    Modifiers.Builder()
                        .setClickable(createOpenFreeGamesAction())
                        .setPadding(
                            Padding.Builder()
                                .setStart(dp(12f))
                                .setEnd(dp(12f))
                                .setTop(dp(4f))
                                .setBottom(dp(4f))
                                .build()
                        )
                        .setBackground(
                            Background.Builder()
                                .setColor(argb(0x3300D4FF)) // Semi-transparent cyan
                                .setCorner(Corner.Builder().setRadius(dp(12f)).build())
                                .build()
                        )
                        .build()
                )
                .addContent(
                    Text.Builder()
                        .setText("FREE NOW")
                        .setFontStyle(
                            FontStyle.Builder()
                                .setSize(sp(10f))
                                .setColor(argb(COLOR_PRIMARY))
                                .setWeight(FONT_WEIGHT_BOLD)
                                .build()
                        )
                        .build()
                )
                .build()
        )

        columnBuilder.addContent(Spacer.Builder().setHeight(dp(10f)).build())

        // Split into current and upcoming games
        val currentGames = games.filter { !it.isUpcoming }
        val upcomingGames = games.filter { it.isUpcoming }

        // Current games list with dynamic sizing
        currentGames.forEachIndexed { index, game ->
            val cardWidth = getCardWidth(index, currentGames.size)
            columnBuilder.addContent(buildGameCard(game, cardWidth))
            if (index < currentGames.size - 1) {
                columnBuilder.addContent(Spacer.Builder().setHeight(dp(4f)).build())
            }
        }

        // Add upcoming section if there are upcoming games
        if (upcomingGames.isNotEmpty()) {
            columnBuilder.addContent(Spacer.Builder().setHeight(dp(8f)).build())

            // "COMING SOON" header
            columnBuilder.addContent(
                Text.Builder()
                    .setText("COMING SOON")
                    .setFontStyle(
                        FontStyle.Builder()
                            .setSize(sp(8f))
                            .setColor(argb(COLOR_TEXT_SECONDARY))
                            .setWeight(FONT_WEIGHT_BOLD)
                            .build()
                    )
                    .build()
            )

            columnBuilder.addContent(Spacer.Builder().setHeight(dp(4f)).build())

            // Upcoming games
            upcomingGames.forEachIndexed { index, game ->
                val cardWidth = getCardWidth(index, upcomingGames.size, isBottom = true)
                columnBuilder.addContent(buildGameCard(game, cardWidth))
                if (index < upcomingGames.size - 1) {
                    columnBuilder.addContent(Spacer.Builder().setHeight(dp(4f)).build())
                }
            }
        }

        return Box.Builder()
            .setWidth(expand())
            .setHeight(expand())
            .setModifiers(
                Modifiers.Builder()
                    .setBackground(
                        Background.Builder()
                            .setColor(argb(COLOR_BACKGROUND))
                            .build()
                    )
                    .build()
            )
            // Gradient overlay
            .addContent(
                Image.Builder()
                    .setResourceId(RES_GRADIENT_BG)
                    .setWidth(expand())
                    .setHeight(expand())
                    .build()
            )
            // Content
            .addContent(
                Box.Builder()
                    .setWidth(expand())
                    .setHeight(expand())
                    .setModifiers(
                        Modifiers.Builder()
                            .setPadding(
                                Padding.Builder()
                                    .setAll(dp(12f))
                                    .build()
                            )
                            .build()
                    )
                    .addContent(columnBuilder.build())
                    .build()
            )
            .build()
    }

    private fun getCardWidth(index: Int, totalCards: Int, isBottom: Boolean = false): Float {
        // Use consistent smaller width for scrollable content
        return if (isBottom) 115f else 130f
    }

    private fun createOpenFreeGamesAction(): Clickable {
        return Clickable.Builder()
            .setOnClick(
                ActionBuilders.LaunchAction.Builder()
                    .setAndroidActivity(
                        ActionBuilders.AndroidActivity.Builder()
                            .setPackageName(PHONE_APP_PACKAGE)
                            .setClassName("$PHONE_APP_PACKAGE.MainActivity")
                            .addKeyToExtraMapping(
                                "action",
                                ActionBuilders.AndroidStringExtra.Builder()
                                    .setValue("free_games")
                                    .build()
                            )
                            .build()
                    )
                    .build()
            )
            .build()
    }

    private fun createOpenOfferAction(offerId: String): Clickable {
        return Clickable.Builder()
            .setOnClick(
                ActionBuilders.LaunchAction.Builder()
                    .setAndroidActivity(
                        ActionBuilders.AndroidActivity.Builder()
                            .setPackageName(PHONE_APP_PACKAGE)
                            .setClassName("$PHONE_APP_PACKAGE.MainActivity")
                            .addKeyToExtraMapping(
                                "action",
                                ActionBuilders.AndroidStringExtra.Builder()
                                    .setValue("open_offer")
                                    .build()
                            )
                            .addKeyToExtraMapping(
                                "offerId",
                                ActionBuilders.AndroidStringExtra.Builder()
                                    .setValue(offerId)
                                    .build()
                            )
                            .build()
                    )
                    .build()
            )
            .build()
    }

    private fun buildGameCard(game: FreeGame, width: Float = 140f): LayoutElement {
        val now = System.currentTimeMillis()
        val timeText: String
        val timeColor: Int

        if (game.isUpcoming) {
            // Upcoming game - show when it starts
            val daysUntilStart = ((game.startDate - now) / (1000 * 60 * 60 * 24)).toInt()
            timeText = when {
                daysUntilStart <= 0 -> "Starts today"
                daysUntilStart == 1 -> "Starts tomorrow"
                else -> "In $daysUntilStart days"
            }
            timeColor = COLOR_PRIMARY // Cyan for upcoming
        } else {
            // Current game - show when it ends
            val daysLeft = ((game.endDate - now) / (1000 * 60 * 60 * 24)).toInt()
            timeText = when {
                daysLeft <= 0 -> "Ends today!"
                daysLeft == 1 -> "1 day left"
                else -> "$daysLeft days left"
            }
            timeColor = if (daysLeft <= 1) 0xFFFF6B6B.toInt() else COLOR_SUCCESS
        }

        // Scale sizes based on card width
        val titleSize = if (width >= 140f) 12f else 11f
        val subtitleSize = if (width >= 140f) 9f else 8f
        val imageSize = if (width >= 140f) 36f else 30f
        val hasImage = gameImages.containsKey(game.id)

        val rowBuilder = Row.Builder()
            .setWidth(expand())
            .setHeight(wrap())
            .setVerticalAlignment(VERTICAL_ALIGN_CENTER)

        // Add image if available
        if (hasImage) {
            rowBuilder.addContent(
                Box.Builder()
                    .setWidth(dp(imageSize))
                    .setHeight(dp(imageSize * 1.33f)) // 3:4 aspect ratio
                    .setModifiers(
                        Modifiers.Builder()
                            .setBackground(
                                Background.Builder()
                                    .setCorner(Corner.Builder().setRadius(dp(6f)).build())
                                    .build()
                            )
                            .build()
                    )
                    .addContent(
                        Image.Builder()
                            .setResourceId("game_${game.id}")
                            .setWidth(dp(imageSize))
                            .setHeight(dp(imageSize * 1.33f))
                            .setContentScaleMode(CONTENT_SCALE_MODE_CROP)
                            .build()
                    )
                    .build()
            )
            rowBuilder.addContent(Spacer.Builder().setWidth(dp(8f)).build())
        }

        // Text content
        rowBuilder.addContent(
            Column.Builder()
                .setWidth(expand())
                .setHeight(wrap())
                .setHorizontalAlignment(if (hasImage) HORIZONTAL_ALIGN_START else HORIZONTAL_ALIGN_CENTER)
                .addContent(
                    Text.Builder()
                        .setText(truncateTitle(game.title, if (hasImage) width - 50f else width))
                        .setFontStyle(
                            FontStyle.Builder()
                                .setSize(sp(titleSize))
                                .setColor(argb(COLOR_TEXT_PRIMARY))
                                .setWeight(FONT_WEIGHT_MEDIUM)
                                .build()
                        )
                        .setMaxLines(1)
                        .build()
                )
                .addContent(Spacer.Builder().setHeight(dp(1f)).build())
                .addContent(
                    Text.Builder()
                        .setText(timeText)
                        .setFontStyle(
                            FontStyle.Builder()
                                .setSize(sp(subtitleSize))
                                .setColor(argb(timeColor))
                                .build()
                        )
                        .build()
                )
                .build()
        )

        return Box.Builder()
            .setWidth(dp(width))
            .setHeight(wrap())
            .setModifiers(
                Modifiers.Builder()
                    .setClickable(createOpenOfferAction(game.id))
                    .setBackground(
                        Background.Builder()
                            .setColor(argb(COLOR_CARD_BG))
                            .setCorner(Corner.Builder().setRadius(dp(10f)).build())
                            .build()
                    )
                    .setPadding(
                        Padding.Builder()
                            .setStart(dp(8f))
                            .setEnd(dp(10f))
                            .setTop(dp(6f))
                            .setBottom(dp(6f))
                            .build()
                    )
                    .setBorder(
                        Border.Builder()
                            .setWidth(dp(1f))
                            .setColor(argb(COLOR_BORDER))
                            .build()
                    )
                    .build()
            )
            .addContent(rowBuilder.build())
            .build()
    }

    private fun truncateTitle(title: String, cardWidth: Float = 140f): String {
        // Adjust max chars based on card width
        val maxChars = when {
            cardWidth >= 145f -> 18
            cardWidth >= 130f -> 16
            else -> 14
        }
        return if (title.length > maxChars) {
            title.take(maxChars - 2) + "..."
        } else {
            title
        }
    }

    data class FreeGame(
        val id: String,
        val title: String,
        val startDate: Long,
        val endDate: Long,
        val imageUrl: String?,
        val isUpcoming: Boolean
    )
}
