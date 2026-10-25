package de.numpy.orbital.atomic_orbital

import android.content.ActivityNotFoundException
import android.content.Intent
import android.app.Activity
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import android.net.Uri
import android.os.Build
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var soundPool: SoundPool? = null
    private val sounds = mutableMapOf<String, Int>()
    private var playGames: PlayGamesBridge? = null
    private var documentResult: MethodChannel.Result? = null
    private var documentContents: ByteArray? = null
    private val documentIo = Executors.newSingleThreadExecutor()
    private val maximumSaveBytes = 1024 * 1024

    @Suppress("DEPRECATION")
    private fun pickSave(export: Boolean, contents: String?, result: MethodChannel.Result) {
        if (documentResult != null) {
            result.error("busy", "A save file is already open.", null)
            return
        }
        val bytes = contents?.toByteArray(Charsets.UTF_8)
        if (export && (bytes == null || bytes.size > maximumSaveBytes)) {
            result.error("invalid_save", "Invalid save file.", null)
            return
        }
        documentResult = result
        documentContents = bytes
        val intent = Intent(if (export) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/json"
            if (export) putExtra(Intent.EXTRA_TITLE, "atomic-orbital-save.json")
        }
        try { startActivityForResult(intent, if (export) 9401 else 9402) }
        catch (error: Exception) {
            documentResult = null
            documentContents = null
            result.error("save_file_failed", error.localizedMessage, null)
        }
    }

    @Deprecated("The Flutter activity forwards document picker results through this callback.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != 9401 && requestCode != 9402) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = documentResult ?: return
        val contents = documentContents
        val exporting = requestCode == 9401
        documentResult = null
        documentContents = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(if (exporting) false else null)
            return
        }
        documentIo.execute {
            try {
                val answer: Any = if (exporting) {
                    val output = contentResolver.openOutputStream(uri, "wt")
                        ?: throw IllegalStateException("Cannot open save destination.")
                    output.use { it.write(contents ?: throw IllegalStateException("Missing save.")) }
                    true
                } else {
                    val bytes = ByteArrayOutputStream()
                    val input = contentResolver.openInputStream(uri)
                        ?: throw IllegalStateException("Cannot open selected save.")
                    input.use { stream ->
                        val buffer = ByteArray(8192)
                        while (true) {
                            val count = stream.read(buffer)
                            if (count < 0) break
                            if (bytes.size() + count > maximumSaveBytes) throw IllegalArgumentException("Save file is too large.")
                            bytes.write(buffer, 0, count)
                        }
                    }
                    Charsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT)
                        .decode(ByteBuffer.wrap(bytes.toByteArray())).toString()
                }
                runOnUiThread { result.success(answer) }
            } catch (error: Exception) {
                runOnUiThread { result.error("save_file_failed", error.localizedMessage, null) }
            }
        }
    }

    private fun loadSoundEffects(result: MethodChannel.Result) {
        soundPool?.release()
        sounds.clear()
        val pool = SoundPool.Builder().setMaxStreams(10)
            .setAudioAttributes(AudioAttributes.Builder()
                .setLegacyStreamType(AudioManager.STREAM_MUSIC).build())
            .build()
        soundPool = pool
        var pending = 3
        var completed = false
        pool.setOnLoadCompleteListener { _, _, status ->
            if (!completed) {
                if (status != 0) {
                    completed = true
                    result.error("sound_load_failed", "Cannot load original sound effects.", null)
                } else if (--pending == 0) {
                    completed = true
                    result.success(null)
                }
            }
        }
        sounds["hit"] = pool.load(this, R.raw.hit, 0)
        sounds["collect"] = pool.load(this, R.raw.collect, 0)
        sounds["shoot"] = pool.load(this, R.raw.shoot, 0)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        playGames = PlayGamesBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        val originalText = OriginalTextRenderer()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "atomic_orbital/platform")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "exportSave" -> pickSave(true, call.argument<String>("contents"), result)
                    "importSave" -> pickSave(false, null, result)
                    "renderOriginalText" -> {
                        try {
                            val arguments = call.arguments as? Map<*, *>
                                ?: throw IllegalArgumentException("Text arguments are required")
                            result.success(originalText.render(arguments))
                        } catch (error: IllegalArgumentException) {
                            result.error("invalid_text", error.message, null)
                        }
                    }
                    "loadSoundEffects" -> loadSoundEffects(result)
                    "playSoundEffect" -> {
                        val sample = sounds[call.argument<String>("name")]
                        if (sample == null) {
                            result.error("invalid_sound", "Unknown sound effect.", null)
                        } else {
                            soundPool?.play(sample, 1f, 1f, 0, 0, 1f)
                            result.success(null)
                        }
                    }
                    "disposeSoundEffects" -> {
                        soundPool?.release()
                        soundPool = null
                        sounds.clear()
                        result.success(null)
                    }
                    "noAds" -> {
                        Toast.makeText(this, "The app is already ad-free", Toast.LENGTH_SHORT).show()
                        result.success(null)
                    }
                    "playGamesDisconnected" -> {
                        Toast.makeText(this, call.argument<String>("message") ?: "Playing offline", Toast.LENGTH_SHORT).show()
                        result.success(null)
                    }
                    "appInfo" -> {
                        val info = packageManager.getPackageInfo(packageName, 0)
                        @Suppress("DEPRECATION")
                        val code = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
                        result.success(mapOf("version" to info.versionName, "build" to code.toString()))
                    }
                    "openUrl" -> {
                        val uri = call.argument<String>("url")?.let(Uri::parse)
                        if (uri == null || uri.scheme != "https" || uri.host != "marvinmaerz.com" ||
                            uri.path !in setOf("/atomic-orbital/privacy/", "/atomic-orbital/support/", "/atomic-orbital/delete-data/") ||
                            uri.query != null || uri.fragment != null || uri.userInfo != null) {
                            result.error("invalid_url", "Unknown support link.", null)
                        } else try {
                            startActivity(Intent(Intent.ACTION_VIEW, uri))
                            result.success(null)
                        } catch (_: ActivityNotFoundException) {
                            result.error("unavailable", "No browser is available.", null)
                        }
                    }
                    "rate" -> {
                        val packageId = "de.numpy.orbital.orbital4"
                        try {
                            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageId")))
                        } catch (_: ActivityNotFoundException) {
                            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$packageId")))
                        }
                        result.success(null)
                    }
                    "share" -> {
                        val score = call.argument<Int>("score")
                        if (score == null || score < 0) {
                            result.error("invalid_score", "A nonnegative score is required.", null)
                        } else {
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_TEXT, (call.argument<String>("message")?.take(1000) ?: "I got $score points in Atomic Orbital. Can you do better?") + " https://play.google.com/store/apps/details?id=de.numpy.orbital.orbital4")
                            }
                            startActivity(Intent.createChooser(intent, "Select"))
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        documentResult?.error("save_file_failed", "The game window was closed.", null)
        documentResult = null
        documentContents = null
        documentIo.shutdown()
        playGames?.dispose()
        playGames = null
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }
}
