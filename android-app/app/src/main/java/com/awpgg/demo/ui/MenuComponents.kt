package com.awpgg.demo.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.roundToInt

@Composable
fun SectionCard(
    title: String,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(AwpColors.BgSection)
            .border(1.dp, AwpColors.StrokeSoft, RoundedCornerShape(12.dp))
            .padding(horizontal = 12.dp, vertical = 10.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .size(6.dp)
                    .clip(CircleShape)
                    .background(AwpGradients.accent)
            )
            Spacer(Modifier.width(7.dp))
            Text(
                text = title,
                color = AwpColors.Text,
                style = AwpTypography.label.copy(
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 0.3.sp
                )
            )
        }
        Spacer(Modifier.height(8.dp))
        content()
    }
}

@Composable
fun DemoToggle(
    label: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    DemoToggle(label, checked, onCheckedChange, subContent = null)
}

@Composable
fun DemoToggle(
    label: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    subContent: (@Composable () -> Unit)?
) {
    var expanded by remember { mutableStateOf(false) }

    Column(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(30.dp)
                .pointerInput(subContent) {
                    detectTapGestures(
                        onTap = { onCheckedChange(!checked) },
                        onLongPress = { if (subContent != null) expanded = !expanded }
                    )
                },
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = label,
                color = if (checked) AwpColors.Text else AwpColors.TextDim,
                style = AwpTypography.label,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f)
            )
            if (subContent != null) {
                Text(
                    text = if (expanded) "▾" else "▸",
                    color = AwpColors.TextMuted,
                    fontSize = 10.sp,
                    modifier = Modifier.padding(end = 8.dp)
                )
            }
            PillSwitch(checked = checked)
        }
        if (expanded && subContent != null) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 2.dp, bottom = 8.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(AwpColors.BgInput.copy(alpha = 0.55f))
                    .border(1.dp, AwpColors.StrokeSoft, RoundedCornerShape(10.dp))
                    .padding(horizontal = 10.dp, vertical = 6.dp)
            ) {
                subContent()
            }
        }
    }
}

@Composable
private fun PillSwitch(checked: Boolean) {
    val thumbOffset by animateDpAsState(
        targetValue = if (checked) 18.dp else 2.dp,
        label = "thumbOffset"
    )
    val thumbColor by animateColorAsState(
        targetValue = if (checked) Color.White else AwpColors.TextMuted,
        label = "thumbColor"
    )

    Box(
        modifier = Modifier
            .width(36.dp)
            .height(20.dp)
            .clip(RoundedCornerShape(999.dp))
            .let {
                if (checked) {
                    it.background(AwpGradients.accent)
                } else {
                    it
                        .background(AwpColors.BgInput)
                        .border(1.dp, AwpColors.Stroke, RoundedCornerShape(999.dp))
                }
            }
    ) {
        Box(
            modifier = Modifier
                .size(16.dp)
                .offset(x = thumbOffset, y = 2.dp)
                .clip(CircleShape)
                .background(thumbColor)
        )
    }
}

@Composable
fun DemoSlider(
    label: String,
    value: Float,
    valueRange: ClosedFloatingPointRange<Float>,
    onValueChange: (Float) -> Unit,
    display: (Float) -> String = { it.roundToInt().toString() }
) {
    val range = valueRange.endInclusive - valueRange.start
    val fraction = if (range > 0f) {
        ((value - valueRange.start) / range).coerceIn(0f, 1f)
    } else {
        0f
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(label, color = AwpColors.TextDim, style = AwpTypography.label)
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(6.dp))
                    .background(AwpColors.BgInput)
                    .padding(horizontal = 6.dp, vertical = 1.dp)
            ) {
                Text(display(value), color = AwpColors.AccentBright, style = AwpTypography.caption)
            }
        }
        Spacer(Modifier.height(6.dp))
        BoxWithConstraints(
            modifier = Modifier
                .fillMaxWidth()
                .height(18.dp)
                .pointerInput(valueRange) {
                    detectTapGestures { offset ->
                        val frac = (offset.x / size.width.toFloat()).coerceIn(0f, 1f)
                        onValueChange(valueRange.start + frac * range)
                    }
                }
                .pointerInput(valueRange) {
                    detectHorizontalDragGestures { change, _ ->
                        change.consume()
                        val frac = (change.position.x / size.width.toFloat()).coerceIn(0f, 1f)
                        onValueChange(valueRange.start + frac * range)
                    }
                },
            contentAlignment = Alignment.CenterStart
        ) {
            val thumbSize = 14.dp
            val thumbX = (maxWidth - thumbSize) * fraction

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp)
                    .clip(RoundedCornerShape(999.dp))
                    .background(AwpColors.BgInput)
            )
            if (fraction > 0f) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth(fraction)
                        .height(6.dp)
                        .clip(RoundedCornerShape(999.dp))
                        .background(AwpGradients.accent)
                )
            }
            Box(
                modifier = Modifier
                    .size(thumbSize)
                    .offset(x = thumbX)
                    .clip(CircleShape)
                    .background(Color.White)
                    .border(2.dp, AwpColors.Accent, CircleShape)
            )
        }
    }
}

@Composable
fun DemoButton(label: String, enabled: Boolean = true, onClick: () -> Unit) {
    var pressed by remember { mutableStateOf(false) }
    val bg by animateColorAsState(
        when {
            !enabled -> AwpColors.BgPanel
            pressed -> AwpColors.AccentDim
            else -> AwpColors.BgInput
        },
        label = "btn"
    )
    val textColor = if (enabled) AwpColors.Text else AwpColors.TextMuted
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(32.dp)
            .clip(RoundedCornerShape(9.dp))
            .background(bg)
            .border(
                1.dp,
                if (enabled) AwpColors.Stroke else AwpColors.StrokeSoft,
                RoundedCornerShape(9.dp)
            )
            .clickable(
                enabled = enabled,
                interactionSource = remember { MutableInteractionSource() },
                indication = null
            ) {
                pressed = true
                onClick()
                pressed = false
            },
        contentAlignment = Alignment.Center
    ) {
        Text(label, color = textColor, style = AwpTypography.label)
    }
}

@Composable
fun DemoLabel(text: String, color: Color = AwpColors.TextDim) {
    Text(
        text = text,
        color = color,
        style = AwpTypography.caption,
        modifier = Modifier.padding(vertical = 3.dp)
    )
}

@Composable
fun DemoKeybind(label: String, keyText: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(28.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, color = AwpColors.TextDim, style = AwpTypography.label)
        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(7.dp))
                .background(AwpColors.BgInput)
                .border(1.dp, AwpColors.Stroke, RoundedCornerShape(7.dp))
                .padding(horizontal = 9.dp, vertical = 3.dp)
        ) {
            Text(keyText, color = AwpColors.AccentBright, style = AwpTypography.caption)
        }
    }
}

@Composable
fun SidebarTab(
    name: String,
    icon: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    val bg by animateColorAsState(
        if (selected) AwpColors.BgInput else Color.Transparent,
        label = "sideTab"
    )
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 2.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(bg)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick
            )
            .padding(horizontal = 10.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(22.dp)
                .clip(RoundedCornerShape(7.dp))
                .let {
                    if (selected) {
                        it.background(AwpGradients.accentVertical)
                    } else {
                        it.background(AwpColors.BgSection)
                    }
                },
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = icon,
                color = if (selected) Color.White else AwpColors.TextMuted,
                fontSize = 11.sp
            )
        }
        Spacer(Modifier.width(9.dp))
        Text(
            text = name,
            color = if (selected) AwpColors.Text else AwpColors.TextDim,
            style = AwpTypography.label.copy(
                fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal
            )
        )
    }
}
