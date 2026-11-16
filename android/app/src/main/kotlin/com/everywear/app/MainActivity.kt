package com.stylewise.app

import android.app.AlertDialog
import android.content.pm.ApplicationInfo
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity: FlutterFragmentActivity() {
    @Volatile private var activityResumed = false
    @Volatile private var windowFocused = false

    override fun onResume() {
        super.onResume()
        activityResumed = true
    }

    override fun onPause() {
        activityResumed = false
        super.onPause()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        windowFocused = hasFocus
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.everywear/system_timezone")
            .setMethodCallHandler { call, result ->
                if (call.method == "getTimeZoneName") {
                    result.success(TimeZone.getDefault().id)
                } else {
                    result.notImplemented()
                }
            }
        if ((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.everywear/ui_smoke_test")
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "isForeground" -> {
                            result.success(activityResumed && windowFocused && !isFinishing)
                        }
                        "confirmOwnerSessionCheckpoint" -> {
                            val checkpoint = call.argument<String>("checkpoint")
                            val content = when (checkpoint) {
                                "after_test_sign_in" -> Pair(
                                    "Normal Everywear check",
                                    "The isolated test app is signed in. Confirm normal Everywear still shows your signed-in screen before continuing."
                                )
                                "after_test_local_sign_out" -> Pair(
                                    "Local test sign-out check",
                                    "The isolated test app has signed out locally. Confirm normal Everywear still shows your signed-in screen before cleanup."
                                )
                                else -> null
                            }
                            if (content == null) {
                                result.error("INVALID_CHECKPOINT", "Unknown auth checkpoint.", null)
                            } else if (!activityResumed || !windowFocused || isFinishing) {
                                result.error("ACTIVITY_NOT_FOREGROUND", "Return to the test app before confirming.", null)
                            } else {
                                AlertDialog.Builder(this)
                                    .setTitle(content.first)
                                    .setMessage(content.second)
                                    .setPositiveButton("I checked — continue") { dialog, _ ->
                                        dialog.dismiss()
                                        result.success(true)
                                    }
                                    .setCancelable(false)
                                    .show()
                            }
                        }
                        else -> result.notImplemented()
                    }
                }
        }
    }
}
