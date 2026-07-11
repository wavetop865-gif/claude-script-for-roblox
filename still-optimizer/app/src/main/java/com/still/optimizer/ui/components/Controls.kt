package com.still.optimizer.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.still.optimizer.ui.theme.Fraunces
import com.still.optimizer.ui.theme.Outfit
import com.still.optimizer.ui.theme.StillTheme

@Composable
fun StillPrimaryButton(
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    val colors = StillTheme.colors
    val scale by animateFloatAsState(
        targetValue = if (enabled) 1f else 0.98f,
        animationSpec = tween(200),
        label = "btnScale",
    )
    Box(
        modifier = modifier
            .scale(scale)
            .fillMaxWidth()
            .height(58.dp)
            .clip(RoundedCornerShape(999.dp))
            .background(if (enabled) colors.ink else colors.inkMuted)
            .clickable(
                enabled = enabled,
                indication = null,
                interactionSource = remember { MutableInteractionSource() },
                onClick = onClick,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            fontFamily = Outfit,
            fontWeight = FontWeight.SemiBold,
            fontSize = 16.sp,
            color = colors.mistSoft,
            letterSpacing = 0.4.sp,
        )
    }
}

@Composable
fun MetricRow(
    label: String,
    value: String,
    progress: Float,
    accent: Color = StillTheme.colors.sage,
) {
    val colors = StillTheme.colors
    val animated by animateFloatAsState(
        targetValue = progress.coerceIn(0f, 1f),
        animationSpec = tween(900),
        label = "metric",
    )

    Column(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.Bottom,
        ) {
            Text(
                text = label,
                fontFamily = Outfit,
                fontWeight = FontWeight.Medium,
                fontSize = 14.sp,
                color = colors.inkSoft,
            )
            Text(
                text = value,
                fontFamily = Fraunces,
                fontWeight = FontWeight.SemiBold,
                fontSize = 18.sp,
                color = colors.ink,
            )
        }
        Spacer(Modifier.height(10.dp))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(3.dp)
                .clip(RoundedCornerShape(99.dp))
                .background(colors.ringTrack),
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(animated)
                    .height(3.dp)
                    .clip(RoundedCornerShape(99.dp))
                    .background(accent),
            )
        }
    }
}

@Composable
fun SectionLabel(text: String) {
    Text(
        text = text.uppercase(),
        fontFamily = Outfit,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        color = StillTheme.colors.inkMuted,
        letterSpacing = 2.4.sp,
    )
}

@Composable
fun StatusDot(active: Boolean) {
    val colors = StillTheme.colors
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .clip(CircleShape)
                .background(if (active) colors.sage else colors.sand),
        )
        Spacer(Modifier.width(8.dp))
        Text(
            text = if (active) "в процессе" else "готово",
            fontFamily = Outfit,
            fontWeight = FontWeight.Medium,
            fontSize = 13.sp,
            color = colors.inkMuted,
        )
    }
}
