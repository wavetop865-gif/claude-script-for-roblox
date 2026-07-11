package com.pulse.optimizer.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Palette — deep graphite with a mint accent.
val Ink = Color(0xFF0B0E14)
val Surface1 = Color(0xFF12161F)
val Surface2 = Color(0xFF1A1F2B)
val Mint = Color(0xFF4FE3C1)
val MintDim = Color(0xFF2A6B5C)
val Amber = Color(0xFFF5C97B)
val Coral = Color(0xFFF07A6B)
val TextPrimary = Color(0xFFEDF1F7)
val TextSecondary = Color(0xFF8A94A6)

private val DarkScheme = darkColorScheme(
    primary = Mint,
    onPrimary = Ink,
    secondary = Amber,
    background = Ink,
    onBackground = TextPrimary,
    surface = Surface1,
    onSurface = TextPrimary,
    surfaceVariant = Surface2,
    onSurfaceVariant = TextSecondary,
    error = Coral,
)

@Composable
fun PulseTheme(content: @Composable () -> Unit) {
    // The app is intentionally dark-only: the design language is built
    // around a graphite canvas regardless of the system setting.
    isSystemInDarkTheme()
    MaterialTheme(
        colorScheme = DarkScheme,
        typography = PulseTypography,
        content = content,
    )
}
