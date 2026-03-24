package io.picoclaw.client.service

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import io.picoclaw.client.PicoClawApp
import io.picoclaw.client.MainActivity
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.InputStreamReader
import java.util.zip.ZipFile

class PicoClawService : Service() {

    companion object {
        private const val TAG = "PicoClawService"
        private const val NOTIFICATION_ID = 1
        private const val GATEWAY_BINARY_NAME = "libpicoclaw.so"
        private const val WEB_BINARY_NAME = "libpicoclaw-web.so"
        private const val GATEWAY_PORT = 18790
        private const val WEB_PORT = 18800
        // 本地 Pico Channel 认证 token（仅用于 loopback 通信）
        const val PICO_TOKEN = "picoclaw-android-local"

        const val ACTION_START = "io.picoclaw.client.action.START"
        const val ACTION_STOP = "io.picoclaw.client.action.STOP"
        const val EXTRA_PUBLIC_MODE = "public_mode"

        // 共享状态供 UI 读取
        @Volatile
        var isRunning = false
            private set

        @Volatile
        var lastLog = ""
            private set

        @Volatile
        var processId: Int = -1
            private set

        fun start(context: Context, publicMode: Boolean = false) {
            val intent = Intent(context, PicoClawService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_PUBLIC_MODE, publicMode)
            }
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            val intent = Intent(context, PicoClawService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }

    private var process: Process? = null
    private var serviceThread: Thread? = null
    private var logThread: Thread? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val logBuffer = StringBuilder()
    private val maxLogSize = 64 * 1024 // 64KB 日志缓冲
    private val serviceLock = Object() // 保护启动/停止并发
    @Volatile
    private var stopped = false // 用于通知运行中的线程应该停止
    @Volatile
    private var publicMode = false // 是否启用公共模式（监听所有接口）
    private var restartCount = 0
    private val maxRestartAttempts = 3 // 最大重启次数

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopService()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                // 从 Intent 读取 publicMode 参数
                publicMode = intent?.getBooleanExtra(EXTRA_PUBLIC_MODE, false) ?: false
                startForeground(NOTIFICATION_ID, createNotification("Starting..."))
                acquireWakeLock()
                startService()
                return START_STICKY
            }
        }
    }

    override fun onDestroy() {
        stopService()
        releaseWakeLock()
        isRunning = false
        Log.i(TAG, "Service destroyed")
        super.onDestroy()
    }

    // --- 核心逻辑 ---

    private fun startService() {
        synchronized(serviceLock) {
            // 防止重复启动
            if (serviceThread?.isAlive == true || process?.isAlive == true) {
                Log.w(TAG, "Service is already starting or running, ignoring duplicate start request")
                return
            }
            stopped = false
            restartCount = 0

            serviceThread = Thread {
                try {
                    val gatewayBinary = getGatewayBinaryFile()
                    testBinary(gatewayBinary)
                    ensureOnboarded(gatewayBinary)
                    // 启动前先清理可能残留的旧进程
                    killPicoClawOrphanProcesses()
                    runWebService()
                } catch (e: Exception) {
                    if (!stopped) {
                        Log.e(TAG, "Failed to start service", e)
                        lastLog = "Error: ${e.message}"
                        updateNotification("Error: ${e.message}")
                    }
                }
            }.also { it.start() }
        }
    }

    /**
     * 测试 gateway 二进制是否可执行
     */
    private fun testBinary(binaryFile: File) {
        Log.i(TAG, "Testing binary at ${binaryFile.absolutePath}...")
        val env = buildEnvironment()

        val pb = ProcessBuilder(binaryFile.absolutePath, "version")
            .directory(filesDir)
            .redirectErrorStream(true)
        pb.environment().putAll(env)

        try {
            val proc = pb.start()
            val output = proc.inputStream.bufferedReader().readText()
            val exitCode = proc.waitFor()
            Log.i(TAG, "Binary test: exit=$exitCode, output=$output")

            if (exitCode != 0) {
                throw RuntimeException(
                    "picoclaw binary test failed (exit $exitCode): $output"
                )
            }
        } catch (e: java.io.IOException) {
            throw RuntimeException(
                "Cannot execute picoclaw binary at ${binaryFile.absolutePath}: ${e.message}", e
            )
        }
    }

    /**
     * 从 app 的 native library 目录获取 gateway 二进制（用于 onboard 初始化和传递给 web 服务）
     * 如果 nativeLibraryDir 中没有，尝试从 APK 中提取
     */
    private fun getGatewayBinaryFile(): File {
        val nativeLibDir = applicationInfo.nativeLibraryDir
        val binaryFile = File(nativeLibDir, GATEWAY_BINARY_NAME)

        if (binaryFile.exists()) {
            Log.i(TAG, "Using gateway binary from nativeLibraryDir: ${binaryFile.absolutePath}")
            return binaryFile
        }

        // 尝试从 APK 中提取
        Log.w(TAG, "Binary not found in nativeLibraryDir, trying to extract from APK")
        val extractedFile = extractBinaryFromApk(GATEWAY_BINARY_NAME)
        if (extractedFile != null) {
            Log.i(TAG, "Using extracted gateway binary: ${extractedFile.absolutePath}")
            return extractedFile
        }

        throw RuntimeException(
            "picoclaw binary not found. " +
            "Tried: ${binaryFile.absolutePath} and APK extraction. " +
            "Ensure libpicoclaw.so is placed in jniLibs/arm64-v8a/"
        )
    }

    /**
     * 从 app 的 native library 目录获取 web console 二进制
     * 如果 nativeLibraryDir 中没有，尝试从 APK 中提取
     */
    private fun getWebBinaryFile(): File {
        val nativeLibDir = applicationInfo.nativeLibraryDir
        val binaryFile = File(nativeLibDir, WEB_BINARY_NAME)

        if (binaryFile.exists()) {
            Log.i(TAG, "Using web binary from nativeLibraryDir: ${binaryFile.absolutePath}")
            return binaryFile
        }

        // 尝试从 APK 中提取
        Log.w(TAG, "Web binary not found in nativeLibraryDir, trying to extract from APK")
        val extractedFile = extractBinaryFromApk(WEB_BINARY_NAME)
        if (extractedFile != null) {
            Log.i(TAG, "Using extracted web binary: ${extractedFile.absolutePath}")
            return extractedFile
        }

        throw RuntimeException(
            "picoclaw-web binary not found. " +
            "Tried: ${binaryFile.absolutePath} and APK extraction. " +
            "Ensure libpicoclaw-web.so is placed in jniLibs/arm64-v8a/"
        )
    }

    /**
     * 运行 `picoclaw onboard` 初始化配置和工作区
     */
    private fun ensureOnboarded(binaryFile: File) {
        val picoHome = File(filesDir, "picoclaw")
        val configFile = File(picoHome, "config.json")

        if (configFile.exists()) {
            Log.i(TAG, "Config already exists, skipping onboard")
            ensurePicoChannelEnabled(configFile)
            return
        }

        Log.i(TAG, "Running onboard...")
        updateNotification("Initializing...")

        val env = buildEnvironment()

        val pb = ProcessBuilder(binaryFile.absolutePath, "onboard")
            .directory(filesDir)
            .redirectErrorStream(true)

        pb.environment().putAll(env)

        val proc = pb.start()
        val output = proc.inputStream.bufferedReader().readText()
        val exitCode = proc.waitFor()

        Log.i(TAG, "Onboard exit code: $exitCode, output: $output")

        if (exitCode != 0) {
            throw RuntimeException("Onboard failed (exit $exitCode): $output")
        }

        ensurePicoChannelEnabled(configFile)
    }

    /**
     * 确保启用 Pico Channel
     */
    private fun ensurePicoChannelEnabled(configFile: File) {
        try {
            if (!configFile.exists()) return

            val json = org.json.JSONObject(configFile.readText())
            val channels = json.optJSONObject("channels") ?: return
            val pico = channels.optJSONObject("pico") ?: return

            if (pico.optBoolean("enabled", false) && pico.optString("token", "").isNotEmpty()) {
                Log.i(TAG, "Pico channel already enabled")
                return
            }

            val token = PICO_TOKEN
            pico.put("enabled", true)
            pico.put("token", token)
            channels.put("pico", pico)
            json.put("channels", channels)

            configFile.writeText(json.toString(2))
            Log.i(TAG, "Pico channel enabled in config.json")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to enable Pico channel: ${e.message}", e)
        }
    }

    /**
     * 运行 web 服务进程（libpicoclaw-web.so）
     * web 服务会通过 TryAutoStartGateway() 自动启动并管理 gateway
     */
    private fun runWebService() {
        // 检查是否已被要求停止
        if (stopped) {
            Log.i(TAG, "Service was stopped, aborting web service start")
            return
        }

        val webBinaryFile = getWebBinaryFile()
        val configFile = File(filesDir, "picoclaw/config.json")
        val env = buildEnvironment()

        val cmdList = mutableListOf(
            webBinaryFile.absolutePath,
            "--console",
            "--no-browser"
        )
        
        // 只有在公共模式开启时才添加 -public 参数
        if (publicMode) {
            cmdList.add("-public")
            Log.i(TAG, "Public mode enabled, adding -public flag")
        } else {
            Log.i(TAG, "Public mode disabled, service will listen on localhost only")
        }
        
        cmdList.addAll(listOf("-port", WEB_PORT.toString(), configFile.absolutePath))
        
        val pb = ProcessBuilder(cmdList)
            .directory(filesDir)
            .redirectErrorStream(true)

        pb.environment().putAll(env)

        Log.i(TAG, "Starting web service on port $WEB_PORT...")
        updateNotification("Starting web service...")

        val proc = pb.start()
        synchronized(serviceLock) {
            if (stopped) {
                // 在启动后立刻被停止，杀掉刚启动的进程
                Log.i(TAG, "Service stopped during startup, killing new process")
                proc.destroyForcibly()
                return
            }
            process = proc
            isRunning = true
        }

        processId = try {
            val pidField = proc.javaClass.getDeclaredField("pid")
            pidField.isAccessible = true
            pidField.getInt(proc)
        } catch (e: Exception) {
            -1
        }

        updateNotification("Running (PID: $processId)")
        Log.i(TAG, "Web service started with PID: $processId, listening on port $WEB_PORT")

        // 后台线程读取 stdout/stderr
        logThread = Thread({
            try {
                val reader = BufferedReader(InputStreamReader(proc.inputStream))
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    val logLine = line ?: continue
                    Log.d(TAG, logLine)
                    appendLog(logLine)
                }
            } catch (e: Exception) {
                if (!stopped) {
                    Log.w(TAG, "Log reader interrupted", e)
                }
            }
        }, "picoclaw-web-log-reader").apply {
            isDaemon = true
            start()
        }

        // 等待进程退出（阻塞）
        val exitCode = proc.waitFor()
        isRunning = false
        processId = -1

        try { logThread?.join(2000) } catch (_: InterruptedException) {}

        // 如果是被主动停止的，不需要重启
        if (stopped) {
            Log.i(TAG, "Web service exited due to stop request (code $exitCode)")
            return
        }

        val lastOutput = logBuffer.toString().takeLast(500)
        Log.w(TAG, "Web service exited with code: $exitCode, last output: $lastOutput")
        lastLog = "Process exited (code $exitCode)\n$lastOutput"
        updateNotification("Stopped (exit code $exitCode)")

        // 非正常退出时自动重启（限制重试次数）
        if (exitCode != 0) {
            restartCount++
            if (restartCount > maxRestartAttempts) {
                Log.e(TAG, "Web service has failed $restartCount times, giving up restart")
                lastLog = "Service crashed $restartCount times, stopped retrying"
                updateNotification("Error: too many restarts")
                return
            }
            Log.i(TAG, "Scheduling restart in 5 seconds... (attempt $restartCount/$maxRestartAttempts)")
            // 清理可能残留的占用端口的进程
            killPicoClawOrphanProcesses()
            Thread.sleep(5000)
            // 再次检查是否被要求停止
            if (stopped) {
                Log.i(TAG, "Service was stopped during restart wait, aborting")
                return
            }
            runWebService()
        }
    }

    /**
     * 从 APK 中提取二进制文件到 filesDir
     * 用于某些设备（特别是 TV）so 文件没有被自动解压到 nativeLibraryDir 的情况
     */
    private fun extractBinaryFromApk(binaryName: String): File? {
        try {
            val abi = android.os.Build.SUPPORTED_ABIS.firstOrNull() ?: "arm64-v8a"
            val zipEntryPath = "lib/$abi/$binaryName"
            val outputFile = File(filesDir, binaryName)

            // 如果已经提取过了，直接返回
            if (outputFile.exists() && outputFile.canExecute()) {
                Log.i(TAG, "Using cached binary: ${outputFile.absolutePath}")
                return outputFile
            }

            // 获取 APK 路径
            val apkPath = applicationInfo.sourceDir
            Log.i(TAG, "Extracting $binaryName from APK: $apkPath (entry: $zipEntryPath)")

            ZipFile(apkPath).use { zipFile ->
                val entry = zipFile.getEntry(zipEntryPath)
                    ?: zipFile.getEntry("lib/arm64-v8a/$binaryName")
                    ?: zipFile.getEntry("lib/armeabi-v7a/$binaryName")
                    ?: return null

                zipFile.getInputStream(entry).use { input ->
                    FileOutputStream(outputFile).use { output ->
                        input.copyTo(output)
                    }
                }
            }

            // 设置可执行权限
            outputFile.setExecutable(true)
            Log.i(TAG, "Successfully extracted $binaryName to ${outputFile.absolutePath}")
            return outputFile

        } catch (e: Exception) {
            Log.e(TAG, "Failed to extract $binaryName from APK", e)
            return null
        }
    }

    /**
     * 杀掉属于当前应用的所有 picoclaw 残留子进程。
     *
     * 通过 UID 匹配（而非 ppid），因为 force-stop 后 app 重启 PID 会变，
     * 旧的孤儿进程的 ppid 可能已变为 1（被 init 收养），无法通过 ppid 找到。
     */
    private fun killPicoClawOrphanProcesses() {
        try {
            val myPid = android.os.Process.myPid()
            val myUid = android.os.Process.myUid()
            val procDir = File("/proc")
            procDir.listFiles()?.forEach { pidDir ->
                val pid = pidDir.name.toIntOrNull() ?: return@forEach
                if (pid == myPid) return@forEach // 不杀自己
                try {
                    // 通过 /proc/<pid>/status 读取进程的 UID
                    val statusFile = File(pidDir, "status")
                    if (!statusFile.canRead()) return@forEach
                    val statusContent = statusFile.readText()

                    // 解析 Uid 行：Uid:\t<real>\t<effective>\t<saved>\t<filesystem>
                    val uidLine = statusContent.lineSequence()
                        .firstOrNull { it.startsWith("Uid:") } ?: return@forEach
                    val uidFields = uidLine.substringAfter("Uid:").trim().split(Regex("\\s+"))
                    val processUid = uidFields.firstOrNull()?.toIntOrNull() ?: return@forEach

                    // 只处理属于同一 UID（同一应用）的进程
                    if (processUid != myUid) return@forEach

                    // 检查 cmdline 是否包含 picoclaw
                    val cmdlineFile = File(pidDir, "cmdline")
                    if (!cmdlineFile.canRead()) return@forEach
                    val cmdline = cmdlineFile.readText()
                    if (!cmdline.contains("picoclaw")) return@forEach

                    Log.i(TAG, "Killing orphan picoclaw process: PID=$pid, UID=$processUid, cmd=$cmdline")
                    android.os.Process.killProcess(pid)
                } catch (e: Exception) {
                    // 忽略无权限的进程
                }
            }
            Log.i(TAG, "Cleaned up orphan picoclaw processes")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to cleanup orphan processes: ${e.message}")
        }
    }

    /**
     * 停止服务（web 进程会在退出时自动停止其管理的 gateway）
     */
    private fun stopService() {
        Log.i(TAG, "Stopping service...")

        synchronized(serviceLock) {
            // 设置停止标志，通知所有运行中的线程
            stopped = true

            process?.let { proc ->
                try {
                    proc.destroy()

                    val thread = Thread {
                        try {
                            proc.waitFor()
                        } catch (_: InterruptedException) {
                        }
                    }
                    thread.start()
                    thread.join(10_000)

                    if (proc.isAlive) {
                        Log.w(TAG, "Force killing web service process")
                        proc.destroyForcibly()
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error stopping web service process", e)
                }
            }

            process = null
            isRunning = false
            processId = -1

            logThread?.interrupt()
            logThread = null
        }

        // 等待服务线程退出
        serviceThread?.let { thread ->
            try {
                thread.join(5_000)
            } catch (_: InterruptedException) {}
        }
        serviceThread = null

        // 清理可能残留的孤儿进程（包括 web 服务自己启动的 gateway）
        killPicoClawOrphanProcesses()

        // 重置重启计数
        restartCount = 0

        Log.i(TAG, "Service stopped and cleaned up")
    }

    // --- 环境变量 ---

    /**
     * 构建子进程环境变量
     * 关键：设置 PICOCLAW_BINARY 指向 gateway 二进制，让 web 服务能找到并启动 gateway
     */
    private fun buildEnvironment(): Map<String, String> {
        val picoHome = File(filesDir, "picoclaw")
        picoHome.mkdirs()

        val tmpDir = File(cacheDir, "tmp")
        tmpDir.mkdirs()

        // 使用 getGatewayBinaryFile() 确保获取正确的路径（包括从 APK 提取的情况）
        val gatewayBinaryPath = try {
            getGatewayBinaryFile().absolutePath
        } catch (e: Exception) {
            // 如果获取失败，使用默认路径
            File(applicationInfo.nativeLibraryDir, GATEWAY_BINARY_NAME).absolutePath
        }
        val configPath = File(picoHome, "config.json").absolutePath

        return mapOf(
            "HOME" to filesDir.absolutePath,
            "PICOCLAW_HOME" to picoHome.absolutePath,
            "PICOCLAW_CONFIG" to configPath,
            "PICOCLAW_BINARY" to gatewayBinaryPath,
            "TMPDIR" to tmpDir.absolutePath,
            "PATH" to "/system/bin:/system/xbin",
            "LANG" to "en_US.UTF-8",
            "SSL_CERT_DIR" to "/system/etc/security/cacerts",
        )
    }

    // --- 通知 ---

    private fun createNotification(status: String): Notification {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, PicoClawService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 1, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, PicoClawApp.CHANNEL_ID)
            .setContentTitle("PicoClaw")
            .setContentText(status)
            .setSmallIcon(android.R.drawable.ic_menu_manage)
            .setContentIntent(pendingIntent)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPendingIntent)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    private fun updateNotification(status: String) {
        try {
            val notification = createNotification(status)
            val manager = getSystemService(android.app.NotificationManager::class.java)
            manager.notify(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to update notification", e)
        }
    }

    // --- Wake Lock ---

    private fun acquireWakeLock() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "PicoClaw::ServiceWakeLock"
        ).apply {
            acquire(24 * 60 * 60 * 1000L) // 24 小时上限
        }
        Log.i(TAG, "Wake lock acquired")
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
                Log.i(TAG, "Wake lock released")
            }
        }
        wakeLock = null
    }

    // --- 日志缓冲 ---

    @Synchronized
    private fun appendLog(line: String) {
        logBuffer.appendLine(line)
        if (logBuffer.length > maxLogSize) {
            logBuffer.delete(0, logBuffer.length - maxLogSize)
        }
        lastLog = line
    }

    @Synchronized
    fun getFullLog(): String = logBuffer.toString()
}
