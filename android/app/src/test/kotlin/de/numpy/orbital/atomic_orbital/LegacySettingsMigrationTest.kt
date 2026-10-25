package de.numpy.orbital.atomic_orbital

import org.junit.Assert.*
import org.junit.Test

class LegacySettingsMigrationTest {
    private val legacy = mapOf<String, Any>(
        "highscore" to 61, "hardcorehighscore" to 36,
        "gamesPlayed" to 149, "TotalPoints" to 999, "MUTE" to false,
    )
    private fun migrate(
        old: Map<String, *> = legacy,
        current: MutableMap<String, Any> = mutableMapOf(),
    ): Boolean = LegacySettingsMigration.migrate(old, current) {
        current.putAll(it)
        true
    }

    @Test fun freshInstallKeepsMutedDefaultAndAllowsAuthentication() {
        val current = mutableMapOf<String, Any>()
        assertTrue(migrate(emptyMap<String, Any>(), current))
        assertEquals(0L, current["flutter.high_score"])
        assertEquals(true, current[LegacySettingsMigration.MUTED])
        assertEquals(false, current[LegacySettingsMigration.DISCONNECTED])
        assertEquals(true, current[LegacySettingsMigration.MARKER])
    }

    @Test fun importsAllProgressAsFlutterLongsWithoutChangingLegacy() {
        val current = mutableMapOf<String, Any>()
        val original = legacy.toMap()
        assertTrue(migrate(current = current))
        assertEquals(61L, current["flutter.high_score"])
        assertEquals(36L, current["flutter.hardcore_high_score"])
        assertEquals(149L, current["flutter.games_played"])
        assertEquals(999L, current["flutter.total_points"])
        assertEquals(false, current[LegacySettingsMigration.MUTED])
        assertEquals(original, legacy)
    }

    @Test fun preservesHigherProgressAndExplicitCurrentChoices() {
        val current = mutableMapOf<String, Any>(
            "flutter.high_score" to 80L, "flutter.hardcore_high_score" to 4L,
            "flutter.games_played" to 200L, "flutter.total_points" to 1400L,
            LegacySettingsMigration.MUTED to true,
            LegacySettingsMigration.DISCONNECTED to false,
        )
        assertTrue(migrate(legacy + ("googlegame" to false), current))
        assertEquals(80L, current["flutter.high_score"])
        assertEquals(36L, current["flutter.hardcore_high_score"])
        assertEquals(200L, current["flutter.games_played"])
        assertEquals(1400L, current["flutter.total_points"])
        assertEquals(true, current[LegacySettingsMigration.MUTED])
        assertEquals(false, current[LegacySettingsMigration.DISCONNECTED])
    }

    @Test fun repeatLaunchDoesNotImportOrCommitAgain() {
        val current = mutableMapOf<String, Any>()
        migrate(current = current)
        val before = current.toMap()
        assertTrue(LegacySettingsMigration.migrate(
            legacy + ("highscore" to 199), current,
        ) { error("Already migrated settings must not be committed again") })
        assertEquals(before, current)
    }

    @Test fun malformedValuesCannotCreateScoresOrEnablePlayGames() {
        val current = mutableMapOf<String, Any>(
            "flutter.high_score" to "999", "flutter.total_points" to -5L,
            LegacySettingsMigration.MUTED to "false",
            LegacySettingsMigration.DISCONNECTED to "false",
        )
        assertFalse(migrate(mapOf("highscore" to -1, "hardcorehighscore" to 12.5,
            "gamesPlayed" to "500", "TotalPoints" to 22, "MUTE" to false), current))
        assertEquals(0L, current["flutter.high_score"])
        assertEquals(0L, current["flutter.hardcore_high_score"])
        assertEquals(0L, current["flutter.games_played"])
        assertEquals(22L, current["flutter.total_points"])
        assertEquals(false, current[LegacySettingsMigration.MUTED])
        assertEquals(true, current[LegacySettingsMigration.DISCONNECTED])
    }

    @Test fun explicitLegacyOptOutIsImportedAndSurvivesRepeatLaunch() {
        val current = mutableMapOf<String, Any>()
        assertFalse(migrate(legacy + ("googlegame" to false), current))
        assertEquals(true, current[LegacySettingsMigration.DISCONNECTED])
        assertFalse(LegacySettingsMigration.migrate(emptyMap<String, Any>(), current) {
            error("Already migrated")
        })
    }

    @Test fun currentDisconnectWinsOverLegacyOptIn() {
        val current = mutableMapOf<String, Any>(LegacySettingsMigration.DISCONNECTED to true)
        assertFalse(migrate(legacy + ("googlegame" to true), current))
        assertEquals(true, current[LegacySettingsMigration.DISCONNECTED])
    }

    @Test fun malformedLegacyOptOutFailsClosed() {
        val current = mutableMapOf<String, Any>()
        assertFalse(migrate(legacy + ("googlegame" to "false"), current))
        assertEquals(true, current[LegacySettingsMigration.DISCONNECTED])
    }

    @Test fun failedCommitDoesNotEnablePlayGamesOrMarkMigrationComplete() {
        val current = mutableMapOf<String, Any>()
        assertFalse(LegacySettingsMigration.migrate(legacy, current) { false })
        assertFalse(current.containsKey(LegacySettingsMigration.MARKER))
        assertFalse(LegacySettingsMigration.migrate(legacy, current) { throw IllegalStateException() })
        assertFalse(current.containsKey(LegacySettingsMigration.MARKER))
        assertTrue(migrate(current = current))
        assertEquals(61L, current["flutter.high_score"])
    }
}
