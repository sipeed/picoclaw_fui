package com.sipeed.picoclaw

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.umeng.analytics.MobclickAgent
import com.umeng.commonsdk.UMConfigure

object AnalyticsReporter {
    private const val DEVICE_REPORT_EVENT = "device_feedback_report"
    private var umengInitialized = false
    private var initError: String? = null

    private val provider: String
        get() = BuildConfig.PICOCLAW_ANALYTICS_PROVIDER.lowercase()

    private val umengAppKey: String
        get() = BuildConfig.PICOCLAW_UMENG_APP_KEY

    private val umengChannel: String
        get() = BuildConfig.PICOCLAW_UMENG_CHANNEL.ifBlank { "official" }

    private fun isUmengProviderEnabled(): Boolean {
        val enabled = provider == "umeng" && umengAppKey.isNotBlank()
        android.util.Log.d("AnalyticsReporter", "isUmengProviderEnabled: provider=$provider, appKeyEmpty=${umengAppKey.isBlank()}, enabled=$enabled")
        return enabled
    }

    private fun checkNetwork(context: Context): Boolean {
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }

    fun preInit(context: Context) {
        if (!isUmengProviderEnabled()) {
            android.util.Log.d("AnalyticsReporter", "Umeng not enabled, skipping preInit")
            return
        }
        
        android.util.Log.d("AnalyticsReporter", "Pre-initializing Umeng SDK with channel=$umengChannel")
        
        try {
            // PreInit must be called before init
            UMConfigure.preInit(context.applicationContext, umengAppKey, umengChannel)
            android.util.Log.d("AnalyticsReporter", "PreInit completed successfully")
            
            // 注意：不再自动初始化，必须等待用户明确同意后再调用 submitConsent()
            android.util.Log.d("AnalyticsReporter", "Waiting for user consent before full initialization")
        } catch (e: Exception) {
            initError = e.message
            android.util.Log.e("AnalyticsReporter", "Failed to preInit Umeng SDK: ${e.message}", e)
        }
    }
    
    private fun performInit(context: Context) {
        try {
            android.util.Log.d("AnalyticsReporter", "Performing Umeng SDK init on main thread...")
            
            UMConfigure.setLogEnabled(false)
            
            UMConfigure.init(
                context,
                umengAppKey,
                umengChannel,
                UMConfigure.DEVICE_TYPE_PHONE,
                null,
            )
            // 使用LEGACY_MANUAL模式，避免自动采集页面数据，手动控制事件上报
            MobclickAgent.setPageCollectionMode(MobclickAgent.PageMode.LEGACY_MANUAL)
            // 设置Session间隔时间为30秒，减少不必要的数据上报
            MobclickAgent.setSessionContinueMillis(30 * 1000)
            MobclickAgent.setDebugMode(false)
            
            umengInitialized = true
            initError = null
            android.util.Log.d("AnalyticsReporter", "Umeng SDK initialized successfully")
        } catch (e: Exception) {
            initError = e.message
            android.util.Log.e("AnalyticsReporter", "Failed to initialize Umeng SDK: ${e.message}", e)
        }
    }

    fun submitConsent(context: Context, granted: Boolean) {
        if (!isUmengProviderEnabled()) {
            return
        }
        val appContext = context.applicationContext
        
        try {
            android.util.Log.d("AnalyticsReporter", "Submitting consent: granted=$granted")
            UMConfigure.submitPolicyGrantResult(appContext, granted)
            
            if (granted && !umengInitialized) {
                android.util.Log.d("AnalyticsReporter", "Initializing Umeng SDK after consent...")
                // 在主线程执行初始化
                if (Looper.myLooper() == Looper.getMainLooper()) {
                    performInit(appContext)
                } else {
                    Handler(Looper.getMainLooper()).post {
                        performInit(appContext)
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("AnalyticsReporter", "Failed to submit consent: ${e.message}", e)
        }
    }

    fun uploadDeviceReport(context: Context, payload: Map<String, Any?>): Map<String, Any> {
        android.util.Log.d("AnalyticsReporter", "=== uploadDeviceReport START ===")
        android.util.Log.d("AnalyticsReporter", "umengInitialized=$umengInitialized, provider=$provider")
        
        // 1. 检查Provider配置
        if (!isUmengProviderEnabled()) {
            android.util.Log.e("AnalyticsReporter", "Umeng provider not enabled!")
            return mapOf<String, Any>(
                "success" to false,
                "errorType" to "CONFIG_ERROR",
                "message" to "Umeng provider is not enabled for this build.",
            )
        }
        
        // 2. 检查SDK初始化状态
        if (!umengInitialized) {
            android.util.Log.e("AnalyticsReporter", "Umeng SDK not initialized")
            return mapOf<String, Any>(
                "success" to false,
                "errorType" to "NOT_INITIALIZED",
                "message" to "Umeng SDK is not initialized. Please call setUmengAnalyticsConsent(true) first. Error: $initError",
            )
        }
        
        // 3. 检查网络状态
        if (!checkNetwork(context)) {
            android.util.Log.e("AnalyticsReporter", "Network not available")
            return mapOf<String, Any>(
                "success" to false,
                "errorType" to "NETWORK_ERROR",
                "message" to "Network not available. Please check your connection.",
            )
        }
        android.util.Log.d("AnalyticsReporter", "Network check passed")

        // 4. 准备事件数据 - 只使用非空参数，避免友盟过滤
        val eventPayload = linkedMapOf<String, String>()
        
        // 安全地添加参数，过滤空值
        (payload["installId"] as? String)?.takeIf { it.isNotBlank() }?.let { 
            eventPayload["installId"] = it 
        }
        (payload["platform"] as? String)?.takeIf { it.isNotBlank() }?.let { 
            eventPayload["platform"] = it 
        }
        (payload["deviceModel"] as? String)?.takeIf { it.isNotBlank() }?.let { 
            eventPayload["deviceModel"] = it 
        }
        (payload["systemVersion"] as? String)?.takeIf { it.isNotBlank() }?.let { 
            eventPayload["systemVersion"] = it 
        }
        (payload["clientType"] as? String)?.takeIf { it.isNotBlank() }?.let { 
            eventPayload["clientType"] = it 
        }
        (payload["channel"] as? String)?.takeIf { it.isNotBlank() }?.let { 
            eventPayload["channel"] = it 
        }
        
        // 添加固定参数
        eventPayload["manufacturer"] = Build.MANUFACTURER ?: "unknown"
        eventPayload["sdkInt"] = Build.VERSION.SDK_INT.toString()
        eventPayload["timestamp"] = System.currentTimeMillis().toString()
        
        android.util.Log.d("AnalyticsReporter", "Event payload prepared: $eventPayload")
        android.util.Log.d("AnalyticsReporter", "Payload entry count: ${eventPayload.size}")

        // 5. 发送事件（多参数类型事件使用 onEventValue）
        return try {
            android.util.Log.d("AnalyticsReporter", "[1/3] Sending multi-parameter event '$DEVICE_REPORT_EVENT'...")
            android.util.Log.d("AnalyticsReporter", "Final payload: $eventPayload")
            android.util.Log.d("AnalyticsReporter", "Payload keys: ${eventPayload.keys}")
            
            // 检查 payload 是否为空
            if (eventPayload.isEmpty()) {
                android.util.Log.e("AnalyticsReporter", "Payload is empty!")
                return mapOf<String, Any>(
                    "success" to false,
                    "errorType" to "INVALID_PAYLOAD",
                    "message" to "Event payload is empty",
                )
            }
            
            // 验证每个参数值
            eventPayload.forEach { (key, value) ->
                android.util.Log.d("AnalyticsReporter", "Param[$key] = '$value' (length=${value.length})")
            }
            
            // 使用 onEventValue 方法上报多参数事件
            // 数值设为 1 表示一次事件触发
            MobclickAgent.onEventValue(
                context.applicationContext, 
                DEVICE_REPORT_EVENT, 
                eventPayload,
                1  // 事件数值，设为1表示计数一次
            )
            android.util.Log.d("AnalyticsReporter", "[2/3] MobclickAgent.onEventValue() called successfully")
            
            // 触发友盟内部的数据上报（实时日志可能需要等待SDK自动上报）
            // 友盟SDK会在合适的时机自动上报，通常几秒到几分钟内
            MobclickAgent.onPause(context.applicationContext)
            MobclickAgent.onResume(context.applicationContext)
            android.util.Log.d("AnalyticsReporter", "[3/3] Triggered data sync via onPause/onResume")
            
            android.util.Log.d("AnalyticsReporter", "=== uploadDeviceReport SUCCESS ===")
            android.util.Log.i("AnalyticsReporter", "Event '$DEVICE_REPORT_EVENT' sent with ${eventPayload.size} parameters")
            android.util.Log.i("AnalyticsReporter", "========================================")
            android.util.Log.i("AnalyticsReporter", "请在友盟后台查看: https://www.umeng.com")
            android.util.Log.i("AnalyticsReporter", "事件名: $DEVICE_REPORT_EVENT")
            android.util.Log.i("AnalyticsReporter", "参数数量: ${eventPayload.size}")
            android.util.Log.i("AnalyticsReporter", "参数列表: ${eventPayload.keys.joinToString(", ")}")
            android.util.Log.i("AnalyticsReporter", "========================================")
            mapOf<String, Any>(
                "success" to true,
                "errorType" to "",
                "message" to "Analytics event synced successfully",
                "paramCount" to eventPayload.size,
                "paramKeys" to eventPayload.keys.toList(),
            )
        } catch (e: Exception) {
            android.util.Log.e("AnalyticsReporter", "=== uploadDeviceReport FAILED ===")
            android.util.Log.e("AnalyticsReporter", "Exception: ${e.message}", e)
            mapOf<String, Any>(
                "success" to false,
                "errorType" to "SDK_ERROR",
                "message" to "Umeng SDK error: ${e.message ?: e.javaClass.simpleName}",
            )
        }
    }
}
