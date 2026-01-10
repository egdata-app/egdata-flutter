package com.ignacioaldama.egdata.wear

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

    companion object {
        private const val RESOURCES_VERSION = "1"
        private const val API_URL = "https://api.egdata.app/free-games"

        // Colors
        private const val COLOR_BACKGROUND = 0xFF0A0A0A.toInt()
        private const val COLOR_PRIMARY = 0xFF00D4FF.toInt()
        private const val COLOR_TEXT_PRIMARY = 0xFFFFFFFF.toInt()
        private const val COLOR_TEXT_SECONDARY = 0xFF9CA3AF.toInt()
        private const val COLOR_SUCCESS = 0xFF10B981.toInt()
    }

    override fun onTileRequest(requestParams: TileRequest): ListenableFuture<Tile> {
        return serviceScope.future {
            val freeGames = fetchFreeGames()
            buildTile(freeGames)
        }
    }

    override fun onTileResourcesRequest(requestParams: ResourcesRequest): ListenableFuture<Resources> {
        return Futures.immediateFuture(
            Resources.Builder()
                .setVersion(RESOURCES_VERSION)
                .build()
        )
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
        val games = mutableListOf<FreeGame>()
        val now = System.currentTimeMillis()

        try {
            val jsonArray = JSONArray(json)
            for (i in 0 until jsonArray.length()) {
                val gameObj = jsonArray.getJSONObject(i)

                val startDate = gameObj.optString("startDate", "")
                val endDate = gameObj.optString("endDate", "")

                // Parse dates
                val startMillis = parseDate(startDate)
                val endMillis = parseDate(endDate)

                // Only include currently active free games
                if (startMillis != null && endMillis != null &&
                    now >= startMillis && now < endMillis) {

                    val title = gameObj.optString("title", "Unknown Game")
                    games.add(FreeGame(
                        title = title,
                        endDate = endMillis
                    ))
                }
            }
        } catch (e: Exception) {
            // Return empty list on parse error
        }

        return games.take(3) // Limit to 3 games for the tile
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
            .setResourcesVersion(RESOURCES_VERSION)
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
                                    .setSize(sp(14f))
                                    .setColor(argb(COLOR_TEXT_SECONDARY))
                                    .build()
                            )
                            .build()
                    )
                    .addContent(Spacer.Builder().setHeight(dp(4f)).build())
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

        // Header
        columnBuilder.addContent(
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

        columnBuilder.addContent(Spacer.Builder().setHeight(dp(8f)).build())

        // Games list
        games.forEachIndexed { index, game ->
            columnBuilder.addContent(buildGameRow(game))
            if (index < games.size - 1) {
                columnBuilder.addContent(Spacer.Builder().setHeight(dp(6f)).build())
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
                    .setPadding(
                        Padding.Builder()
                            .setAll(dp(12f))
                            .build()
                    )
                    .build()
            )
            .addContent(columnBuilder.build())
            .build()
    }

    private fun buildGameRow(game: FreeGame): LayoutElement {
        val daysLeft = ((game.endDate - System.currentTimeMillis()) / (1000 * 60 * 60 * 24)).toInt()
        val timeText = when {
            daysLeft <= 0 -> "Ends today"
            daysLeft == 1 -> "1 day left"
            else -> "$daysLeft days left"
        }

        return Column.Builder()
            .setWidth(expand())
            .setHeight(wrap())
            .setHorizontalAlignment(HORIZONTAL_ALIGN_CENTER)
            .addContent(
                Text.Builder()
                    .setText(truncateTitle(game.title))
                    .setFontStyle(
                        FontStyle.Builder()
                            .setSize(sp(13f))
                            .setColor(argb(COLOR_TEXT_PRIMARY))
                            .setWeight(FONT_WEIGHT_MEDIUM)
                            .build()
                    )
                    .setMaxLines(1)
                    .build()
            )
            .addContent(
                Text.Builder()
                    .setText(timeText)
                    .setFontStyle(
                        FontStyle.Builder()
                            .setSize(sp(10f))
                            .setColor(argb(COLOR_SUCCESS))
                            .build()
                    )
                    .build()
            )
            .build()
    }

    private fun truncateTitle(title: String): String {
        return if (title.length > 18) {
            title.take(16) + "..."
        } else {
            title
        }
    }

    data class FreeGame(
        val title: String,
        val endDate: Long
    )
}
