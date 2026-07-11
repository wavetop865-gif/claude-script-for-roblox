package com.sfera.optimizer.ui

import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.Settings
import android.widget.Toast
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sfera.optimizer.DeviceSnapshot
import com.sfera.optimizer.clearTemporaryFiles
import com.sfera.optimizer.formatBytes
import com.sfera.optimizer.readDeviceSnapshot
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

private enum class Section(val title: String) {
    HOME("Обзор"),
    STORAGE("Память"),
    BATTERY("Энергия")
}

@Composable
fun OptimizerApp() {
    val context = LocalContext.current
    var section by remember { mutableStateOf(Section.HOME) }
    var snapshot by remember { mutableStateOf(readDeviceSnapshot(context)) }
    var isOptimizing by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        while (true) {
            delay(15_000)
            snapshot = readDeviceSnapshot(context)
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(SferaColors.Background)
    ) {
        AmbientBackdrop()
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
        ) {
            AnimatedContent(
                targetState = section,
                transitionSpec = { fadeIn(tween(220)) togetherWith fadeOut(tween(140)) },
                label = "section",
                modifier = Modifier.weight(1f)
            ) { target ->
                when (target) {
                    Section.HOME -> HomeScreen(
                        snapshot = snapshot,
                        isOptimizing = isOptimizing,
                        onOptimize = {
                            if (!isOptimizing) {
                                scope.launch {
                                    isOptimizing = true
                                    delay(650)
                                    val freed = withContext(Dispatchers.IO) {
                                        clearTemporaryFiles(context)
                                    }
                                    delay(650)
                                    snapshot = readDeviceSnapshot(context)
                                    isOptimizing = false
                                    val result = if (freed > 0) {
                                        "Освобождено ${formatBytes(freed)} временных данных"
                                    } else {
                                        "Проверка завершена — всё уже в порядке"
                                    }
                                    Toast.makeText(context, result, Toast.LENGTH_LONG).show()
                                }
                            }
                        },
                        onOpenStorage = {
                            openSettings(context, Settings.ACTION_INTERNAL_STORAGE_SETTINGS)
                        }
                    )
                    Section.STORAGE -> StorageScreen(
                        snapshot = snapshot,
                        onOpenStorage = {
                            openSettings(context, Settings.ACTION_INTERNAL_STORAGE_SETTINGS)
                        },
                        onRefresh = { snapshot = readDeviceSnapshot(context) }
                    )
                    Section.BATTERY -> BatteryScreen(
                        snapshot = snapshot,
                        onOpenBattery = {
                            openSettings(context, Settings.ACTION_BATTERY_SAVER_SETTINGS)
                        }
                    )
                }
            }
            BottomNavigation(selected = section, onSelected = { section = it })
        }
    }
}

@Composable
private fun AmbientBackdrop() {
    val motion = rememberInfiniteTransition(label = "ambient")
    val drift by motion.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(9000), RepeatMode.Reverse),
        label = "drift"
    )
    Canvas(Modifier.fillMaxSize()) {
        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(SferaColors.Lime.copy(alpha = 0.10f), Color.Transparent),
                center = Offset(size.width * (0.82f - drift * 0.08f), size.height * 0.12f),
                radius = size.width * 0.66f
            ),
            radius = size.width * 0.66f,
            center = Offset(size.width * (0.82f - drift * 0.08f), size.height * 0.12f)
        )
        drawCircle(
            color = SferaColors.Aqua.copy(alpha = 0.04f),
            radius = size.width * 0.52f,
            center = Offset(-size.width * 0.12f, size.height * (0.72f + drift * 0.03f))
        )
    }
}

@Composable
private fun ScreenHeader(eyebrow: String, title: String, subtitle: String) {
    Column(modifier = Modifier.padding(horizontal = 22.dp, vertical = 18.dp)) {
        Text(
            text = eyebrow.uppercase(),
            color = SferaColors.Lime,
            style = SferaTypography.label
        )
        Spacer(Modifier.height(10.dp))
        Text(text = title, color = SferaColors.Text, style = SferaTypography.title)
        Spacer(Modifier.height(6.dp))
        Text(text = subtitle, color = SferaColors.TextSecondary, style = SferaTypography.body)
    }
}

@Composable
private fun HomeScreen(
    snapshot: DeviceSnapshot,
    isOptimizing: Boolean,
    onOptimize: () -> Unit,
    onOpenStorage: () -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(bottom = 24.dp)
    ) {
        item {
            ScreenHeader(
                eyebrow = "СФЕРА · УСТРОЙСТВО",
                title = "Добрый вечер",
                subtitle = "Честная диагностика без агрессивного закрытия приложений."
            )
        }
        item {
            ScoreCard(
                score = snapshot.score,
                isOptimizing = isOptimizing,
                onOptimize = onOptimize
            )
        }
        item {
            Text(
                text = "СОСТОЯНИЕ",
                color = SferaColors.TextMuted,
                style = SferaTypography.label,
                modifier = Modifier.padding(start = 22.dp, top = 24.dp, bottom = 10.dp)
            )
        }
        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 22.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                MetricCard(
                    modifier = Modifier.weight(1f),
                    label = "Хранилище",
                    value = "${snapshot.storageUsedPercent}%",
                    detail = "${snapshot.storageFree} свободно",
                    progress = snapshot.storageUsedPercent / 100f,
                    accent = SferaColors.Aqua,
                    onClick = onOpenStorage
                )
                MetricCard(
                    modifier = Modifier.weight(1f),
                    label = "Оперативная",
                    value = "${snapshot.memoryUsedPercent}%",
                    detail = "${snapshot.memoryFree} доступно",
                    progress = snapshot.memoryUsedPercent / 100f,
                    accent = SferaColors.Amber
                )
            }
        }
        item {
            InsightCard(snapshot = snapshot)
        }
    }
}

@Composable
private fun ScoreCard(score: Int, isOptimizing: Boolean, onOptimize: () -> Unit) {
    val animatedScore by animateFloatAsState(
        targetValue = score.toFloat(),
        animationSpec = tween(900),
        label = "score"
    )
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 22.dp)
            .clip(RoundedCornerShape(30.dp))
            .background(
                Brush.linearGradient(
                    listOf(Color(0xFF20271D), SferaColors.Surface)
                )
            )
            .border(1.dp, SferaColors.Lime.copy(alpha = 0.16f), RoundedCornerShape(30.dp))
            .padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(contentAlignment = Alignment.Center, modifier = Modifier.size(184.dp)) {
            Canvas(Modifier.fillMaxSize()) {
                drawArc(
                    color = SferaColors.Border,
                    startAngle = 138f,
                    sweepAngle = 264f,
                    useCenter = false,
                    style = Stroke(12.dp.toPx(), cap = StrokeCap.Round)
                )
                drawArc(
                    brush = Brush.sweepGradient(
                        listOf(SferaColors.Aqua, SferaColors.Lime, SferaColors.Aqua)
                    ),
                    startAngle = 138f,
                    sweepAngle = 264f * (animatedScore / 100f),
                    useCenter = false,
                    style = Stroke(12.dp.toPx(), cap = StrokeCap.Round)
                )
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = score.toString(),
                    color = SferaColors.Text,
                    style = SferaTypography.hero
                )
                Text(
                    text = if (score >= 75) "ОТЛИЧНО" else "СТАБИЛЬНО",
                    color = SferaColors.TextSecondary,
                    style = SferaTypography.label
                )
            }
        }
        Text(
            text = if (isOptimizing) "Проверяем устройство…" else "Безопасная оптимизация",
            color = SferaColors.Text,
            fontSize = 18.sp,
            fontWeight = FontWeight.SemiBold
        )
        Text(
            text = "Удалим только временные файлы Сферы и обновим диагностику",
            color = SferaColors.TextSecondary,
            style = SferaTypography.body,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 5.dp, bottom = 16.dp)
        )
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp)
                .clip(RoundedCornerShape(18.dp))
                .background(if (isOptimizing) SferaColors.LimeDark else SferaColors.Lime)
                .clickable(enabled = !isOptimizing, onClick = onOptimize),
            contentAlignment = Alignment.Center
        ) {
            if (isOptimizing) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = SferaColors.Lime,
                        strokeWidth = 2.dp
                    )
                    Spacer(Modifier.width(10.dp))
                    Text("АНАЛИЗ", color = SferaColors.Lime, style = SferaTypography.label)
                }
            } else {
                Text("ОПТИМИЗИРОВАТЬ", color = SferaColors.Background, style = SferaTypography.label)
            }
        }
    }
}

@Composable
private fun MetricCard(
    modifier: Modifier,
    label: String,
    value: String,
    detail: String,
    progress: Float,
    accent: Color,
    onClick: (() -> Unit)? = null
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(22.dp))
            .background(SferaColors.Surface.copy(alpha = 0.92f))
            .border(1.dp, SferaColors.Border, RoundedCornerShape(22.dp))
            .clickable(enabled = onClick != null) { onClick?.invoke() }
            .padding(16.dp)
    ) {
        Box(
            modifier = Modifier
                .size(9.dp)
                .clip(CircleShape)
                .background(accent)
        )
        Spacer(Modifier.height(20.dp))
        Text(text = value, color = SferaColors.Text, fontSize = 27.sp, fontWeight = FontWeight.Light)
        Text(text = label, color = SferaColors.Text, style = SferaTypography.label)
        Spacer(Modifier.height(13.dp))
        ProgressLine(progress = progress, color = accent)
        Spacer(Modifier.height(9.dp))
        Text(text = detail, color = SferaColors.TextMuted, fontSize = 11.sp)
    }
}

@Composable
private fun InsightCard(snapshot: DeviceSnapshot) {
    val message = when {
        snapshot.storageUsedPercent >= 90 ->
            "Хранилище почти заполнено. Освободите место через системный менеджер."
        snapshot.memoryUsedPercent >= 85 ->
            "Высокая нагрузка на память нормальна для Android — система освободит её сама."
        else ->
            "Критичных проблем не найдено. Android самостоятельно управляет фоновой памятью."
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 22.dp, vertical = 14.dp)
            .clip(RoundedCornerShape(22.dp))
            .background(SferaColors.SurfaceRaised.copy(alpha = 0.72f))
            .padding(16.dp),
        verticalAlignment = Alignment.Top
    ) {
        Box(
            modifier = Modifier
                .size(34.dp)
                .clip(CircleShape)
                .background(SferaColors.LimeDark),
            contentAlignment = Alignment.Center
        ) {
            Text("i", color = SferaColors.Lime, fontWeight = FontWeight.Bold)
        }
        Spacer(Modifier.width(12.dp))
        Column {
            Text("Рекомендация", color = SferaColors.Text, style = SferaTypography.label)
            Text(
                text = message,
                color = SferaColors.TextSecondary,
                style = SferaTypography.body,
                modifier = Modifier.padding(top = 3.dp)
            )
        }
    }
}

@Composable
private fun StorageScreen(
    snapshot: DeviceSnapshot,
    onOpenStorage: () -> Unit,
    onRefresh: () -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(bottom = 24.dp)
    ) {
        item {
            ScreenHeader(
                eyebrow = "ХРАНИЛИЩЕ",
                title = "${snapshot.storageFree} свободно",
                subtitle = "Из ${snapshot.storageTotal} внутренней памяти"
            )
        }
        item {
            LargeProgressCard(
                progress = snapshot.storageUsedPercent / 100f,
                value = "${snapshot.storageUsedPercent}%",
                title = "Использовано",
                accent = SferaColors.Aqua
            )
        }
        item {
            ActionRow(
                marker = "01",
                title = "Управление файлами",
                subtitle = "Открыть встроенный менеджер Android",
                onClick = onOpenStorage
            )
            ActionRow(
                marker = "02",
                title = "Обновить расчёт",
                subtitle = "Повторно проверить свободное место",
                onClick = onRefresh
            )
        }
        item {
            PrivacyNote(
                text = "Сфера не запрашивает доступ ко всем файлам. Очистка загрузок и данных других приложений выполняется только в системных настройках."
            )
        }
    }
}

@Composable
private fun BatteryScreen(snapshot: DeviceSnapshot, onOpenBattery: () -> Unit) {
    val batteryLabel = if (snapshot.isCharging) "Идёт зарядка" else "Работа от аккумулятора"
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(bottom = 24.dp)
    ) {
        item {
            ScreenHeader(
                eyebrow = "ЭНЕРГИЯ",
                title = "${snapshot.batteryPercent}% заряда",
                subtitle = batteryLabel
            )
        }
        item {
            LargeProgressCard(
                progress = snapshot.batteryPercent / 100f,
                value = "${snapshot.batteryPercent}%",
                title = if (snapshot.isCharging) "Подключено" else "Осталось",
                accent = SferaColors.Lime
            )
        }
        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 22.dp, vertical = 14.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                InfoTile(
                    modifier = Modifier.weight(1f),
                    value = "${snapshot.batteryTemperature}°",
                    label = "Температура"
                )
                InfoTile(
                    modifier = Modifier.weight(1f),
                    value = if (snapshot.isCharging) "ON" else "OFF",
                    label = "Зарядка"
                )
            }
        }
        item {
            ActionRow(
                marker = "→",
                title = "Режим энергосбережения",
                subtitle = "Настроить системные ограничения",
                onClick = onOpenBattery
            )
            PrivacyNote(
                text = "Приложение показывает данные, которые предоставляет Android, и не ограничивает фоновые процессы без вашего решения."
            )
        }
    }
}

@Composable
private fun LargeProgressCard(
    progress: Float,
    value: String,
    title: String,
    accent: Color
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 22.dp)
            .clip(RoundedCornerShape(28.dp))
            .background(SferaColors.Surface)
            .border(1.dp, SferaColors.Border, RoundedCornerShape(28.dp))
            .padding(20.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(modifier = Modifier.size(110.dp), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(
                progress = { progress },
                modifier = Modifier.fillMaxSize(),
                color = accent,
                trackColor = SferaColors.Border,
                strokeWidth = 9.dp
            )
            Text(value, color = SferaColors.Text, fontSize = 23.sp, fontWeight = FontWeight.Light)
        }
        Spacer(Modifier.width(20.dp))
        Column {
            Text(title, color = SferaColors.Text, fontSize = 18.sp, fontWeight = FontWeight.SemiBold)
            Text(
                "Актуальные системные данные",
                color = SferaColors.TextSecondary,
                style = SferaTypography.body,
                modifier = Modifier.padding(top = 5.dp)
            )
        }
    }
}

@Composable
private fun ActionRow(marker: String, title: String, subtitle: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 22.dp, vertical = 5.dp)
            .clip(RoundedCornerShape(20.dp))
            .clickable(onClick = onClick)
            .padding(vertical = 15.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(42.dp)
                .clip(CircleShape)
                .background(SferaColors.SurfaceRaised),
            contentAlignment = Alignment.Center
        ) {
            Text(marker, color = SferaColors.Lime, style = SferaTypography.label)
        }
        Spacer(Modifier.width(13.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(title, color = SferaColors.Text, fontSize = 15.sp, fontWeight = FontWeight.Medium)
            Text(subtitle, color = SferaColors.TextMuted, fontSize = 12.sp)
        }
        Text("›", color = SferaColors.TextSecondary, fontSize = 25.sp)
    }
}

@Composable
private fun InfoTile(modifier: Modifier, value: String, label: String) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(20.dp))
            .background(SferaColors.Surface)
            .padding(16.dp)
    ) {
        Text(value, color = SferaColors.Text, fontSize = 24.sp, fontWeight = FontWeight.Light)
        Text(label, color = SferaColors.TextSecondary, style = SferaTypography.label)
    }
}

@Composable
private fun PrivacyNote(text: String) {
    Text(
        text = text,
        color = SferaColors.TextMuted,
        style = SferaTypography.body,
        modifier = Modifier.padding(horizontal = 22.dp, vertical = 20.dp)
    )
}

@Composable
private fun ProgressLine(progress: Float, color: Color) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(3.dp)
            .clip(CircleShape)
            .background(SferaColors.Border)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(progress.coerceIn(0f, 1f))
                .fillMaxHeight()
                .background(color)
        )
    }
}

@Composable
private fun BottomNavigation(selected: Section, onSelected: (Section) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(SferaColors.Background.copy(alpha = 0.96f))
            .border(1.dp, SferaColors.Border.copy(alpha = 0.65f))
            .navigationBarsPadding()
            .padding(horizontal = 12.dp, vertical = 9.dp),
        horizontalArrangement = Arrangement.SpaceAround
    ) {
        Section.entries.forEach { section ->
            val active = section == selected
            Column(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(16.dp))
                    .clickable { onSelected(section) }
                    .padding(vertical = 7.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                NavigationGlyph(section = section, active = active)
                Spacer(Modifier.height(4.dp))
                Text(
                    text = section.title,
                    color = if (active) SferaColors.Lime else SferaColors.TextMuted,
                    fontSize = 10.sp,
                    fontWeight = if (active) FontWeight.SemiBold else FontWeight.Normal
                )
            }
        }
    }
}

@Composable
private fun NavigationGlyph(section: Section, active: Boolean) {
    val color = if (active) SferaColors.Lime else SferaColors.TextMuted
    Canvas(modifier = Modifier.size(21.dp)) {
        val stroke = Stroke(width = 1.8.dp.toPx(), cap = StrokeCap.Round)
        when (section) {
            Section.HOME -> {
                drawCircle(color, radius = size.minDimension * 0.34f, style = stroke)
                drawCircle(color, radius = 2.dp.toPx())
            }
            Section.STORAGE -> {
                drawArc(color, 205f, 290f, false, style = stroke)
                drawLine(
                    color,
                    Offset(size.width * 0.25f, size.height * 0.62f),
                    Offset(size.width * 0.75f, size.height * 0.62f),
                    strokeWidth = 1.8.dp.toPx(),
                    cap = StrokeCap.Round
                )
            }
            Section.BATTERY -> {
                drawRoundRect(
                    color = color,
                    topLeft = Offset(size.width * 0.23f, size.height * 0.12f),
                    size = androidx.compose.ui.geometry.Size(size.width * 0.54f, size.height * 0.76f),
                    cornerRadius = androidx.compose.ui.geometry.CornerRadius(3.dp.toPx()),
                    style = stroke
                )
                drawLine(
                    color,
                    Offset(size.width * 0.42f, size.height * 0.05f),
                    Offset(size.width * 0.58f, size.height * 0.05f),
                    strokeWidth = 2.dp.toPx()
                )
            }
        }
    }
}

private fun openSettings(context: android.content.Context, action: String) {
    try {
        context.startActivity(Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    } catch (_: ActivityNotFoundException) {
        context.startActivity(Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }
}
