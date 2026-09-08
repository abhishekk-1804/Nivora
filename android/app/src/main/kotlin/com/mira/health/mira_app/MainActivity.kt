package com.imyra.health.imyra_app

import io.flutter.embedding.android.FlutterFragmentActivity
import android.os.Bundle
import android.view.WindowManager

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // S-02 fix: FLAG_SECURE prevents screenshots, screen recording, and the
        // app appearing as a thumbnail in the Android recents screen.
        // This is the correct API — the previous intent.putExtra approach was a no-op.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }
}
