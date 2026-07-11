package com.sfera.optimizer.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

object SferaColors {
    val Background = Color(0xFF0B0D0C)
    val Surface = Color(0xFF141715)
    val SurfaceRaised = Color(0xFF1B1F1C)
    val Border = Color(0xFF2A302C)
    val Lime = Color(0xFFC7F36B)
    val LimeDark = Color(0xFF27331D)
    val Aqua = Color(0xFF6DE5C4)
    val Amber = Color(0xFFFFC66B)
    val Text = Color(0xFFF3F5F1)
    val TextSecondary = Color(0xFFA5ADA7)
    val TextMuted = Color(0xFF68706A)
}

private val CrispText = PlatformTextStyle(includeFontPadding = false)

object SferaTypography {
    val hero = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.Light,
        fontSize = 50.sp,
        lineHeight = 52.sp,
        letterSpacing = (-2).sp,
        platformStyle = CrispText
    )
    val title = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.SemiBold,
        fontSize = 24.sp,
        lineHeight = 28.sp,
        letterSpacing = (-0.5).sp,
        platformStyle = CrispText
    )
    val body = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.Normal,
        fontSize = 15.sp,
        lineHeight = 21.sp,
        letterSpacing = 0.sp,
        platformStyle = CrispText
    )
    val label = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.4.sp,
        platformStyle = CrispText
    )
}

private val DarkScheme = darkColorScheme(
    background = SferaColors.Background,
    surface = SferaColors.Surface,
    surfaceVariant = SferaColors.SurfaceRaised,
    onBackground = SferaColors.Text,
    onSurface = SferaColors.Text,
    primary = SferaColors.Lime,
    onPrimary = SferaColors.Background,
    secondary = SferaColors.Aqua,
    outline = SferaColors.Border
)

private val AppTypography = Typography(
    displayLarge = SferaTypography.hero,
    headlineMedium = SferaTypography.title,
    bodyMedium = SferaTypography.body,
    labelMedium = SferaTypography.label
)

@Composable
fun SferaTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkScheme,
        typography = AppTypography,
        shapes = Shapes(
            small = androidx.compose.foundation.shape.RoundedCornerShape(14.dp),
            medium = androidx.compose.foundation.shape.RoundedCornerShape(22.dp),
            large = androidx.compose.foundation.shape.RoundedCornerShape(32.dp)
        ),
        content = content
    )
}
