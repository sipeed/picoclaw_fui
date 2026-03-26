package com.sipeed.picoclaw

import android.app.NotificationChannel
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
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
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
