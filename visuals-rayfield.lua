-- ============================================================
--  Cosmetic Visuals — powered by the Rayfield UI library
--  (https://github.com/shlexware/Rayfield  •  https://sirius.menu/rayfield)
--
--  Mobile-friendly menu of COSMETIC-ONLY effects for YOUR OWN
--  character. No gameplay advantage / no cheat functions:
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
--  Load the Rayfield library from GitHub
-- ------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ============================================================
--  Cosmetic effect state (self only)
-- ============================================================
local PALETTE_DEFAULT = Color3.fromRGB(120, 110, 255)

local FX = {
	Trail        = false,
	TrailColor   = PALETTE_DEFAULT,
	TrailRainbow = false,
	TrailWidth   = 1.0,
	TrailLife    = 0.6,

	Glow         = false,
	GlowColor    = PALETTE_DEFAULT,
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
local function getChar(): (Model?, BasePart?)
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
	trailObj.Name        = "Vis_Trail"
	trailObj.Attachment0 = trailA
	trailObj.Attachment1 = trailB
	trailObj.Lifetime    = FX.TrailLife
	trailObj.WidthScale  = NumberSequence.new(FX.TrailWidth)
	trailObj.LightEmission = 1
	trailObj.FaceCamera  = true
	trailObj.Color       = ColorSequence.new(FX.TrailColor)
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
local function applyNeon(on: boolean)
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
	sparkleObj.Name        = "Vis_Sparkles"
	sparkleObj.Texture     = "rbxasset://textures/particles/sparkles_main.dds"
	sparkleObj.Rate        = 40
	sparkleObj.Lifetime    = NumberRange.new(0.6, 1.0)
	sparkleObj.Speed       = NumberRange.new(1, 2)
	sparkleObj.SpreadAngle = Vector2.new(180, 180)
	sparkleObj.Size        = NumberSequence.new(0.4)
	sparkleObj.LightEmission = 1
	sparkleObj.Parent      = hrp
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
	auraObj.Name        = "Vis_Aura"
	auraObj.Texture     = "rbxasset://textures/particles/smoke_main.dds"
	auraObj.Rate        = 60
	auraObj.Lifetime    = NumberRange.new(0.8, 1.2)
	auraObj.Speed       = NumberRange.new(0, 1)
	auraObj.SpreadAngle = Vector2.new(360, 360)
	auraObj.Color       = ColorSequence.new(FX.AuraColor)
	auraObj.Size        = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	auraObj.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	auraObj.LightEmission = 0.8
	auraObj.Parent      = hrp
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
--  Build the Rayfield UI
-- ============================================================
local Window = Rayfield:CreateWindow({
	Name = "Visuals",
	Icon = 0,
	LoadingTitle = "Cosmetic Visuals",
	LoadingSubtitle = "self-only effects",
	Theme = "Amethyst",
	ToggleUIKeybind = "K",
	DisableRayfieldPrompts = true,
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "CosmeticVisuals",
		FileName = "Config",
	},
	KeySystem = false,
})

-- ---- Trail tab ---------------------------------------------
local trailTab = Window:CreateTab("Trail", 4483362458)
trailTab:CreateToggle({
	Name = "Enable Trail",
	CurrentValue = false,
	Flag = "TrailEnabled",
	Callback = function(v)
		FX.Trail = v
		if v then buildTrail() else destroyTrail() end
	end,
})
trailTab:CreateColorPicker({
	Name = "Trail Color",
	Color = FX.TrailColor,
	Flag = "TrailColor",
	Callback = function(c)
		FX.TrailColor = c
		if trailObj and not FX.TrailRainbow then
			trailObj.Color = ColorSequence.new(c)
		end
	end,
})
trailTab:CreateToggle({
	Name = "Rainbow Trail",
	CurrentValue = false,
	Flag = "TrailRainbow",
	Callback = function(v) FX.TrailRainbow = v end,
})
trailTab:CreateSlider({
	Name = "Trail Width",
	Range = {0.2, 4},
	Increment = 0.1,
	CurrentValue = 1,
	Flag = "TrailWidth",
	Callback = function(v)
		FX.TrailWidth = v
		if trailObj then trailObj.WidthScale = NumberSequence.new(v) end
	end,
})
trailTab:CreateSlider({
	Name = "Trail Lifetime",
	Range = {0.2, 2},
	Increment = 0.1,
	Suffix = "s",
	CurrentValue = 0.6,
	Flag = "TrailLife",
	Callback = function(v)
		FX.TrailLife = v
		if trailObj then trailObj.Lifetime = v end
	end,
})

-- ---- Glow tab ----------------------------------------------
local glowTab = Window:CreateTab("Glow", 4483362458)
glowTab:CreateToggle({
	Name = "Character Glow",
	CurrentValue = false,
	Flag = "GlowEnabled",
	Callback = function(v)
		FX.Glow = v
		if v then buildGlow() else destroyGlow() end
	end,
})
glowTab:CreateColorPicker({
	Name = "Glow Color",
	Color = FX.GlowColor,
	Flag = "GlowColor",
	Callback = function(c)
		FX.GlowColor = c
		if glowObj and not FX.GlowRainbow then
			glowObj.FillColor = c
			glowObj.OutlineColor = c
		end
	end,
})
glowTab:CreateToggle({
	Name = "Rainbow Glow",
	CurrentValue = false,
	Flag = "GlowRainbow",
	Callback = function(v) FX.GlowRainbow = v end,
})

-- ---- Body tab ----------------------------------------------
local bodyTab = Window:CreateTab("Body", 4483362458)
bodyTab:CreateToggle({
	Name = "Neon Body",
	CurrentValue = false,
	Flag = "NeonEnabled",
	Callback = function(v)
		FX.Neon = v
		applyNeon(v)
	end,
})
bodyTab:CreateColorPicker({
	Name = "Neon Color",
	Color = FX.NeonColor,
	Flag = "NeonColor",
	Callback = function(c)
		FX.NeonColor = c
		if FX.Neon and not FX.NeonRainbow then
			for p in pairs(neonParts) do
				if p and p.Parent then p.Color = c end
			end
		end
	end,
})
bodyTab:CreateToggle({
	Name = "Rainbow Neon",
	CurrentValue = false,
	Flag = "NeonRainbow",
	Callback = function(v) FX.NeonRainbow = v end,
})

-- ---- Particles tab -----------------------------------------
local partTab = Window:CreateTab("Particles", 4483362458)
partTab:CreateToggle({
	Name = "Sparkles",
	CurrentValue = false,
	Flag = "SparklesEnabled",
	Callback = function(v)
		FX.Sparkles = v
		if v then buildSparkles() else destroySparkles() end
	end,
})
partTab:CreateToggle({
	Name = "Aura",
	CurrentValue = false,
	Flag = "AuraEnabled",
	Callback = function(v)
		FX.Aura = v
		if v then buildAura() else destroyAura() end
	end,
})
partTab:CreateColorPicker({
	Name = "Aura Color",
	Color = FX.AuraColor,
	Flag = "AuraColor",
	Callback = function(c)
		FX.AuraColor = c
		if auraObj and not FX.AuraRainbow then
			auraObj.Color = ColorSequence.new(c)
		end
	end,
})
partTab:CreateToggle({
	Name = "Rainbow Aura",
	CurrentValue = false,
	Flag = "AuraRainbow",
	Callback = function(v) FX.AuraRainbow = v end,
})

-- ---- Info tab ----------------------------------------------
local infoTab = Window:CreateTab("Info", 4483362458)
infoTab:CreateParagraph({
	Title = "About",
	Content = "Cosmetic effects only, applied to your own character. "
		.. "Toggle the menu with the K key (or the floating button on mobile). "
		.. "Drag the title bar to move the window.",
})
infoTab:CreateButton({
	Name = "Clear All Effects",
	Callback = function()
		destroyTrail(); destroyGlow(); destroySparkles(); destroyAura()
		applyNeon(false)
		FX.Trail, FX.Glow, FX.Neon, FX.Sparkles, FX.Aura = false, false, false, false, false
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

Rayfield:LoadConfiguration()
