package com.machadev.strola_health

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

/**
 * Standard AppWidgetProvider — no home_widget base class dependency in the
 * render path, so the widget inflates cleanly even before the Flutter engine
 * has started. Reads from the SharedPreferences file that home_widget writes.
 */
class StrollaWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        // home_widget stores data in this preferences file
        val prefs = context.getSharedPreferences(
            "HomeWidgetPreferences", Context.MODE_PRIVATE
        )

        val steps     = prefs.getInt("steps", 0)
        val goal      = prefs.getInt("goal", 10_000)
        val distance  = prefs.getString("distance", "0.0") ?: "0.0"
        val calories  = prefs.getInt("calories", 0)
        val activeMin = prefs.getInt("activeMin", 0)
        val progress  = ((steps.toFloat() / goal.toFloat()) * 100)
            .toInt().coerceIn(0, 100)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.strolla_widget)

            views.setTextViewText(R.id.tv_steps,      "%,d".format(steps))
            views.setTextViewText(R.id.tv_goal_label, "of %,d steps".format(goal))
            views.setTextViewText(R.id.tv_distance,   distance)
            views.setTextViewText(R.id.tv_calories,   "$calories")
            views.setTextViewText(R.id.tv_active,     "$activeMin")
            views.setProgressBar(R.id.widget_progress, 100, progress, false)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
