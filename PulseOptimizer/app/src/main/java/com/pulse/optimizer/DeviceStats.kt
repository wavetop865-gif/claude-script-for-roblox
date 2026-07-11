package com.pulse.optimizer

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Environment
import android.os.StatFs
import java.io.File

data class DeviceSnapshot(
    val ramUsedBytes: Long,
    val ramTotalBytes: Long,
    val storageUsedBytes: Long,
    val storageTotalBytes: Long,
    val batteryPercent: Int,
    val batteryTempC: Float,
    val isCharging: Boolean,
) {
    val ramFraction: Float
        get() = if (ramTotalBytes > 0) ramUsedBytes.toFloat() / ramTotalBytes else 0f

    val storageFraction: Float
        get() = if (storageTotalBytes > 0) storageUsedBytes.toFloat() / storageTotalBytes else 0f

    /** Composite 0..100 health score: free RAM, free storage and battery all contribute. */
    val healthScore: Int
        get() {
            val ramScore = (1f - ramFraction) * 40f
            val storageScore = (1f - storageFraction) * 30f
            val batteryScore = batteryPercent / 100f * 30f
            return (ramScore + storageScore + batteryScore).toInt().coerceIn(0, 100)
        }
}

object DeviceStats {

    fun read(context: Context): DeviceSnapshot {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memInfo = ActivityManager.MemoryInfo().also { am.getMemoryInfo(it) }

        val stat = StatFs(Environment.getDataDirectory().path)
        val storageTotal = stat.totalBytes
        val storageFree = stat.availableBytes

        val batteryIntent: Intent? = context.registerReceiver(
            null, IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        )
        val level = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
        val percent = if (level >= 0 && scale > 0) level * 100 / scale else 50
        val tempTenths = batteryIntent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 250) ?: 250
        val status = batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val charging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL

        return DeviceSnapshot(
            ramUsedBytes = memInfo.totalMem - memInfo.availMem,
            ramTotalBytes = memInfo.totalMem,
            storageUsedBytes = storageTotal - storageFree,
            storageTotalBytes = storageTotal,
            batteryPercent = percent,
            batteryTempC = tempTenths / 10f,
            isCharging = charging,
        )
    }

    /** Deletes this app's own cache directories and returns the number of bytes freed. */
    fun clearOwnCache(context: Context): Long {
        var freed = 0L
        val dirs = listOfNotNull(context.cacheDir, context.externalCacheDir)
        for (dir in dirs) {
            freed += deleteRecursively(dir, keepRoot = true)
        }
        return freed
    }

    private fun deleteRecursively(file: File, keepRoot: Boolean): Long {
        var freed = 0L
        if (file.isDirectory) {
            file.listFiles()?.forEach { freed += deleteRecursively(it, keepRoot = false) }
        }
        if (!keepRoot) {
            val size = if (file.isFile) file.length() else 0L
            if (file.delete()) freed += size
        }
        return freed
    }

    fun formatBytes(bytes: Long): String {
        val gb = bytes / 1_073_741_824.0
        if (gb >= 1) return String.format("%.1f ГБ", gb)
        val mb = bytes / 1_048_576.0
        if (mb >= 1) return String.format("%.0f МБ", mb)
        val kb = bytes / 1024.0
        return String.format("%.0f КБ", kb)
    }
}
