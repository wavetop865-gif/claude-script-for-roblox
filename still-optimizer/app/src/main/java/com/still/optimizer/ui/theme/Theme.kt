package com.still.optimizer.ui.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import com.still.optimizer.R

val Fraunces = FontFamily(
    Font(R.font.fraunces_regular, FontWeight.Normal),
    Font(R.font.fraunces_semibold, FontWeight.SemiBold),
)

val Outfit = FontFamily(
    Font(R.font.outfit_regular, FontWeight.Normal),
    Font(R.font.outfit_medium, FontWeight.Medium),
    Font(R.font.outfit_semibold, FontWeight.SemiBold),
)

object StillTheme {
    val colors: StillColors
        @Composable
        @ReadOnlyComposable
        get() = LocalStillColors.current
}

@Composable
fun StillTheme(content: @Composable () -> Unit) {
    CompositionLocalProvider(LocalStillColors provides StillColors()) {
        content()
    }
}
