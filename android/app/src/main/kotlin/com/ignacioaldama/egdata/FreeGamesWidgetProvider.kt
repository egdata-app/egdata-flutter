package com.ignacioaldama.egdata

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Shader
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.renderscript.Allocation
import android.renderscript.Element
import android.renderscript.RenderScript
import android.renderscript.ScriptIntrinsicBlur
import android.util.Log
import android.widget.RemoteViews
import org.json.JSONObject

class FreeGamesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            // Go async to allow bitmap generation without blocking
            val pendingResult = goAsync()

            // Run in a coroutine or background thread
            Thread {
                        try {
                            updateWidget(context, appWidgetManager, widgetId)
                        } finally {
                            pendingResult.finish()
                        }
                    }
                    .start()
        }
    }

    override fun onAppWidgetOptionsChanged(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int,
            newOptions: Bundle
    ) {
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

            // Generate and apply Material You dynamic background
            val density = context.resources.displayMetrics.density
            val widthPx = (minWidth * density).toInt()
            val heightPx = (minHeight * density).toInt()
            val backgroundBitmap = createMaterialYouBackground(context, widthPx, heightPx)
            views.setImageViewBitmap(R.id.widget_background, backgroundBitmap)

            // 1. Template for individual item clicks (ListView)
            val clickIntent =
                    Intent(context, MainActivity::class.java).apply {
                        action = "com.ignacioaldama.egdata.ACTION_OPEN_OFFER"
                    }
            val clickPendingIntent =
                    PendingIntent.getActivity(
                            context,
                            0,
                            clickIntent,
                            PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                    )
            views.setPendingIntentTemplate(R.id.game_list, clickPendingIntent)

            // 2. Default click for the whole widget (fallback)
            val intent =
                    Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
            val pendingIntent =
                    PendingIntent.getActivity(
                            context,
                            1,
                            intent,
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
        val serviceIntent =
                Intent(context, WidgetService::class.java).apply {
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
        val text =
                when {
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

    /** Creates a Material You themed blurred gradient background using colored blobs */
    private fun createMaterialYouBackground(context: Context, width: Int, height: Int): Bitmap {
        // 1. Get multiple tones from Material You (API 31+)
        val primary = getSystemColor(context, android.R.color.system_accent1_200, Color.CYAN)
        val secondary = getSystemColor(context, android.R.color.system_accent2_500, Color.MAGENTA)
        val neutralBase = getSystemColor(context, android.R.color.system_neutral1_900, Color.BLACK)

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // 2. Draw the dynamic system-aware dark base
        canvas.drawColor(neutralBase)

        val baseRadius = width.coerceAtLeast(height) * 0.7f

        // Improved Helper with multiple tones
        fun drawDynamicBlob(centerX: Float, centerY: Float, color: Int, radius: Float) {
            val paint =
                    Paint().apply {
                        isAntiAlias = true
                        shader =
                                android.graphics.RadialGradient(
                                        centerX,
                                        centerY,
                                        radius,
                                        // Using very low alpha (0.12f) for subtle Material You tint
                                        intArrayOf(adjustAlpha(color, 0.06f), Color.TRANSPARENT),
                                        floatArrayOf(0f, 1f),
                                        Shader.TileMode.CLAMP
                                )
                    }
            canvas.drawCircle(centerX, centerY, radius, paint)
        }

        // Top-Left: Light Accent
        drawDynamicBlob(0f, 0f, primary, baseRadius)

        // Bottom-Right: Deep Accent
        drawDynamicBlob(width.toFloat(), height.toFloat(), secondary, baseRadius * 1.2f)

        // Center: Subtle Glow
        drawDynamicBlob(width * 0.5f, height * 0.5f, primary, baseRadius * 0.5f)

        return bitmap
    }

    /** Access specific system tokens safely */
    private fun getSystemColor(context: Context, colorId: Int, fallback: Int): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                context.getColor(colorId)
            } catch (e: Exception) {
                fallback
            }
        } else {
            fallback
        }
    }

    /** Apply blur effect to bitmap using RenderScript */
    private fun applyBlur(context: Context, bitmap: Bitmap, radius: Float): Bitmap {
        val output =
                Bitmap.createBitmap(
                        bitmap.width,
                        bitmap.height,
                        bitmap.config ?: Bitmap.Config.ARGB_8888
                )

        try {
            val rs = RenderScript.create(context)
            val input = Allocation.createFromBitmap(rs, bitmap)
            val outAlloc = Allocation.createFromBitmap(rs, output)

            val script = ScriptIntrinsicBlur.create(rs, Element.U8_4(rs))
            script.setRadius(radius.coerceIn(0f, 25f))
            script.setInput(input)
            script.forEach(outAlloc)

            outAlloc.copyTo(output)

            rs.destroy()
        } catch (e: Exception) {
            Log.e("FreeGamesWidget", "Blur failed, using original: ${e.message}")
            return bitmap
        }

        return output
    }

    /** Darken a color by a factor */
    private fun darkenColor(color: Int, factor: Float): Int {
        val hsv = FloatArray(3)
        Color.colorToHSV(color, hsv)
        hsv[2] *= (1f - factor)
        return Color.HSVToColor(hsv)
    }

    /** Lighten a color by a factor */
    private fun lightenColor(color: Int, factor: Float): Int {
        val hsv = FloatArray(3)
        Color.colorToHSV(color, hsv)
        hsv[2] = (hsv[2] + (1f - hsv[2]) * factor).coerceIn(0f, 1f)
        return Color.HSVToColor(hsv)
    }

    /** Adjust alpha channel of a color */
    private fun adjustAlpha(color: Int, alpha: Float): Int {
        return Color.argb(
                (alpha * 255).toInt(),
                Color.red(color),
                Color.green(color),
                Color.blue(color)
        )
    }

    /** Reduce overall opacity of a bitmap */
    private fun adjustBitmapOpacity(bitmap: Bitmap, opacity: Float): Bitmap {
        val output = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint().apply { alpha = (opacity * 255).toInt() }
        canvas.drawBitmap(bitmap, 0f, 0f, paint)
        return output
    }

    data class WidgetDataContainer(val games: List<GameData>, val lastUpdate: String)
    data class GameData(
            val id: String,
            val title: String,
            val thumbnailUrl: String?,
            val endDate: String
    )
}
