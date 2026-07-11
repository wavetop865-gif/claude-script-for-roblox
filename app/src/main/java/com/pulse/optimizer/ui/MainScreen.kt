package com.pulse.optimizer.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.BatteryChargingFull
import androidx.compose.material.icons.outlined.BatteryStd
import androidx.compose.material.icons.outlined.Bolt
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Memory
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.Storage
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.pulse.optimizer.OptimizePhase
import com.pulse.optimizer.OptimizerViewModel
import com.pulse.optimizer.data.formatBytes
import com.pulse.optimizer.ui.components.HealthGauge
import com.pulse.optimizer.ui.components.StatCard
import com.pulse.optimizer.ui.components.StatRow
import com.pulse.optimizer.ui.theme.Amber
import com.pulse.optimizer.ui.theme.Coral
import com.pulse.optimizer.ui.theme.Ink
import com.pulse.optimizer.ui.theme.Mint
import com.pulse.optimizer.ui.theme.Surface1
import com.pulse.optimizer.ui.theme.Surface2
import com.pulse.optimizer.ui.theme.TextSecondary

@Composable
fun MainScreen(vm: OptimizerViewModel, modifier: Modifier = Modifier) {
    val state by vm.state.collectAsState()
    val stats = state.stats
    val working = state.phase == OptimizePhase.Scanning || state.phase == OptimizePhase.Cleaning

    Box(modifier = modifier) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .statusBarsPadding()
                .navigationBarsPadding()
                .padding(horizontal = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.height(16.dp))

            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f)) {
                    Text(
                        text = "Pulse",
                        style = MaterialTheme.typography.headlineMedium,
                        color = Color.White,
                    )
                    Text(
                        text = "оптимизатор устройства",
                        style = MaterialTheme.typography.bodyMedium,
                        color = TextSecondary,
                    )
                }
                IconButton(onClick = vm::refresh) {
                    Icon(
                        imageVector = Icons.Outlined.Refresh,
                        contentDescription = "Обновить",
                        tint = TextSecondary,
                    )
                }
            }

            Spacer(Modifier.height(24.dp))

            HealthGauge(score = stats.healthScore, isWorking = working)

            Spacer(Modifier.height(8.dp))

            // Status line under the gauge
            AnimatedVisibility(visible = working, enter = fadeIn(), exit = fadeOut()) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = state.currentStep,
                        style = MaterialTheme.typography.bodyMedium,
                        color = Mint,
                        textAlign = TextAlign.Center,
                    )
                    Spacer(Modifier.height(10.dp))
                    LinearProgressIndicator(
                        progress = { state.progress },
                        modifier = Modifier
                            .fillMaxWidth(0.55f)
                            .clip(RoundedCornerShape(2.dp)),
                        color = Mint,
                        trackColor = Surface2,
                    )
                }
            }

            Spacer(Modifier.height(24.dp))

            // Metric cards
            StatRow(
                left = { m ->
                    StatCard(
                        icon = Icons.Outlined.Memory,
                        label = "Память",
                        value = formatBytes(stats.ramUsedBytes),
                        detail = "из ${formatBytes(stats.ramTotalBytes)}",
                        fraction = stats.ramFraction,
                        accent = if (stats.ramFraction < 0.8f) Mint else Coral,
                        modifier = m,
                    )
                },
                right = { m ->
                    StatCard(
                        icon = Icons.Outlined.Storage,
                        label = "Хранилище",
                        value = formatBytes(stats.storageUsedBytes),
                        detail = "из ${formatBytes(stats.storageTotalBytes)}",
                        fraction = stats.storageFraction,
                        accent = if (stats.storageFraction < 0.85f) Mint else Amber,
                        modifier = m,
                    )
                },
            )

            Spacer(Modifier.height(12.dp))

            StatRow(
                left = { m ->
                    StatCard(
                        icon = if (stats.isCharging) Icons.Outlined.BatteryChargingFull
                        else Icons.Outlined.BatteryStd,
                        label = "Батарея",
                        value = "${stats.batteryPercent}%",
                        detail = if (stats.isCharging) "заряжается" else "автономно",
                        fraction = stats.batteryPercent / 100f,
                        accent = if (stats.batteryPercent > 20) Mint else Coral,
                        modifier = m,
                    )
                },
                right = { m ->
                    StatCard(
                        icon = Icons.Outlined.Bolt,
                        label = "Кэш",
                        value = formatBytes(stats.cacheEstimateBytes),
                        detail = "можно освободить",
                        fraction = (stats.cacheEstimateBytes / 52_428_800f).coerceIn(0.02f, 1f),
                        accent = Amber,
                        modifier = m,
                    )
                },
            )

            Spacer(Modifier.height(28.dp))

            // Main action button
            val buttonAlpha by animateFloatAsState(
                targetValue = if (working) 0.4f else 1f,
                animationSpec = tween(300),
                label = "buttonAlpha",
            )
            Button(
                onClick = vm::optimize,
                enabled = !working,
                shape = RoundedCornerShape(20.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Mint,
                    contentColor = Ink,
                    disabledContainerColor = Mint.copy(alpha = buttonAlpha * 0.4f),
                    disabledContentColor = Ink.copy(alpha = 0.6f),
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(58.dp),
            ) {
                Icon(
                    imageVector = Icons.Outlined.Bolt,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                )
                Spacer(Modifier.size(8.dp))
                Text(
                    text = if (working) "Оптимизация…" else "Оптимизировать",
                    style = MaterialTheme.typography.titleMedium,
                )
            }

            Spacer(Modifier.height(32.dp))
        }

        // Result sheet
        AnimatedVisibility(
            visible = state.phase == OptimizePhase.Done,
            enter = slideInVertically(initialOffsetY = { it }) + fadeIn(),
            exit = slideOutVertically(targetOffsetY = { it }) + fadeOut(),
            modifier = Modifier.align(Alignment.BottomCenter),
        ) {
            ResultSheet(
                freedBytes = state.freedBytes,
                score = stats.healthScore,
                onDismiss = vm::dismissResult,
            )
        }
    }
}

@Composable
private fun ResultSheet(freedBytes: Long, score: Int, onDismiss: () -> Unit) {
    Surface(
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
        color = Surface1,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier
                .navigationBarsPadding()
                .padding(horizontal = 24.dp, vertical = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(
                modifier = Modifier
                    .size(64.dp)
                    .clip(CircleShape)
                    .background(Mint.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = Icons.Outlined.CheckCircle,
                    contentDescription = null,
                    tint = Mint,
                    modifier = Modifier.size(34.dp),
                )
            }

            Spacer(Modifier.height(16.dp))

            Text(
                text = "Готово",
                style = MaterialTheme.typography.headlineMedium,
                color = Color.White,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = "Освобождено ${formatBytes(freedBytes)} · индекс здоровья $score",
                style = MaterialTheme.typography.bodyMedium,
                color = TextSecondary,
                textAlign = TextAlign.Center,
            )

            Spacer(Modifier.height(20.dp))

            Button(
                onClick = onDismiss,
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Surface2,
                    contentColor = Color.White,
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
            ) {
                Text("Отлично", style = MaterialTheme.typography.titleMedium)
            }
        }
    }
}
