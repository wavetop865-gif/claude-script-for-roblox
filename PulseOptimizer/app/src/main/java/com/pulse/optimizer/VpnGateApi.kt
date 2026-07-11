package com.pulse.optimizer

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Base64
import androidx.core.content.FileProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.nio.charset.Charset

/**
 * Free public VPN servers from VPN Gate (University of Tsukuba).
 * API: http://www.vpngate.net/api/iphone/
 * Credentials for L2TP/IPsec: user=vpn, pass=vpn, PSK=vpn
 */
data class VpnServer(
    val hostName: String,
    val ip: String,
    val countryLong: String,
    val countryShort: String,
    val ping: Int,
    val speedBps: Long,
    val score: Long,
    val sessions: Int,
    val openVpnConfigBase64: String,
) {
    val speedMbps: Double get() = speedBps / 1_000_000.0
    val hasOpenVpn: Boolean get() = openVpnConfigBase64.isNotBlank()

    fun decodeConfig(): String {
        if (openVpnConfigBase64.isBlank()) return ""
        val bytes = Base64.decode(openVpnConfigBase64, Base64.DEFAULT)
        return String(bytes, Charset.forName("UTF-8"))
    }
}

object VpnGateApi {
    private const val API = "http://www.vpngate.net/api/iphone/"
    private val MIRRORS = listOf(
        "http://www.vpngate.net/api/iphone/",
        "http://vpngate.net/api/iphone/",
    )

    suspend fun fetchServers(): List<VpnServer> = withContext(Dispatchers.IO) {
        var lastError: Exception? = null
        for (url in MIRRORS) {
            try {
                return@withContext parseCsv(download(url))
            } catch (e: Exception) {
                lastError = e
            }
        }
        throw lastError ?: IllegalStateException("Не удалось загрузить серверы")
    }

    private fun download(urlStr: String): String {
        val conn = (URL(urlStr).openConnection() as HttpURLConnection).apply {
            connectTimeout = 15000
            readTimeout = 20000
            requestMethod = "GET"
            setRequestProperty("User-Agent", "PulseOptimizer/1.0")
        }
        try {
            if (conn.responseCode !in 200..299) {
                throw IllegalStateException("HTTP ${conn.responseCode}")
            }
            return BufferedReader(InputStreamReader(conn.inputStream, Charsets.UTF_8)).use { it.readText() }
        } finally {
            conn.disconnect()
        }
    }

    /**
     * CSV columns (VPN Gate):
     * HostName, IP, Score, Ping, Speed, CountryLong, CountryShort, NumVpnSessions,
     * Uptime, TotalUsers, TotalTraffic, LogType, Operator, Message, OpenVPN_ConfigData_Base64, *
     */
    private fun parseCsv(raw: String): List<VpnServer> {
        val lines = raw.lineSequence()
            .map { it.trim() }
            .filter { it.isNotEmpty() && !it.startsWith("*") && !it.startsWith("#") }
            .toList()

        return lines.mapNotNull { line ->
            // First 14 fields are metadata; everything after the 14th comma is OpenVPN base64
            val parts = ArrayList<String>(15)
            var rest = line
            repeat(14) {
                val idx = rest.indexOf(',')
                if (idx < 0) return@mapNotNull null
                parts.add(rest.substring(0, idx))
                rest = rest.substring(idx + 1)
            }
            val config = rest.trimEnd(',').trim()
            if (config.isBlank()) return@mapNotNull null
            VpnServer(
                hostName = parts[0],
                ip = parts[1],
                score = parts[2].toLongOrNull() ?: 0L,
                ping = parts[3].toIntOrNull() ?: 9999,
                speedBps = parts[4].toLongOrNull() ?: 0L,
                countryLong = parts[5],
                countryShort = parts[6],
                sessions = parts[7].toIntOrNull() ?: 0,
                openVpnConfigBase64 = config,
            )
        }
            .sortedByDescending { it.score }
            .take(40)
    }

    fun saveConfig(context: Context, server: VpnServer): File {
        val dir = File(context.cacheDir, "vpn").also { it.mkdirs() }
        val file = File(dir, "${server.countryShort}_${server.hostName}.ovpn")
        file.writeText(server.decodeConfig())
        return file
    }

    fun openWithOpenVpn(context: Context, file: File): Boolean {
        val uri: Uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            file
        )
        val packages = listOf(
            "net.openvpn.openvpn",      // OpenVPN Connect
            "de.blinkt.openvpn",         // OpenVPN for Android
            "com.github.openvpn",
        )
        for (pkg in packages) {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/x-openvpn-profile")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                setPackage(pkg)
            }
            if (intent.resolveActivity(context.packageManager) != null) {
                context.startActivity(intent)
                return true
            }
        }
        // Generic view / share fallback
        val view = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/octet-stream")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return try {
            context.startActivity(Intent.createChooser(view, "Открыть VPN-конфиг"))
            true
        } catch (_: Exception) {
            false
        }
    }

    fun openPlayStoreForOpenVpn(context: Context) {
        val market = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("market://details?id=net.openvpn.openvpn")
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val web = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("https://play.google.com/store/apps/details?id=net.openvpn.openvpn")
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(market)
        } catch (_: Exception) {
            context.startActivity(web)
        }
    }

    fun openSystemVpnSettings(context: Context) {
        context.startActivity(
            Intent(android.provider.Settings.ACTION_VPN_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }
}
