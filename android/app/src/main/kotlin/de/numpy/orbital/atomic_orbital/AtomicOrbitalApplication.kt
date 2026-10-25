package de.numpy.orbital.atomic_orbital

import android.app.Application
import com.google.android.gms.games.PlayGamesSdk

class AtomicOrbitalApplication : Application() {
    companion object {
        var automaticPlayGamesAllowed = false
            private set
    }

    override fun onCreate() {
        super.onCreate()
        val preferences = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val allowPlayGames = try {
            LegacySettingsMigration.migrate(
                getSharedPreferences("settings", MODE_PRIVATE).all,
                preferences.all,
            ) { values ->
                val editor = preferences.edit()
                for ((key, value) in values) {
                    when (value) {
                        is Long -> editor.putLong(key, value)
                        is Boolean -> editor.putBoolean(key, value)
                    }
                }
                editor.commit()
            }
        } catch (_: Exception) {
            false
        }
        automaticPlayGamesAllowed = allowPlayGames
        // PGS must observe the first Activity creation, after saving any opt-out.
        if (allowPlayGames) {
            PlayGamesSdk.initialize(this)
        }
    }
}
