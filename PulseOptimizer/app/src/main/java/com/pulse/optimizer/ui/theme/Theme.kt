package com.pulse.optimizer.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Palette — deep space + neon mint
val DeepSpace = Color(0xFF0B0E14)
val Surface1 = Color(0xFF121722)
val Surface2 = Color(0xFF1A2130)
val NeonMint = Color(0xFF5EF2C4)
val ElectricBlue = Color(0xFF57A6FF)
val SoftViolet = Color(0xFF9D7BFF)
val WarmAmber = Color(0xFFFFC46B)
val DangerRose = Color(0xFFFF6B8B)
val TextPrimary = Color(0xFFEDF1F7)
val TextSecondary = Color(0xFF8B93A7)

private val PulseColorScheme = darkColorScheme(
    primary = NeonMint,
    onPrimary = DeepSpace,
    secondary = ElectricBlue,
    onSecondary = DeepSpace,
    tertiary = SoftViolet,
    background = DeepSpace,
    onBackground = TextPrimary,
    surface = Surface1,
    onSurface = TextPrimary,
    surfaceVariant = Surface2,
    onSurfaceVariant = TextSecondary,
    error = DangerRose,
)

@Composable
fun PulseOptimizerTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = PulseColorScheme,
        content = content
    )
}
