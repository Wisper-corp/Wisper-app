package com.wisperuser.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    // Ensure the existing activity handles the new intent (CallKit accept)
    setIntent(intent)
  }
}
