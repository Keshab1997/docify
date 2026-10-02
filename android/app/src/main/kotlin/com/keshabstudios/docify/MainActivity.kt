package com.keshabstudios.docify

import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

// local_auth needs a FragmentActivity for the system fingerprint/PIN prompt.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.keshabstudios.docify/documents").setMethodCallHandler { call, result ->
            when (call.method) {
                "pdfPageCount" -> Thread {
                    try {
                        val file = checkedPath(call)
                        val count = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
                            PdfRenderer(descriptor).use { renderer -> renderer.pageCount }
                        }
                        runOnUiThread { result.success(count) }
                    } catch (_: Exception) {
                        runOnUiThread { result.error("PDF_UNAVAILABLE", "Could not read this PDF.", null) }
                    }
                }.start()
                "recogniseText" -> Thread {
                    try {
                        val file = checkedPath(call)
                        val image = InputImage.fromFilePath(this, Uri.fromFile(file))
                        val recogniser = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                        recogniser.process(image)
                            .addOnSuccessListener { text ->
                                recogniser.close()
                                runOnUiThread { result.success(text.text) }
                            }
                            .addOnFailureListener {
                                recogniser.close()
                                runOnUiThread { result.error("OCR_UNAVAILABLE", "Could not recognise this image.", null) }
                            }
                    } catch (_: Exception) {
                        runOnUiThread { result.error("OCR_UNAVAILABLE", "Could not read this image.", null) }
                    }
                }.start()
                else -> result.notImplemented()
            }
        }
    }

    // Only files inside this app's private data directory can reach native APIs.
    private fun checkedPath(call: MethodCall): File {
        val path = call.argument<String>("path") ?: throw IllegalArgumentException("Missing path")
        val file = File(path).canonicalFile
        val root = File(applicationInfo.dataDir).canonicalPath + File.separator
        require(file.path.startsWith(root) && file.isFile) { "Not a private app file" }
        return file
    }
}
