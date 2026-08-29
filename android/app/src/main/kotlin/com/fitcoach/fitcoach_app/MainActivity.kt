package com.fitcoach.fitcoach_app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Oplus/ColorOS devices can deliver the same activity result twice
    // (e.g. request 69 = UCrop crop result). The second delivery re-replies to an
    // already-submitted Flutter MethodChannel result and crashes with
    // "Reply already submitted". Deduplicate at the activity boundary so the engine
    // only ever sees the first delivery. Static so it also survives activity
    // recreation, which resets instance fields.
    private companion object {
        @Volatile
        private var lastCropResultTime: Long = 0L
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == 69) {
            val now = System.currentTimeMillis()
            synchronized(this) {
                if (now - lastCropResultTime < 2000L) {
                    return // duplicate delivery of the same crop result - swallow it
                }
                lastCropResultTime = now
            }
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
