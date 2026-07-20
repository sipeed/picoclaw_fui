package com.sipeed.picoclaw

import android.os.Build
import android.app.NotificationManager
import io.flutter.app.FlutterApplication

class PicoClawApp : FlutterApplication() {

    companion object {
        const val CHANNEL_ID = "picoclaw_service"
        const val CHANNEL_NAME = "PicoClaw Service"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        AnalyticsReporter.preInit(this)
    }

    private fun createNotificationChannel() {
        // NotificationChannel is only available on API 26 (Android 8.0)+.
        // On API 25 and below (e.g. Android 7.x devices), skip channel
        // creation entirely — the foreground service still works, it just
        // won't have a dedicated notification channel.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val channel = android.app.NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "PicoClaw AI Assistant background service"
            setShowBadge(false)
        }

        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }
}
