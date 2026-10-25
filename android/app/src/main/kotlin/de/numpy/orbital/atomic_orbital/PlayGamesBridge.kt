package de.numpy.orbital.atomic_orbital

import android.app.Activity
import android.content.Intent
import android.util.Log
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.games.PlayGames
import com.google.android.gms.games.achievement.Achievement
import com.google.android.gms.games.GamesClientStatusCodes
import com.google.android.gms.games.PlayGamesSdk
import com.google.android.gms.tasks.Task
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PlayGamesBridge(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {
    private companion object {
        var sdkInitialized = false
    }

    private val channel = MethodChannel(messenger, "atomic_orbital/play_games")
    private val leaderboardRanges = mapOf(
        "CgkItOGapf0GEAIQAQ" to (1L..200L),
        "CgkItOGapf0GEAIQAg" to (1L..100L),
        "CgkItOGapf0GEAIQAw" to (1L..Long.MAX_VALUE),
        "CgkItOGapf0GEAIQGg" to (1L..9007199254740991L),
        "CgkItOGapf0GEAIQGw" to (1L..9007199254740991L)
    )
    private val achievementIds = setOf(
        "CgkItOGapf0GEAIQBw", "CgkItOGapf0GEAIQCA", "CgkItOGapf0GEAIQCQ",
        "CgkItOGapf0GEAIQCg", "CgkItOGapf0GEAIQCw", "CgkItOGapf0GEAIQDA",
        "CgkItOGapf0GEAIQDQ", "CgkItOGapf0GEAIQDg", "CgkItOGapf0GEAIQDw",
        "CgkItOGapf0GEAIQEA", "CgkItOGapf0GEAIQEQ", "CgkItOGapf0GEAIQEg",
        "CgkItOGapf0GEAIQFw", "CgkItOGapf0GEAIQFA", "CgkItOGapf0GEAIQFQ", "CgkItOGapf0GEAIQGQ", "CgkItOGapf0GEAIQGA", "CgkItOGapf0GEAIQFg"
    )

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            if (!sdkInitialized && call.method != "signIn" &&
                !AtomicOrbitalApplication.automaticPlayGamesAllowed) {
                if (call.method == "status") {
                    result.success(mapOf("authenticated" to false))
                } else {
                    result.error("sign_in_required", "Sign in to Google Play Games to continue.", null)
                }
                return
            }
            if (!sdkInitialized) {
                // Explicit reconnect is allowed even if startup migration could not persist.
                PlayGamesSdk.initialize(activity.applicationContext)
                sdkInitialized = true
            }
            when (call.method) {
                "status", "signIn" -> {
                    val client = PlayGames.getGamesSignInClient(activity)
                    val task = if (call.method == "signIn") client.signIn() else client.isAuthenticated
                    task.addOnCompleteListener { completed ->
                        if (completed.isCanceled) {
                            result.success(mapOf("authenticated" to false))
                        } else if (!completed.isSuccessful) {
                            fail(result, completed.exception, "${call.method}/authentication")
                        } else if (!completed.result.isAuthenticated) {
                            result.success(mapOf("authenticated" to false))
                        } else {
                            PlayGames.getPlayersClient(activity).currentPlayer
                                .addOnCompleteListener { playerTask ->
                                    if (playerTask.isSuccessful) {
                                        val player = playerTask.result
                                        result.success(mapOf(
                                            "authenticated" to true,
                                            "playerId" to player.playerId,
                                            "displayName" to player.displayName
                                        ))
                                    } else {
                                        fail(result, playerTask.exception, "${call.method}/playerProfile")
                                    }
                                }
                        }
                    }
                }
                "loadAchievements" -> authenticated(result, "loadAchievements", call.argument<String>("playerId")) {
                    PlayGames.getAchievementsClient(activity).load(false)
                        .addOnSuccessListener { annotated ->
                            val buffer = annotated.get()
                            val unlocked = mutableListOf<String>()
                            try {
                                if (buffer != null) for (achievement in buffer) {
                                    if (achievement.state == Achievement.STATE_UNLOCKED) unlocked.add(achievement.achievementId)
                                }
                            } finally { buffer?.release() }
                            result.success(unlocked)
                        }
                        .addOnFailureListener { fail(result, it, call.method) }
                        .addOnCanceledListener { cancelled(result) }
                }
                "showAchievements" -> authenticated(result, "showAchievements", call.argument<String>("playerId")) {
                    showIntent(PlayGames.getAchievementsClient(activity).achievementsIntent, result, "showAchievements")
                }
                "showLeaderboards" -> {
                    val id = call.argument<String>("leaderboardId")
                    if (id !in leaderboardRanges) {
                        result.error("invalid_leaderboard", "Unknown Atomic Orbital leaderboard.", null)
                    } else authenticated(result, "showLeaderboards", call.argument<String>("playerId")) {
                        showIntent(PlayGames.getLeaderboardsClient(activity).getLeaderboardIntent(id!!), result, "showLeaderboards")
                    }
                }
                "submitScore" -> {
                    val id = call.argument<String>("leaderboardId")
                    val rawScore = call.argument<Any>("score")
                    val score = when (rawScore) {
                        is Int -> rawScore.toLong()
                        is Long -> rawScore
                        else -> null
                    }
                    if (id !in leaderboardRanges || score == null || score < 0) {
                        result.error("invalid_score", "A known leaderboard and nonnegative score are required.", null)
                    } else if (score !in leaderboardRanges.getValue(id!!)) {
                        result.error("score_out_of_range", "The published leaderboard cannot accept this score. Your local high score is preserved.", null)
                    } else authenticated(result, "submitScore", call.argument<String>("playerId")) {
                        PlayGames.getLeaderboardsClient(activity).submitScoreImmediate(id!!, score)
                            .addOnSuccessListener { result.success(null) }
                            .addOnFailureListener { fail(result, it, call.method) }
                            .addOnCanceledListener { cancelled(result) }
                    }
                }
                "unlockAchievement" -> {
                    val id = call.argument<String>("achievementId")
                    if (id !in achievementIds) {
                        result.error("invalid_achievement", "Unknown Atomic Orbital achievement.", null)
                    } else authenticated(result, "unlockAchievement", call.argument<String>("playerId")) {
                        PlayGames.getAchievementsClient(activity).unlockImmediate(id!!)
                            .addOnSuccessListener { result.success(null) }
                            .addOnFailureListener { fail(result, it, call.method) }
                            .addOnCanceledListener { cancelled(result) }
                    }
                }
                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            fail(result, error, call.method)
        }
    }

    private fun authenticated(result: MethodChannel.Result, operation: String, owner: String? = null, action: () -> Unit) {
        PlayGames.getGamesSignInClient(activity).isAuthenticated
            .addOnCompleteListener { task ->
                if (!task.isSuccessful) {
                    fail(result, task.exception, "$operation/authentication")
                } else if (!task.result.isAuthenticated) {
                    result.error("sign_in_required", "Sign in to Google Play Games to continue.", null)
                } else {
                    try {
                        if (owner == null) action()
                        else PlayGames.getPlayersClient(activity).currentPlayer
                            .addOnSuccessListener { player ->
                                if (player.playerId == owner) action()
                                else result.error("profile_changed", "Switch back to the original game profile to sync.", null)
                            }
                            .addOnFailureListener { fail(result, it, operation) }
                            .addOnCanceledListener { cancelled(result) }
                    } catch (error: Exception) {
                        fail(result, error, operation)
                    }
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun showIntent(task: Task<Intent>, result: MethodChannel.Result, operation: String) {
        task.addOnSuccessListener { intent ->
            try {
                // Required by PGS to establish the identity of the calling package.
                activity.startActivityForResult(intent, 9002)
                result.success(null)
            } catch (error: Exception) {
                fail(result, error, operation)
            }
        }.addOnFailureListener { fail(result, it, operation) }
            .addOnCanceledListener { cancelled(result) }
    }

    private fun cancelled(result: MethodChannel.Result) {
        result.error("play_games_cancelled", "Google Play Games request was cancelled.", null)
    }

    private fun fail(result: MethodChannel.Result, error: Exception?, operation: String) {
        val code = (error as? ApiException)?.statusCode
        val message = if (code == null) error?.javaClass?.simpleName ?: "Unknown failure"
            else GamesClientStatusCodes.getStatusCodeString(code)
        Log.w("AtomicOrbitalPGS", "operation=$operation status=$code message=$message")
        result.error(
            if (code == null) "play_games_failed" else "play_games_$code",
            error?.message ?: "Google Play Games could not complete the request.",
            if (code == null) null else mapOf("statusCode" to code)
        )
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
