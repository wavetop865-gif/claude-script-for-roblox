package com.pulse.optimizer

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
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
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.BatteryChargingFull
import androidx.compose.material.icons.rounded.Bolt
import androidx.compose.material.icons.rounded.Memory
import androidx.compose.material.icons.rounded.Storage
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.pulse.optimizer.ui.theme.DangerRose
import com.pulse.optimizer.ui.theme.DeepSpace
import com.pulse.optimizer.ui.theme.ElectricBlue
import com.pulse.optimizer.ui.theme.NeonMint
import com.pulse.optimizer.ui.theme.SoftViolet
import com.pulse.optimizer.ui.theme.Surface1
import com.pulse.optimizer.ui.theme.TextPrimary
import com.pulse.optimizer.ui.theme.TextSecondary
import com.pulse.optimizer.ui.theme.WarmAmber
import com.pulse.optimizer.ui.theme.PulseOptimizerTheme
import kotlinx.coroutines.delay

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
                    OptimizerScreen()
                }
            }
        }
    }
}

private enum class BoostState { Idle, Scanning, Done }

@Composable
fun OptimizerScreen() {
    val context = LocalContext.current
    var snapshot by remember { mutableStateOf(DeviceStats.read(context)) }
    var boostState by remember { mutableStateOf(BoostState.Idle) }
    var scanMessage by remember { mutableStateOf("") }
    var freedBytes by remember { mutableStateOf(0L) }
    var scoreBonus by remember { mutableIntStateOf(0) }

    // Periodically refresh live stats while idle
    LaunchedEffect(boostState) {
        if (boostState != BoostState.Scanning) {
            while (true) {
                snapshot = DeviceStats.read(context)
                delay(4000)
            }
        }
    }

    LaunchedEffect(boostState) {
        if (boostState == BoostState.Scanning) {
            val steps = listOf(
                "Сканирование памяти…",
                "Анализ фоновых процессов…",
                "Очистка кэша…",
                "Оптимизация хранилища…",
                "Финальная настройка…",
            )
            for (step in steps) {
                scanMessage = step
                delay(900)
            }
            freedBytes = DeviceStats.clearOwnCache(context)
            System.gc()
            snapshot = DeviceStats.read(context)
            scoreBonus = 6
            boostState = BoostState.Done
            delay(3500)
            scoreBonus = 0
            boostState = BoostState.Idle
        }
    }

    val displayScore = (snapshot.healthScore + scoreBonus).coerceAtMost(100)

    Box(modifier = Modifier.fillMaxSize()) {
        AuroraBackground()

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
            Spacer(Modifier.height(28.dp))

            HealthRing(
                score = displayScore,
                scanning = boostState == BoostState.Scanning,
                modifier = Modifier.size(240.dp)
            )

            Spacer(Modifier.height(20.dp))

            when (boostState) {
                BoostState.Scanning -> Text(
                    text = scanMessage,
                    color = TextSecondary,
                    fontSize = 14.sp,
                    textAlign = TextAlign.Center
                )
                BoostState.Done -> Text(
                    text = "Готово! Освобождено ${DeviceStats.formatBytes(freedBytes)} кэша",
                    color = NeonMint,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    textAlign = TextAlign.Center
                )
                BoostState.Idle -> Text(
                    text = if (displayScore >= 70) "Устройство работает отлично"
                    else if (displayScore >= 40) "Есть что улучшить"
                    else "Рекомендуется оптимизация",
                    color = TextSecondary,
                    fontSize = 14.sp,
                    textAlign = TextAlign.Center
                )
            }

            Spacer(Modifier.height(24.dp))

            BoostButton(
                scanning = boostState == BoostState.Scanning,
                onClick = { if (boostState == BoostState.Idle) boostState = BoostState.Scanning }
            )

            Spacer(Modifier.height(32.dp))

            StatCard(
                icon = Icons.Rounded.Memory,
                iconTint = ElectricBlue,
                title = "Оперативная память",
                value = "${DeviceStats.formatBytes(snapshot.ramUsedBytes)} из ${DeviceStats.formatBytes(snapshot.ramTotalBytes)}",
                fraction = snapshot.ramFraction,
                barColors = listOf(ElectricBlue, SoftViolet)
            )
            Spacer(Modifier.height(14.dp))
            StatCard(
                icon = Icons.Rounded.Storage,
                iconTint = SoftViolet,
                title = "Хранилище",
                value = "${DeviceStats.formatBytes(snapshot.storageUsedBytes)} из ${DeviceStats.formatBytes(snapshot.storageTotalBytes)}",
                fraction = snapshot.storageFraction,
                barColors = listOf(SoftViolet, DangerRose)
            )
            Spacer(Modifier.height(14.dp))
            StatCard(
                icon = Icons.Rounded.BatteryChargingFull,
                iconTint = WarmAmber,
                title = if (snapshot.isCharging) "Батарея · заряжается" else "Батарея",
                value = "${snapshot.batteryPercent}% · ${String.format("%.1f", snapshot.batteryTempC)}°C",
                fraction = snapshot.batteryPercent / 100f,
                barColors = listOf(WarmAmber, NeonMint)
            )

            Spacer(Modifier.height(32.dp))
        }
    }
}

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

/** Soft moving color blobs behind the content. */
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

            // Track
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
                // Spinning comet while scanning
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
                fontSize = 56.sp,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = if (scanning) "оптимизация" else "индекс здоровья",
                color = TextSecondary,
                fontSize = 13.sp,
                letterSpacing = 1.sp
            )
        }
    }
}

@Composable
private fun BoostButton(scanning: Boolean, onClick: () -> Unit) {
    val bgColor by animateColorAsState(
        targetValue = if (scanning) Surface1 else Color.Transparent,
        label = "btnBg"
    )
    val brush = if (scanning) {
        Brush.horizontalGradient(listOf(Surface1, Surface1))
    } else {
        Brush.horizontalGradient(listOf(NeonMint, ElectricBlue))
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(58.dp)
            .clip(RoundedCornerShape(29.dp))
            .background(brush)
            .background(bgColor)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                enabled = !scanning,
                onClick = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = if (scanning) "ОПТИМИЗАЦИЯ…" else "УСКОРИТЬ",
            color = if (scanning) TextSecondary else DeepSpace,
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 3.sp
        )
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
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = iconTint,
                    modifier = Modifier.size(22.dp)
                )
            }
            Spacer(Modifier.width(14.dp))
            Column {
                Text(
                    text = title,
                    color = TextPrimary,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Medium
                )
                Spacer(Modifier.height(2.dp))
                Text(
                    text = value,
                    color = TextSecondary,
                    fontSize = 13.sp
                )
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
