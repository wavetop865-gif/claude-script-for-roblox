-- ============================================================
--  Cosmetic Visuals — powered by the WindUI library
--  (https://github.com/Footagesus/WindUI)
--
--  A modern, unusual UI (animated acrylic window, lucide icons,
--  works great on mobile). COSMETIC-ONLY effects for YOUR OWN
--  character — no gameplay advantage / no cheat functions:
--    • Trail        (color / rainbow / width / lifetime)
--    • Character Glow (color / rainbow)
--    • Neon Body    (color / rainbow, restores on disable)
--    • Sparkles     (particle emitter)
--    • Aura         (soft particle ring, color / rainbow)
--
--  Usage: paste into an executor, or drop into
--  StarterPlayer > StarterPlayerScripts as a LocalScript.
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting   = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ------------------------------------------------------------
--  Load the WindUI library from GitHub
-- ------------------------------------------------------------
local WindUI = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

-- ============================================================
--  Cosmetic effect state (self only)
-- ============================================================
local ACCENT = Color3.fromRGB(120, 110, 255)

local FX = {
	Trail        = false,
	TrailColor   = ACCENT,
	TrailRainbow = false,
	TrailWidth   = 1.0,
	TrailLife    = 0.6,

	Glow         = false,
	GlowColor    = ACCENT,
	GlowRainbow  = false,

	Neon         = false,
	NeonColor    = Color3.fromRGB(70, 200, 255),
	NeonRainbow  = false,

	Sparkles     = false,

	Aura         = false,
	AuraColor    = Color3.fromRGB(90, 230, 130),
	AuraRainbow  = false,

	-- world / weather (client-side)
	Rain         = false,
	Snow         = false,
	Storm        = false,
}

-- ------------------------------------------------------------
--  Helpers
-- ------------------------------------------------------------
local function getChar()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	return char, hrp
end

-- ---- Trail --------------------------------------------------
local trailA, trailB, trailObj
local function buildTrail()
	local _, hrp = getChar()
	if not hrp then return end
	if trailObj then trailObj:Destroy() end
	if trailA then trailA:Destroy() end
	if trailB then trailB:Destroy() end
	trailA = Instance.new("Attachment"); trailA.Name = "Vis_TrailA"
	trailA.Position = Vector3.new(0, 1.5, 0); trailA.Parent = hrp
	trailB = Instance.new("Attachment"); trailB.Name = "Vis_TrailB"
	trailB.Position = Vector3.new(0, -1.5, 0); trailB.Parent = hrp
	trailObj = Instance.new("Trail")
	trailObj.Name         = "Vis_Trail"
	trailObj.Attachment0  = trailA
	trailObj.Attachment1  = trailB
	trailObj.Lifetime     = FX.TrailLife
	trailObj.WidthScale   = NumberSequence.new(FX.TrailWidth)
	trailObj.LightEmission = 1
	trailObj.FaceCamera   = true
	trailObj.Color        = ColorSequence.new(FX.TrailColor)
	trailObj.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	trailObj.Parent = hrp
end
local function destroyTrail()
	if trailObj then trailObj:Destroy(); trailObj = nil end
	if trailA then trailA:Destroy(); trailA = nil end
	if trailB then trailB:Destroy(); trailB = nil end
end

-- ---- Glow (Highlight) --------------------------------------
local glowObj
local function buildGlow()
	local char = getChar()
	if not char then return end
	if glowObj then glowObj:Destroy() end
	glowObj = Instance.new("Highlight")
	glowObj.Name                = "Vis_Glow"
	glowObj.Adornee             = char
	glowObj.FillTransparency    = 0.6
	glowObj.OutlineTransparency = 0
	glowObj.FillColor           = FX.GlowColor
	glowObj.OutlineColor        = FX.GlowColor
	glowObj.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
	glowObj.Parent              = char
end
local function destroyGlow()
	if glowObj then glowObj:Destroy(); glowObj = nil end
end

-- ---- Neon body ---------------------------------------------
local neonParts = {}
local function applyNeon(on)
	local char = getChar()
	if not char then return end
	if on then
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				if not neonParts[p] then
					neonParts[p] = { mat = p.Material, col = p.Color }
				end
				p.Material = Enum.Material.Neon
				p.Color    = FX.NeonColor
			end
		end
	else
		for p, saved in pairs(neonParts) do
			if p and p.Parent then
				p.Material = saved.mat
				p.Color    = saved.col
			end
		end
		neonParts = {}
	end
end

-- ---- Sparkles ----------------------------------------------
local sparkleObj
local function buildSparkles()
	local _, hrp = getChar()
	if not hrp then return end
	if sparkleObj then sparkleObj:Destroy() end
	sparkleObj = Instance.new("ParticleEmitter")
	sparkleObj.Name          = "Vis_Sparkles"
	sparkleObj.Texture       = "rbxasset://textures/particles/sparkles_main.dds"
	sparkleObj.Rate          = 40
	sparkleObj.Lifetime      = NumberRange.new(0.6, 1.0)
	sparkleObj.Speed         = NumberRange.new(1, 2)
	sparkleObj.SpreadAngle   = Vector2.new(180, 180)
	sparkleObj.Size          = NumberSequence.new(0.4)
	sparkleObj.LightEmission = 1
	sparkleObj.Parent        = hrp
end
local function destroySparkles()
	if sparkleObj then sparkleObj:Destroy(); sparkleObj = nil end
end

-- ---- Aura --------------------------------------------------
local auraObj
local function buildAura()
	local _, hrp = getChar()
	if not hrp then return end
	if auraObj then auraObj:Destroy() end
	auraObj = Instance.new("ParticleEmitter")
	auraObj.Name         = "Vis_Aura"
	auraObj.Texture      = "rbxasset://textures/particles/smoke_main.dds"
	auraObj.Rate         = 60
	auraObj.Lifetime     = NumberRange.new(0.8, 1.2)
	auraObj.Speed        = NumberRange.new(0, 1)
	auraObj.SpreadAngle  = Vector2.new(360, 360)
	auraObj.Color        = ColorSequence.new(FX.AuraColor)
	auraObj.Size         = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	auraObj.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	auraObj.LightEmission = 0.8
	auraObj.Parent        = hrp
end
local function destroyAura()
	if auraObj then auraObj:Destroy(); auraObj = nil end
end

-- ============================================================
--  World / Weather (client-side, cosmetic)
-- ============================================================
-- Snapshot the original lighting so we can fully restore it later.
local origLighting = {
	Ambient        = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	Brightness     = Lighting.Brightness,
	ClockTime      = Lighting.ClockTime,
	FogColor       = Lighting.FogColor,
	FogEnd         = Lighting.FogEnd,
	FogStart       = Lighting.FogStart,
}

-- ColorCorrection effect for world tint + saturation.
local ccEffect
local function ensureCC()
	if ccEffect and ccEffect.Parent then return ccEffect end
	ccEffect = Instance.new("ColorCorrectionEffect")
	ccEffect.Name    = "Vis_CC"
	ccEffect.Enabled = true
	ccEffect.Parent  = Lighting
	return ccEffect
end

-- Precipitation lives on a flat part that follows the camera each frame.
local weatherPart, rainEmitter, snowEmitter
local function ensureWeatherPart()
	if weatherPart and weatherPart.Parent then return weatherPart end
	weatherPart = Instance.new("Part")
	weatherPart.Name         = "Vis_Weather"
	weatherPart.Anchored     = true
	weatherPart.CanCollide   = false
	weatherPart.CanQuery     = false
	weatherPart.CanTouch     = false
	weatherPart.Transparency = 1
	weatherPart.Size         = Vector3.new(130, 1, 130)
	weatherPart.Parent       = workspace
	return weatherPart
end

local function setRain(on: boolean, heavy: boolean?)
	if on then
		ensureWeatherPart()
		if rainEmitter then rainEmitter:Destroy() end
		rainEmitter = Instance.new("ParticleEmitter")
		rainEmitter.Name             = "Vis_Rain"
		rainEmitter.Texture          = "rbxasset://textures/particles/sparkles_main.dds"
		rainEmitter.Color            = ColorSequence.new(Color3.fromRGB(170, 190, 220))
		rainEmitter.Transparency     = NumberSequence.new(0.35)
		rainEmitter.Rate             = heavy and 900 or 500
		rainEmitter.Lifetime         = NumberRange.new(0.7, 0.9)
		rainEmitter.Speed            = NumberRange.new(90, 110)
		rainEmitter.Size             = NumberSequence.new(0.35)
		rainEmitter.Acceleration     = Vector3.new(0, -180, 0)
		rainEmitter.EmissionDirection = Enum.NormalId.Bottom
		rainEmitter.SpreadAngle      = Vector2.new(6, 6)
		rainEmitter.LightEmission    = 0.3
		pcall(function() rainEmitter.Squash = NumberSequence.new(6) end) -- stretch into streaks
		rainEmitter.Parent = weatherPart
	else
		if rainEmitter then rainEmitter:Destroy(); rainEmitter = nil end
	end
end

local function setSnow(on: boolean)
	if on then
		ensureWeatherPart()
		if snowEmitter then snowEmitter:Destroy() end
		snowEmitter = Instance.new("ParticleEmitter")
		snowEmitter.Name             = "Vis_Snow"
		snowEmitter.Texture          = "rbxasset://textures/particles/sparkles_main.dds"
		snowEmitter.Color            = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		snowEmitter.Transparency     = NumberSequence.new(0.1)
		snowEmitter.Rate             = 220
		snowEmitter.Lifetime         = NumberRange.new(2.5, 3.5)
		snowEmitter.Speed            = NumberRange.new(6, 12)
		snowEmitter.Size             = NumberSequence.new(0.45)
		snowEmitter.Rotation         = NumberRange.new(0, 360)
		snowEmitter.RotSpeed         = NumberRange.new(-40, 40)
		snowEmitter.Acceleration     = Vector3.new(2, -8, 0)
		snowEmitter.EmissionDirection = Enum.NormalId.Bottom
		snowEmitter.SpreadAngle      = Vector2.new(40, 40)
		snowEmitter.LightEmission    = 0.5
		snowEmitter.Parent = weatherPart
	else
		if snowEmitter then snowEmitter:Destroy(); snowEmitter = nil end
	end
end

-- Fog density: 0 = clear (restore original), 1 = very dense.
local function applyFog(density: number)
	if density <= 0.001 then
		Lighting.FogEnd   = origLighting.FogEnd
		Lighting.FogStart = origLighting.FogStart
		return
	end
	local far = 2000 + (60 - 2000) * density -- lerp 2000 -> 60
	Lighting.FogStart = 0
	Lighting.FogEnd   = far
end

local function applyStorm(on: boolean)
	if on then
		Lighting.ClockTime      = 15
		Lighting.Brightness     = 0.6
		Lighting.Ambient        = Color3.fromRGB(60, 62, 70)
		Lighting.OutdoorAmbient = Color3.fromRGB(70, 72, 82)
		Lighting.FogColor       = Color3.fromRGB(90, 92, 100)
		applyFog(0.35)
		setRain(true, true)
	else
		setRain(FX.Rain, false)
		Lighting.Ambient        = origLighting.Ambient
		Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
		Lighting.Brightness     = origLighting.Brightness
		Lighting.ClockTime      = origLighting.ClockTime
		Lighting.FogColor       = origLighting.FogColor
		if not FX.Rain then applyFog(0) end
	end
end

-- Sky presets: adjust ClockTime / ambient / stars for a distinct sky mood.
local customSky
local function clearCustomSky()
	if customSky then customSky:Destroy(); customSky = nil end
end
local function applySkyPreset(name: string)
	clearCustomSky()
	if name == "Default" then
		Lighting.ClockTime      = origLighting.ClockTime
		Lighting.Ambient        = origLighting.Ambient
		Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
		return
	elseif name == "Clear Day" then
		Lighting.ClockTime      = 14
		Lighting.Ambient        = Color3.fromRGB(140, 145, 155)
		Lighting.OutdoorAmbient = Color3.fromRGB(150, 155, 165)
	elseif name == "Sunset" then
		Lighting.ClockTime      = 17.6
		Lighting.Ambient        = Color3.fromRGB(120, 80, 60)
		Lighting.OutdoorAmbient = Color3.fromRGB(150, 100, 70)
	elseif name == "Night" then
		Lighting.ClockTime      = 0
		Lighting.Ambient        = Color3.fromRGB(30, 34, 55)
		Lighting.OutdoorAmbient = Color3.fromRGB(40, 44, 70)
		customSky = Instance.new("Sky")
		customSky.StarCount           = 6000
		customSky.CelestialBodiesShown = true
		customSky.Parent = Lighting
	elseif name == "Galaxy" then
		Lighting.ClockTime      = 0
		Lighting.Ambient        = Color3.fromRGB(60, 40, 80)
		Lighting.OutdoorAmbient = Color3.fromRGB(70, 50, 95)
		customSky = Instance.new("Sky")
		customSky.StarCount           = 10000
		customSky.CelestialBodiesShown = false
		customSky.Parent = Lighting
	end
end

local function resetWorld()
	setRain(false); setSnow(false)
	FX.Rain, FX.Snow, FX.Storm = false, false, false
	clearCustomSky()
	if ccEffect then ccEffect:Destroy(); ccEffect = nil end
	if weatherPart then weatherPart:Destroy(); weatherPart = nil end
	Lighting.Ambient        = origLighting.Ambient
	Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
	Lighting.Brightness     = origLighting.Brightness
	Lighting.ClockTime      = origLighting.ClockTime
	Lighting.FogColor       = origLighting.FogColor
	Lighting.FogEnd         = origLighting.FogEnd
	Lighting.FogStart       = origLighting.FogStart
end

-- ---- Re-apply on respawn -----------------------------------
local function reapplyAll()
	if FX.Trail then buildTrail() end
	if FX.Glow then buildGlow() end
	if FX.Neon then applyNeon(true) end
	if FX.Sparkles then buildSparkles() end
	if FX.Aura then buildAura() end
end
player.CharacterAdded:Connect(function()
	task.wait(0.6)
	neonParts = {}
	reapplyAll()
end)

-- ============================================================
--  Build the WindUI window
-- ============================================================
local Window = WindUI:CreateWindow({
	Title  = "Visuals",
	Icon   = "sparkles",
	Author = "cosmetic • self only",
	Folder = "CosmeticVisuals",
	Size   = UDim2.fromOffset(520, 400),
	Theme  = "Dark",
	Transparent = true,
	ToggleKey = Enum.KeyCode.K,
	SideBarWidth = 160,
})

-- ---- Trail tab ---------------------------------------------
local trailTab = Window:Tab({ Title = "Trail", Icon = "wind" })
trailTab:Toggle({
	Title = "Enable Trail",
	Value = false,
	Callback = function(v)
		FX.Trail = v
		if v then buildTrail() else destroyTrail() end
	end,
})
trailTab:Colorpicker({
	Title = "Trail Color",
	Default = FX.TrailColor,
	Callback = function(c)
		FX.TrailColor = c
		if trailObj and not FX.TrailRainbow then
			trailObj.Color = ColorSequence.new(c)
		end
	end,
})
trailTab:Toggle({
	Title = "Rainbow Trail",
	Value = false,
	Callback = function(v) FX.TrailRainbow = v end,
})
trailTab:Slider({
	Title = "Trail Width",
	Step  = 0.1,
	Value = { Min = 0.2, Max = 4, Default = 1 },
	Callback = function(v)
		FX.TrailWidth = v
		if trailObj then trailObj.WidthScale = NumberSequence.new(v) end
	end,
})
trailTab:Slider({
	Title = "Trail Lifetime",
	Step  = 0.1,
	Value = { Min = 0.2, Max = 2, Default = 0.6 },
	Callback = function(v)
		FX.TrailLife = v
		if trailObj then trailObj.Lifetime = v end
	end,
})

-- ---- Glow tab ----------------------------------------------
local glowTab = Window:Tab({ Title = "Glow", Icon = "sun" })
glowTab:Toggle({
	Title = "Character Glow",
	Value = false,
	Callback = function(v)
		FX.Glow = v
		if v then buildGlow() else destroyGlow() end
	end,
})
glowTab:Colorpicker({
	Title = "Glow Color",
	Default = FX.GlowColor,
	Callback = function(c)
		FX.GlowColor = c
		if glowObj and not FX.GlowRainbow then
			glowObj.FillColor = c
			glowObj.OutlineColor = c
		end
	end,
})
glowTab:Toggle({
	Title = "Rainbow Glow",
	Value = false,
	Callback = function(v) FX.GlowRainbow = v end,
})

-- ---- Body tab ----------------------------------------------
local bodyTab = Window:Tab({ Title = "Body", Icon = "zap" })
bodyTab:Toggle({
	Title = "Neon Body",
	Value = false,
	Callback = function(v)
		FX.Neon = v
		applyNeon(v)
	end,
})
bodyTab:Colorpicker({
	Title = "Neon Color",
	Default = FX.NeonColor,
	Callback = function(c)
		FX.NeonColor = c
		if FX.Neon and not FX.NeonRainbow then
			for p in pairs(neonParts) do
				if p and p.Parent then p.Color = c end
			end
		end
	end,
})
bodyTab:Toggle({
	Title = "Rainbow Neon",
	Value = false,
	Callback = function(v) FX.NeonRainbow = v end,
})

-- ---- Particles tab -----------------------------------------
local partTab = Window:Tab({ Title = "Particles", Icon = "stars" })
partTab:Toggle({
	Title = "Sparkles",
	Value = false,
	Callback = function(v)
		FX.Sparkles = v
		if v then buildSparkles() else destroySparkles() end
	end,
})
partTab:Toggle({
	Title = "Aura",
	Value = false,
	Callback = function(v)
		FX.Aura = v
		if v then buildAura() else destroyAura() end
	end,
})
partTab:Colorpicker({
	Title = "Aura Color",
	Default = FX.AuraColor,
	Callback = function(c)
		FX.AuraColor = c
		if auraObj and not FX.AuraRainbow then
			auraObj.Color = ColorSequence.new(c)
		end
	end,
})
partTab:Toggle({
	Title = "Rainbow Aura",
	Value = false,
	Callback = function(v) FX.AuraRainbow = v end,
})

-- ---- World tab ---------------------------------------------
local worldTab = Window:Tab({ Title = "World", Icon = "cloud" })
worldTab:Toggle({
	Title = "Rain",
	Value = false,
	Callback = function(v)
		FX.Rain = v
		if not FX.Storm then setRain(v, false) end
	end,
})
worldTab:Toggle({
	Title = "Snow",
	Value = false,
	Callback = function(v)
		FX.Snow = v
		setSnow(v)
	end,
})
worldTab:Toggle({
	Title = "Storm (rain + dark + lightning)",
	Value = false,
	Callback = function(v)
		FX.Storm = v
		applyStorm(v)
	end,
})
worldTab:Slider({
	Title = "Fog",
	Step  = 0.01,
	Value = { Min = 0, Max = 1, Default = 0 },
	Callback = function(v) applyFog(v) end,
})
worldTab:Slider({
	Title = "Time of Day",
	Step  = 0.1,
	Value = { Min = 0, Max = 24, Default = 14 },
	Callback = function(v) Lighting.ClockTime = v end,
})
worldTab:Slider({
	Title = "Brightness",
	Step  = 0.1,
	Value = { Min = 0, Max = 5, Default = 2 },
	Callback = function(v) Lighting.Brightness = v end,
})
worldTab:Colorpicker({
	Title = "World Tint",
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(c) ensureCC().TintColor = c end,
})
worldTab:Slider({
	Title = "Saturation",
	Step  = 0.05,
	Value = { Min = -1, Max = 2, Default = 0 },
	Callback = function(v) ensureCC().Saturation = v end,
})
worldTab:Dropdown({
	Title = "Sky Preset",
	Values = { "Default", "Clear Day", "Sunset", "Night", "Galaxy" },
	Value = "Default",
	Callback = function(name) applySkyPreset(name) end,
})
worldTab:Button({
	Title = "Reset World",
	Callback = function()
		resetWorld()
		WindUI:Notify({ Title = "World", Content = "Lighting restored.", Duration = 3 })
	end,
})

-- ---- Info tab ----------------------------------------------
local infoTab = Window:Tab({ Title = "Info", Icon = "info" })
infoTab:Paragraph({
	Title = "About",
	Desc  = "Cosmetic effects only, applied to your own character. "
		.. "Toggle the menu with the K key (or the floating button on mobile).",
})
infoTab:Button({
	Title = "Clear All Effects",
	Callback = function()
		destroyTrail(); destroyGlow(); destroySparkles(); destroyAura()
		applyNeon(false)
		resetWorld()
		FX.Trail, FX.Glow, FX.Neon, FX.Sparkles, FX.Aura = false, false, false, false, false
		WindUI:Notify({ Title = "Visuals", Content = "All effects cleared.", Duration = 3 })
	end,
})

-- ============================================================
--  Rainbow / animated color driver
-- ============================================================
local nextStrike = 0
RunService.RenderStepped:Connect(function()
	local hue = (tick() * 0.15) % 1
	local rainbow = Color3.fromHSV(hue, 0.85, 1)

	-- Keep precipitation centered above the camera.
	if weatherPart and (rainEmitter or snowEmitter) then
		weatherPart.Position = camera.CFrame.Position + Vector3.new(0, 45, 0)
	end

	-- Storm lightning: brief brightness flashes at random intervals.
	if FX.Storm then
		local t = time()
		if t >= nextStrike then
			nextStrike = t + math.random(4, 10)
			task.spawn(function()
				for _, b in ipairs({ 3, 0.3, 2.5, 0.6 }) do
					Lighting.Brightness = b
					task.wait(0.06)
				end
			end)
		end
	end

	if FX.Trail and FX.TrailRainbow and trailObj then
		trailObj.Color = ColorSequence.new(rainbow)
	end
	if FX.Glow and FX.GlowRainbow and glowObj then
		glowObj.FillColor = rainbow
		glowObj.OutlineColor = rainbow
	end
	if FX.Neon and FX.NeonRainbow then
		for p in pairs(neonParts) do
			if p and p.Parent then p.Color = rainbow end
		end
	end
	if FX.Aura and FX.AuraRainbow and auraObj then
		auraObj.Color = ColorSequence.new(rainbow)
	end
end)

WindUI:Notify({
	Title = "Cosmetic Visuals",
	Content = "Loaded. Open with K. Self-only effects.",
	Duration = 4,
})
