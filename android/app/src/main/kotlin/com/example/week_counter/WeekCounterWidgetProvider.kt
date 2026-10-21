package com.example.week_counter

import android.app.AlarmManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen countdown. Renders the precomputed segment for the current time, so it stays
 * correct while the app is closed.
 *
 * With exact alarms allowed it shows a live Chronometer that ticks every second; the app
 * schedules widget updates at every point where the text or the day count changes. Without
 * them (default on Android 14+) it shows a coarse "2d 3h" that refreshes about every 30 minutes.
 */
class WeekCounterWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = WidgetPayload.parse(widgetData.getString(WidgetPayload.KEY, null))
        val live = canTickLive(context)
        for (id in appWidgetIds) {
            val views = buildViews(context, payload, System.currentTimeMillis(), live)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            // The Chronometer counts from elapsedRealtime, so a clock change needs a new base.
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED -> {
                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(ComponentName(context, javaClass))
                onUpdate(context, manager, ids, HomeWidgetPlugin.getData(context))
            }
        }
    }

    private fun buildViews(
        context: Context,
        payload: WidgetPayload?,
        now: Long,
        live: Boolean,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.week_counter_widget)
        views.setOnClickPendingIntent(
            R.id.wc_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )

        val segment = payload?.segmentAt(now)
        val target = segment?.target
        if (segment == null) {
            views.setTextViewText(R.id.wc_title, context.getString(R.string.widget_name))
            views.setTextViewText(
                R.id.wc_subtitle,
                payload?.strings?.empty ?: context.getString(R.string.widget_placeholder),
            )
            views.setViewVisibility(R.id.wc_counter, View.GONE)
            views.setViewVisibility(R.id.wc_secondary, View.GONE)
            return views
        }

        views.setTextViewText(R.id.wc_title, segment.title)
        views.setTextViewText(R.id.wc_subtitle, segment.subtitle)
        views.setTextViewText(R.id.wc_secondary, segment.secondary ?: "")
        views.setViewVisibility(
            R.id.wc_secondary,
            if (segment.secondary.isNullOrEmpty()) View.GONE else View.VISIBLE,
        )
        if (target == null) {
            views.setViewVisibility(R.id.wc_counter, View.GONE)
            return views
        }
        views.setViewVisibility(R.id.wc_counter, View.VISIBLE)

        val strings = payload.strings
        val remaining = maxOf(0L, target - now)
        val days = remaining / DAY_MS
        if (live) {
            views.setViewVisibility(R.id.wc_coarse, View.GONE)
            views.setViewVisibility(R.id.wc_timer, View.VISIBLE)
            views.setViewVisibility(R.id.wc_days, if (days > 0) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.wc_days, "$days${strings.dayShort}")
            val untilDayTick = remaining - days * DAY_MS
            views.setChronometer(
                R.id.wc_timer,
                SystemClock.elapsedRealtime() + untilDayTick,
                null,
                true,
            )
            views.setChronometerCountDown(R.id.wc_timer, true)
        } else {
            views.setViewVisibility(R.id.wc_timer, View.GONE)
            views.setViewVisibility(R.id.wc_days, View.GONE)
            views.setViewVisibility(R.id.wc_coarse, View.VISIBLE)
            views.setTextViewText(R.id.wc_coarse, coarse(remaining, strings))
        }
        return views
    }

    /** "2d 3h", "3h 20m" or "20m", matching `compactDuration` in Dart. */
    private fun coarse(remaining: Long, strings: WidgetStrings): String {
        val days = remaining / DAY_MS
        val hours = remaining % DAY_MS / HOUR_MS
        val minutes = remaining % HOUR_MS / MINUTE_MS
        return when {
            days > 0 -> "$days${strings.dayShort} $hours${strings.hourShort}"
            hours > 0 -> "$hours${strings.hourShort} $minutes${strings.minuteShort}"
            else -> "$minutes${strings.minuteShort}"
        }
    }

    private fun canTickLive(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return false
        return alarms.canScheduleExactAlarms()
    }

    private companion object {
        const val MINUTE_MS = 60_000L
        const val HOUR_MS = 60 * MINUTE_MS
        const val DAY_MS = 24 * HOUR_MS
    }
}
