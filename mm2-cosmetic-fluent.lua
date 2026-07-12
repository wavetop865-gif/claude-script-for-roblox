-- ============================================================
--  MM2 Cosmetic Visuals — powered by the Fluent UI library
--  (https://github.com/dawid-scripts/Fluent)
--
--  Clean acrylic UI, mobile-friendly. COSMETIC-ONLY effects for
--  YOUR OWN character / view. No role ESP, no coin farm, no kill
--  aura, no aimbot — nothing that affects gameplay or other
--  players. Just visual flair.
--
--  Tabs:
--    Character — trail, glow, neon, light (self)
--    World     — rain / snow / fog / time / sky (client view)
--    MM2       — knife trail on your equipped tool + coin sparkle
--
--  Usage: paste into an executor, or drop into
--  StarterPlayer > StarterPlayerScripts as a LocalScript.
-- ============================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local Lighting     = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ------------------------------------------------------------
--  Load Fluent (+ optional add-on managers) from GitHub
-- ------------------------------------------------------------
local Fluent = loadstring(game:HttpGet(
	"https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

-- ============================================================
--  State (self only)
-- ============================================================
local ACCENT = Color3.fromRGB(120, 110, 255)

local FX = {
	Trail = false, TrailColor = ACCENT, TrailRainbow = false, TrailWidth = 1.0, TrailLife = 0.6,
	Glow = false, GlowColor = ACCENT, GlowRainbow = false,
	Neon = false, NeonColor = Color3.fromRGB(70, 200, 255), NeonRainbow = false,
	Light = false, LightColor = Color3.fromRGB(255, 255, 255), LightBright = 3, LightRange = 24, LightRainbow = false,

	Rain = false, Snow = false,

	Knife = false, KnifeColor = Color3.fromRGB(255, 60, 60), KnifeRainbow = false,
	Coin = false,

	Halo = false, HaloColor = Color3.fromRGB(255, 230, 120), HaloRainbow = false,
	Orb = false, OrbColor = Color3.fromRGB(120, 200, 255), OrbRainbow = false, OrbSpeed = 1.5,
	Footsteps = false,
	Shockwave = false,
	Cinema = false,

	RainbowSpeed = 0.15,
}

local function getChar()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	return char, hrp
end

-- ============================================================
--  Character effects
-- ============================================================
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
	trailObj.Attachment0 = trailA
	trailObj.Attachment1 = trailB
	trailObj.Lifetime = FX.TrailLife
	trailObj.WidthScale = NumberSequence.new(FX.TrailWidth)
	trailObj.LightEmission = 1
	trailObj.FaceCamera = true
	trailObj.Color = ColorSequence.new(FX.TrailColor)
	trailObj.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1),
	})
	trailObj.Parent = hrp
end
local function destroyTrail()
	if trailObj then trailObj:Destroy(); trailObj = nil end
	if trailA then trailA:Destroy(); trailA = nil end
	if trailB then trailB:Destroy(); trailB = nil end
end

-- ---- Glow ---------------------------------------------------
local glowObj
local function buildGlow()
	local char = getChar()
	if not char then return end
	if glowObj then glowObj:Destroy() end
	glowObj = Instance.new("Highlight")
	glowObj.Adornee = char
	glowObj.FillTransparency = 0.6
	glowObj.OutlineTransparency = 0
	glowObj.FillColor = FX.GlowColor
	glowObj.OutlineColor = FX.GlowColor
	glowObj.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	glowObj.Parent = char
end
local function destroyGlow()
	if glowObj then glowObj:Destroy(); glowObj = nil end
end

-- ---- Neon ---------------------------------------------------
local neonParts = {}
local function applyNeon(on)
	local char = getChar()
	if not char then return end
	if on then
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				if not neonParts[p] then neonParts[p] = { mat = p.Material, col = p.Color } end
				p.Material = Enum.Material.Neon
				p.Color = FX.NeonColor
			end
		end
	else
		for p, saved in pairs(neonParts) do
			if p and p.Parent then p.Material = saved.mat; p.Color = saved.col end
		end
		neonParts = {}
	end
end

-- ---- Light --------------------------------------------------
local lightObj
local function setLight(on)
	local _, hrp = getChar()
	if on then
		if not hrp then return end
		if lightObj then lightObj:Destroy() end
		lightObj = Instance.new("PointLight")
		lightObj.Color = FX.LightColor
		lightObj.Brightness = FX.LightBright
		lightObj.Range = FX.LightRange
		lightObj.Parent = hrp
	else
		if lightObj then lightObj:Destroy(); lightObj = nil end
	end
end

-- ============================================================
--  World / weather (client-side)
-- ============================================================
local origLighting = {
	Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
	Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
	FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
}
local customSky
local function clearCustomSky() if customSky then customSky:Destroy(); customSky = nil end end

local weatherPart, rainEmitter, snowEmitter
local function ensureWeatherPart()
	if weatherPart and weatherPart.Parent then return weatherPart end
	weatherPart = Instance.new("Part")
	weatherPart.Name = "Vis_Weather"
	weatherPart.Anchored = true
	weatherPart.CanCollide = false
	weatherPart.CanQuery = false
	weatherPart.CanTouch = false
	weatherPart.Transparency = 1
	weatherPart.Size = Vector3.new(140, 1, 140)
	weatherPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 50, 0))
	weatherPart.Parent = workspace
	return weatherPart
end
local function setRain(on)
	if on then
		ensureWeatherPart()
		if rainEmitter then rainEmitter:Destroy() end
		rainEmitter = Instance.new("ParticleEmitter")
		rainEmitter.Texture = "rbxassetid://8992859960"
		rainEmitter.Color = ColorSequence.new(Color3.fromRGB(180, 200, 235))
		rainEmitter.Transparency = NumberSequence.new(0.25)
		rainEmitter.Rate = 800
		rainEmitter.Lifetime = NumberRange.new(0.6, 0.8)
		rainEmitter.Speed = NumberRange.new(120, 150)
		rainEmitter.Size = NumberSequence.new(0.5)
		rainEmitter.Acceleration = Vector3.new(0, -120, 0)
		rainEmitter.EmissionDirection = Enum.NormalId.Bottom
		rainEmitter.SpreadAngle = Vector2.new(4, 4)
		rainEmitter.ZOffset = 1
		pcall(function() rainEmitter.Squash = NumberSequence.new(8) end)
		rainEmitter.Parent = weatherPart
	else
		if rainEmitter then rainEmitter:Destroy(); rainEmitter = nil end
	end
end
local function setSnow(on)
	if on then
		ensureWeatherPart()
		if snowEmitter then snowEmitter:Destroy() end
		snowEmitter = Instance.new("ParticleEmitter")
		snowEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		snowEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		snowEmitter.Transparency = NumberSequence.new(0.1)
		snowEmitter.Rate = 260
		snowEmitter.Lifetime = NumberRange.new(2.5, 3.5)
		snowEmitter.Speed = NumberRange.new(6, 12)
		snowEmitter.Size = NumberSequence.new(0.45)
		snowEmitter.Rotation = NumberRange.new(0, 360)
		snowEmitter.RotSpeed = NumberRange.new(-40, 40)
		snowEmitter.Acceleration = Vector3.new(2, -8, 0)
		snowEmitter.EmissionDirection = Enum.NormalId.Bottom
		snowEmitter.SpreadAngle = Vector2.new(40, 40)
		snowEmitter.Parent = weatherPart
	else
		if snowEmitter then snowEmitter:Destroy(); snowEmitter = nil end
	end
end
local function applyFog(density)
	if density <= 0.001 then
		Lighting.FogEnd = origLighting.FogEnd; Lighting.FogStart = origLighting.FogStart
		return
	end
	Lighting.FogStart = 0
	Lighting.FogEnd = 2000 + (60 - 2000) * density
end
local function applySkyPreset(name)
	clearCustomSky()
	if name == "Default" then
		Lighting.ClockTime = origLighting.ClockTime
		Lighting.Ambient = origLighting.Ambient; Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
	elseif name == "Clear Day" then
		Lighting.ClockTime = 14
		Lighting.Ambient = Color3.fromRGB(140, 145, 155); Lighting.OutdoorAmbient = Color3.fromRGB(150, 155, 165)
	elseif name == "Sunset" then
		Lighting.ClockTime = 17.6
		Lighting.Ambient = Color3.fromRGB(120, 80, 60); Lighting.OutdoorAmbient = Color3.fromRGB(150, 100, 70)
	elseif name == "Night" then
		Lighting.ClockTime = 0
		Lighting.Ambient = Color3.fromRGB(30, 34, 55); Lighting.OutdoorAmbient = Color3.fromRGB(40, 44, 70)
		customSky = Instance.new("Sky"); customSky.StarCount = 6000; customSky.Parent = Lighting
	elseif name == "Galaxy" then
		Lighting.ClockTime = 0
		Lighting.Ambient = Color3.fromRGB(60, 40, 80); Lighting.OutdoorAmbient = Color3.fromRGB(70, 50, 95)
		customSky = Instance.new("Sky"); customSky.StarCount = 10000; customSky.CelestialBodiesShown = false; customSky.Parent = Lighting
	end
end
local function resetWorld()
	setRain(false); setSnow(false); clearCustomSky()
	FX.Rain, FX.Snow = false, false
	if weatherPart then weatherPart:Destroy(); weatherPart = nil end
	Lighting.Ambient = origLighting.Ambient; Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
	Lighting.Brightness = origLighting.Brightness; Lighting.ClockTime = origLighting.ClockTime
	Lighting.FogColor = origLighting.FogColor; Lighting.FogEnd = origLighting.FogEnd; Lighting.FogStart = origLighting.FogStart
end

-- ============================================================
--  MM2 cosmetic — knife trail on your equipped tool
-- ============================================================
local knifeA, knifeB, knifeTrail
local function destroyKnife()
	if knifeTrail then knifeTrail:Destroy(); knifeTrail = nil end
	if knifeA then knifeA:Destroy(); knifeA = nil end
	if knifeB then knifeB:Destroy(); knifeB = nil end
end
local function buildKnifeTrail()
	destroyKnife()
	local char = player.Character
	if not char then return end
	local tool = char:FindFirstChildOfClass("Tool")
	local handle = tool and tool:FindFirstChild("Handle")
	if not handle then return end
	knifeA = Instance.new("Attachment"); knifeA.Name = "Vis_KnifeA"
	knifeA.Position = Vector3.new(0, 0,  handle.Size.Z * 0.5); knifeA.Parent = handle
	knifeB = Instance.new("Attachment"); knifeB.Name = "Vis_KnifeB"
	knifeB.Position = Vector3.new(0, 0, -handle.Size.Z * 0.5); knifeB.Parent = handle
	knifeTrail = Instance.new("Trail")
	knifeTrail.Attachment0 = knifeA
	knifeTrail.Attachment1 = knifeB
	knifeTrail.Lifetime = 0.35
	knifeTrail.WidthScale = NumberSequence.new(1)
	knifeTrail.LightEmission = 1
	knifeTrail.FaceCamera = true
	knifeTrail.Color = ColorSequence.new(FX.KnifeColor)
	knifeTrail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1),
	})
	knifeTrail.Parent = handle
end
-- Rebuild the knife trail whenever a tool is equipped.
local function hookToolEquip()
	local char = player.Character
	if not char then return end
	char.ChildAdded:Connect(function(c)
		if FX.Knife and c:IsA("Tool") then
			task.wait(0.1)
			buildKnifeTrail()
		end
	end)
end

-- ============================================================
--  MM2 cosmetic — coin sparkle (reacts to YOUR coin count going up)
-- ============================================================
local function coinBurst()
	local _, hrp = getChar()
	if not hrp then return end
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(255, 215, 60))
	e.Rate = 0
	e.Lifetime = NumberRange.new(0.5, 0.9)
	e.Speed = NumberRange.new(6, 10)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new(0.5)
	e.LightEmission = 1
	e.Parent = hrp
	e:Emit(30)
	task.delay(1.2, function() if e then e:Destroy() end end)
end

local coinConn
local function findCoinStat()
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return nil end
	local fallback
	for _, v in ipairs(ls:GetChildren()) do
		if v:IsA("IntValue") or v:IsA("NumberValue") then
			if string.find(string.lower(v.Name), "coin") then return v end
			fallback = fallback or v
		end
	end
	return fallback
end
local function watchCoins(on)
	if coinConn then coinConn:Disconnect(); coinConn = nil end
	if not on then return end
	local stat = findCoinStat()
	if not stat then return end
	local last = stat.Value
	coinConn = stat.Changed:Connect(function(new)
		if new > last then coinBurst() end
		last = new
	end)
end

-- ============================================================
--  Fun effects (all local / cosmetic)
-- ============================================================
-- ---- Halo: spinning neon disc above your head ---------------
local haloPart
local function setHalo(on)
	if on then
		if haloPart then haloPart:Destroy() end
		haloPart = Instance.new("Part")
		haloPart.Name         = "Vis_Halo"
		haloPart.Anchored     = true
		haloPart.CanCollide   = false
		haloPart.CanQuery     = false
		haloPart.CanTouch     = false
		haloPart.Material     = Enum.Material.Neon
		haloPart.Shape        = Enum.PartType.Cylinder
		haloPart.Size         = Vector3.new(0.12, 2.2, 2.2)
		haloPart.Transparency = 0.25
		haloPart.Color        = FX.HaloColor
		haloPart.Parent       = workspace
	else
		if haloPart then haloPart:Destroy(); haloPart = nil end
	end
end

-- ---- Orbit orb: glowing "pet" circling around you -----------
local orbPart
local function setOrb(on)
	if on then
		if orbPart then orbPart:Destroy() end
		orbPart = Instance.new("Part")
		orbPart.Name       = "Vis_Orb"
		orbPart.Anchored   = true
		orbPart.CanCollide = false
		orbPart.CanQuery   = false
		orbPart.CanTouch   = false
		orbPart.Material   = Enum.Material.Neon
		orbPart.Shape      = Enum.PartType.Ball
		orbPart.Size       = Vector3.new(0.7, 0.7, 0.7)
		orbPart.Color      = FX.OrbColor
		orbPart.Parent     = workspace
		local l = Instance.new("PointLight")
		l.Brightness = 2; l.Range = 12; l.Color = FX.OrbColor; l.Parent = orbPart
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Rate = 25; e.Lifetime = NumberRange.new(0.3, 0.6)
		e.Speed = NumberRange.new(0.5, 1); e.Size = NumberSequence.new(0.25)
		e.LightEmission = 1; e.Parent = orbPart
	else
		if orbPart then orbPart:Destroy(); orbPart = nil end
	end
end

-- ---- Footstep sparks ----------------------------------------
local stepEmitter
local function buildStepEmitter()
	local _, hrp = getChar()
	if not hrp then return end
	if stepEmitter then stepEmitter:Destroy() end
	stepEmitter = Instance.new("ParticleEmitter")
	stepEmitter.Name = "Vis_Steps"
	stepEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	stepEmitter.Rate = 0 -- burst-only via :Emit
	stepEmitter.Lifetime = NumberRange.new(0.3, 0.5)
	stepEmitter.Speed = NumberRange.new(2, 4)
	stepEmitter.SpreadAngle = Vector2.new(60, 60)
	stepEmitter.Size = NumberSequence.new(0.25)
	stepEmitter.LightEmission = 1
	stepEmitter.EmissionDirection = Enum.NormalId.Bottom
	stepEmitter.Parent = hrp
end
local function setFootsteps(on)
	if on then buildStepEmitter()
	elseif stepEmitter then stepEmitter:Destroy(); stepEmitter = nil end
end

-- ---- Jump shockwave -----------------------------------------
local function spawnShockwave()
	local _, hrp = getChar()
	if not hrp then return end
	local ring = Instance.new("Part")
	ring.Anchored     = true
	ring.CanCollide   = false
	ring.CanQuery     = false
	ring.CanTouch     = false
	ring.Material     = Enum.Material.Neon
	ring.Shape        = Enum.PartType.Cylinder
	ring.Size         = Vector3.new(0.12, 1, 1)
	ring.Transparency = 0.2
	ring.Color        = Color3.fromRGB(255, 255, 255)
	ring.CFrame       = CFrame.new(hrp.Position - Vector3.new(0, 2.7, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent       = workspace
	TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.12, 14, 14),
		Transparency = 1,
	}):Play()
	task.delay(0.5, function() ring:Destroy() end)
end
local humStateConn
local function hookHumanoid()
	if humStateConn then humStateConn:Disconnect(); humStateConn = nil end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	humStateConn = hum.StateChanged:Connect(function(_, new)
		if FX.Shockwave and new == Enum.HumanoidStateType.Jumping then
			spawnShockwave()
		end
	end)
end

-- ---- Fireworks (button) -------------------------------------
local function firework()
	local _, hrp = getChar()
	if not hrp then return end
	for i = 1, 4 do
		task.delay(i * 0.3, function()
			local _, hrp2 = getChar()
			if not hrp2 then return end
			local p = Instance.new("Part")
			p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
			p.Transparency = 1
			p.Size = Vector3.new(1, 1, 1)
			p.Position = hrp2.Position + Vector3.new(math.random(-12, 12), math.random(16, 26), math.random(-12, 12))
			p.Parent = workspace
			local e = Instance.new("ParticleEmitter")
			e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			e.Color = ColorSequence.new(Color3.fromHSV(math.random(), 0.8, 1))
			e.Rate = 0
			e.Lifetime = NumberRange.new(0.8, 1.2)
			e.Speed = NumberRange.new(25, 35)
			e.SpreadAngle = Vector2.new(180, 180)
			e.Size = NumberSequence.new(0.4)
			e.LightEmission = 1
			e.Acceleration = Vector3.new(0, -20, 0)
			e.Parent = p
			e:Emit(140)
			task.delay(2, function() p:Destroy() end)
		end)
	end
end

-- ---- Confetti (button) --------------------------------------
local CONFETTI_COLORS = {
	Color3.fromRGB(255, 80, 120), Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(90, 230, 130), Color3.fromRGB(70, 200, 255),
	Color3.fromRGB(190, 120, 255),
}
local function confetti()
	local _, hrp = getChar()
	if not hrp then return end
	for _, col in ipairs(CONFETTI_COLORS) do
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(col)
		e.Rate = 0
		e.Lifetime = NumberRange.new(1.2, 1.8)
		e.Speed = NumberRange.new(12, 18)
		e.SpreadAngle = Vector2.new(70, 70)
		e.Size = NumberSequence.new(0.3)
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-200, 200)
		e.Acceleration = Vector3.new(0, -25, 0)
		e.EmissionDirection = Enum.NormalId.Top
		e.Parent = hrp
		e:Emit(20)
		task.delay(2.2, function() e:Destroy() end)
	end
end

-- ---- Cinema mode (letterbox bars) ---------------------------
local cinemaGui
local function setCinema(on)
	if on then
		if cinemaGui then cinemaGui:Destroy() end
		cinemaGui = Instance.new("ScreenGui")
		cinemaGui.Name = "Vis_Cinema"
		cinemaGui.IgnoreGuiInset = true
		cinemaGui.DisplayOrder = 500
		cinemaGui.ResetOnSpawn = false
		local function bar(anchorY, posY)
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0, anchorY)
			f.Position = UDim2.new(0, 0, posY, 0)
			f.Size = UDim2.new(1, 0, 0.11, 0)
			f.BackgroundColor3 = Color3.new(0, 0, 0)
			f.BorderSizePixel = 0
			f.Parent = cinemaGui
		end
		bar(0, 0); bar(1, 1)
		cinemaGui.Parent = player:WaitForChild("PlayerGui")
	else
		if cinemaGui then cinemaGui:Destroy(); cinemaGui = nil end
	end
end

-- ============================================================
--  Re-apply on respawn
-- ============================================================
player.CharacterAdded:Connect(function()
	task.wait(0.6)
	neonParts = {}
	if FX.Trail then buildTrail() end
	if FX.Glow then buildGlow() end
	if FX.Neon then applyNeon(true) end
	if FX.Light then setLight(true) end
	if FX.Knife then buildKnifeTrail() end
	if FX.Footsteps then buildStepEmitter() end
	hookToolEquip()
	hookHumanoid()
	if FX.Coin then watchCoins(true) end
end)
hookToolEquip()
hookHumanoid()

-- ============================================================
--  Build the Fluent window
-- ============================================================
local Window = Fluent:CreateWindow({
	Title    = "MM2 Cosmetic",
	SubTitle = "self-only visuals",
	TabWidth = 150,
	Size     = UDim2.fromOffset(560, 440),
	Acrylic  = true,
	Theme    = "Dark",
	MinimizeKey = Enum.KeyCode.K,
})

local Tabs = {
	Character = Window:AddTab({ Title = "Character", Icon = "user" }),
	World     = Window:AddTab({ Title = "World",     Icon = "cloud" }),
	MM2       = Window:AddTab({ Title = "MM2",        Icon = "sparkles" }),
	Fun       = Window:AddTab({ Title = "Fun",        Icon = "party-popper" }),
	Settings  = Window:AddTab({ Title = "Settings",   Icon = "settings" }),
}

-- ---- Character tab -----------------------------------------
local c = Tabs.Character
c:AddToggle("TrailEnable", { Title = "Trail", Default = false, Callback = function(v)
	FX.Trail = v; if v then buildTrail() else destroyTrail() end
end })
c:AddColorpicker("TrailColor", { Title = "Trail Color", Default = FX.TrailColor, Callback = function(col)
	FX.TrailColor = col; if trailObj and not FX.TrailRainbow then trailObj.Color = ColorSequence.new(col) end
end })
c:AddToggle("TrailRainbow", { Title = "Rainbow Trail", Default = false, Callback = function(v) FX.TrailRainbow = v end })
c:AddSlider("TrailWidth", { Title = "Trail Width", Default = 1, Min = 0.2, Max = 4, Rounding = 1, Callback = function(v)
	FX.TrailWidth = v; if trailObj then trailObj.WidthScale = NumberSequence.new(v) end
end })
c:AddToggle("GlowEnable", { Title = "Character Glow", Default = false, Callback = function(v)
	FX.Glow = v; if v then buildGlow() else destroyGlow() end
end })
c:AddColorpicker("GlowColor", { Title = "Glow Color", Default = FX.GlowColor, Callback = function(col)
	FX.GlowColor = col; if glowObj and not FX.GlowRainbow then glowObj.FillColor = col; glowObj.OutlineColor = col end
end })
c:AddToggle("GlowRainbow", { Title = "Rainbow Glow", Default = false, Callback = function(v) FX.GlowRainbow = v end })
c:AddToggle("NeonEnable", { Title = "Neon Body", Default = false, Callback = function(v) FX.Neon = v; applyNeon(v) end })
c:AddColorpicker("NeonColor", { Title = "Neon Color", Default = FX.NeonColor, Callback = function(col)
	FX.NeonColor = col
	if FX.Neon and not FX.NeonRainbow then for p in pairs(neonParts) do if p and p.Parent then p.Color = col end end end
end })
c:AddToggle("NeonRainbow", { Title = "Rainbow Neon", Default = false, Callback = function(v) FX.NeonRainbow = v end })
c:AddToggle("LightEnable", { Title = "Character Light", Default = false, Callback = function(v) FX.Light = v; setLight(v) end })
c:AddColorpicker("LightColor", { Title = "Light Color", Default = FX.LightColor, Callback = function(col)
	FX.LightColor = col; if lightObj and not FX.LightRainbow then lightObj.Color = col end
end })
c:AddToggle("LightRainbow", { Title = "Rainbow Light", Default = false, Callback = function(v) FX.LightRainbow = v end })

-- ---- World tab ---------------------------------------------
local w = Tabs.World
w:AddToggle("Rain", { Title = "Rain", Default = false, Callback = function(v) FX.Rain = v; setRain(v) end })
w:AddToggle("Snow", { Title = "Snow", Default = false, Callback = function(v) FX.Snow = v; setSnow(v) end })
w:AddSlider("Fog", { Title = "Fog", Default = 0, Min = 0, Max = 1, Rounding = 2, Callback = function(v) applyFog(v) end })
w:AddSlider("Time", { Title = "Time of Day", Default = 14, Min = 0, Max = 24, Rounding = 1, Callback = function(v) Lighting.ClockTime = v end })
w:AddSlider("Bright", { Title = "Brightness", Default = 2, Min = 0, Max = 5, Rounding = 1, Callback = function(v) Lighting.Brightness = v end })
w:AddDropdown("Sky", { Title = "Sky Preset", Values = { "Default", "Clear Day", "Sunset", "Night", "Galaxy" }, Default = 1, Callback = function(v) applySkyPreset(v) end })
w:AddButton({ Title = "Reset World", Description = "Restore original lighting", Callback = function()
	resetWorld(); Fluent:Notify({ Title = "World", Content = "Lighting restored.", Duration = 3 })
end })

-- ---- MM2 tab (cosmetic only) -------------------------------
local m = Tabs.MM2
m:AddParagraph({
	Title = "Cosmetic only",
	Content = "These effects are visual and apply only to you. No role reveal, coin farm, kill aura or aimbot.",
})
m:AddToggle("Knife", { Title = "Knife Trail", Default = false, Callback = function(v)
	FX.Knife = v; if v then buildKnifeTrail() else destroyKnife() end
end })
m:AddColorpicker("KnifeColor", { Title = "Knife Trail Color", Default = FX.KnifeColor, Callback = function(col)
	FX.KnifeColor = col; if knifeTrail and not FX.KnifeRainbow then knifeTrail.Color = ColorSequence.new(col) end
end })
m:AddToggle("KnifeRainbow", { Title = "Rainbow Knife Trail", Default = false, Callback = function(v) FX.KnifeRainbow = v end })
m:AddToggle("Coin", { Title = "Coin Sparkle", Default = false, Callback = function(v) FX.Coin = v; watchCoins(v) end })
m:AddButton({ Title = "Test Sparkle", Description = "Preview the coin sparkle burst", Callback = coinBurst })

-- ---- Fun tab ------------------------------------------------
local f = Tabs.Fun
f:AddToggle("Halo", { Title = "Halo", Default = false, Callback = function(v) FX.Halo = v; setHalo(v) end })
f:AddColorpicker("HaloColor", { Title = "Halo Color", Default = FX.HaloColor, Callback = function(col)
	FX.HaloColor = col; if haloPart and not FX.HaloRainbow then haloPart.Color = col end
end })
f:AddToggle("HaloRainbow", { Title = "Rainbow Halo", Default = false, Callback = function(v) FX.HaloRainbow = v end })
f:AddToggle("Orb", { Title = "Orbit Orb (pet)", Default = false, Callback = function(v) FX.Orb = v; setOrb(v) end })
f:AddColorpicker("OrbColor", { Title = "Orb Color", Default = FX.OrbColor, Callback = function(col)
	FX.OrbColor = col
	if orbPart and not FX.OrbRainbow then
		orbPart.Color = col
		local l = orbPart:FindFirstChildOfClass("PointLight")
		if l then l.Color = col end
	end
end })
f:AddToggle("OrbRainbow", { Title = "Rainbow Orb", Default = false, Callback = function(v) FX.OrbRainbow = v end })
f:AddSlider("OrbSpeed", { Title = "Orb Speed", Default = 1.5, Min = 0.3, Max = 5, Rounding = 1, Callback = function(v) FX.OrbSpeed = v end })
f:AddToggle("Footsteps", { Title = "Footstep Sparks", Default = false, Callback = function(v) FX.Footsteps = v; setFootsteps(v) end })
f:AddToggle("Shockwave", { Title = "Jump Shockwave", Default = false, Callback = function(v) FX.Shockwave = v end })
f:AddToggle("Cinema", { Title = "Cinema Mode (letterbox)", Default = false, Callback = function(v) FX.Cinema = v; setCinema(v) end })
f:AddButton({ Title = "Fireworks", Description = "Launch a firework show above you", Callback = firework })
f:AddButton({ Title = "Confetti", Description = "Pop a confetti burst", Callback = confetti })

-- ---- Settings tab ------------------------------------------
local s = Tabs.Settings
s:AddSlider("RainbowSpeed", { Title = "Rainbow Speed", Default = 0.15, Min = 0.02, Max = 1, Rounding = 2, Callback = function(v) FX.RainbowSpeed = v end })
s:AddButton({ Title = "Clear All Effects", Description = "Remove everything and restore the world", Callback = function()
	destroyTrail(); destroyGlow(); applyNeon(false); setLight(false); destroyKnife(); watchCoins(false)
	setHalo(false); setOrb(false); setFootsteps(false); setCinema(false)
	resetWorld()
	FX.Trail, FX.Glow, FX.Neon, FX.Light, FX.Knife, FX.Coin = false, false, false, false, false, false
	FX.Halo, FX.Orb, FX.Footsteps, FX.Shockwave, FX.Cinema = false, false, false, false, false
	Fluent:Notify({ Title = "MM2 Cosmetic", Content = "All effects cleared.", Duration = 3 })
end })

-- ============================================================
--  Animated color driver + weather follow
-- ============================================================
local stepAccum = 0
RunService.RenderStepped:Connect(function(dt)
	local t = tick()
	local hue = (t * FX.RainbowSpeed) % 1
	local rainbow = Color3.fromHSV(hue, 0.85, 1)

	if weatherPart and (rainEmitter or snowEmitter) then
		weatherPart.Position = camera.CFrame.Position + Vector3.new(0, 50, 0)
	end

	local char, hrp = getChar()

	-- Halo: hover above the head with a slow wobble
	if FX.Halo and haloPart then
		local head = char and char:FindFirstChild("Head")
		if head then
			local tilt = math.rad(10) * math.sin(t * 1.5)
			haloPart.CFrame = CFrame.new(head.Position + Vector3.new(0, 1.4, 0))
				* CFrame.Angles(0, t * 0.8, tilt)
				* CFrame.Angles(0, 0, math.rad(90))
		end
	end

	-- Orbit orb: circle around the player with a gentle bob
	if FX.Orb and orbPart and hrp then
		local a = t * FX.OrbSpeed
		orbPart.Position = hrp.Position
			+ Vector3.new(math.cos(a) * 3.2, 1.6 + math.sin(t * 2) * 0.45, math.sin(a) * 3.2)
	end

	-- Footstep sparks while moving on the ground
	if FX.Footsteps and stepEmitter then
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air then
			stepAccum += dt
			if stepAccum >= 0.16 then
				stepAccum = 0
				stepEmitter:Emit(3)
			end
		end
	end

	if FX.Trail and FX.TrailRainbow and trailObj then trailObj.Color = ColorSequence.new(rainbow) end
	if FX.Glow and FX.GlowRainbow and glowObj then glowObj.FillColor = rainbow; glowObj.OutlineColor = rainbow end
	if FX.Neon and FX.NeonRainbow then for p in pairs(neonParts) do if p and p.Parent then p.Color = rainbow end end end
	if FX.Light and FX.LightRainbow and lightObj then lightObj.Color = rainbow end
	if FX.Knife and FX.KnifeRainbow and knifeTrail then knifeTrail.Color = ColorSequence.new(rainbow) end
	if FX.Halo and FX.HaloRainbow and haloPart then haloPart.Color = rainbow end
	if FX.Orb and FX.OrbRainbow and orbPart then
		orbPart.Color = rainbow
		local l = orbPart:FindFirstChildOfClass("PointLight")
		if l then l.Color = rainbow end
	end
end)

Fluent:Notify({
	Title = "MM2 Cosmetic",
	Content = "Loaded. Minimize/open with K. Self-only visuals.",
	Duration = 5,
})
