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

    val healthScore: Int
        get() {
            val ramScore = (1f - ramFraction) * 40f
            val storageScore = (1f - storageFraction) * 30f
            val batteryScore = batteryPercent / 100f * 30f
            return (ramScore + storageScore + batteryScore).toInt().coerceIn(0, 100)
        }
}

data class CleanResult(
    val freedBytes: Long,
    val filesRemoved: Int,
    val label: String,
)

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

    /** Quick boost: clear app caches + request GC. */
    fun quickBoost(context: Context): CleanResult {
        var freed = 0L
        var files = 0
        val dirs = listOfNotNull(context.cacheDir, context.externalCacheDir)
        for (dir in dirs) {
            val r = deleteRecursively(dir, keepRoot = true)
            freed += r.first
            files += r.second
        }
        System.gc()
        return CleanResult(freed, files, "Быстрое ускорение")
    }

    /**
     * Deep clean: cache + code_cache + temp files under filesDir +
     * leftover .tmp / .log files. Different method from quickBoost.
     */
    fun deepClean(context: Context): CleanResult {
        var freed = 0L
        var files = 0

        val targets = buildList {
            add(context.cacheDir)
            add(context.codeCacheDir)
            context.externalCacheDir?.let { add(it) }
            add(File(context.filesDir, "temp"))
            add(File(context.filesDir, "tmp"))
            add(File(context.filesDir, "logs"))
        }

        for (dir in targets) {
            if (!dir.exists()) continue
            val r = deleteRecursively(dir, keepRoot = true)
            freed += r.first
            files += r.second
        }

        // Sweep leftover temp/log files in filesDir root
        context.filesDir.listFiles()?.forEach { f ->
            val name = f.name.lowercase()
            if (f.isFile && (name.endsWith(".tmp") || name.endsWith(".log") || name.endsWith(".cache"))) {
                val size = f.length()
                if (f.delete()) {
                    freed += size
                    files += 1
                }
            }
        }

        Runtime.getRuntime().gc()
        System.runFinalization()
        System.gc()

        return CleanResult(freed, files, "Глубокая очистка")
    }

    /** Battery care: drop temp heat sources (caches) + return tip based on temp. */
    fun batteryCare(context: Context): CleanResult {
        val before = read(context)
        val quick = quickBoost(context)
        val tip = when {
            before.batteryTempC >= 40f -> "Батарея горячая — снизьте яркость и закройте тяжёлые приложения"
            before.isCharging && before.batteryPercent >= 80 -> "Заряд почти полный — можно отключить зарядку"
            before.batteryPercent <= 20 -> "Низкий заряд — включите режим энергосбережения"
            else -> "Температура в норме · кэш очищен для снижения нагрузки"
        }
        return CleanResult(quick.freedBytes, quick.filesRemoved, tip)
    }

    private fun deleteRecursively(file: File, keepRoot: Boolean): Pair<Long, Int> {
        var freed = 0L
        var count = 0
        if (file.isDirectory) {
            file.listFiles()?.forEach {
                val r = deleteRecursively(it, keepRoot = false)
                freed += r.first
                count += r.second
            }
        }
        if (!keepRoot) {
            val size = if (file.isFile) file.length() else 0L
            if (file.delete()) {
                freed += size
                count += 1
            }
        }
        return freed to count
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
