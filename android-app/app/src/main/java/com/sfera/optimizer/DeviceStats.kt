package com.sfera.optimizer

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Environment
import android.os.StatFs
import java.io.File
import kotlin.math.roundToInt

data class DeviceSnapshot(
    val storageUsedPercent: Int,
    val storageFree: String,
    val storageTotal: String,
    val memoryUsedPercent: Int,
    val memoryFree: String,
    val batteryPercent: Int,
    val batteryTemperature: Int,
    val isCharging: Boolean,
    val score: Int
)

fun readDeviceSnapshot(context: Context): DeviceSnapshot {
    val stat = StatFs(Environment.getDataDirectory().path)
    val totalBytes = stat.blockCountLong * stat.blockSizeLong
    val freeBytes = stat.availableBlocksLong * stat.blockSizeLong
    val storageUsed = percent(totalBytes - freeBytes, totalBytes)

    val memoryInfo = ActivityManager.MemoryInfo()
    val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    activityManager.getMemoryInfo(memoryInfo)
    val memoryUsed = percent(memoryInfo.totalMem - memoryInfo.availMem, memoryInfo.totalMem)

    val battery = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
    val level = battery?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
    val scale = battery?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
    val batteryPercent = if (level >= 0) percent(level.toLong(), scale.toLong()) else 0
    val temperature = (battery?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0) / 10
    val status = battery?.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
    val charging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
        status == BatteryManager.BATTERY_STATUS_FULL

    val scorePenalty = (storageUsed * 0.32f + memoryUsed * 0.18f).roundToInt()
    val score = (100 - scorePenalty).coerceIn(35, 100)

    return DeviceSnapshot(
        storageUsedPercent = storageUsed,
        storageFree = formatBytes(freeBytes),
        storageTotal = formatBytes(totalBytes),
        memoryUsedPercent = memoryUsed,
        memoryFree = formatBytes(memoryInfo.availMem),
        batteryPercent = batteryPercent,
        batteryTemperature = temperature,
        isCharging = charging,
        score = score
    )
}

fun clearTemporaryFiles(context: Context): Long =
    listOf(context.cacheDir, context.externalCacheDir)
        .filterNotNull()
        .sumOf { clearChildren(it) }

private fun clearChildren(directory: File): Long {
    var freedBytes = 0L
    directory.listFiles()?.forEach { file ->
        val size = if (file.isDirectory) file.walkBottomUp().filter(File::isFile).sumOf(File::length)
        else file.length()
        if (file.deleteRecursively()) freedBytes += size
    }
    return freedBytes
}

fun formatBytes(bytes: Long): String {
    val gib = bytes / (1024.0 * 1024.0 * 1024.0)
    return if (gib >= 1) {
        val rounded = (gib * 10).roundToInt() / 10.0
        "$rounded ГБ"
    } else {
        "${(bytes / (1024.0 * 1024.0)).roundToInt()} МБ"
    }
}

private fun percent(value: Long, total: Long): Int =
    if (total <= 0) 0 else ((value.toDouble() / total) * 100).roundToInt().coerceIn(0, 100)
