package com.still.optimizer

import android.app.ActivityManager
import android.content.Context
import android.os.Environment
import android.os.StatFs
import kotlin.math.roundToInt

data class DeviceSnapshot(
    val calmScore: Int,
    val usedRamMb: Long,
    val totalRamMb: Long,
    val usedStorageGb: Float,
    val totalStorageGb: Float,
    val batteryHint: String,
    val cacheHintMb: Long,
)

object DeviceMetrics {

    fun snapshot(context: Context): DeviceSnapshot {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memInfo = ActivityManager.MemoryInfo()
        am.getMemoryInfo(memInfo)

        val totalRamMb = memInfo.totalMem / (1024 * 1024)
        val availRamMb = memInfo.availMem / (1024 * 1024)
        val usedRamMb = (totalRamMb - availRamMb).coerceAtLeast(0)

        val stat = StatFs(Environment.getDataDirectory().path)
        val totalStorage = stat.totalBytes.toDouble()
        val availStorage = stat.availableBytes.toDouble()
        val usedStorage = (totalStorage - availStorage).coerceAtLeast(0.0)
        val totalGb = (totalStorage / (1024.0 * 1024.0 * 1024.0)).toFloat()
        val usedGb = (usedStorage / (1024.0 * 1024.0 * 1024.0)).toFloat()

        val cacheMb = estimateCacheMb(context)

        val ramPressure = usedRamMb.toFloat() / totalRamMb.coerceAtLeast(1).toFloat()
        val storagePressure = usedGb / totalGb.coerceAtLeast(0.1f)
        val calm = ((1f - (ramPressure * 0.55f + storagePressure * 0.35f + (cacheMb / 800f).coerceIn(0f, 0.2f))) * 100f)
            .roundToInt()
            .coerceIn(12, 99)

        return DeviceSnapshot(
            calmScore = calm,
            usedRamMb = usedRamMb,
            totalRamMb = totalRamMb,
            usedStorageGb = usedGb,
            totalStorageGb = totalGb,
            batteryHint = "Спокойный режим",
            cacheHintMb = cacheMb,
        )
    }

    private fun estimateCacheMb(context: Context): Long {
        return try {
            val cache = context.cacheDir
            val size = cache.walkTopDown().filter { it.isFile }.map { it.length() }.sum()
            (size / (1024 * 1024)).coerceAtLeast(8)
        } catch (_: Exception) {
            24L
        }
    }

    fun clearAppCache(context: Context): Long {
        var freed = 0L
        try {
            context.cacheDir.walkTopDown().forEach { file ->
                if (file.isFile) {
                    freed += file.length()
                    file.delete()
                }
            }
            context.externalCacheDir?.walkTopDown()?.forEach { file ->
                if (file.isFile) {
                    freed += file.length()
                    file.delete()
                }
            }
        } catch (_: Exception) {
            // ignore
        }
        // Suggest GC to reclaim memory pressure
        System.gc()
        return (freed / (1024 * 1024)).coerceAtLeast(1)
    }
}
