package com.eduportfolio.eduportfolio

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.common.OverlaySettings
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.StaticOverlaySettings
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

    companion object {
        private const val TAG = "Media3VideoProcessor"
    }

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

        Log.d(TAG, "processVideoWithEmojis called with inputPath=$inputPath, ${facesData.size} face entries")

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
                Log.e(TAG, "Error parsing face data: $e")
                null
            }
        }

        Log.d(TAG, "Parsed ${faces.size} valid faces from ${facesData.size} entries")
        faces.forEachIndexed { i, face ->
            Log.d(TAG, "  Face[$i]: pos=(${face.x}, ${face.y}) size=(${face.width}x${face.height}) time=${face.startTimeMs}-${face.endTimeMs}ms")
        }

        // If no faces detected, return original file
        if (faces.isEmpty()) {
            Log.d(TAG, "No valid faces, returning original file")
            continuation.resume(inputPath)
            return@suspendCoroutine
        }

        // Group faces by timestamp to handle multiple faces per frame
        // We assume faces sharing the same startTimeMs belong to the same frame
        val facesByTime = faces.groupBy { it.startTimeMs }
        
        // Find maximum number of concurrent faces
        val maxConcurrentFaces = facesByTime.values.maxOfOrNull { it.size } ?: 0
        Log.d(TAG, "Max concurrent faces: $maxConcurrentFaces")

        // Distribute faces into "tracks"
        // Track 0 gets the 1st face of every frame, Track 1 gets the 2nd, etc.
        // We sort by X coordinate to keep assignments somewhat stable across frames
        val tracks = List(maxConcurrentFaces) { ArrayList<FacePosition>() }

        facesByTime.entries.sortedBy { it.key }.forEach { (_, frameFaces) ->
            val sortedFaces = frameFaces.sortedBy { it.x }
            sortedFaces.forEachIndexed { index, face ->
                tracks[index].add(face)
            }
        }

        // Generate emoji bitmap
        val emojiBitmap = generateEmojiBitmap(200)
        Log.d(TAG, "Generated emoji bitmap: ${emojiBitmap.width}x${emojiBitmap.height}")

        // Create output file path
        val outputFile = File(context.cacheDir, "privacy_video_${System.currentTimeMillis()}.mp4")
        val outputPath = outputFile.absolutePath
        Log.d(TAG, "Output path: $outputPath")

        // Create one overlay per track. 
        // If we have 3 simultaneous faces, we need 3 EmojiOverlays.
        val overlays = tracks.map { trackFaces ->
            EmojiOverlay(emojiBitmap, trackFaces)
        }
        
        val overlayEffect = OverlayEffect(overlays)

        // Transformer.start() MUST be called on a thread with a Looper (main thread).
        // The listener callbacks are also delivered on the main thread.
        Handler(Looper.getMainLooper()).post {
            try {
                // Configure transformer
                val transformer = Transformer.Builder(context)
                    .addListener(object : Transformer.Listener {
                        override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                            Log.d(TAG, "Transformer COMPLETED successfully. Output: $outputPath")
                            continuation.resume(outputPath)
                        }

                        override fun onError(
                            composition: Composition,
                            exportResult: ExportResult,
                            exportException: ExportException
                        ) {
                            Log.e(TAG, "Transformer ERROR: ${exportException.message}", exportException)
                            continuation.resumeWithException(exportException)
                        }
                    })
                    .build()

                // Create edited media item with video effects
                // Use Uri.fromFile() to ensure proper file:// URI format
                val inputUri = Uri.fromFile(File(inputPath))
                Log.d(TAG, "Input URI: $inputUri")
                val mediaItem = MediaItem.fromUri(inputUri)
                val editedMediaItem = EditedMediaItem.Builder(mediaItem)
                    .setEffects(Effects(/* audioProcessors= */ emptyList(), listOf(overlayEffect)))
                    .build()

                // Start transformation on main thread
                Log.d(TAG, "Starting Transformer...")
                transformer.start(editedMediaItem, outputPath)
            } catch (e: Exception) {
                Log.e(TAG, "Error starting transformer: ${e.message}", e)
                continuation.resumeWithException(e)
            }
        }
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
                return StaticOverlaySettings.Builder()
                    .setAlphaScale(0f)
                    .build()
            }

            // Show the first visible face (BitmapOverlay supports one overlay at a time)
            val face = visibleFaces.first()

            // Convert from normalized (0-1) to NDC (-1..1) coordinates.
            // Media3 uses OpenGL NDC: center=(0,0), x: -1=left, +1=right, y: -1=bottom, +1=top
            // Flutter sends: x,y in 0-1 (top-left origin), width,height in 0-1
            val faceCenterX01 = face.x + face.width / 2   // 0-1, left-to-right
            val faceCenterY01 = face.y + face.height / 2  // 0-1, top-to-bottom

            val ndcX = faceCenterX01 * 2f - 1f            // 0→-1, 0.5→0, 1→+1
            val ndcY = -(faceCenterY01 * 2f - 1f)         // 0→+1 (top), 1→-1 (bottom)

            Log.d(TAG, "Overlay at t=${presentationTimeMs}ms: norm=($faceCenterX01, $faceCenterY01) NDC=($ndcX, $ndcY) scale=${maxOf(face.width, face.height) * 2.0f}")

            return StaticOverlaySettings.Builder()
                .setOverlayFrameAnchor(0f, 0f)  // Center of emoji bitmap
                .setBackgroundFrameAnchor(ndcX, ndcY)
                .setScale(
                    // Scale emoji to cover face with good margin (2.0x instead of 1.3x)
                    maxOf(face.width, face.height) * 2.0f,
                    maxOf(face.width, face.height) * 2.0f
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

        // Draw emoji text - use a fixed emoji for consistency
        val emoji = "😊"

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
