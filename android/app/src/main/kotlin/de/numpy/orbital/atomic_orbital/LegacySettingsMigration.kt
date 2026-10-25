package de.numpy.orbital.atomic_orbital

/** Returns whether startup may initialize Play Games after preserving legacy settings. */
internal object LegacySettingsMigration {
    const val MARKER = "flutter.legacy_settings_migrated_v1"
    const val MUTED = "flutter.is_muted"
    const val DISCONNECTED = "flutter.play_games_disconnected"
    private val counters = mapOf(
        "highscore" to "flutter.high_score",
        "hardcorehighscore" to "flutter.hardcore_high_score",
        "gamesPlayed" to "flutter.games_played",
        "TotalPoints" to "flutter.total_points",
    )

    fun migrate(
        legacy: Map<String, *>,
        current: Map<String, *>,
        commit: (Map<String, Any>) -> Boolean,
    ): Boolean {
        // An unreadable opt-out must never become permission to connect.
        val disconnected = when (val saved = current[DISCONNECTED]) {
            is Boolean -> saved
            null -> legacy["googlegame"] == false ||
                (legacy.containsKey("googlegame") && legacy["googlegame"] !is Boolean)
            else -> true
        }
        if (current[MARKER] == true &&
            current[MUTED] is Boolean && current[DISCONNECTED] is Boolean &&
            counters.values.all { nonnegative(current[it]) != null }) {
            return !disconnected
        }
        val values = mutableMapOf<String, Any>()
        for ((oldKey, newKey) in counters) {
            values[newKey] = maxOf(nonnegative(current[newKey]) ?: 0,
                nonnegative(legacy[oldKey]) ?: 0)
        }
        values[MUTED] = current[MUTED] as? Boolean ?: legacy["MUTE"] as? Boolean ?: true
        values[DISCONNECTED] = disconnected
        values[MARKER] = true
        val saved = try {
            commit(values)
        } catch (_: Exception) {
            false
        }
        return saved && !disconnected
    }

    private fun nonnegative(value: Any?): Long? = when (value) {
        is Int -> value.toLong().takeIf { it >= 0 }
        is Long -> value.takeIf { it >= 0 }
        else -> null
    }
}
