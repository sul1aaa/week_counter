package com.example.week_counter

import android.app.AlarmManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import kotlin.math.roundToInt

/**
 * Home-screen countdown. Renders the precomputed segment for the current time, so it stays
 * correct while the app is closed.
 *
 * With exact alarms allowed it shows a live Chronometer that ticks every second; the app
 * schedules widget updates at every point where the text or the day count changes. Without
 * them (default on Android 14+) it shows a coarse "2d 3h" that refreshes about every 30 minutes.
 *
 * Beside the text is the app's orb, filled to how far the week (or the time off) has gone, with
 * the app's progress bar under the text when the widget is tall enough. Both catch up on each
 * refresh.
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
        val now = System.currentTimeMillis()
        val progress = progressAt(context, payload?.segmentAt(now), now)
        for (id in appWidgetIds) {
            val views = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // The launcher shows the biggest one that fits and switches on resize.
                RemoteViews(
                    Fit.entries.flatMap { fit ->
                        OrbSize.entries.map { orb ->
                            SizeF(orb.minWidth, fit.minHeight(context)) to
                                buildViews(context, payload, now, live, progress, fit, orb)
                        }
                    }.toMap(),
                )
            } else {
                // The portrait size; older launchers keep one layout for both orientations.
                val options = appWidgetManager.getAppWidgetOptions(id)
                val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
                val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
                buildViews(
                    context, payload, now, live, progress,
                    Fit.forHeight(context, height), OrbSize.forWidth(width),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    /** The orb and bar fill for [segment], with the orb drawn once for every layout. */
    private fun progressAt(context: Context, segment: WidgetSegment?, now: Long): Progress {
        val fill = segment?.fillAt(now) ?: 0.5f
        val mode = when {
            segment == null -> OrbMode.Paused
            segment.counting -> OrbMode.Work
            else -> OrbMode.Weekend
        }
        val density = context.resources.displayMetrics.density
        return Progress(fill, mode, OrbRenderer.render(ORB_DP, density, fill, mode))
    }

    private class Progress(val fill: Float, val mode: OrbMode, val orb: Bitmap)

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        // Android 12+ launchers already have a layout for every size.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) return
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId), HomeWidgetPlugin.getData(context))
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            // The Chronometer counts from elapsedRealtime, so a clock change needs a new base.
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED,
            // Exact alarms were just allowed: swap "2d 3h" for the ticking timer now, not on
            // the next refresh.
            AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED -> {
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
        progress: Progress,
        fit: Fit,
        orb: OrbSize,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.week_counter_widget)
        views.setOnClickPendingIntent(
            R.id.wc_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )
        views.setInt(R.id.wc_subtitle, "setMaxLines", if (fit >= Fit.Regular) 2 else 1)
        showProgress(views, progress, fit, orb)

        val segment = payload?.segmentAt(now)
        val target = segment?.target
        if (segment == null) {
            views.setTextViewText(R.id.wc_title, context.getString(R.string.widget_name))
            views.setTextViewText(
                R.id.wc_subtitle,
                payload?.strings?.empty ?: context.getString(R.string.widget_placeholder),
            )
            views.setViewVisibility(R.id.wc_subtitle, View.VISIBLE)
            views.setViewVisibility(R.id.wc_counter, View.GONE)
            views.setViewVisibility(R.id.wc_secondary, View.GONE)
            return views
        }

        views.setTextViewText(R.id.wc_title, segment.title)
        views.setTextViewText(R.id.wc_subtitle, segment.subtitle)
        views.setTextViewText(R.id.wc_secondary, segment.secondary ?: "")
        // Without a number the subtitle fits at any size.
        views.setViewVisibility(
            R.id.wc_subtitle,
            if (fit == Fit.Tiny && target != null) View.GONE else View.VISIBLE,
        )
        views.setViewVisibility(
            R.id.wc_secondary,
            if (fit >= Fit.Regular && !segment.secondary.isNullOrEmpty()) View.VISIBLE else View.GONE,
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
            val untilDayTick = remaining - days * DAY_MS
            // The days go in the timer's own text ("2d 3:20:15"), so the whole number is one
            // view that can shrink to fit.
            views.setChronometer(
                R.id.wc_timer,
                SystemClock.elapsedRealtime() + untilDayTick,
                if (days > 0) "$days${strings.dayShort} %s" else null,
                true,
            )
            views.setChronometerCountDown(R.id.wc_timer, true)
        } else {
            views.setViewVisibility(R.id.wc_timer, View.GONE)
            views.setViewVisibility(R.id.wc_coarse, View.VISIBLE)
            views.setTextViewText(R.id.wc_coarse, coarse(remaining, strings))
        }
        return views
    }

    /** The orb, if the widget is wide enough, and the bar, if it's tall enough. */
    private fun showProgress(views: RemoteViews, progress: Progress, fit: Fit, orb: OrbSize) {
        views.setViewVisibility(R.id.wc_orb, if (orb == OrbSize.Large) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.wc_orb_small, if (orb == OrbSize.Small) View.VISIBLE else View.GONE)
        when (orb) {
            OrbSize.Large -> views.setImageViewBitmap(R.id.wc_orb, progress.orb)
            OrbSize.Small -> views.setImageViewBitmap(R.id.wc_orb_small, progress.orb)
            OrbSize.None -> {}
        }

        val off = progress.mode == OrbMode.Weekend
        views.setViewVisibility(R.id.wc_bar, if (fit == Fit.Full) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.wc_bar_work, if (off) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.wc_bar_off, if (off) View.VISIBLE else View.GONE)
        views.setProgressBar(
            if (off) R.id.wc_bar_off else R.id.wc_bar_work,
            BAR_MAX,
            (progress.fill * BAR_MAX).roundToInt(),
            false,
        )
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

    /** The lines the widget's height has room for, smallest first. */
    private enum class Fit(private val textDp: Float, private val barDp: Float = 0f) {
        /** The title and the number. */
        Tiny(TITLE_DP),

        /** Also the subtitle, on one line. */
        Compact(TITLE_DP + SUBTITLE_DP),

        /** Also a second subtitle line and the secondary line, as on the medium iOS widget. */
        Regular(TITLE_DP + 2 * SUBTITLE_DP + SECONDARY_DP),

        /** Also the progress bar, once all the text fits. */
        Full(TITLE_DP + 2 * SUBTITLE_DP + SECONDARY_DP, BAR_DP);

        /** The widget height in dp these lines need at the current font size. */
        fun minHeight(context: Context): Float =
            2 * PADDING_DP + COUNTER_DP + barDp + textDp * context.resources.configuration.fontScale

        companion object {
            /** [height] is 0 until the launcher reports a size. */
            fun forHeight(context: Context, height: Int): Fit =
                if (height == 0) Regular
                else entries.lastOrNull { it.minHeight(context) <= height } ?: Tiny
        }
    }

    /** How big an orb the widget's width has room for beside the number, smallest first. */
    private enum class OrbSize(val minWidth: Float) {
        None(0f),

        /** The 56dp orb. */
        Small(SMALL_ORB_MIN_WIDTH_DP),

        /** The orb at up to [ORB_DP], shrinking with the height. */
        Large(LARGE_ORB_MIN_WIDTH_DP);

        companion object {
            /** [width] is 0 until the launcher reports a size. */
            fun forWidth(width: Int): OrbSize =
                if (width == 0) Small else entries.last { it.minWidth <= width }
        }
    }

    private companion object {
        const val MINUTE_MS = 60_000L
        const val HOUR_MS = 60 * MINUTE_MS
        const val DAY_MS = 24 * HOUR_MS

        // Heights from week_counter_widget.xml; the text lines are at font scale 1.
        const val PADDING_DP = 16f
        const val COUNTER_DP = 46f
        const val TITLE_DP = 16f
        const val SUBTITLE_DP = 18f
        const val SECONDARY_DP = 16f
        const val BAR_DP = 16f

        /** The large orb's size in week_counter_widget.xml. */
        const val ORB_DP = 96

        // Widths that leave the number about 100dp beside the orb.
        const val SMALL_ORB_MIN_WIDTH_DP = 200f
        const val LARGE_ORB_MIN_WIDTH_DP = 260f

        const val BAR_MAX = 1000
    }
}
