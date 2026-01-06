package com.ignacioaldama.egdata

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import android.widget.RemoteViews

class SmallFreeGamesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
        try {
            Log.d("SmallFreeGamesWidget", "Updating small widget $widgetId")

            val views = RemoteViews(context.packageName, R.layout.widget_small)

            // Setup carousel
            setupCarousel(context, views, widgetId)

            // Update the widget
            appWidgetManager.updateAppWidget(widgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.carousel_flipper)

        } catch (e: Exception) {
            Log.e("SmallFreeGamesWidget", "Error updating widget", e)
        }
    }

    private fun setupCarousel(context: Context, views: RemoteViews, widgetId: Int) {
        val serviceIntent =
                Intent(context, CarouselService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
        views.setRemoteAdapter(R.id.carousel_flipper, serviceIntent)

        // Set Click Template
        val clickPendingIntent = createClickPendingIntent(context, widgetId)
        views.setPendingIntentTemplate(R.id.carousel_flipper, clickPendingIntent)
    }

    private fun createClickPendingIntent(context: Context, widgetId: Int): PendingIntent {
        val clickIntent = Intent(context, MainActivity::class.java).apply {
            action = "com.ignacioaldama.egdata.ACTION_OPEN_OFFER"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        return PendingIntent.getActivity(
            context,
            widgetId,
            clickIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )
    }
}
