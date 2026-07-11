package com.still.optimizer.ui.theme

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/**
 * Still palette — cool mist atmosphere with sage calm accent.
 * Soft morning fog over still water; never purple, never cream-terracotta.
 */
@Immutable
data class StillColors(
    val mist: Color = Color(0xFFE6EEF2),
    val mistDeep: Color = Color(0xFFD0DDE6),
    val mistSoft: Color = Color(0xFFF3F7F9),
    val ink: Color = Color(0xFF15202B),
    val inkSoft: Color = Color(0xFF3A4A58),
    val inkMuted: Color = Color(0xFF7A8B99),
    val sage: Color = Color(0xFF4F7A6C),
    val sageSoft: Color = Color(0xFF6B9A8A),
    val sageGlow: Color = Color(0x334F7A6C),
    val sand: Color = Color(0xFFC9B8A0),
    val line: Color = Color(0x3315202B),
    val ringTrack: Color = Color(0x2215202B),
)

val LocalStillColors = staticCompositionLocalOf { StillColors() }
