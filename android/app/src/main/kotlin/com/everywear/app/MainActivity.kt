package com.stylewise.app

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
                    if (call.method == "isForeground") {
                        result.success(activityResumed && windowFocused && !isFinishing)
                    } else {
                        result.notImplemented()
                    }
                }
        }
    }
}
