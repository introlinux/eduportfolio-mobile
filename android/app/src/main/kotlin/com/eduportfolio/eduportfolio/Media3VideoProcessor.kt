package com.eduportfolio.eduportfolio

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import androidx.media3.common.MediaItem
import androidx.media3.common.OverlaySettings
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.OverlayEffect
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import java.io.File
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

/**
 * Processes videos using Media3 Transformer to add emoji overlays over detected faces.
 */
@UnstableApi
class Media3VideoProcessor(private val context: Context) {

    /**
     * Data class representing a face detection with position and timing.
     */
    data class FacePosition(
        val x: Float,           // X coordinate (0-1, normalized to video width)
        val y: Float,           // Y coordinate (0-1, normalized to video height)
        val width: Float,       // Width (0-1, normalized to video width)
        val height: Float,      // Height (0-1, normalized to video height)
        val startTimeMs: Long,  // Start time in milliseconds
        val endTimeMs: Long     // End time in milliseconds
    )

    /**
     * Process a video file by adding emoji overlays over detected faces.
     *
     * @param inputPath Path to the input video file
     * @param facesData List of face detections from Flutter (maps with x, y, width, height, startTimeMs, endTimeMs)
     * @return Path to the processed output video file
     */
    suspend fun processVideoWithEmojis(
        inputPath: String,
        facesData: List<Map<String, Any>>
    ): String = suspendCoroutine { continuation ->

        // Parse face data from Flutter
        val faces = facesData.mapNotNull { faceMap ->
            try {
                FacePosition(
                    x = (faceMap["x"] as? Number)?.toFloat() ?: return@mapNotNull null,
                    y = (faceMap["y"] as? Number)?.toFloat() ?: return@mapNotNull null,
                    width = (faceMap["width"] as? Number)?.toFloat() ?: return@mapNotNull null,
                    height = (faceMap["height"] as? Number)?.toFloat() ?: return@mapNotNull null,
                    startTimeMs = (faceMap["startTimeMs"] as? Number)?.toLong() ?: return@mapNotNull null,
                    endTimeMs = (faceMap["endTimeMs"] as? Number)?.toLong() ?: return@mapNotNull null
                )
            } catch (e: Exception) {
                null
            }
        }

        // If no faces detected, return original file
        if (faces.isEmpty()) {
            continuation.resume(inputPath)
            return@suspendCoroutine
        }

        // Generate emoji bitmap (we'll use the same emoji for all faces)
        val emojiBitmap = generateEmojiBitmap(200)

        // Create output file path
        val outputFile = File(context.cacheDir, "privacy_video_${System.currentTimeMillis()}.mp4")
        val outputPath = outputFile.absolutePath

        // Create custom overlay effect with all faces
        val overlayEffect = OverlayEffect(listOf(
            EmojiOverlay(emojiBitmap, faces)
        ))

        // Configure transformer
        val transformer = Transformer.Builder(context)
            .addListener(object : Transformer.Listener {
                override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                    continuation.resume(outputPath)
                }

                override fun onError(
                    composition: Composition,
                    exportResult: ExportResult,
                    exportException: ExportException
                ) {
                    continuation.resumeWithException(exportException)
                }
            })
            .build()

        // Create edited media item with video effects
        val mediaItem = MediaItem.fromUri(inputPath)
        val editedMediaItem = EditedMediaItem.Builder(mediaItem)
            .setEffects(Effects(/* audioProcessors= */ emptyList(), listOf(overlayEffect)))
            .build()

        // Start transformation
        transformer.start(editedMediaItem, outputPath)
    }

    /**
     * Custom BitmapOverlay that displays emojis over faces at specific times.
     */
    private inner class EmojiOverlay(
        private val emojiBitmap: Bitmap,
        private val faces: List<FacePosition>
    ) : BitmapOverlay() {

        override fun getBitmap(presentationTimeUs: Long): Bitmap {
            return emojiBitmap
        }

        override fun getOverlaySettings(presentationTimeUs: Long): OverlaySettings {
            val presentationTimeMs = presentationTimeUs / 1000

            // Find all faces that should be visible at this timestamp
            val visibleFaces = faces.filter { face ->
                presentationTimeMs in face.startTimeMs..face.endTimeMs
            }

            // If no faces visible, return invisible overlay
            if (visibleFaces.isEmpty()) {
                return OverlaySettings.Builder()
                    .setAlphaScale(0f)
                    .build()
            }

            // For simplicity, we'll show the first visible face
            // TODO: Support multiple overlays for multiple simultaneous faces
            val face = visibleFaces.first()

            // Calculate overlay position and size
            // The overlay anchor is at the center of the emoji bitmap
            // The background anchor is where to place the emoji on the video frame
            return OverlaySettings.Builder()
                .setOverlayFrameAnchor(0.5f, 0.5f)  // Center of emoji
                .setBackgroundFrameAnchor(
                    face.x + face.width / 2,  // Center X of face
                    face.y + face.height / 2  // Center Y of face
                )
                .setScale(
                    // Scale emoji to cover face with some padding
                    maxOf(face.width, face.height) * 1.3f
                )
                .setAlphaScale(1f)  // Fully opaque
                .build()
        }
    }

    /**
     * Generate a bitmap with an emoji character drawn on it.
     *
     * @param size Size of the bitmap in pixels
     * @return Bitmap containing the emoji
     */
    private fun generateEmojiBitmap(size: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Draw white circle background
        val backgroundPaint = Paint().apply {
            color = Color.WHITE
            isAntiAlias = true
            style = Paint.Style.FILL
        }
        canvas.drawCircle(size / 2f, size / 2f, size / 2f, backgroundPaint)

        // Draw emoji text
        val emojis = listOf("😊", "🙂", "😎", "🤗", "😺", "🐱", "🎭", "👤")
        val emoji = emojis.random()

        val textPaint = Paint().apply {
            color = Color.BLACK
            textSize = size * 0.7f
            isAntiAlias = true
            textAlign = Paint.Align.CENTER
        }

        // Calculate text position (centered)
        val textBounds = Rect()
        textPaint.getTextBounds(emoji, 0, emoji.length, textBounds)
        val x = size / 2f
        val y = size / 2f - textBounds.exactCenterY()

        canvas.drawText(emoji, x, y, textPaint)

        return bitmap
    }
}
