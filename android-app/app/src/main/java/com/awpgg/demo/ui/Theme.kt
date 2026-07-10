package com.awpgg.demo.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

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
    onPrimary = AwpColors.BgPanel,
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
