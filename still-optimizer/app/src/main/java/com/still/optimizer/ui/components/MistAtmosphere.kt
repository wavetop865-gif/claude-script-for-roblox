package com.still.optimizer.ui.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Path
import com.still.optimizer.ui.theme.StillTheme
import kotlin.math.sin
import kotlin.random.Random

@Composable
fun MistAtmosphere(modifier: Modifier = Modifier) {
    val colors = StillTheme.colors
    val transition = rememberInfiniteTransition(label = "mist")
    val drift by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(14000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart,
        ),
        label = "drift",
    )
    val wave by transition.animateFloat(
        initialValue = 0f,
        targetValue = (Math.PI * 2).toFloat(),
        animationSpec = infiniteRepeatable(
            animation = tween(9000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart,
        ),
        label = "wave",
    )

    val motes = remember {
        List(18) {
            Triple(
                Random.nextFloat(),
                Random.nextFloat(),
                0.4f + Random.nextFloat() * 0.6f,
            )
        }
    }

    Canvas(modifier = modifier.fillMaxSize()) {
        drawRect(
            brush = Brush.verticalGradient(
                colors = listOf(
                    colors.mistSoft,
                    colors.mist,
                    colors.mistDeep,
                ),
            ),
        )

        // Soft diagonal wash
        drawRect(
            brush = Brush.linearGradient(
                colors = listOf(
                    colors.sage.copy(alpha = 0.06f),
                    colors.sand.copy(alpha = 0.08f),
                    colors.mist.copy(alpha = 0f),
                ),
                start = Offset(0f, 0f),
                end = Offset(size.width, size.height * 0.7f),
            ),
        )

        // Gentle horizon wave
        val path = Path()
        val baseY = size.height * 0.72f + sin(wave.toDouble()).toFloat() * 12f
        path.moveTo(0f, baseY)
        var x = 0f
        while (x <= size.width) {
            val y = baseY + sin((x / size.width * 4f + wave).toDouble()).toFloat() * 18f
            path.lineTo(x, y)
            x += 8f
        }
        path.lineTo(size.width, size.height)
        path.lineTo(0f, size.height)
        path.close()
        drawPath(
            path = path,
            brush = Brush.verticalGradient(
                colors = listOf(
                    colors.sage.copy(alpha = 0.07f),
                    colors.mistDeep.copy(alpha = 0.35f),
                ),
                startY = baseY - 40f,
                endY = size.height,
            ),
        )

        motes.forEachIndexed { index, (nx, ny, speed) ->
            val moteX = ((nx + drift * speed + index * 0.03f) % 1.1f) * size.width
            val moteY = ny * size.height * 0.65f + sin((wave + index).toDouble()).toFloat() * 10f
            drawCircle(
                color = colors.ink.copy(alpha = 0.06f + speed * 0.04f),
                radius = 2.5f + speed * 3f,
                center = Offset(moteX, moteY),
            )
        }
    }
}
