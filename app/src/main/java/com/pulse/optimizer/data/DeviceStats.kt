package com.pulse.optimizer.data

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Environment
import android.os.StatFs

data class DeviceStats(
    val ramUsedBytes: Long = 0,
    val ramTotalBytes: Long = 1,
    val storageUsedBytes: Long = 0,
    val storageTotalBytes: Long = 1,
    val batteryPercent: Int = 0,
    val isCharging: Boolean = false,
    val cacheEstimateBytes: Long = 0,
) {
    val ramFraction: Float get() = ramUsedBytes.toFloat() / ramTotalBytes
    val storageFraction: Float get() = storageUsedBytes.toFloat() / storageTotalBytes

    /** Composite 0..100 health score used by the main gauge. */
    val healthScore: Int
        get() {
            val ram = (1f - ramFraction) * 40f
            val storage = (1f - storageFraction) * 35f
            val battery = batteryPercent / 100f * 25f
            return (ram + storage + battery).toInt().coerceIn(0, 100)
        }
}

object DeviceStatsReader {

    fun read(context: Context): DeviceStats {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mem = ActivityManager.MemoryInfo().also(am::getMemoryInfo)

        val stat = StatFs(Environment.getDataDirectory().path)
        val storageTotal = stat.totalBytes
        val storageFree = stat.availableBytes

        val battery = context.registerReceiver(
            null, IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        )
        val level = battery?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = battery?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val status = battery?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val percent = if (level >= 0 && scale > 0) level * 100 / scale else 0
        val charging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                status == BatteryManager.BATTERY_STATUS_FULL

        return DeviceStats(
            ramUsedBytes = mem.totalMem - mem.availMem,
            ramTotalBytes = mem.totalMem,
            storageUsedBytes = storageTotal - storageFree,
            storageTotalBytes = storageTotal,
            batteryPercent = percent,
            isCharging = charging,
            cacheEstimateBytes = context.cacheDir.walkBottomUp()
                .filter { it.isFile }
                .sumOf { it.length() },
        )
    }

    /** Clears this app's own cache directories — the only cache a modern
     *  non-system app is allowed to touch. */
    fun clearOwnCache(context: Context): Long {
        var freed = 0L
        listOfNotNull(context.cacheDir, context.externalCacheDir).forEach { dir ->
            dir.walkBottomUp().forEach { file ->
                if (file.isFile) {
                    val size = file.length()
                    if (file.delete()) freed += size
                } else if (file != dir) {
                    file.delete()
                }
            }
        }
        return freed
    }
}

fun formatBytes(bytes: Long): String {
    val gb = bytes / 1_073_741_824.0
    if (gb >= 1) return "%.1f ГБ".format(gb)
    val mb = bytes / 1_048_576.0
    if (mb >= 1) return "%.0f МБ".format(mb)
    val kb = bytes / 1024.0
    return "%.0f КБ".format(kb)
}
