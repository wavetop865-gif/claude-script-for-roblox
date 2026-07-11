package com.pulse.optimizer

/**
 * Free public Cloudflare WARP anycast edges used as selectable VPN servers.
 * All speak the same WARP/WireGuard protocol — connection stays inside Pulse Optimizer.
 */
data class FreeVpnServer(
    val id: String,
    val name: String,
    val country: String,
    val countryCode: String,
    val endpoint: String,
    val pingHintMs: Int,
)

object FreeVpnServers {
    val all = listOf(
        FreeVpnServer("cf-jp", "Tokyo Edge", "Япония", "JP", "162.159.192.1:2408", 40),
        FreeVpnServer("cf-sg", "Singapore Edge", "Сингапур", "SG", "162.159.193.1:2408", 55),
        FreeVpnServer("cf-de", "Frankfurt Edge", "Германия", "DE", "162.159.192.5:2408", 70),
        FreeVpnServer("cf-nl", "Amsterdam Edge", "Нидерланды", "NL", "162.159.193.5:2408", 75),
        FreeVpnServer("cf-us-west", "Los Angeles Edge", "США · Запад", "US", "162.159.192.6:2408", 120),
        FreeVpnServer("cf-us-east", "Ashburn Edge", "США · Восток", "US", "162.159.193.6:2408", 110),
        FreeVpnServer("cf-gb", "London Edge", "Великобритания", "GB", "162.159.192.7:2408", 80),
        FreeVpnServer("cf-au", "Sydney Edge", "Австралия", "AU", "162.159.193.7:2408", 160),
        FreeVpnServer("cf-auto", "Auto (Cloudflare)", "Автовыбор", "CF", "engage.cloudflareclient.com:2408", 30),
    )
}
