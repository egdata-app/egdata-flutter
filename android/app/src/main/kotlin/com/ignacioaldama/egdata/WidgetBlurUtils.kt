package com.ignacioaldama.egdata

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.renderscript.Allocation
import android.renderscript.Element
import android.renderscript.RenderScript
import android.renderscript.ScriptIntrinsicBlur
import android.util.Log

object WidgetBlurUtils {

    /** Apply blur effect to bitmap using RenderScript */
    fun applyBlur(context: Context, bitmap: Bitmap, radius: Float): Bitmap {
        val output = Bitmap.createBitmap(
            bitmap.width,
            bitmap.height,
            bitmap.config ?: Bitmap.Config.ARGB_8888
        )

        try {
            val rs = RenderScript.create(context)
            val input = Allocation.createFromBitmap(rs, bitmap)
            val outAlloc = Allocation.createFromBitmap(rs, output)

            val script = ScriptIntrinsicBlur.create(rs, Element.U8_4(rs))
            script.setRadius(radius.coerceIn(0f, 25f))
            script.setInput(input)
            script.forEach(outAlloc)

            outAlloc.copyTo(output)

            rs.destroy()
        } catch (e: Exception) {
            Log.e("WidgetBlurUtils", "Blur failed, using original: ${e.message}")
            return bitmap
        }

        return output
    }

    /** Adjust overall opacity of a bitmap */
    fun adjustBitmapOpacity(bitmap: Bitmap, opacity: Float): Bitmap {
        val output = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint().apply { alpha = (opacity * 255).toInt() }
        canvas.drawBitmap(bitmap, 0f, 0f, paint)
        return output
    }
}
