package com.pulse.optimizer

import android.content.Context
import android.content.SharedPreferences
import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Tunnel
import com.wireguard.config.Config
import com.wireguard.crypto.KeyPair
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.StringReader
import java.net.HttpURLConnection
import java.net.URL
import java.nio.charset.StandardCharsets
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

enum class VpnPhase {
    Disconnected,
    Preparing,
    Connecting,
    Connected,
    Disconnecting,
    Error,
}

data class VpnUiState(
    val phase: VpnPhase = VpnPhase.Disconnected,
    val message: String = "Встроенный бесплатный VPN",
    val endpoint: String = "",
    val address: String = "",
)

/**
 * In-app VPN via WireGuard + free Cloudflare WARP.
 * No third-party VPN apps required — uses Android VpnService inside this process.
 */
object PulseVpn {
    private const val PREFS = "pulse_warp"
    private const val TUNNEL_NAME = "pulse-warp"
    // Несколько URL — на случай блокировок в РФ
    private val API_BASES = listOf(
        "https://api.cloudflareclient.com/v0a1922",
        "https://api.cloudflareclient.com/v0a2470",
    )

    private val _state = MutableStateFlow(
        VpnUiState(message = "Серверы уже встроены · интернет для списка не нужен")
    )
    val state: StateFlow<VpnUiState> = _state.asStateFlow()

    @Volatile private var backend: GoBackend? = null
    private val tunnel = object : Tunnel {
        override fun getName(): String = TUNNEL_NAME
        override fun onStateChange(newState: Tunnel.State) {
            when (newState) {
                Tunnel.State.UP -> _state.value = _state.value.copy(
                    phase = VpnPhase.Connected,
                    message = "VPN подключён · трафик защищён"
                )
                Tunnel.State.DOWN -> _state.value = _state.value.copy(
                    phase = VpnPhase.Disconnected,
                    message = "VPN отключён",
                    endpoint = "",
                    address = "",
                )
                else -> Unit
            }
        }
    }

    fun backend(context: Context): GoBackend {
        return backend ?: GoBackend(context.applicationContext).also { backend = it }
    }

    /** Returns an Intent that must be launched for VPN permission, or null if already granted. */
    fun prepareIntent(context: Context) = GoBackend.VpnService.prepare(context)

    suspend fun connect(context: Context, endpointOverride: String? = null) = withContext(Dispatchers.IO) {
        try {
            val hasCache = !prefs(context).getString("wg_conf", null).isNullOrBlank()
            _state.value = VpnUiState(
                VpnPhase.Preparing,
                if (hasCache) "Подключение к выбранному серверу…"
                else "Первый запуск · создание ключей…"
            )
            var confText = ensureWarpConfig(context)
            if (!endpointOverride.isNullOrBlank()) {
                confText = confText.replace(
                    Regex("""(?m)^Endpoint\s*=\s*.*$"""),
                    "Endpoint = $endpointOverride"
                )
            }
            val config = Config.parse(BufferedReader(StringReader(confText)))
            val endpoint = config.peers.firstOrNull()
                ?.endpoint?.orElse(null)?.toString().orEmpty()
            val address = config.`interface`.addresses.joinToString { it.toString() }

            _state.value = VpnUiState(
                phase = VpnPhase.Connecting,
                message = "Установка туннеля…",
                endpoint = endpoint,
                address = address,
            )

            backend(context).setState(tunnel, Tunnel.State.UP, config)

            _state.value = VpnUiState(
                phase = VpnPhase.Connected,
                message = "VPN подключён внутри приложения",
                endpoint = endpoint,
                address = address,
            )
        } catch (e: Exception) {
            _state.value = VpnUiState(
                phase = VpnPhase.Error,
                message = e.message?.take(140) ?: "Ошибка подключения"
            )
        }
    }

    suspend fun disconnect(context: Context) = withContext(Dispatchers.IO) {
        try {
            _state.value = _state.value.copy(phase = VpnPhase.Disconnecting, message = "Отключение…")
            backend(context).setState(tunnel, Tunnel.State.DOWN, null)
            _state.value = VpnUiState(VpnPhase.Disconnected, "VPN отключён")
        } catch (e: Exception) {
            _state.value = VpnUiState(VpnPhase.Error, e.message?.take(120) ?: "Ошибка отключения")
        }
    }

    suspend fun toggle(context: Context, endpointOverride: String? = null) {
        when (_state.value.phase) {
            VpnPhase.Connected -> disconnect(context)
            VpnPhase.Disconnected, VpnPhase.Error -> connect(context, endpointOverride)
            else -> Unit
        }
    }

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun ensureWarpConfig(context: Context): String {
        val p = prefs(context)
        val cached = p.getString("wg_conf", null)
        if (!cached.isNullOrBlank()) return cached

        val keyPair = KeyPair()
        val privateKey = keyPair.privateKey.toBase64()
        val publicKey = keyPair.publicKey.toBase64()

        val tos = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }.format(Date())

        val body = JSONObject()
            .put("install_id", "")
            .put("tos", tos)
            .put("key", publicKey)
            .put("fcm_token", "")
            .put("type", "Android")
            .put("locale", "ru_RU")
            .toString()

        var lastError: Exception? = null
        for (base in API_BASES) {
            repeat(2) { attempt ->
                try {
                    val raw = postJson("$base/reg", body)
                    val json = JSONObject(raw)
                    val cfg = json.getJSONObject("config")
                    val iface = cfg.getJSONObject("interface").getJSONObject("addresses")
                    val peer = cfg.getJSONArray("peers").getJSONObject(0)
                    val endpointHost = peer.getJSONObject("endpoint").optString("host")
                        .ifBlank { "engage.cloudflareclient.com:2408" }
                    val endpoint = if (endpointHost.contains(":")) endpointHost
                    else "$endpointHost:2408"

                    val v4 = iface.getString("v4")
                    val v6 = iface.optString("v6")
                    val addressLine = if (v6.isNullOrBlank()) "$v4/32" else "$v4/32, $v6/128"

                    val conf = buildString {
                        appendLine("[Interface]")
                        appendLine("PrivateKey = $privateKey")
                        appendLine("Address = $addressLine")
                        appendLine("DNS = 1.1.1.1, 8.8.8.8")
                        appendLine("MTU = 1280")
                        appendLine()
                        appendLine("[Peer]")
                        appendLine("PublicKey = ${peer.getString("public_key")}")
                        appendLine("AllowedIPs = 0.0.0.0/0, ::/0")
                        appendLine("Endpoint = $endpoint")
                        appendLine("PersistentKeepalive = 25")
                    }

                    p.edit()
                        .putString("wg_conf", conf)
                        .putString("device_id", json.optString("id"))
                        .putString("token", json.optString("token"))
                        .apply()

                    return conf
                } catch (e: Exception) {
                    lastError = e
                    try {
                        Thread.sleep(400L * (attempt + 1))
                    } catch (_: InterruptedException) {
                    }
                }
            }
        }
        throw IllegalStateException(
            "Не удалось создать VPN-ключ. Проверьте интернет и попробуйте снова. " +
                "(${lastError?.message ?: "нет ответа"})"
        )
    }

    private fun postJson(urlStr: String, body: String): String {
        val conn = (URL(urlStr).openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            connectTimeout = 25000
            readTimeout = 25000
            doOutput = true
            setRequestProperty("Content-Type", "application/json; charset=UTF-8")
            setRequestProperty("Accept", "application/json")
            setRequestProperty("User-Agent", "okhttp/3.12.1")
        }
        try {
            conn.outputStream.use { it.write(body.toByteArray(StandardCharsets.UTF_8)) }
            val code = conn.responseCode
            val stream = if (code in 200..299) conn.inputStream else conn.errorStream
            val raw = BufferedReader(InputStreamReader(stream, StandardCharsets.UTF_8)).use { it.readText() }
            if (code !in 200..299) throw IllegalStateException("HTTP $code")
            return raw
        } finally {
            conn.disconnect()
        }
    }

    fun clearAccount(context: Context) {
        prefs(context).edit().clear().apply()
    }
}
