package com.ignacioaldama.egdata

import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

/**
 * GlanceAppWidgetReceiver for the Small Free Games widget
 */
class SmallFreeGamesGlanceReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = SmallFreeGamesGlanceWidget()
}
