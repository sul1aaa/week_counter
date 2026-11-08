package com.example.week_counter

import android.graphics.Bitmap
import android.graphics.BlurMaskFilter
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.SweepGradient
import android.util.DisplayMetrics
import kotlin.math.roundToInt
import kotlin.math.sqrt

/** The orb's liquid colours (surface highlight, main, deep), as in lib/ui/kit/orb.dart. */
enum class OrbMode(val surface: Int, val main: Int, val deep: Int) {
    /** Violet: the week is filling up. */
    Work(0xFFFF8AD8.toInt(), 0xFF9B6BFF.toInt(), 0xFF5B2FD6.toInt()),

    /** Lime: time off, draining back toward work. */
    Weekend(0xFF6FF2C7.toInt(), 0xFFE4FF7A.toInt(), 0xFF9EDB00.toInt()),

    /** Grey: nothing to count. */
    Paused(0xFFE6E3DD.toInt(), 0xFFC9C6C0.toInt(), 0xFF9C9890.toInt()),
}

/**
 * Draws the app's glass orb into a bitmap for the widget's ImageView: still, on dark glass,
 * as the in-app widget preview shows it. A port of `_OrbPainter` in lib/ui/kit/orb.dart with
 * the waves at rest.
 *
 * The drop shadow is left out. An ImageView can't draw past its bounds, and on the
 * near-black card the shadow doesn't show anyway.
 */
object OrbRenderer {

    /**
     * An orb [sizeDp] across. It's drawn at most at 3x to keep the bitmap small enough to
     * send to the launcher, and tagged so the ImageView still measures it as [sizeDp].
     */
    fun render(sizeDp: Int, density: Float, fill: Float, mode: OrbMode): Bitmap {
        val scale = density.coerceAtMost(3f)
        val px = (sizeDp * scale).roundToInt()
        val bitmap = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
        bitmap.density = (DisplayMetrics.DENSITY_DEFAULT * scale).roundToInt()
        paint(Canvas(bitmap), px.toFloat(), scale, fill.coerceIn(0f, 1f), mode)
        return bitmap
    }

    private fun paint(canvas: Canvas, w: Float, scale: Float, fill: Float, mode: OrbMode) {
        val r = w / 2
        val rect = RectF(0f, 0f, w, w)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        /** A Flutter `Alignment` coordinate inside the sphere's box. */
        fun at(a: Float) = r + a * r

        canvas.save()
        canvas.clipPath(Path().apply { addOval(rect, Path.Direction.CW) })

        // Glass body.
        paint.shader = LinearGradient(
            at(-0.34f), at(-0.94f), at(0.34f), at(0.94f),
            white(0.14f), 0x147864C8, Shader.TileMode.CLAMP,
        )
        canvas.drawRect(rect, paint)
        paint.shader = RadialGradient(
            at(-0.4f), at(-0.6f), 1.06f * w,
            intArrayOf(white(0.28f), white(0.04f)), floatArrayOf(0f, 0.55f), Shader.TileMode.CLAMP,
        )
        canvas.drawRect(rect, paint)

        // Liquid: a fainter back wave behind the front one.
        val top = (1 - fill) * w - 0.06f * w
        val bottom = top + 1.2f * w
        fun liquid(svgTop: Float, baseline: Float) = LinearGradient(
            0f, svgTop + (baseline - 10.5f) * w / 200, 0f, bottom,
            intArrayOf(mode.surface, mode.main, mode.deep), floatArrayOf(0f, 0.18f, 1f),
            Shader.TileMode.CLAMP,
        )
        canvas.saveLayerAlpha(rect, (0.55f * 255).roundToInt())
        paint.shader = liquid(top - 0.036f * w, 28f)
        canvas.drawPath(wave(w, top - 0.036f * w, 28f, 1f, bottom), paint)
        canvas.restore()
        paint.shader = liquid(top, 22f)
        canvas.drawPath(wave(w, top, 22f, 0f, bottom), paint)

        // Iridescent sheen, faded out toward the middle and the rim.
        canvas.saveLayer(rect, null)
        paint.shader = SweepGradient(
            r, r,
            intArrayOf(0x26FF8AD8, 0x007C4DF0, 0x1A6FF2C7, 0x00C8F53C, 0x26FF8AD8),
            floatArrayOf(0f, 0.3f, 0.5f, 0.72f, 1f),
        )
        canvas.drawRect(rect, paint)
        paint.shader = RadialGradient(
            r, r, w * sqrt(2f) / 2,
            intArrayOf(Color.BLACK, Color.TRANSPARENT), floatArrayOf(0.3f, 0.72f), Shader.TileMode.CLAMP,
        )
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_IN)
        canvas.drawRect(rect, paint)
        paint.xfermode = null
        canvas.restore()

        canvas.restore()

        // Rim: 1 dp, just inside the edge.
        paint.shader = null
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = scale
        paint.color = white(0.14f)
        canvas.drawCircle(r, r, r - scale / 2, paint)
        paint.style = Paint.Style.FILL

        // Highlights: a soft oval up left and a small glint down right.
        canvas.save()
        canvas.translate(0.35f * w, 0.21f * w)
        canvas.rotate(-24f)
        canvas.scale(0.17f * w, 0.11f * w)
        paint.shader = RadialGradient(
            0f, 0f, 1f,
            intArrayOf(white(0.95f), white(0f)), floatArrayOf(0f, 0.99f), Shader.TileMode.CLAMP,
        )
        canvas.drawCircle(0f, 0f, 1f, paint)
        canvas.restore()

        paint.shader = null
        paint.color = white(0.55f)
        paint.maskFilter = BlurMaskFilter(blurRadius(0.01f * w), BlurMaskFilter.Blur.NORMAL)
        canvas.save()
        canvas.translate(0.78f * w, 0.825f * w)
        canvas.rotate(-30f)
        canvas.drawOval(-0.06f * w, -0.035f * w, 0.06f * w, 0.035f * w, paint)
        canvas.restore()
    }

    /**
     * The prototype's SVG wave: an 800 × 240 box stretched over 2w × 1.2w, made of cubic
     * curves that meet the baseline vertically. [baseline] is in SVG units; [shift] is how
     * far along one period the wave has drifted.
     */
    private fun wave(w: Float, svgTop: Float, baseline: Float, shift: Float, bottom: Float): Path {
        val sx = w / 400
        val sy = w / 200
        val y = svgTop + baseline * sy
        val rise = 14 * sy
        val period = 200 * sx
        var x = -0.5f * w - shift * period
        val path = Path()
        path.moveTo(x, bottom)
        path.lineTo(x, y)
        repeat(5) {
            path.cubicTo(x + 50 * sx, y - rise, x + 100 * sx, y - rise, x + 100 * sx, y)
            path.cubicTo(x + 100 * sx, y + rise, x + 150 * sx, y + rise, x + period, y)
            x += period
        }
        path.lineTo(x, bottom)
        path.close()
        return path
    }

    private fun white(alpha: Float) = Color.argb((alpha * 255).roundToInt(), 255, 255, 255)

    /** Flutter blurs by sigma; Skia turns a BlurMaskFilter radius into sigma = 0.57735 r + 0.5. */
    private fun blurRadius(sigma: Float) = ((sigma - 0.5f) / 0.57735f).coerceAtLeast(0.5f)
}
