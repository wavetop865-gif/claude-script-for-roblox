package com.awpgg.demo.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
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
            .clip(RoundedCornerShape(0.dp))
            .background(AwpColors.BgSection)
            .border(1.dp, AwpColors.StrokeSoft)
            .padding(8.dp)
    ) {
        Text(
            text = title.uppercase(),
            color = AwpColors.TextMuted,
            fontSize = 10.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 1.sp,
            modifier = Modifier.padding(bottom = 6.dp)
        )
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
                .height(28.dp)
                .pointerInput(subContent) {
                    detectTapGestures(
                        onTap = { onCheckedChange(!checked) },
                        onLongPress = { if (subContent != null) expanded = !expanded }
                    )
                },
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = label,
                color = if (checked) AwpColors.Text else AwpColors.TextDim,
                fontSize = 12.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f)
            )
            ToggleSwitch(checked = checked)
        }
        if (expanded && subContent != null) {
            Column(
                modifier = Modifier
                    .padding(start = 10.dp, top = 4.dp, bottom = 4.dp)
                    .border(1.dp, AwpColors.StrokeSoft, RoundedCornerShape(0.dp))
                    .background(AwpColors.BgInput)
                    .padding(6.dp)
            ) {
                subContent()
            }
        }
    }
}

@Composable
private fun ToggleSwitch(checked: Boolean) {
    val trackColor by animateColorAsState(
        if (checked) AwpColors.Accent else AwpColors.BgInput,
        label = "track"
    )
    val thumbColor by animateColorAsState(
        if (checked) AwpColors.BgPanel else AwpColors.AccentDim,
        label = "thumb"
    )
    Box(
        modifier = Modifier
            .width(34.dp)
            .height(16.dp)
            .clip(RoundedCornerShape(0.dp))
            .background(trackColor)
            .border(1.dp, AwpColors.Stroke)
    ) {
        Box(
            modifier = Modifier
                .size(12.dp)
                .offset(x = if (checked) 20.dp else 2.dp, y = 1.dp)
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
    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(label, color = AwpColors.TextDim, fontSize = 12.sp)
            Text(display(value), color = AwpColors.Accent, fontSize = 12.sp)
        }
        Slider(
            value = value,
            onValueChange = onValueChange,
            valueRange = valueRange,
            colors = SliderDefaults.colors(
                thumbColor = AwpColors.AccentBright,
                activeTrackColor = AwpColors.Accent,
                inactiveTrackColor = AwpColors.BgInput
            )
        )
    }
}

@Composable
fun DemoButton(label: String, onClick: () -> Unit) {
    var pressed by remember { mutableStateOf(false) }
    val bg by animateColorAsState(
        if (pressed) AwpColors.BgInput else AwpColors.BgSection,
        label = "btn"
    )
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(28.dp)
            .background(bg)
            .border(1.dp, AwpColors.StrokeSoft)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null
            ) {
                pressed = true
                onClick()
                pressed = false
            },
        contentAlignment = Alignment.Center
    ) {
        Text(label, color = AwpColors.Text, fontSize = 12.sp)
    }
}

@Composable
fun DemoLabel(text: String, color: Color = AwpColors.TextDim) {
    Text(
        text = text,
        color = color,
        fontSize = 11.sp,
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
        Text(label, color = AwpColors.TextDim, fontSize = 12.sp)
        Text("[$keyText]", color = AwpColors.Accent, fontSize = 12.sp)
    }
}

@Composable
fun TabButton(
    name: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val bg by animateColorAsState(
        if (selected) AwpColors.BgInput else AwpColors.BgSection,
        label = "tab"
    )
    Box(
        modifier = modifier
            .height(28.dp)
            .background(bg)
            .border(1.dp, if (selected) AwpColors.AccentDim else AwpColors.StrokeSoft)
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = name,
            color = if (selected) AwpColors.AccentBright else AwpColors.TextDim,
            fontSize = 12.sp,
            fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal
        )
    }
}
