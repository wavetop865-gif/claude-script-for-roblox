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

local player = Players.LocalPlayer

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
		FX.Trail, FX.Glow, FX.Neon, FX.Sparkles, FX.Aura = false, false, false, false, false
		WindUI:Notify({ Title = "Visuals", Content = "All effects cleared.", Duration = 3 })
	end,
})

-- ============================================================
--  Rainbow / animated color driver
-- ============================================================
RunService.RenderStepped:Connect(function()
	local hue = (tick() * 0.15) % 1
	local rainbow = Color3.fromHSV(hue, 0.85, 1)

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
