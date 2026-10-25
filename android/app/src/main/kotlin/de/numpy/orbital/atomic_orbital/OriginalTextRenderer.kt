package de.numpy.orbital.atomic_orbital

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import java.io.ByteArrayOutputStream
import kotlin.math.max

/** Cache the release's software Paint glyphs for gameplay Canvas drawing. */
class OriginalTextRenderer {
    fun render(arguments: Map<*, *>): Map<String, Any> {
        val items = arguments["items"] as? List<*>
            ?: throw IllegalArgumentException("Text items are required")
        require(items.size <= 160) { "Too many text stamps" }
        return mapOf("items" to items.map {
            renderItem(it as? Map<*, *>
                ?: throw IllegalArgumentException("Invalid text stamp"))
        })
    }

    private fun renderItem(item: Map<*, *>): Map<String, Any> {
        val key = item["key"] as? String
            ?: throw IllegalArgumentException("Text key is required")
        val text = item["text"] as? String
            ?: throw IllegalArgumentException("Text is required")
        val size = (item["sizePx"] as? Number)?.toFloat()
            ?: throw IllegalArgumentException("Text size is required")
        require(item["kind"] == "canvas") { "Only gameplay Canvas text is supported" }
        require(text.length <= 128 && size.isFinite() && size > 0 && size <= 1024)
        val paint = Paint().apply {
            color = (item["color"] as? Number)?.toInt() ?: Color.WHITE
            textSize = size
        }
        val bounds = Rect()
        paint.getTextBounds(text, 0, text.length, bounds)
        val pad = 2
        val originX = bounds.left - pad
        val originY = bounds.top - pad
        val width = max(1, bounds.width() + pad * 2)
        val height = max(1, bounds.height() + pad * 2)
        require(width in 1..8192 && height in 1..2048 && width.toLong() * height <= 8_388_608) {
            "Text stamp dimensions exceed the bitmap limit"
        }
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        try {
            Canvas(bitmap).drawText(text, -originX.toFloat(), -originY.toFloat(), paint)
            val bytes = ByteArrayOutputStream()
            require(bitmap.compress(Bitmap.CompressFormat.PNG, 100, bytes)) {
                "Cannot encode gameplay text stamp"
            }
            return mapOf("key" to key, "png" to bytes.toByteArray(),
                "originX" to originX, "originY" to originY)
        } finally {
            bitmap.recycle()
        }
    }
}
