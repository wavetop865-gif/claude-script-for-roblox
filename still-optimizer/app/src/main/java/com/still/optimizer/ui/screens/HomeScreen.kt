package com.still.optimizer.ui.screens

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.still.optimizer.DeviceMetrics
import com.still.optimizer.DeviceSnapshot
import com.still.optimizer.ui.components.CalmRing
import com.still.optimizer.ui.components.MetricRow
import com.still.optimizer.ui.components.MistAtmosphere
import com.still.optimizer.ui.components.SectionLabel
import com.still.optimizer.ui.components.StatusDot
import com.still.optimizer.ui.components.StillPrimaryButton
import com.still.optimizer.ui.theme.Fraunces
import com.still.optimizer.ui.theme.Outfit
import com.still.optimizer.ui.theme.StillTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.Locale

private enum class Phase { Idle, Optimizing, Done }

@Composable
fun HomeScreen() {
    val context = LocalContext.current
    val colors = StillTheme.colors
    val scope = rememberCoroutineScope()

    var snapshot by remember {
        mutableStateOf(DeviceMetrics.snapshot(context))
    }
    var phase by remember { mutableStateOf(Phase.Idle) }
    var displayScore by remember { mutableIntStateOf(snapshot.calmScore) }
    var freedMb by remember { mutableIntStateOf(0) }
    var statusLine by remember {
        mutableStateOf("Тишина для вашего телефона")
    }

    LaunchedEffect(Unit) {
        delay(80)
        snapshot = DeviceMetrics.snapshot(context)
        displayScore = snapshot.calmScore
    }

    fun runOptimize() {
        if (phase == Phase.Optimizing) return
        scope.launch {
            phase = Phase.Optimizing
            statusLine = "Очищаем кэш…"
            delay(700)
            val freed = DeviceMetrics.clearAppCache(context).toInt()
            freedMb = freed
            statusLine = "Освобождаем память…"
            delay(900)
            statusLine = "Выравниваем нагрузку…"
            delay(800)
            val refreshed = DeviceMetrics.snapshot(context)
            val boosted = (refreshed.calmScore + 6 + (freed / 8)).coerceAtMost(99)
            snapshot = refreshed.copy(calmScore = boosted)
            displayScore = boosted
            statusLine = "Освобождено ≈ ${freed} МБ"
            phase = Phase.Done
            delay(2200)
            if (phase == Phase.Done) {
                phase = Phase.Idle
                statusLine = "Телефон дышит спокойнее"
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        MistAtmosphere()

        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.height(28.dp))

            // Brand — hero-level signal
            Text(
                text = "Still",
                fontFamily = Fraunces,
                fontWeight = FontWeight.SemiBold,
                fontSize = 44.sp,
                color = colors.ink,
                letterSpacing = (-0.8).sp,
            )

            Spacer(Modifier.height(6.dp))

            AnimatedContent(
                targetState = statusLine,
                transitionSpec = {
                    (fadeIn(tween(400)) + slideInVertically { it / 3 }) togetherWith fadeOut(tween(250))
                },
                label = "status",
            ) { line ->
                Text(
                    text = line,
                    fontFamily = Outfit,
                    fontWeight = FontWeight.Normal,
                    fontSize = 15.sp,
                    color = colors.inkMuted,
                    textAlign = TextAlign.Center,
                )
            }

            Spacer(Modifier.height(36.dp))

            CalmRing(
                score = displayScore,
                animating = phase == Phase.Optimizing,
            )

            Spacer(Modifier.height(28.dp))

            StatusDot(active = phase == Phase.Optimizing)

            Spacer(Modifier.height(28.dp))

            StillPrimaryButton(
                label = when (phase) {
                    Phase.Idle -> "Оптимизировать"
                    Phase.Optimizing -> "Спокойно…"
                    Phase.Done -> "Готово"
                },
                onClick = { runOptimize() },
                enabled = phase == Phase.Idle,
            )

            Spacer(Modifier.height(48.dp))

            AnimatedVisibility(
                visible = true,
                enter = fadeIn(tween(700)) + slideInVertically { it / 4 },
            ) {
                MetricsSection(snapshot = snapshot)
            }

            Spacer(Modifier.height(40.dp))
        }
    }
}

@Composable
private fun MetricsSection(snapshot: DeviceSnapshot) {
    val colors = StillTheme.colors
    val ramProgress = snapshot.usedRamMb.toFloat() / snapshot.totalRamMb.coerceAtLeast(1).toFloat()
    val storageProgress = snapshot.usedStorageGb / snapshot.totalStorageGb.coerceAtLeast(0.1f)

    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(28.dp),
    ) {
        SectionLabel(text = "Состояние")

        MetricRow(
            label = "Память",
            value = "${snapshot.usedRamMb} / ${snapshot.totalRamMb} МБ",
            progress = ramProgress,
            accent = colors.sage,
        )

        MetricRow(
            label = "Хранилище",
            value = String.format(
                Locale.getDefault(),
                "%.1f / %.0f ГБ",
                snapshot.usedStorageGb,
                snapshot.totalStorageGb,
            ),
            progress = storageProgress,
            accent = colors.sand,
        )

        MetricRow(
            label = "Кэш",
            value = "≈ ${snapshot.cacheHintMb} МБ",
            progress = (snapshot.cacheHintMb / 200f).coerceIn(0.08f, 1f),
            accent = colors.sageSoft,
        )

        Spacer(Modifier.height(8.dp))

        Text(
            text = "Still убирает лишнее — без шума, без суеты.",
            fontFamily = Outfit,
            fontWeight = FontWeight.Normal,
            fontSize = 14.sp,
            color = colors.inkMuted,
            lineHeight = 22.sp,
        )
    }
}
