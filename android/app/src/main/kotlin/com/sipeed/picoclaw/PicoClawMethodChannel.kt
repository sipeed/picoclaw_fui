package com.sipeed.picoclaw

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.sipeed.picoclaw.service.PicoClawService
import com.sipeed.picoclaw.util.HealthChecker
import java.io.File
import java.util.concurrent.Executor

/**
 * Flutter MethodChannel 桥接层，将 Kotlin 原生功能暴露给 Dart 端。
 *
 * 支持的方法：
 * - startService: 启动 PicoClaw 前台服务
 * - stopService: 停止 PicoClaw 前台服务
 * - getServiceStatus: 获取服务状态（isRunning, pid, lastLog）
 * - checkHealth: 检查 /health 端点
 * - getConfig: 读取 config.json 内容
 * - saveConfig: 保存 config.json 内容
 * - getFullLog: 获取完整日志
 * - setAutoStart: 设置开机自启
 * - getAutoStart: 获取开机自启设置
 * - getWebPort: 获取 Web Console 端口号
 */
class PicoClawMethodChannel(
    private val context: Context,
    flutterEngine: FlutterEngine
) {
    companion object {
        private const val TAG = "PicoClawMethodChannel"
        private const val CHANNEL_NAME = "com.sipeed.picoclaw/picoclaw"
        private const val PREF_NAME = "picoclaw_prefs"
        private const val KEY_AUTO_START = "auto_start"
    }

    // Copy a content:// URI to the app cache and return the absolute file path.
    private fun copyContentUriToCache(uriStr: String, fileName: String): String? {
        try {
            if (uriStr.isBlank()) return null
            val uri = android.net.Uri.parse(uriStr)
            val resolver = context.contentResolver
            resolver.openInputStream(uri).use { input ->
                if (input == null) return null
                val cacheDir = context.cacheDir
                val outFile = java.io.File(cacheDir, fileName)
                input.use { inp ->
                    outFile.outputStream().use { out ->
                        inp.copyTo(out)
                        out.flush()
                    }
                }
                return outFile.absolutePath
            }
        } catch (e: Exception) {
            Log.w(TAG, "copyContentUriToCache failed: ${e.message}")
            return null
        }
    }

    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
    private val healthChecker = HealthChecker()

    private fun getMainExecutor(): Executor {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            context.mainExecutor
        } else {
            val handler = Handler(Looper.getMainLooper())
            Executor { r -> handler.post(r) }
        }
    }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    try {
                        // 从参数中读取 publicMode，默认为 false
                        val args = call.argument<String>("args") ?: ""
                        val publicMode = args.contains("-public")
                        // 保存 publicMode 到 SharedPreferences
                        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
                        prefs.edit().putBoolean("public_mode", publicMode).apply()
                        Log.d(TAG, "Starting service with publicMode=$publicMode (args: $args)")
                        PicoClawService.start(context, publicMode)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("START_FAILED", e.message, null)
                    }
                }
                "getPublicMode" -> {
                    try {
                        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
                        result.success(prefs.getBoolean("public_mode", false))
                    } catch (e: Exception) {
                        result.error("GET_PUBLIC_MODE_FAILED", e.message, null)
                    }
                }
                "stopService" -> {
                    try {
                        PicoClawService.stop(context)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STOP_FAILED", e.message, null)
                    }
                }
                "getServiceStatus" -> {
                    result.success(mapOf(
                        "isRunning" to PicoClawService.isRunning,
                        "pid" to PicoClawService.processId,
                        "lastLog" to PicoClawService.lastLog
                    ))
                }
                "checkHealth" -> {
                    Thread {
                        val mainExecutor = getMainExecutor()

                        try {
                            val status = healthChecker.check()
                            val resultMap = mapOf(
                                "isHealthy" to status.isHealthy,
                                "status" to status.status,
                                "uptime" to status.uptime,
                                "pid" to status.pid,
                                "error" to (status.error ?: "")
                            )
                            mainExecutor.execute {
                                result.success(resultMap)
                            }
                        } catch (e: Exception) {
                            mainExecutor.execute {
                                result.error("HEALTH_CHECK_FAILED", e.message, null)
                            }
                        }
                    }.start()
                }
                "getConfig" -> {
                    try {
                        val configFile = File(context.filesDir, "picoclaw/config.json")
                        if (configFile.exists()) {
                            result.success(configFile.readText())
                        } else {
                            result.success("")
                        }
                    } catch (e: Exception) {
                        result.error("READ_CONFIG_FAILED", e.message, null)
                    }
                }
                "saveConfig" -> {
                    try {
                        val content = call.argument<String>("content") ?: ""
                        val configFile = File(context.filesDir, "picoclaw/config.json")
                        configFile.parentFile?.mkdirs()
                        configFile.writeText(content)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SAVE_CONFIG_FAILED", e.message, null)
                    }
                }
                "getFullLog" -> {
                    result.success(PicoClawService.lastLog)
                }
                "setAutoStart" -> {
                    try {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
                        prefs.edit().putBoolean(KEY_AUTO_START, enabled).apply()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SET_AUTO_START_FAILED", e.message, null)
                    }
                }
                "getAutoStart" -> {
                    try {
                        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
                        result.success(prefs.getBoolean(KEY_AUTO_START, false))
                    } catch (e: Exception) {
                        result.error("GET_AUTO_START_FAILED", e.message, null)
                    }
                }
                "getCoreVersion" -> {
                    Thread {
                        val mainExecutor = getMainExecutor()
                        try {
                            val version = PicoClawService.readCoreVersion(context)
                            mainExecutor.execute {
                                result.success(version)
                            }
                        } catch (e: Exception) {
                            Log.w(TAG, "getCoreVersion failed: ${e.message}", e)
                            mainExecutor.execute {
                                result.success("unknown")
                            }
                        }
                    }.start()
                }
                "getConfigPath" -> {
                    val configFile = File(context.filesDir, "picoclaw/config.json")
                    result.success(configFile.absolutePath)
                }
                "getHomePath" -> {
                    result.success(PicoClawService.getWorkspacePath(context))
                }
                "isStorageManagerGranted" -> {
                    val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        Environment.isExternalStorageManager()
                    } else {
                        true
                    }
                    result.success(granted)
                }
                "requestStorageManager" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        try {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                                Uri.parse("package:${context.packageName}")
                            )
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            context.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            // 部分设备不支持精确跳转，回退到通用页
                            val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            context.startActivity(intent)
                            result.success(true)
                        }
                    } else {
                        result.success(true) // 低版本无需此权限
                    }
                }
                "getPicoToken" -> {
                    result.success(PicoClawService.PICO_TOKEN)
                }
                "getSafeDeviceInfo" -> {
                    val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
                    val deviceCategory = if (context.resources.configuration.smallestScreenWidthDp >= 600) {
                        "Tablet"
                    } else {
                        "Mobile"
                    }
                    result.success(mapOf(
                        "deviceModel" to listOf(Build.MANUFACTURER, Build.MODEL)
                            .filter { it.isNotBlank() }
                            .joinToString(" ")
                            .trim(),
                        "osVersion" to "Android ${Build.VERSION.RELEASE}",
                        "deviceCategory" to deviceCategory,
                        "appVersion" to (packageInfo.versionName ?: "unknown")
                    ))
                }
                "setUmengAnalyticsConsent" -> {
                    try {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        AnalyticsReporter.submitConsent(context, enabled)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SET_UMENG_CONSENT_FAILED", e.message, null)
                    }
                }
                "uploadUmengDeviceReport" -> {
                    android.util.Log.d("PicoClawChannel", "=== uploadUmengDeviceReport called ===")
                    try {
                        val payload = call.arguments<Map<String, Any?>>() ?: emptyMap()
                        android.util.Log.d("PicoClawChannel", "Payload received with ${payload.size} fields")
                        val reportResult = AnalyticsReporter.uploadDeviceReport(context, payload)
                        android.util.Log.d("PicoClawChannel", "AnalyticsReporter returned: success=${reportResult["success"]}, message=${reportResult["message"]}")
                        result.success(reportResult)
                        android.util.Log.d("PicoClawChannel", "=== uploadUmengDeviceReport completed ===")
                    } catch (e: Exception) {
                        android.util.Log.e("PicoClawChannel", "uploadUmengDeviceReport failed: ${e.message}", e)
                        result.error("UPLOAD_UMENG_REPORT_FAILED", e.message, null)
                    }
                }
                "getWebPort" -> {
                    result.success(18800)
                }
                "saveToDownloads" -> {
                    // args: filename: String, bytes: Uint8List
                    try {
                        val filename = call.argument<String>("filename") ?: "picoclaw_logs.txt"
                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes == null) {
                            result.error("NO_BYTES", "No bytes provided", null)
                            return@setMethodCallHandler
                        }

                        val savedUriStr = saveToDownloads(filename, bytes)
                        result.success(savedUriStr)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                }
                "copyContentUriToCache" -> {
                    try {
                        val uriStr = call.argument<String>("uri") ?: ""
                        val name = call.argument<String>("filename") ?: "picoclaw_logs.txt"
                        val path = copyContentUriToCache(uriStr, name)
                        result.success(path)
                    } catch (e: Exception) {
                        result.error("COPY_FAILED", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    // Save bytes to Downloads using MediaStore (preferred for Android Q+).
    private fun saveToDownloads(fileName: String, data: ByteArray): String? {
        try {
            val resolver = context.contentResolver
            val values = android.content.ContentValues().apply {
                put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(android.provider.MediaStore.MediaColumns.MIME_TYPE, "text/plain")
                // Place in Downloads directory under Pictures (app-specific folder not required)
                put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH, android.os.Environment.DIRECTORY_DOWNLOADS)
            }

            val uri = resolver.insert(android.provider.MediaStore.Downloads.getContentUri(android.provider.MediaStore.VOLUME_EXTERNAL_PRIMARY), values)
                ?: return null

            resolver.openOutputStream(uri).use { out ->
                out?.write(data)
                out?.flush()
            }

            return uri.toString()
        } catch (e: Exception) {
            // For older devices, attempt fallback to legacy external storage path
            try {
                val downloads = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS)
                val dir = java.io.File(downloads, "picoclaw")
                if (!dir.exists()) dir.mkdirs()
                val f = java.io.File(dir, fileName)
                f.writeBytes(data)
                return f.absolutePath
            } catch (ex: Exception) {
                return null
            }
        }
    }
}
