package com.awpgg.demo.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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
            .background(AwpColors.BgSection)
            .border(1.dp, AwpColors.StrokeSoft)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(26.dp)
                .background(AwpColors.BgPanel),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .height(12.dp)
                    .background(AwpColors.Accent)
            )
            Spacer(Modifier.width(8.dp))
            Text(
                text = title.uppercase(),
                color = AwpColors.Text,
                style = AwpTypography.caption.copy(
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 0.8.sp
                )
            )
        }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(1.dp)
                .background(AwpColors.StrokeSoft)
        )
        Column(modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)) {
            content()
        }
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
                .height(26.dp)
                .pointerInput(subContent) {
                    detectTapGestures(
                        onTap = { onCheckedChange(!checked) },
                        onLongPress = { if (subContent != null) expanded = !expanded }
                    )
                },
            verticalAlignment = Alignment.CenterVertically
        ) {
            CheckBox(checked = checked)
            Spacer(Modifier.width(8.dp))
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
                    fontSize = 10.sp
                )
            }
        }
        if (expanded && subContent != null) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 22.dp, top = 2.dp, bottom = 6.dp)
                    .background(AwpColors.BgInput)
                    .border(1.dp, AwpColors.StrokeSoft)
                    .padding(horizontal = 8.dp, vertical = 4.dp)
            ) {
                subContent()
            }
        }
    }
}

@Composable
private fun CheckBox(checked: Boolean) {
    val fillColor by animateColorAsState(
        if (checked) AwpColors.Accent else Color.Transparent,
        label = "checkFill"
    )
    val borderColor by animateColorAsState(
        if (checked) AwpColors.Accent else AwpColors.Stroke,
        label = "checkBorder"
    )
    Box(
        modifier = Modifier
            .size(14.dp)
            .background(AwpColors.BgInput)
            .border(1.dp, borderColor),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .background(fillColor)
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
            Text(display(value), color = AwpColors.AccentBright, style = AwpTypography.label)
        }
        Spacer(Modifier.height(5.dp))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(14.dp)
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
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp)
                    .background(AwpColors.BgInput)
                    .border(1.dp, AwpColors.StrokeSoft)
            )
            if (fraction > 0f) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth(fraction)
                        .height(6.dp)
                        .background(AwpColors.Accent)
                )
            }
        }
    }
}

@Composable
fun DemoButton(label: String, enabled: Boolean = true, onClick: () -> Unit) {
    var pressed by remember { mutableStateOf(false) }
    val bg by animateColorAsState(
        when {
            !enabled -> AwpColors.BgPanel
            pressed -> AwpColors.BgInput
            else -> AwpColors.BgSection
        },
        label = "btn"
    )
    val textColor = if (enabled) AwpColors.Text else AwpColors.TextMuted
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(28.dp)
            .background(bg)
            .border(1.dp, if (enabled) AwpColors.Stroke else AwpColors.StrokeSoft)
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
            .height(26.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, color = AwpColors.TextDim, style = AwpTypography.label)
        Box(
            modifier = Modifier
                .background(AwpColors.BgInput)
                .border(1.dp, AwpColors.Stroke)
                .padding(horizontal = 8.dp, vertical = 3.dp)
        ) {
            Text(keyText, color = AwpColors.AccentBright, style = AwpTypography.caption)
        }
    }
}

@Composable
fun SidebarTab(
    name: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    val bg by animateColorAsState(
        if (selected) AwpColors.BgSection else Color.Transparent,
        label = "sideTab"
    )
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(34.dp)
            .background(bg)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick
            ),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .width(3.dp)
                .fillMaxHeight()
                .background(if (selected) AwpColors.Accent else Color.Transparent)
        )
        Spacer(Modifier.width(12.dp))
        Text(
            text = name,
            color = if (selected) AwpColors.AccentBright else AwpColors.TextDim,
            style = AwpTypography.label.copy(
                fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal
            )
        )
    }
}
