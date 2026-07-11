package com.still.optimizer.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.still.optimizer.ui.theme.Fraunces
import com.still.optimizer.ui.theme.Outfit
import com.still.optimizer.ui.theme.StillTheme
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun CalmRing(
    score: Int,
    animating: Boolean,
    modifier: Modifier = Modifier,
    size: Dp = 280.dp,
) {
    val colors = StillTheme.colors
    val progress = remember { Animatable(0f) }
    val breath = rememberInfiniteTransition(label = "breath")
    val breathScale by breath.animateFloat(
        initialValue = 0.96f,
        targetValue = 1.04f,
        animationSpec = infiniteRepeatable(
            animation = tween(3200, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "breathScale",
    )
    val spin by breath.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(18000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart,
        ),
        label = "spin",
    )

    LaunchedEffect(score, animating) {
        if (animating) {
            progress.snapTo(0.08f)
            progress.animateTo(
                targetValue = (score / 100f).coerceIn(0.08f, 1f),
                animationSpec = tween(2200),
            )
        } else {
            progress.animateTo(
                targetValue = (score / 100f).coerceIn(0.08f, 1f),
                animationSpec = tween(1400),
            )
        }
    }

    Box(
        modifier = modifier.size(size),
        contentAlignment = Alignment.Center,
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val stroke = 10.dp.toPx()
            val pad = stroke / 2 + 8.dp.toPx()
            val diameter = (this.size.minDimension * breathScale) - pad * 2
            val topLeft = Offset(
                (this.size.width - diameter) / 2f,
                (this.size.height - diameter) / 2f,
            )

            // Soft atmospheric halo
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(colors.sageGlow, colors.mist.copy(alpha = 0f)),
                    center = center,
                    radius = diameter * 0.72f,
                ),
                radius = diameter * 0.55f,
                center = center,
            )

            drawArc(
                color = colors.ringTrack,
                startAngle = -90f,
                sweepAngle = 360f,
                useCenter = false,
                topLeft = topLeft,
                size = Size(diameter, diameter),
                style = Stroke(width = stroke, cap = StrokeCap.Round),
            )

            rotate(degrees = if (animating) spin * 0.15f else 0f, pivot = center) {
                drawArc(
                    brush = Brush.sweepGradient(
                        colors = listOf(colors.sageSoft, colors.sage, colors.sand, colors.sageSoft),
                        center = center,
                    ),
                    startAngle = -90f,
                    sweepAngle = 360f * progress.value,
                    useCenter = false,
                    topLeft = topLeft,
                    size = Size(diameter, diameter),
                    style = Stroke(width = stroke, cap = StrokeCap.Round),
                )
            }

            // Orbiting mote
            val angle = Math.toRadians((spin - 90.0))
            val r = diameter / 2f
            val mote = Offset(
                center.x + (cos(angle) * r).toFloat(),
                center.y + (sin(angle) * r).toFloat(),
            )
            drawCircle(color = colors.sage, radius = 4.dp.toPx(), center = mote)
        }

        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = score.toString(),
                fontFamily = Fraunces,
                fontWeight = FontWeight.SemiBold,
                fontSize = 72.sp,
                color = colors.ink,
                letterSpacing = (-1.5).sp,
            )
            Text(
                text = "спокойствие",
                fontFamily = Outfit,
                fontWeight = FontWeight.Medium,
                fontSize = 13.sp,
                color = colors.inkMuted,
                letterSpacing = 2.sp,
            )
        }
    }
}
