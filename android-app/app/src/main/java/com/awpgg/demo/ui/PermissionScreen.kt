package com.awpgg.demo.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.awpgg.demo.PermissionStatus

@Composable
fun PermissionScreen(
    status: PermissionStatus,
    onRequestNotifications: () -> Unit,
    onRequestOverlay: () -> Unit,
    onStartMenu: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0A0A0C))
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp, vertical = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("awp.gg Demo", style = AwpTypography.title, color = AwpColors.Text)
        Spacer(Modifier.height(6.dp))
        Text(
            "Перед запуском нужны разрешения",
            style = AwpTypography.body,
            color = AwpColors.TextDim
        )
        Spacer(Modifier.height(28.dp))

        PermissionCard(
            title = "Уведомления",
            description = "Чтобы меню работало в фоне и его можно было закрыть из шторки",
            granted = status.notificationsGranted,
            skipped = !status.needsNotifications && !status.notificationsGranted,
            actionLabel = if (status.notificationsGranted) "Выдано" else "Разрешить",
            enabled = status.needsNotifications,
            onAction = onRequestNotifications
        )

        Spacer(Modifier.height(12.dp))

        PermissionCard(
            title = "Поверх других приложений",
            description = "Чтобы меню отображалось поверх Roblox и других приложений",
            granted = status.overlayGranted,
            skipped = false,
            actionLabel = if (status.overlayGranted) "Выдано" else "Открыть настройки",
            enabled = !status.overlayGranted,
            onAction = onRequestOverlay
        )

        Spacer(Modifier.height(28.dp))

        if (!status.allGranted) {
            DemoButton("Выдать все разрешения") {
                when {
                    status.needsNotifications -> onRequestNotifications()
                    !status.overlayGranted -> onRequestOverlay()
                }
            }
            Spacer(Modifier.height(10.dp))
            Text(
                "Разрешения запрашиваются по очереди",
                style = AwpTypography.caption,
                color = AwpColors.TextMuted
            )
        } else {
            DemoButton("Запустить меню") { onStartMenu() }
            Spacer(Modifier.height(10.dp))
            Text(
                "Все разрешения получены — можно запускать",
                style = AwpTypography.caption,
                color = AwpColors.AccentDim
            )
        }
    }
}

@Composable
private fun PermissionCard(
    title: String,
    description: String,
    granted: Boolean,
    skipped: Boolean,
    actionLabel: String,
    enabled: Boolean,
    onAction: () -> Unit
) {
    val borderColor = when {
        granted -> AwpColors.AccentDim
        skipped -> AwpColors.StrokeSoft
        else -> AwpColors.Stroke
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(AwpColors.BgSection)
            .border(1.dp, borderColor)
            .padding(14.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(title, style = AwpTypography.label, color = AwpColors.Text, fontWeight = FontWeight.Bold)
            StatusBadge(granted = granted, skipped = skipped)
        }
        Spacer(Modifier.height(6.dp))
        Text(description, style = AwpTypography.caption, color = AwpColors.TextDim)
        if (!granted && !skipped) {
            Spacer(Modifier.height(12.dp))
            DemoButton(actionLabel, enabled = enabled, onClick = onAction)
        }
    }
}

@Composable
private fun StatusBadge(granted: Boolean, skipped: Boolean) {
    val (text, color) = when {
        granted -> "✓" to AwpColors.AccentBright
        skipped -> "—" to AwpColors.TextMuted
        else -> "!" to Color(0xFFE0A060)
    }
    Box(
        modifier = Modifier
            .size(22.dp)
            .background(AwpColors.BgInput)
            .border(1.dp, AwpColors.StrokeSoft),
        contentAlignment = Alignment.Center
    ) {
        Text(text, color = color, fontSize = 12.sp, fontWeight = FontWeight.Bold)
    }
}
