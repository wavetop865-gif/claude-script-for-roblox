package com.pulse.optimizer

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.EaseInOutSine
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.BatteryChargingFull
import androidx.compose.material.icons.rounded.Bolt
import androidx.compose.material.icons.rounded.CleaningServices
import androidx.compose.material.icons.rounded.Memory
import androidx.compose.material.icons.rounded.Public
import androidx.compose.material.icons.rounded.Speed
import androidx.compose.material.icons.rounded.Storage
import androidx.compose.material.icons.rounded.VpnKey
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.pulse.optimizer.ui.theme.DangerRose
import com.pulse.optimizer.ui.theme.DeepSpace
import com.pulse.optimizer.ui.theme.ElectricBlue
import com.pulse.optimizer.ui.theme.NeonMint
import com.pulse.optimizer.ui.theme.PulseOptimizerTheme
import com.pulse.optimizer.ui.theme.SoftViolet
import com.pulse.optimizer.ui.theme.Surface1
import com.pulse.optimizer.ui.theme.Surface2
import com.pulse.optimizer.ui.theme.TextPrimary
import com.pulse.optimizer.ui.theme.TextSecondary
import com.pulse.optimizer.ui.theme.WarmAmber
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            PulseOptimizerTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    PulseApp()
                }
            }
        }
    }
}

private enum class Tab { Optimize, Vpn }

@Composable
fun PulseApp() {
    var tab by remember { mutableStateOf(Tab.Optimize) }

    Box(modifier = Modifier.fillMaxSize()) {
        AuroraBackground()
        Column(modifier = Modifier.fillMaxSize()) {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
            ) {
                when (tab) {
                    Tab.Optimize -> OptimizerScreen()
                    Tab.Vpn -> VpnScreen()
                }
            }
            BottomBar(selected = tab, onSelect = { tab = it })
        }
    }
}

@Composable
private fun BottomBar(selected: Tab, onSelect: (Tab) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Surface1.copy(alpha = 0.95f))
            .navigationBarsPadding()
            .padding(horizontal = 12.dp, vertical = 10.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        BottomItem(
            label = "Оптимизация",
            icon = Icons.Rounded.Speed,
            selected = selected == Tab.Optimize,
            onClick = { onSelect(Tab.Optimize) }
        )
        BottomItem(
            label = "VPN",
            icon = Icons.Rounded.VpnKey,
            selected = selected == Tab.Vpn,
            onClick = { onSelect(Tab.Vpn) }
        )
    }
}

@Composable
private fun BottomItem(
    label: String,
    icon: ImageVector,
    selected: Boolean,
    onClick: () -> Unit,
) {
    val tint by animateColorAsState(
        if (selected) NeonMint else TextSecondary,
        label = "tab"
    )
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .clip(RoundedCornerShape(16.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 28.dp, vertical = 6.dp)
    ) {
        Icon(icon, contentDescription = label, tint = tint, modifier = Modifier.size(24.dp))
        Spacer(Modifier.height(4.dp))
        Text(label, color = tint, fontSize = 12.sp, fontWeight = FontWeight.Medium)
    }
}

/* ───────────────────────── Optimize ───────────────────────── */

private enum class BoostKind { Quick, Deep, Battery }
private enum class BoostState { Idle, Running, Done }

@Composable
fun OptimizerScreen() {
    val context = LocalContext.current
    var snapshot by remember { mutableStateOf(DeviceStats.read(context)) }
    var boostState by remember { mutableStateOf(BoostState.Idle) }
    var activeKind by remember { mutableStateOf(BoostKind.Quick) }
    var scanMessage by remember { mutableStateOf("") }
    var resultText by remember { mutableStateOf("") }
    var scoreBonus by remember { mutableIntStateOf(0) }

    LaunchedEffect(boostState) {
        if (boostState != BoostState.Running) {
            while (true) {
                snapshot = DeviceStats.read(context)
                delay(4000)
            }
        }
    }

    LaunchedEffect(boostState, activeKind) {
        if (boostState != BoostState.Running) return@LaunchedEffect
        val steps = when (activeKind) {
            BoostKind.Quick -> listOf(
                "Сканирование памяти…",
                "Очистка кэша…",
                "Освобождение RAM…",
            )
            BoostKind.Deep -> listOf(
                "Поиск временных файлов…",
                "Очистка code-cache…",
                "Удаление логов и .tmp…",
                "Сжатие мусора…",
                "Финальная проверка…",
            )
            BoostKind.Battery -> listOf(
                "Анализ температуры…",
                "Снижение фоновой нагрузки…",
                "Оптимизация энергопотребления…",
            )
        }
        for (step in steps) {
            scanMessage = step
            delay(700)
        }
        val result = withContext(Dispatchers.IO) {
            when (activeKind) {
                BoostKind.Quick -> DeviceStats.quickBoost(context)
                BoostKind.Deep -> DeviceStats.deepClean(context)
                BoostKind.Battery -> DeviceStats.batteryCare(context)
            }
        }
        snapshot = DeviceStats.read(context)
        scoreBonus = when (activeKind) {
            BoostKind.Quick -> 5
            BoostKind.Deep -> 8
            BoostKind.Battery -> 4
        }
        resultText = when (activeKind) {
            BoostKind.Quick, BoostKind.Deep ->
                "${result.label}: освобождено ${DeviceStats.formatBytes(result.freedBytes)}" +
                    if (result.filesRemoved > 0) " · ${result.filesRemoved} файлов" else ""
            BoostKind.Battery -> result.label
        }
        boostState = BoostState.Done
        delay(3500)
        scoreBonus = 0
        boostState = BoostState.Idle
    }

    val displayScore = (snapshot.healthScore + scoreBonus).coerceAtMost(100)
    val busy = boostState == BoostState.Running

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .statusBarsPadding()
            .padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(20.dp))
        Header()
        Spacer(Modifier.height(24.dp))

        HealthRing(
            score = displayScore,
            scanning = busy,
            modifier = Modifier.size(220.dp)
        )

        Spacer(Modifier.height(16.dp))

        Text(
            text = when (boostState) {
                BoostState.Running -> scanMessage
                BoostState.Done -> resultText
                BoostState.Idle -> when {
                    displayScore >= 70 -> "Устройство работает отлично"
                    displayScore >= 40 -> "Есть что улучшить"
                    else -> "Рекомендуется оптимизация"
                }
            },
            color = if (boostState == BoostState.Done) NeonMint else TextSecondary,
            fontSize = 14.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 8.dp)
        )

        Spacer(Modifier.height(22.dp))

        Text(
            text = "МЕТОДЫ ОПТИМИЗАЦИИ",
            color = TextSecondary,
            fontSize = 11.sp,
            letterSpacing = 2.sp,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.align(Alignment.Start)
        )
        Spacer(Modifier.height(12.dp))

        MethodButton(
            title = "Быстрое ускорение",
            subtitle = "Кэш + оперативная память",
            icon = Icons.Rounded.Bolt,
            gradient = listOf(NeonMint, ElectricBlue),
            enabled = !busy,
            onClick = {
                activeKind = BoostKind.Quick
                boostState = BoostState.Running
            }
        )
        Spacer(Modifier.height(10.dp))
        MethodButton(
            title = "Глубокая очистка",
            subtitle = "Временные файлы, логи, code-cache",
            icon = Icons.Rounded.CleaningServices,
            gradient = listOf(SoftViolet, ElectricBlue),
            enabled = !busy,
            onClick = {
                activeKind = BoostKind.Deep
                boostState = BoostState.Running
            }
        )
        Spacer(Modifier.height(10.dp))
        MethodButton(
            title = "Забота о батарее",
            subtitle = "Температура и энергопотребление",
            icon = Icons.Rounded.BatteryChargingFull,
            gradient = listOf(WarmAmber, NeonMint),
            enabled = !busy,
            onClick = {
                activeKind = BoostKind.Battery
                boostState = BoostState.Running
            }
        )

        Spacer(Modifier.height(28.dp))

        StatCard(
            icon = Icons.Rounded.Memory,
            iconTint = ElectricBlue,
            title = "Оперативная память",
            value = "${DeviceStats.formatBytes(snapshot.ramUsedBytes)} из ${DeviceStats.formatBytes(snapshot.ramTotalBytes)}",
            fraction = snapshot.ramFraction,
            barColors = listOf(ElectricBlue, SoftViolet)
        )
        Spacer(Modifier.height(12.dp))
        StatCard(
            icon = Icons.Rounded.Storage,
            iconTint = SoftViolet,
            title = "Хранилище",
            value = "${DeviceStats.formatBytes(snapshot.storageUsedBytes)} из ${DeviceStats.formatBytes(snapshot.storageTotalBytes)}",
            fraction = snapshot.storageFraction,
            barColors = listOf(SoftViolet, DangerRose)
        )
        Spacer(Modifier.height(12.dp))
        StatCard(
            icon = Icons.Rounded.BatteryChargingFull,
            iconTint = WarmAmber,
            title = if (snapshot.isCharging) "Батарея · заряжается" else "Батарея",
            value = "${snapshot.batteryPercent}% · ${String.format("%.1f", snapshot.batteryTempC)}°C",
            fraction = snapshot.batteryPercent / 100f,
            barColors = listOf(WarmAmber, NeonMint)
        )
        Spacer(Modifier.height(24.dp))
    }
}

@Composable
private fun MethodButton(
    title: String,
    subtitle: String,
    icon: ImageVector,
    gradient: List<Color>,
    enabled: Boolean,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Brush.horizontalGradient(gradient.map { it.copy(alpha = if (enabled) 0.18f else 0.08f) }))
            .clickable(enabled = enabled, onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(Brush.linearGradient(gradient)),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, null, tint = DeepSpace, modifier = Modifier.size(22.dp))
        }
        Spacer(Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(title, color = TextPrimary, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
            Text(subtitle, color = TextSecondary, fontSize = 12.sp)
        }
    }
}

/* ───────────────────────── VPN ───────────────────────── */

@Composable
fun VpnScreen() {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val vpnState by PulseVpn.state.collectAsState()
    var selected by remember { mutableStateOf(FreeVpnServers.all.last()) }
    var pendingConnect by remember { mutableStateOf(false) }

    val vpnPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == android.app.Activity.RESULT_OK && pendingConnect) {
            pendingConnect = false
            scope.launch { PulseVpn.connect(context, selected.endpoint) }
        } else {
            pendingConnect = false
        }
    }

    fun requestConnect() {
        val prepare = PulseVpn.prepareIntent(context)
        if (prepare != null) {
            pendingConnect = true
            vpnPermissionLauncher.launch(prepare)
        } else {
            scope.launch { PulseVpn.connect(context, selected.endpoint) }
        }
    }

    val busy = vpnState.phase == VpnPhase.Preparing ||
        vpnState.phase == VpnPhase.Connecting ||
        vpnState.phase == VpnPhase.Disconnecting
    val connected = vpnState.phase == VpnPhase.Connected

    Column(
        modifier = Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .padding(horizontal = 20.dp)
    ) {
        Spacer(Modifier.height(20.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.VpnKey, null, tint = NeonMint, modifier = Modifier.size(26.dp))
            Spacer(Modifier.width(8.dp))
            Text(
                "Pulse VPN",
                color = TextPrimary,
                fontSize = 22.sp,
                fontWeight = FontWeight.SemiBold
            )
        }
        Spacer(Modifier.height(6.dp))
        Text(
            "Встроенный VPN · без других приложений",
            color = TextSecondary,
            fontSize = 13.sp
        )

        Spacer(Modifier.height(20.dp))

        // Status / connect card
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(24.dp))
                .background(Surface1.copy(alpha = 0.95f))
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(96.dp)
                    .clip(CircleShape)
                    .background(
                        Brush.radialGradient(
                            listOf(
                                if (connected) NeonMint.copy(alpha = 0.35f) else ElectricBlue.copy(alpha = 0.2f),
                                Color.Transparent
                            )
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                if (busy) {
                    CircularProgressIndicator(color = NeonMint, strokeWidth = 3.dp, modifier = Modifier.size(42.dp))
                } else {
                    Icon(
                        Icons.Rounded.Public,
                        null,
                        tint = if (connected) NeonMint else TextSecondary,
                        modifier = Modifier.size(42.dp)
                    )
                }
            }
            Spacer(Modifier.height(12.dp))
            Text(
                when (vpnState.phase) {
                    VpnPhase.Connected -> "Подключено"
                    VpnPhase.Connecting, VpnPhase.Preparing -> "Подключение…"
                    VpnPhase.Disconnecting -> "Отключение…"
                    VpnPhase.Error -> "Ошибка"
                    VpnPhase.Disconnected -> "Не подключено"
                },
                color = TextPrimary,
                fontSize = 20.sp,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(Modifier.height(6.dp))
            Text(
                vpnState.message,
                color = if (vpnState.phase == VpnPhase.Error) DangerRose else TextSecondary,
                fontSize = 13.sp,
                textAlign = TextAlign.Center
            )
            if (connected && vpnState.endpoint.isNotBlank()) {
                Spacer(Modifier.height(4.dp))
                Text(vpnState.endpoint, color = NeonMint, fontSize = 12.sp)
            }
            Spacer(Modifier.height(18.dp))

            val btnBrush = when {
                connected -> Brush.horizontalGradient(listOf(DangerRose, SoftViolet))
                busy -> Brush.horizontalGradient(listOf(Surface2, Surface2))
                else -> Brush.horizontalGradient(listOf(NeonMint, ElectricBlue))
            }
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp)
                    .clip(RoundedCornerShape(27.dp))
                    .background(btnBrush)
                    .clickable(enabled = !busy) {
                        if (connected) scope.launch { PulseVpn.disconnect(context) }
                        else requestConnect()
                    },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    when {
                        connected -> "ОТКЛЮЧИТЬ"
                        busy -> "ПОДОЖДИТЕ…"
                        else -> "ПОДКЛЮЧИТЬ"
                    },
                    color = if (busy) TextSecondary else DeepSpace,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 2.sp,
                    fontSize = 15.sp
                )
            }
        }

        Spacer(Modifier.height(18.dp))
        Text(
            "БЕСПЛАТНЫЕ СЕРВЕРЫ",
            color = TextSecondary,
            fontSize = 11.sp,
            letterSpacing = 2.sp,
            fontWeight = FontWeight.Medium
        )
        Spacer(Modifier.height(10.dp))

        LazyColumn(
            contentPadding = PaddingValues(bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            items(FreeVpnServers.all, key = { it.id }) { server ->
                FreeServerRow(
                    server = server,
                    selected = selected.id == server.id,
                    enabled = !busy,
                    onClick = { selected = server }
                )
            }
        }
    }
}

@Composable
private fun FreeServerRow(
    server: FreeVpnServer,
    selected: Boolean,
    enabled: Boolean,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(if (selected) Surface2 else Surface1.copy(alpha = 0.85f))
            .clickable(enabled = enabled, onClick = onClick)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(countryFlag(server.countryCode), fontSize = 24.sp)
        Spacer(Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                server.name,
                color = TextPrimary,
                fontWeight = FontWeight.Medium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                "${server.country} · ${server.endpoint}",
                color = TextSecondary,
                fontSize = 12.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
        if (selected) {
            Text("✓", color = NeonMint, fontWeight = FontWeight.Bold, fontSize = 16.sp)
        }
    }
}

private fun countryFlag(code: String): String {
    if (code.length != 2) return "🌐"
    val c = code.uppercase()
    val first = Character.codePointAt(c, 0) - 0x41 + 0x1F1E6
    val second = Character.codePointAt(c, 1) - 0x41 + 0x1F1E6
    return String(Character.toChars(first)) + String(Character.toChars(second))
}

/* ───────────────────────── Shared UI ───────────────────────── */

@Composable
private fun Header() {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Rounded.Bolt,
            contentDescription = null,
            tint = NeonMint,
            modifier = Modifier.size(26.dp)
        )
        Spacer(Modifier.width(8.dp))
        Text(
            text = "Pulse Optimizer",
            color = TextPrimary,
            fontSize = 22.sp,
            fontWeight = FontWeight.SemiBold,
            letterSpacing = 0.5.sp
        )
    }
}

@Composable
private fun AuroraBackground() {
    val transition = rememberInfiniteTransition(label = "aurora")
    val shift by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(12000, easing = EaseInOutSine),
            repeatMode = RepeatMode.Reverse
        ),
        label = "shift"
    )

    Canvas(modifier = Modifier.fillMaxSize()) {
        drawRect(DeepSpace)
        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(ElectricBlue.copy(alpha = 0.16f), Color.Transparent),
                center = Offset(size.width * (0.15f + 0.2f * shift), size.height * 0.12f),
                radius = size.width * 0.7f
            ),
            radius = size.width * 0.7f,
            center = Offset(size.width * (0.15f + 0.2f * shift), size.height * 0.12f)
        )
        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(SoftViolet.copy(alpha = 0.12f), Color.Transparent),
                center = Offset(size.width * (0.9f - 0.2f * shift), size.height * 0.45f),
                radius = size.width * 0.6f
            ),
            radius = size.width * 0.6f,
            center = Offset(size.width * (0.9f - 0.2f * shift), size.height * 0.45f)
        )
        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(NeonMint.copy(alpha = 0.08f), Color.Transparent),
                center = Offset(size.width * 0.5f, size.height * (0.9f - 0.1f * shift)),
                radius = size.width * 0.8f
            ),
            radius = size.width * 0.8f,
            center = Offset(size.width * 0.5f, size.height * (0.9f - 0.1f * shift))
        )
    }
}

@Composable
private fun HealthRing(score: Int, scanning: Boolean, modifier: Modifier = Modifier) {
    val animatedScore by animateFloatAsState(
        targetValue = score / 100f,
        animationSpec = tween(1200),
        label = "score"
    )
    val infinite = rememberInfiniteTransition(label = "ring")
    val spin by infinite.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(1400, easing = LinearEasing)),
        label = "spin"
    )
    val breathe by infinite.animateFloat(
        initialValue = 0.97f,
        targetValue = 1.03f,
        animationSpec = infiniteRepeatable(
            animation = tween(2200, easing = EaseInOutSine),
            repeatMode = RepeatMode.Reverse
        ),
        label = "breathe"
    )
    val ringBrush = Brush.sweepGradient(
        colors = listOf(ElectricBlue, NeonMint, SoftViolet, ElectricBlue)
    )

    Box(
        modifier = modifier.graphicsLayer {
            scaleX = breathe
            scaleY = breathe
        },
        contentAlignment = Alignment.Center
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val stroke = 22.dp.toPx()
            val inset = stroke / 2 + 4.dp.toPx()
            val arcSize = androidx.compose.ui.geometry.Size(
                size.width - inset * 2, size.height - inset * 2
            )
            val topLeft = Offset(inset, inset)

            drawArc(
                color = Surface1,
                startAngle = 120f,
                sweepAngle = 300f,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = stroke, cap = StrokeCap.Round)
            )
            if (scanning) {
                drawArc(
                    brush = ringBrush,
                    startAngle = spin,
                    sweepAngle = 90f,
                    useCenter = false,
                    topLeft = topLeft,
                    size = arcSize,
                    style = Stroke(width = stroke, cap = StrokeCap.Round)
                )
            } else {
                drawArc(
                    brush = ringBrush,
                    startAngle = 120f,
                    sweepAngle = 300f * animatedScore,
                    useCenter = false,
                    topLeft = topLeft,
                    size = arcSize,
                    style = Stroke(width = stroke, cap = StrokeCap.Round)
                )
            }
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = if (scanning) "…" else "$score",
                color = TextPrimary,
                fontSize = 52.sp,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = if (scanning) "оптимизация" else "индекс здоровья",
                color = TextSecondary,
                fontSize = 12.sp,
                letterSpacing = 1.sp
            )
        }
    }
}

@Composable
private fun StatCard(
    icon: ImageVector,
    iconTint: Color,
    title: String,
    value: String,
    fraction: Float,
    barColors: List<Color>,
) {
    val animatedFraction by animateFloatAsState(
        targetValue = fraction.coerceIn(0f, 1f),
        animationSpec = tween(900),
        label = "bar"
    )
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(22.dp))
            .background(Surface1.copy(alpha = 0.85f))
            .padding(18.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .size(42.dp)
                    .clip(CircleShape)
                    .background(iconTint.copy(alpha = 0.14f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(icon, null, tint = iconTint, modifier = Modifier.size(22.dp))
            }
            Spacer(Modifier.width(14.dp))
            Column {
                Text(title, color = TextPrimary, fontSize = 15.sp, fontWeight = FontWeight.Medium)
                Spacer(Modifier.height(2.dp))
                Text(value, color = TextSecondary, fontSize = 13.sp)
            }
        }
        Spacer(Modifier.height(14.dp))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(6.dp)
                .clip(RoundedCornerShape(3.dp))
                .background(DeepSpace)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(animatedFraction)
                    .height(6.dp)
                    .clip(RoundedCornerShape(3.dp))
                    .background(Brush.horizontalGradient(barColors))
            )
        }
    }
}
