package com.awpgg.demo.ui

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.roundToInt
import kotlin.random.Random

private val tabs = listOf("Visuals", "Combat", "Movement", "Misc", "Settings")

@Composable
fun MenuScreen(
    visible: Boolean,
    watermarkVisible: Boolean,
    overlayMode: Boolean = false,
    onWatermarkChange: (Boolean) -> Unit,
    onMinimize: () -> Unit,
    onClose: () -> Unit,
    onShowMenu: () -> Unit,
    onDemoAction: (String) -> Unit
) {
    val rootColor = if (overlayMode) Color.Transparent else Color(0xFF0A0A0C)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(rootColor)
    ) {
        if (visible && watermarkVisible) {
            WatermarkHud()
        }

        if (!visible) {
            ShowMenuChip(onClick = onShowMenu, overlayMode = overlayMode)
        }

        if (visible) {
            MenuWindow(
                onMinimize = onMinimize,
                onClose = onClose,
                onDemoAction = onDemoAction,
                onWatermarkChange = onWatermarkChange,
                watermarkVisible = watermarkVisible
            )
        }
    }
}

@Composable
private fun ShowMenuChip(onClick: () -> Unit, overlayMode: Boolean) {
    Box(
        modifier = if (overlayMode) {
            Modifier.padding(8.dp)
        } else {
            Modifier
                .fillMaxSize()
                .padding(16.dp)
        },
        contentAlignment = Alignment.TopStart
    ) {
        Row(
            modifier = Modifier
                .clickable(onClick = onClick)
                .background(AwpColors.BgPanel)
                .border(1.dp, AwpColors.Stroke),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .height(32.dp)
                    .background(AwpColors.Accent)
            )
            Text(
                text = "awp.gg  |  tap to open",
                color = AwpColors.Text,
                style = AwpTypography.label,
                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
            )
        }
    }
}

@Composable
private fun WatermarkHud() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(12.dp),
        contentAlignment = Alignment.TopEnd
    ) {
        Row(
            modifier = Modifier
                .background(AwpColors.BgPanel.copy(alpha = 0.9f))
                .border(1.dp, AwpColors.Stroke),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .height(24.dp)
                    .background(AwpColors.Accent)
            )
            Text(
                text = "awp.gg  |  60 fps",
                color = AwpColors.Text,
                style = AwpTypography.caption,
                modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp)
            )
        }
    }
}

@Composable
private fun StarfieldBackground(modifier: Modifier = Modifier) {
    val stars = remember {
        List(50) {
            Star(
                x = Random.nextFloat(),
                y = Random.nextFloat(),
                size = if (Random.nextBoolean()) 1f else 2f,
                speed = Random.nextFloat() * 0.0008f + 0.0002f,
                alpha = Random.nextFloat() * 0.4f + 0.1f
            )
        }
    }
    val transition = rememberInfiniteTransition(label = "stars")
    val phase by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(20000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "phase"
    )

    Canvas(modifier = modifier) {
        stars.forEach { star ->
            val x = ((star.x + phase * star.speed * 1000) % 1.1f) * size.width
            val y = ((star.y + phase * star.speed * 700) % 1.1f) * size.height
            drawCircle(
                color = Color.White.copy(alpha = star.alpha),
                radius = star.size,
                center = Offset(x.roundToInt() + 0.5f, y.roundToInt() + 0.5f)
            )
        }
    }
}

private data class Star(
    val x: Float,
    val y: Float,
    val size: Float,
    val speed: Float,
    val alpha: Float
)

@Composable
private fun MenuWindow(
    onMinimize: () -> Unit,
    onClose: () -> Unit,
    onDemoAction: (String) -> Unit,
    watermarkVisible: Boolean,
    onWatermarkChange: (Boolean) -> Unit
) {
    var offsetX by remember { mutableFloatStateOf(0f) }
    var offsetY by remember { mutableFloatStateOf(0f) }
    var selectedTab by remember { mutableIntStateOf(0) }

    BoxWithConstraints(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        val density = LocalDensity.current
        val menuWidth = with(density) {
            val maxPx = maxWidth.roundToPx()
            val targetPx = minOf(maxPx, 640.dp.roundToPx())
            (targetPx / density.density).dp
        }
        val menuHeight = menuWidth * (370f / 640f)

        Row(
            modifier = Modifier
                .size(width = menuWidth, height = menuHeight)
                .offset { IntOffset(offsetX.roundToInt(), offsetY.roundToInt()) }
                .background(AwpColors.Bg)
                .border(1.dp, AwpColors.Stroke)
        ) {
            Sidebar(
                selectedTab = selectedTab,
                onTabSelect = { selectedTab = it }
            )

            Box(
                modifier = Modifier
                    .width(1.dp)
                    .fillMaxHeight()
                    .background(AwpColors.Stroke)
            )

            Column(modifier = Modifier.fillMaxSize()) {
                ContentHeader(
                    title = tabs[selectedTab],
                    onMinimize = onMinimize,
                    onClose = onClose,
                    onDrag = { dx, dy ->
                        offsetX = (offsetX + dx).roundToInt().toFloat()
                        offsetY = (offsetY + dy).roundToInt().toFloat()
                    }
                )

                Box(modifier = Modifier.fillMaxSize()) {
                    StarfieldBackground(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(AwpColors.Bg)
                    )

                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(10.dp)
                    ) {
                        when (selectedTab) {
                            0 -> VisualsTab(onDemoAction)
                            1 -> CombatTab(onDemoAction)
                            2 -> MovementTab(onDemoAction)
                            3 -> MiscTab(onDemoAction)
                            4 -> SettingsTab(
                                onDemoAction = onDemoAction,
                                watermarkVisible = watermarkVisible,
                                onWatermarkChange = onWatermarkChange,
                                onClose = onClose
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun Sidebar(
    selectedTab: Int,
    onTabSelect: (Int) -> Unit
) {
    Column(
        modifier = Modifier
            .width(118.dp)
            .fillMaxHeight()
            .background(AwpColors.BgPanel)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp)
                .padding(start = 15.dp),
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "awp.gg",
                color = AwpColors.AccentBright,
                style = AwpTypography.body.copy(fontWeight = FontWeight.Bold)
            )
            Text(
                text = "DEMO BUILD",
                color = AwpColors.TextMuted,
                style = AwpTypography.caption.copy(letterSpacing = 1.2.sp)
            )
        }

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(1.dp)
                .background(AwpColors.Stroke)
        )

        Spacer(Modifier.height(8.dp))

        tabs.forEachIndexed { index, name ->
            SidebarTab(
                name = name,
                selected = selectedTab == index,
                onClick = { onTabSelect(index) }
            )
        }

        Spacer(Modifier.weight(1f))

        Text(
            text = "v1.0",
            color = AwpColors.TextMuted,
            style = AwpTypography.caption,
            modifier = Modifier.padding(start = 15.dp, bottom = 10.dp)
        )
    }
}

@Composable
private fun ContentHeader(
    title: String,
    onMinimize: () -> Unit,
    onClose: () -> Unit,
    onDrag: (Float, Float) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(32.dp)
            .background(AwpColors.BgPanel)
            .pointerInput(Unit) {
                detectDragGestures { change, drag ->
                    change.consume()
                    onDrag(drag.x, drag.y)
                }
            }
            .padding(start = 12.dp, end = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            color = AwpColors.Text,
            style = AwpTypography.label.copy(fontWeight = FontWeight.Bold),
            modifier = Modifier.weight(1f)
        )
        HeaderButton("—", onMinimize)
        Spacer(Modifier.width(4.dp))
        HeaderButton("×", onClose)
    }
}

@Composable
private fun HeaderButton(symbol: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(width = 24.dp, height = 20.dp)
            .clickable(onClick = onClick)
            .background(AwpColors.BgInput)
            .border(1.dp, AwpColors.StrokeSoft),
        contentAlignment = Alignment.Center
    ) {
        Text(symbol, color = AwpColors.TextDim, style = AwpTypography.label)
    }
}

@Composable
private fun VisualsTab(onDemoAction: (String) -> Unit) {
    var maxDistance by remember { mutableFloatStateOf(1000f) }
    var cameraFov by remember { mutableFloatStateOf(70f) }
    var crosshairSize by remember { mutableFloatStateOf(8f) }
    val toggles = remember { mutableStateOf(mapOf<String, Boolean>()) }
    fun bool(key: String) = toggles.value[key] == true
    fun setBool(key: String, v: Boolean) {
        toggles.value = toggles.value + (key to v)
        onDemoAction("Demo: $key = ${if (v) "ON" else "OFF"}")
    }

    Row(
        modifier = Modifier.fillMaxSize(),
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Column(
            Modifier.weight(1f).verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            SectionCard("Player ESP") {
                listOf(
                    "Enabled", "Box", "Name", "Health Bar", "Health Text",
                    "Distance", "Tracers", "Chams", "Glow", "Skeleton",
                    "Head Dot", "Tool", "Off-Screen", "Team Color"
                ).forEach { name ->
                    DemoToggle(name, bool(name)) { setBool(name, it) }
                }
            }
        }
        Column(
            Modifier.weight(1f).verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            SectionCard("Filters") {
                DemoToggle("Team Check", bool("Team Check")) { setBool("Team Check", it) }
                DemoToggle("Visible Check", bool("Visible Check")) { setBool("Visible Check", it) }
                DemoToggle("Show Self", bool("Show Self")) { setBool("Show Self", it) }
                DemoSlider("Max Distance", maxDistance, 50f..5000f, onValueChange = {
                    maxDistance = it
                })
            }
            SectionCard("World") {
                DemoToggle("Fullbright", bool("Fullbright")) { setBool("Fullbright", it) }
                DemoToggle("No Fog", bool("No Fog")) { setBool("No Fog", it) }
                DemoSlider("Camera FOV", cameraFov, 70f..120f, onValueChange = {
                    cameraFov = it
                })
            }
            SectionCard("Crosshair") {
                DemoToggle("Enabled", bool("Crosshair")) { setBool("Crosshair", it) }
                DemoSlider("Size", crosshairSize, 2f..30f, onValueChange = {
                    crosshairSize = it
                })
            }
        }
    }
}

@Composable
private fun CombatTab(onDemoAction: (String) -> Unit) {
    var aimbot by remember { mutableStateOf(false) }
    var trigger by remember { mutableStateOf(false) }
    var aimFov by remember { mutableFloatStateOf(80f) }
    var aimSmooth by remember { mutableFloatStateOf(5f) }
    var triggerDelay by remember { mutableFloatStateOf(50f) }
    var triggerCd by remember { mutableFloatStateOf(80f) }

    Row(Modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            SectionCard("Aimbot") {
                DemoToggle("Aimbot", aimbot, onCheckedChange = { aimbot = it; onDemoAction("Demo: Aimbot = $it") }, subContent = {
                    DemoSlider("FOV", aimFov, 20f..400f, onValueChange = { aimFov = it })
                    DemoSlider("Smoothness", aimSmooth, 1f..20f, onValueChange = { aimSmooth = it })
                    DemoToggle("Team Check", true, onCheckedChange = { onDemoAction("Demo: Aimbot Team Check = $it") })
                    DemoToggle("Visible Check", true, onCheckedChange = { onDemoAction("Demo: Aimbot Visible Check = $it") })
                    DemoToggle("Show FOV", false, onCheckedChange = { onDemoAction("Demo: Show FOV = $it") })
                    DemoToggle("Target ESP", false, onCheckedChange = { onDemoAction("Demo: Target ESP = $it") })
                    DemoKeybind("Aim Key", "E")
                })
            }
        }
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            SectionCard("Trigger Bot") {
                DemoToggle("Trigger Bot", trigger, onCheckedChange = { trigger = it; onDemoAction("Demo: Trigger Bot = $it") }, subContent = {
                    DemoToggle("Team Check", true, onCheckedChange = { onDemoAction("Demo: Trigger Team Check = $it") })
                    DemoToggle("Visible Check", true, onCheckedChange = { onDemoAction("Demo: Trigger Visible Check = $it") })
                    DemoSlider("Delay (ms)", triggerDelay, 0f..500f, onValueChange = { triggerDelay = it })
                    DemoSlider("Cooldown (ms)", triggerCd, 0f..500f, onValueChange = { triggerCd = it })
                })
            }
        }
    }
}

@Composable
private fun MovementTab(onDemoAction: (String) -> Unit) {
    var flySpeed by remember { mutableFloatStateOf(50f) }
    var walkSpeed by remember { mutableFloatStateOf(16f) }
    var jumpPower by remember { mutableFloatStateOf(50f) }

    Row(Modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            SectionCard("Movement") {
                DemoToggle("Infinite Jump", false) { onDemoAction("Demo: Infinite Jump = $it") }
                DemoToggle("Bunny Hop", false) { onDemoAction("Demo: Bunny Hop = $it") }
                DemoToggle("Fly", false) { onDemoAction("Demo: Fly = $it") }
                DemoToggle("Noclip", false) { onDemoAction("Demo: Noclip = $it") }
            }
        }
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            SectionCard("Speed") {
                DemoToggle("Speed Boost", false, onCheckedChange = { onDemoAction("Demo: Speed Boost = $it") }, subContent = {
                    DemoSlider("Walk Speed", walkSpeed, 16f..500f, onValueChange = { walkSpeed = it })
                })
                DemoToggle("Jump Boost", false, onCheckedChange = { onDemoAction("Demo: Jump Boost = $it") }, subContent = {
                    DemoSlider("Jump Power", jumpPower, 50f..500f, onValueChange = { jumpPower = it })
                })
                DemoSlider("Fly Speed", flySpeed, 10f..300f, onValueChange = { flySpeed = it })
            }
        }
    }
}

@Composable
private fun MiscTab(onDemoAction: (String) -> Unit) {
    Row(Modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            SectionCard("Utility") {
                DemoToggle("Anti-AFK", false) { onDemoAction("Demo: Anti-AFK = $it") }
                Spacer(Modifier.height(6.dp))
                DemoButton("Reset Character") {
                    onDemoAction("Demo: Reset Character — не работает в демо")
                }
                Spacer(Modifier.height(6.dp))
                DemoButton("Rejoin Server") {
                    onDemoAction("Demo: Rejoin Server — не работает в демо")
                }
            }
        }
        Column(Modifier.weight(1f)) {}
    }
}

@Composable
private fun SettingsTab(
    onDemoAction: (String) -> Unit,
    watermarkVisible: Boolean,
    onWatermarkChange: (Boolean) -> Unit,
    onClose: () -> Unit
) {
    Row(Modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Column(
            Modifier.weight(1f).verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            SectionCard("UI") {
                DemoKeybind("Toggle Menu", "Chip")
                Spacer(Modifier.height(6.dp))
                DemoButton("Unload Menu") {
                    onDemoAction("Demo: меню закрыто")
                    onClose()
                }
            }
            SectionCard("HUD") {
                DemoToggle("Watermark (FPS)", watermarkVisible, onWatermarkChange)
                DemoToggle("Target HUD", false) { onDemoAction("Demo: Target HUD = $it") }
                DemoToggle("Keybinds HUD", false) { onDemoAction("Demo: Keybinds HUD = $it") }
                DemoToggle("Velocity HUD", false) { onDemoAction("Demo: Velocity HUD = $it") }
            }
        }
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            SectionCard("Info") {
                DemoLabel("awp.gg v1.0 — Android Demo")
                DemoLabel("UI only, no game features")
                DemoLabel("Долгое нажатие — поднастройки")
                DemoLabel("Тяните заголовок — перемещение")
            }
        }
    }
}
