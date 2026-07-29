package dev.bassiuz.seedling

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * Today at a glance: appointments on the left, what is left to do on the right.
 *
 * Four rows a side. RemoteViews cannot loop, so the rows exist in the layout
 * and the unused ones are hidden — which is the ordinary way to do this and
 * cheaper than a collection widget for a list that is never long.
 */
class SeedlingWidgetProvider : HomeWidgetProvider() {

    /** Must match `WidgetPayload.lines` on the Dart side. */
    private val ROWS = 6


    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences,
    ) {
        val payload = widgetData.getString("seedling_today", null)
        val data = payload?.let { runCatching { JSONObject(it) }.getOrNull() }

        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.seedling_widget)

            // Tapping anywhere that is not a checkbox opens the app.
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            renderEvents(views, data)
            renderTasks(context, views, data)

            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun renderEvents(views: RemoteViews, data: JSONObject?) {
        val events = data?.optJSONArray("events")
        val rows = (0 until ROWS).map { R.id::class.java.getField("event_$it").getInt(null) }
        val times = (0 until ROWS).map { R.id::class.java.getField("event_time_$it").getInt(null) }
        val titles = (0 until ROWS).map { R.id::class.java.getField("event_title_$it").getInt(null) }

        rows.indices.forEach { i ->
            val event = events?.optJSONObject(i)
            if (event == null) {
                views.setViewVisibility(rows[i], View.GONE)
            } else {
                views.setViewVisibility(rows[i], View.VISIBLE)
                views.setTextViewText(times[i], event.optString("time"))
                views.setTextViewText(titles[i], event.optString("title"))
            }
        }

        val nothing = events == null || events.length() == 0
        views.setViewVisibility(R.id.events_empty, if (nothing) View.VISIBLE else View.GONE)
        more(views, R.id.events_more, data?.optInt("moreEvents") ?: 0)
    }

    private fun renderTasks(context: Context, views: RemoteViews, data: JSONObject?) {
        val tasks = data?.optJSONArray("tasks")
        val rows = (0 until ROWS).map { R.id::class.java.getField("task_$it").getInt(null) }
        val titles = (0 until ROWS).map { R.id::class.java.getField("task_title_$it").getInt(null) }
        val boxes = (0 until ROWS).map { R.id::class.java.getField("task_box_$it").getInt(null) }

        rows.indices.forEach { i ->
            val task = tasks?.optJSONObject(i)
            if (task == null) {
                views.setViewVisibility(rows[i], View.GONE)
            } else {
                views.setViewVisibility(rows[i], View.VISIBLE)
                views.setTextViewText(titles[i], task.optString("title"))

                // The checkbox wakes a background isolate rather than opening
                // the app: ticking something off should not cost you the
                // screen you were on.
                val uri = Uri.parse("seedling://toggle?id=${Uri.encode(task.optString("id"))}")
                views.setOnClickPendingIntent(
                    boxes[i],
                    HomeWidgetBackgroundIntent.getBroadcast(context, uri),
                )
            }
        }

        val nothing = tasks == null || tasks.length() == 0
        views.setViewVisibility(R.id.tasks_empty, if (nothing) View.VISIBLE else View.GONE)
        more(views, R.id.tasks_more, data?.optInt("moreTasks") ?: 0)
    }

    private fun more(views: RemoteViews, id: Int, count: Int) {
        if (count > 0) {
            views.setViewVisibility(id, View.VISIBLE)
            views.setTextViewText(id, "+$count more")
        } else {
            views.setViewVisibility(id, View.GONE)
        }
    }
}
