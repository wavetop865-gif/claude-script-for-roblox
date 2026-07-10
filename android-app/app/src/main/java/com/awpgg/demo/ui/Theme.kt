package com.awpgg.demo.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

// "Nova" design language: deep space dark + violet-to-cyan gradient accent,
// rounded surfaces, pill controls.
object AwpColors {
    val Bg = Color(0xFF0E0E16)
    val BgPanel = Color(0xFF13131D)
    val BgSection = Color(0xFF181826)
    val BgInput = Color(0xFF212132)
    val Stroke = Color(0xFF2C2C42)
    val StrokeSoft = Color(0xFF232336)

    val Accent = Color(0xFF8B5CF6)
    val AccentAlt = Color(0xFF22D3EE)
    val AccentBright = Color(0xFFB79CFF)
    val AccentDim = Color(0xFF5B3FA8)

    val Text = Color(0xFFE9E9F4)
    val TextDim = Color(0xFF9C9CB2)
    val TextMuted = Color(0xFF60607A)
}

object AwpGradients {
    val accent = Brush.horizontalGradient(
        listOf(AwpColors.Accent, AwpColors.AccentAlt)
    )
    val accentVertical = Brush.verticalGradient(
        listOf(AwpColors.Accent, AwpColors.AccentAlt)
    )
    val header = Brush.horizontalGradient(
        listOf(Color(0xFF191929), Color(0xFF13131D))
    )
}

private val CrispText = PlatformTextStyle(includeFontPadding = false)

object AwpTypography {
    val title = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.Bold,
        fontSize = 22.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.sp,
        platformStyle = CrispText
    )
    val body = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.sp,
        platformStyle = CrispText
    )
    val label = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        lineHeight = 14.sp,
        letterSpacing = 0.sp,
        platformStyle = CrispText
    )
    val caption = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.Normal,
        fontSize = 11.sp,
        lineHeight = 13.sp,
        letterSpacing = 0.sp,
        platformStyle = CrispText
    )
}

private val DarkScheme = darkColorScheme(
    background = AwpColors.Bg,
    surface = AwpColors.BgSection,
    onBackground = AwpColors.Text,
    onSurface = AwpColors.Text,
    primary = AwpColors.Accent,
    onPrimary = Color.White,
    outline = AwpColors.Stroke
)

private val AwpMaterialTypography = Typography(
    bodyMedium = AwpTypography.body,
    labelMedium = AwpTypography.label,
    titleMedium = AwpTypography.title
)

@Composable
fun AwpTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkScheme,
        typography = AwpMaterialTypography,
        content = content
    )
}
