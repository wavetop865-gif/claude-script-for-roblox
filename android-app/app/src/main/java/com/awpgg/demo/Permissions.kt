package com.awpgg.demo

import android.content.Context
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat

data class PermissionStatus(
    val notificationsGranted: Boolean,
    val overlayGranted: Boolean
) {
    val allGranted: Boolean
        get() = notificationsGranted && overlayGranted

    val needsNotifications: Boolean
        get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !notificationsGranted
}

object Permissions {
    fun status(context: Context): PermissionStatus {
        val notifications = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            NotificationManagerCompat.from(context).areNotificationsEnabled()
        } else {
            true
        }
        val overlay = Settings.canDrawOverlays(context)
        return PermissionStatus(notifications, overlay)
    }
}
