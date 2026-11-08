package com.example.week_counter

import org.json.JSONException
import org.json.JSONObject

/** Mirrors `lib/domain/widget_payload.dart`. All times are epoch milliseconds. */
data class WidgetSegment(
    val start: Long,
    val end: Long,
    val counting: Boolean,
    val target: Long?,
    /** Start of the run of workdays or of the time off; the orb fills from here to [target]. */
    val from: Long?,
    val title: String,
    val subtitle: String,
    val secondary: String?,
) {
    /**
     * How full the orb and bar are at [now], from 0 to 1: the share of the run that's done, or
     * of the time off that's left. Like the app, an unknown start counts as nothing done.
     */
    fun fillAt(now: Long): Float {
        val from = from
        val to = target
        val done = if (from == null || to == null || to <= from) 0f
        else ((now - from).toFloat() / (to - from)).coerceIn(0f, 1f)
        return if (counting) done else 1f - done
    }
}

data class WidgetStrings(
    val dayShort: String,
    val hourShort: String,
    val minuteShort: String,
    val empty: String?,
)

data class WidgetPayload(val strings: WidgetStrings, val segments: List<WidgetSegment>) {

    /** The segment to show at [now], or null once all precomputed segments have passed. */
    fun segmentAt(now: Long): WidgetSegment? = segments.firstOrNull { it.end > now }

    companion object {
        const val KEY = "wc_payload_v1"

        fun parse(json: String?): WidgetPayload? {
            if (json == null) return null
            return try {
                val root = JSONObject(json)
                val strings = root.getJSONObject("strings")
                val items = root.getJSONArray("segments")
                WidgetPayload(
                    WidgetStrings(
                        dayShort = strings.getString("dayShort"),
                        hourShort = strings.getString("hourShort"),
                        minuteShort = strings.getString("minuteShort"),
                        empty = strings.optStringOrNull("empty"),
                    ),
                    List(items.length()) { i ->
                        val item = items.getJSONObject(i)
                        WidgetSegment(
                            start = item.getLong("start"),
                            end = item.getLong("end"),
                            counting = item.getString("mode") == "countdown",
                            target = if (item.isNull("target")) null else item.getLong("target"),
                            // Missing in payloads from before the orb.
                            from = if (item.isNull("from")) null else item.getLong("from"),
                            title = item.getString("title"),
                            subtitle = item.getString("subtitle"),
                            secondary = item.optStringOrNull("secondary"),
                        )
                    },
                )
            } catch (e: JSONException) {
                null
            }
        }

        private fun JSONObject.optStringOrNull(key: String): String? =
            if (isNull(key)) null else getString(key)
    }
}
