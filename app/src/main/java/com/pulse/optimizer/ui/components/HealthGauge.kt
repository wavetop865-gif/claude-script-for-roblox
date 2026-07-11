package com.pulse.optimizer.ui.components

import androidx.compose.animation.core.EaseOutCubic
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.pulse.optimizer.ui.theme.Amber
import com.pulse.optimizer.ui.theme.Coral
import com.pulse.optimizer.ui.theme.Mint
import com.pulse.optimizer.ui.theme.Surface2
import com.pulse.optimizer.ui.theme.TextSecondary

/**
 * Circular health gauge: a 270° arc with a soft glow,
 * score in the center and a slowly rotating "breathing" halo.
 */
@Composable
fun HealthGauge(
    score: Int,
    isWorking: Boolean,
    modifier: Modifier = Modifier,
    size: Dp = 240.dp,
) {
    val animatedScore by animateFloatAsState(
        targetValue = score / 100f,
        animationSpec = tween(1200, easing = EaseOutCubic),
        label = "score",
    )

    val infinite = rememberInfiniteTransition(label = "halo")
    val haloAngle by infinite.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(if (isWorking) 1600 else 8000, easing = LinearEasing),
        ),
        label = "haloAngle",
    )

    val accent = when {
        score >= 70 -> Mint
        score >= 40 -> Amber
        else -> Coral
    }

    Box(modifier = modifier.size(size), contentAlignment = Alignment.Center) {
        Canvas(modifier = Modifier.size(size)) {
            val strokeWidth = 14.dp.toPx()
            val inset = strokeWidth * 1.6f
            val arcSize = Size(this.size.width - inset * 2, this.size.height - inset * 2)
            val topLeft = Offset(inset, inset)
            val startAngle = 135f
            val sweepMax = 270f

            // Track
            drawArc(
                color = Surface2,
                startAngle = startAngle,
                sweepAngle = sweepMax,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(strokeWidth, cap = StrokeCap.Round),
            )

            // Progress with glow (wider translucent pass underneath)
            val sweep = sweepMax * animatedScore
            drawArc(
                color = accent.copy(alpha = 0.25f),
                startAngle = startAngle,
                sweepAngle = sweep,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(strokeWidth * 2.2f, cap = StrokeCap.Round),
            )
            drawArc(
                brush = Brush.sweepGradient(
                    0f to accent.copy(alpha = 0.4f),
                    0.5f to accent,
                    1f to accent.copy(alpha = 0.4f),
                ),
                startAngle = startAngle,
                sweepAngle = sweep,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(strokeWidth, cap = StrokeCap.Round),
            )

            // Orbiting halo dot
            val radius = arcSize.width / 2
            val rad = Math.toRadians(haloAngle.toDouble())
            val cx = this.size.width / 2 + radius * kotlin.math.cos(rad).toFloat()
            val cy = this.size.height / 2 + radius * kotlin.math.sin(rad).toFloat()
            drawCircle(
                color = accent.copy(alpha = if (isWorking) 0.9f else 0.35f),
                radius = 4.dp.toPx(),
                center = Offset(cx, cy),
            )
            drawCircle(
                color = accent.copy(alpha = if (isWorking) 0.3f else 0.1f),
                radius = 10.dp.toPx(),
                center = Offset(cx, cy),
            )
        }

        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            androidx.compose.material3.Text(
                text = "${(animatedScore * 100).toInt()}",
                style = MaterialTheme.typography.displayLarge,
                color = Color.White,
            )
            androidx.compose.material3.Text(
                text = "ИНДЕКС ЗДОРОВЬЯ",
                style = MaterialTheme.typography.labelSmall,
                color = TextSecondary,
                textAlign = TextAlign.Center,
            )
        }
    }
}
