package com.pulse.optimizer

/**
 * Серверы заранее вшиты в APK — список не качается из интернета
 * (важно для РФ, где VPN Gate / внешние API часто недоступны).
 */
data class FreeVpnServer(
    val id: String,
    val name: String,
    val country: String,
    val countryCode: String,
    val endpoint: String,
)

object FreeVpnServers {
    /** Полностью офлайн-список. Порядок: удобнее для РФ сверху. */
    val all = listOf(
        FreeVpnServer(
            id = "auto",
            name = "Авто · Cloudflare",
            country = "Ближайший узел",
            countryCode = "UN",
            endpoint = "engage.cloudflareclient.com:2408",
        ),
        FreeVpnServer(
            id = "de-1",
            name = "Frankfurt 1",
            country = "Германия",
            countryCode = "DE",
            endpoint = "162.159.192.1:2408",
        ),
        FreeVpnServer(
            id = "de-2",
            name = "Frankfurt 2",
            country = "Германия",
            countryCode = "DE",
            endpoint = "162.159.193.1:2408",
        ),
        FreeVpnServer(
            id = "nl-1",
            name = "Amsterdam 1",
            country = "Нидерланды",
            countryCode = "NL",
            endpoint = "162.159.192.5:2408",
        ),
        FreeVpnServer(
            id = "nl-2",
            name = "Amsterdam 2",
            country = "Нидерланды",
            countryCode = "NL",
            endpoint = "162.159.193.5:2408",
        ),
        FreeVpnServer(
            id = "gb-1",
            name = "London 1",
            country = "Великобритания",
            countryCode = "GB",
            endpoint = "162.159.192.7:2408",
        ),
        FreeVpnServer(
            id = "fi-1",
            name = "Helsinki",
            country = "Финляндия",
            countryCode = "FI",
            endpoint = "162.159.192.9:2408",
        ),
        FreeVpnServer(
            id = "pl-1",
            name = "Warsaw",
            country = "Польша",
            countryCode = "PL",
            endpoint = "162.159.193.9:2408",
        ),
        FreeVpnServer(
            id = "tr-1",
            name = "Istanbul",
            country = "Турция",
            countryCode = "TR",
            endpoint = "162.159.192.8:2408",
        ),
        FreeVpnServer(
            id = "sg-1",
            name = "Singapore",
            country = "Сингапур",
            countryCode = "SG",
            endpoint = "162.159.193.8:2408",
        ),
        FreeVpnServer(
            id = "jp-1",
            name = "Tokyo",
            country = "Япония",
            countryCode = "JP",
            endpoint = "162.159.192.2:2408",
        ),
        FreeVpnServer(
            id = "us-1",
            name = "Ashburn",
            country = "США · Восток",
            countryCode = "US",
            endpoint = "162.159.192.6:2408",
        ),
        FreeVpnServer(
            id = "us-2",
            name = "Los Angeles",
            country = "США · Запад",
            countryCode = "US",
            endpoint = "162.159.193.6:2408",
        ),
        FreeVpnServer(
            id = "ca-1",
            name = "Toronto",
            country = "Канада",
            countryCode = "CA",
            endpoint = "162.159.192.3:2408",
        ),
        FreeVpnServer(
            id = "br-1",
            name = "São Paulo",
            country = "Бразилия",
            countryCode = "BR",
            endpoint = "162.159.193.3:2408",
        ),
        FreeVpnServer(
            id = "in-1",
            name = "Mumbai",
            country = "Индия",
            countryCode = "IN",
            endpoint = "162.159.192.4:2408",
        ),
        FreeVpnServer(
            id = "kr-1",
            name = "Seoul",
            country = "Корея",
            countryCode = "KR",
            endpoint = "162.159.193.4:2408",
        ),
        FreeVpnServer(
            id = "au-1",
            name = "Sydney",
            country = "Австралия",
            countryCode = "AU",
            endpoint = "162.159.192.10:2408",
        ),
    )
}
