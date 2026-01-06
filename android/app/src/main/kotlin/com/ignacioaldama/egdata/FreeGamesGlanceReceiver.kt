package com.ignacioaldama.egdata

import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

/**
 * GlanceAppWidgetReceiver for the Free Games widget
 * This replaces the old AppWidgetProvider with modern Jetpack Glance
 */
class FreeGamesGlanceReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = FreeGamesGlanceWidget()
}
