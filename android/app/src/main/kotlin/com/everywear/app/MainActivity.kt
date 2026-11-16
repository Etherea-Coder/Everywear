package com.stylewise.app

import android.app.AlertDialog
import android.content.pm.ApplicationInfo
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.TimeZone
import org.json.JSONObject

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
                        "consumeStagingSmokeLoginCredentials" -> {
                            if (packageName != "com.stylewise.app.stagingtest") {
                                result.error(
                                    "WRONG_PACKAGE",
                                    "Runtime smoke credentials are restricted to the isolated staging-test package.",
                                    null
                                )
                                return@setMethodCallHandler
                            }

                            val credentialFile = File(
                                noBackupFilesDir,
                                "everywear_smoke_login_credentials.json"
                            )
                            try {
                                if (!credentialFile.isFile) {
                                    result.error(
                                        "CREDENTIALS_UNAVAILABLE",
                                        "Private staging smoke credentials were not provisioned.",
                                        null
                                    )
                                    return@setMethodCallHandler
                                }
                                val data = JSONObject(
                                    credentialFile.readText(Charsets.UTF_8)
                                )
                                val email = data.optString("login_email").trim()
                                val password = data.optString("login_password")
                                if (!credentialFile.delete()) {
                                    result.error(
                                        "CREDENTIALS_CLEANUP_FAILED",
                                        "Private staging smoke credentials could not be cleared.",
                                        null
                                    )
                                    return@setMethodCallHandler
                                }
                                if (email.isEmpty() || password.isEmpty() || data.length() != 2) {
                                    result.error(
                                        "CREDENTIALS_INVALID",
                                        "Private staging smoke credentials are invalid.",
                                        null
                                    )
                                } else {
                                    result.success(
                                        mapOf("email" to email, "password" to password)
                                    )
                                }
                            } catch (_: Exception) {
                                credentialFile.delete()
                                result.error(
                                    "CREDENTIALS_INVALID",
                                    "Private staging smoke credentials are invalid.",
                                    null
                                )
                            }
                        }
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
