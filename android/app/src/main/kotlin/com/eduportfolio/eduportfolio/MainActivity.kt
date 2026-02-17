package com.eduportfolio.eduportfolio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.eduportfolio/media3"
    private lateinit var videoProcessor: Media3VideoProcessor

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        videoProcessor = Media3VideoProcessor(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "processVideo" -> {
                        val inputPath = call.argument<String>("inputPath")
                        val facesData = call.argument<List<Map<String, Any>>>("faces")

                        if (inputPath == null || facesData == null) {
                            result.error("INVALID_ARGS", "Missing inputPath or faces", null)
                            return@setMethodCallHandler
                        }

                        // Process video in background coroutine
                        CoroutineScope(Dispatchers.Main).launch {
                            try {
                                val outputPath = withContext(Dispatchers.IO) {
                                    videoProcessor.processVideoWithEmojis(inputPath, facesData)
                                }
                                result.success(outputPath)
                            } catch (e: Exception) {
                                result.error("PROCESSING_ERROR", e.message, e.stackTraceToString())
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
