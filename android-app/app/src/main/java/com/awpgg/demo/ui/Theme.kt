package com.awpgg.demo.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

object AwpColors {
    val Bg = Color(0xFF161618)
    val BgPanel = Color(0xFF101012)
    val BgSection = Color(0xFF1A1A1C)
    val BgInput = Color(0xFF202022)
    val Stroke = Color(0xFF2E2E32)
    val StrokeSoft = Color(0xFF26262A)
    val Accent = Color(0xFFD2D2D7)
    val AccentBright = Color(0xFFF5F5FA)
    val AccentDim = Color(0xFF5F5F64)
    val Text = Color(0xFFDCDCE0)
    val TextDim = Color(0xFF96969E)
    val TextMuted = Color(0xFF696970)
}

private val DarkScheme = darkColorScheme(
    background = AwpColors.Bg,
    surface = AwpColors.BgSection,
    onBackground = AwpColors.Text,
    onSurface = AwpColors.Text,
    primary = AwpColors.Accent,
    onPrimary = AwpColors.BgPanel,
    outline = AwpColors.Stroke
)

@Composable
fun AwpTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkScheme,
        content = content
    )
}
