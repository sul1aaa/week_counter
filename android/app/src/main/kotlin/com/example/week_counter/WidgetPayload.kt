package com.example.week_counter

import org.json.JSONException
import org.json.JSONObject

/** Mirrors `lib/domain/widget_payload.dart`. All times are epoch milliseconds. */
data class WidgetSegment(
    val start: Long,
    val end: Long,
    val counting: Boolean,
    val target: Long?,
    val title: String,
    val subtitle: String,
    val secondary: String?,
)

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
