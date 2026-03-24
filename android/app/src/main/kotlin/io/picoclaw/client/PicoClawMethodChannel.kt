package io.picoclaw.client

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.picoclaw.client.service.PicoClawService
import io.picoclaw.client.util.HealthChecker
import java.io.File

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
        private const val CHANNEL_NAME = "io.picoclaw.client/picoclaw"
        private const val PREF_NAME = "picoclaw_prefs"
        private const val KEY_AUTO_START = "auto_start"
    }

    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
    private val healthChecker = HealthChecker()

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
                        try {
                            val status = healthChecker.check()
                            val resultMap = mapOf(
                                "isHealthy" to status.isHealthy,
                                "status" to status.status,
                                "uptime" to status.uptime,
                                "pid" to status.pid,
                                "error" to (status.error ?: "")
                            )
                            context.mainExecutor.execute {
                                result.success(resultMap)
                            }
                        } catch (e: Exception) {
                            context.mainExecutor.execute {
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
                "getConfigPath" -> {
                    val configFile = File(context.filesDir, "picoclaw/config.json")
                    result.success(configFile.absolutePath)
                }
                "getPicoToken" -> {
                    result.success(PicoClawService.PICO_TOKEN)
                }
                "getWebPort" -> {
                    result.success(18800)
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
}
