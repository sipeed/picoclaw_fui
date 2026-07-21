package com.sipeed.picoclaw

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val PERMISSION_REQUEST_CODE = 1001
    }

    private var methodChannel: PicoClawMethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        logIncomingIntent(intent)
        requestRequiredPermissions()
    }

    /**
     * Request runtime permissions that the service needs.
     *
     * - API 23–29: WRITE_EXTERNAL_STORAGE / READ_EXTERNAL_STORAGE are required
     *   to write workspace files to shared storage.
     * - API 30+:  MANAGE_EXTERNAL_STORAGE is handled in onResume() instead.
     * - READ_PHONE_STATE: required by Umeng analytics.
     *
     * On API < 23 all of these are granted at install time, so no prompt.
     */
    private fun requestRequiredPermissions() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        // API 30+ uses MANAGE_EXTERNAL_STORAGE (handled in onResume).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) return

        val needed = mutableListOf<String>()
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
            // WRITE_EXTERNAL_STORAGE is the only way to write to shared
            // storage on API 23–29.
            if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.WRITE_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED
            ) needed.add(android.Manifest.permission.WRITE_EXTERNAL_STORAGE)
            if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED
            ) needed.add(android.Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_PHONE_STATE)
            != PackageManager.PERMISSION_GRANTED
        ) needed.add(android.Manifest.permission.READ_PHONE_STATE)

        if (needed.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, needed.toTypedArray(), PERMISSION_REQUEST_CODE)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            for (i in permissions.indices) {
                val granted = grantResults.getOrElse(i) { PackageManager.PERMISSION_GRANTED }
                Log.d(TAG, "Permission ${permissions[i]}: ${if (granted == PackageManager.PERMISSION_GRANTED) "GRANTED" else "DENIED"}")
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = PicoClawMethodChannel(this, flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        logIncomingIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        // Android 11+ 需要 MANAGE_EXTERNAL_STORAGE 才能写 Downloads 目录。
        // 若未授予，跳转系统设置页引导用户开启（只弹一次，直到用户授予或主动拒绝）。
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
            !Environment.isExternalStorageManager()
        ) {
            try {
                startActivity(
                    Intent(
                        Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                )
            } catch (e: Exception) {
                startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        methodChannel?.dispose()
        methodChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun logIncomingIntent(intent: Intent?) {
        val data = intent?.data ?: return
        if (data.scheme == BuildConfig.PICOCLAW_UMENG_LINK_SCHEME) {
            Log.i(TAG, "Received Umeng link: $data")
        }
    }
}
