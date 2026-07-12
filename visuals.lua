--!strict
-- ============================================================
--  Visuals Menu — cosmetic-only effects for YOUR OWN character.
--  Mobile-first UI (big touch targets + floating open/close button).
--
--  Features (all applied to the local player only, no gameplay
--  advantage): Trail, Character Glow, Neon Body, Sparkles, Aura.
--
--  Usage: drop into StarterPlayer > StarterPlayerScripts as a
--  LocalScript, or run through an executor.
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
--  Theme
-- ============================================================
local THEME = {
	bg        = Color3.fromRGB(20, 20, 28),
	bgPanel   = Color3.fromRGB(28, 28, 38),
	bgInput   = Color3.fromRGB(38, 38, 52),
	stroke    = Color3.fromRGB(58, 58, 78),
	accent    = Color3.fromRGB(120, 110, 255),
	accentDim = Color3.fromRGB(70, 66, 130),
	text      = Color3.fromRGB(236, 236, 244),
	textDim   = Color3.fromRGB(150, 150, 168),
	good      = Color3.fromRGB(120, 110, 255),
	font      = Enum.Font.GothamMedium,
	fontBold  = Enum.Font.GothamBold,
	tween     = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

-- ============================================================
--  Helpers
-- ============================================================
local function new(class: string, props: {[string]: any}?, children: {Instance}?): any
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do (inst :: any)[k] = v end
	end
	if children then
		for _, c in ipairs(children) do c.Parent = inst end
	end
	return inst
end

local function corner(r: number): UICorner
	return new("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function stroke(color: Color3, thickness: number?): UIStroke
	return new("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function tween(obj: Instance, props: {[string]: any}, info: TweenInfo?)
	TweenService:Create(obj, info or THEME.tween, props):Play()
end

-- Drag a `target` GUI via a `handle` (works with touch + mouse).
local function makeDraggable(handle: GuiObject, target: GuiObject)
	local dragging = false
	local startInput: Vector3
	local startPos: UDim2
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging   = true
			startInput = input.Position
			startPos   = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local d = input.Position - startInput
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
end

-- Small tap detector that ignores drags (so tapping the FAB opens the
-- menu, but dragging it only moves it).
local function onTap(btn: GuiObject, cb: () -> ())
	local downPos: Vector3? = nil
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			downPos = input.Position
		end
	end)
	btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if downPos and (input.Position - downPos).Magnitude <= 8 then
				cb()
			end
			downPos = nil
		end
	end)
end

-- ============================================================
--  Cleanup a previous mount
-- ============================================================
do
	local prev = playerGui:FindFirstChild("VisualsMenu")
	if prev then prev:Destroy() end
end

-- ============================================================
--  Root GUI + floating open button (FAB)
-- ============================================================
local gui = new("ScreenGui", {
	Name = "VisualsMenu",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999,
	Parent = playerGui,
})

local fab = new("TextButton", {
	Name = "OpenButton",
	Parent = gui,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.5, 0),
	Size = UDim2.fromOffset(54, 54),
	BackgroundColor3 = THEME.accent,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 20,
}, {
	corner(27),
	stroke(Color3.fromRGB(255, 255, 255), 1),
})
new("TextLabel", {
	Parent = fab,
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = THEME.fontBold,
	Text = "\u{2728}",
	TextSize = 24,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	ZIndex = 21,
})

-- ============================================================
--  Main window
-- ============================================================
local WIN_W, WIN_H = 320, 440
local root = new("Frame", {
	Name = "Window",
	Parent = gui,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.fromOffset(WIN_W, WIN_H),
	BackgroundColor3 = THEME.bg,
	BorderSizePixel = 0,
	Visible = false,
	ClipsDescendants = true,
	Active = true,
	ZIndex = 10,
}, {
	corner(16),
	stroke(THEME.stroke, 1),
})

-- Keep the window inside the screen on small devices.
new("UISizeConstraint", {
	Parent = root,
	MaxSize = Vector2.new(WIN_W, WIN_H),
	MinSize = Vector2.new(260, 300),
})

-- Title bar (drag handle) --------------------------------------------------
local titleBar = new("Frame", {
	Parent = root,
	Size = UDim2.new(1, 0, 0, 48),
	BackgroundColor3 = THEME.bgPanel,
	BorderSizePixel = 0,
	Active = true,
	ZIndex = 11,
}, { corner(16) })
new("Frame", {
	Parent = titleBar,
	Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.new(0, 0, 1, -16),
	BackgroundColor3 = THEME.bgPanel,
	BorderSizePixel = 0,
	ZIndex = 11,
})

new("TextLabel", {
	Parent = titleBar,
	Position = UDim2.fromOffset(16, 0),
	Size = UDim2.new(1, -60, 1, 0),
	BackgroundTransparency = 1,
	Font = THEME.fontBold,
	Text = "Visuals",
	TextSize = 18,
	TextColor3 = THEME.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
})

local closeBtn = new("TextButton", {
	Parent = titleBar,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -12, 0.5, 0),
	Size = UDim2.fromOffset(32, 32),
	BackgroundColor3 = THEME.bgInput,
	Text = "\u{2715}",
	Font = THEME.fontBold,
	TextSize = 16,
	TextColor3 = THEME.textDim,
	AutoButtonColor = false,
	ZIndex = 12,
}, { corner(10) })

makeDraggable(titleBar, root)

-- Scrolling body -----------------------------------------------------------
local body = new("ScrollingFrame", {
	Parent = root,
	Position = UDim2.fromOffset(0, 48),
	Size = UDim2.new(1, 0, 1, -48),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = THEME.accent,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ZIndex = 11,
}, {
	new("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 16),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}),
	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
	}),
})

-- Open / close animation ---------------------------------------------------
local isOpen = false
local function setOpen(open: boolean)
	isOpen = open
	if open then
		root.Visible = true
		root.Size = UDim2.fromOffset(0, 0)
		tween(root, { Size = UDim2.fromOffset(WIN_W, WIN_H) },
			TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
		tween(fab, { BackgroundColor3 = THEME.accentDim })
	else
		tween(root, { Size = UDim2.fromOffset(0, 0) })
		tween(fab, { BackgroundColor3 = THEME.accent })
		task.delay(0.2, function()
			if not isOpen then root.Visible = false end
		end)
	end
end

onTap(fab, function() setOpen(not isOpen) end)
onTap(closeBtn, function() setOpen(false) end)
makeDraggable(fab, fab)

-- ============================================================
--  Component builders (mobile sized)
-- ============================================================
local function addCategory(titleText: string): Frame
	local holder = new("Frame", {
		Parent = body,
		Size = UDim2.new(1, 0, 0, 34),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.bgPanel,
		BorderSizePixel = 0,
		ZIndex = 11,
	}, {
		corner(12),
		new("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
		new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
	})
	new("TextLabel", {
		Parent = holder,
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = THEME.fontBold,
		Text = titleText,
		TextSize = 14,
		TextColor3 = THEME.accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 12,
	})
	return holder
end

local function addToggle(parent: Instance, label: string, default: boolean, cb: (boolean) -> ())
	local state = default
	local row = new("TextButton", {
		Parent = parent,
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = THEME.bgInput,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 12,
	}, { corner(10) })

	new("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -70, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.font,
		Text = label,
		TextSize = 14,
		TextColor3 = THEME.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
	})

	local knobTrack = new("Frame", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(46, 26),
		BackgroundColor3 = state and THEME.accent or THEME.stroke,
		BorderSizePixel = 0,
		ZIndex = 13,
	}, { corner(13) })

	local knob = new("Frame", {
		Parent = knobTrack,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = state and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 14,
	}, { corner(10) })

	local function refresh()
		tween(knobTrack, { BackgroundColor3 = state and THEME.accent or THEME.stroke })
		tween(knob, { Position = state and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
	end

	onTap(row, function()
		state = not state
		refresh()
		cb(state)
	end)

	task.spawn(cb, state)
	return { Set = function(v: boolean) state = v; refresh(); cb(state) end }
end

local function addSlider(parent: Instance, label: string, min: number, max: number, default: number, cb: (number) -> ())
	local value = math.clamp(default, min, max)
	local row = new("Frame", {
		Parent = parent,
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = THEME.bgInput,
		BorderSizePixel = 0,
		ZIndex = 12,
	}, { corner(10) })

	new("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -70, 0, 18),
		BackgroundTransparency = 1,
		Font = THEME.font,
		Text = label,
		TextSize = 14,
		TextColor3 = THEME.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
	})
	local valLbl = new("TextLabel", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 6),
		Size = UDim2.fromOffset(56, 18),
		BackgroundTransparency = 1,
		Font = THEME.fontBold,
		Text = string.format("%.2g", value),
		TextSize = 13,
		TextColor3 = THEME.accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 13,
	})

	local track = new("Frame", {
		Parent = row,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -12),
		Size = UDim2.new(1, -24, 0, 8),
		BackgroundColor3 = THEME.stroke,
		BorderSizePixel = 0,
		ZIndex = 13,
	}, { corner(4) })
	local fill = new("Frame", {
		Parent = track,
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = THEME.accent,
		BorderSizePixel = 0,
		ZIndex = 14,
	}, { corner(4) })
	local grab = new("Frame", {
		Parent = track,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 15,
	}, { corner(9) })

	local dragging = false
	local function update(px: number)
		local rel = math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		value = min + (max - min) * rel
		valLbl.Text = string.format("%.2g", value)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		grab.Position = UDim2.new(rel, 0, 0.5, 0)
		cb(value)
	end
	-- Hit area a bit taller than the track for easier touch.
	local hit = new("TextButton", {
		Parent = row,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 6, 1, -4),
		Size = UDim2.new(1, -12, 0, 24),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 15,
	})
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(input.Position.X)
		end
	end)
	hit.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			update(input.Position.X)
		end
	end)

	task.spawn(cb, value)
end

-- Preset color swatch picker (cycles a palette; last swatch = Rainbow).
local PALETTE = {
	Color3.fromRGB(120, 110, 255), Color3.fromRGB(255, 80, 120),
	Color3.fromRGB(255, 170, 60),  Color3.fromRGB(255, 235, 90),
	Color3.fromRGB(90, 230, 130),  Color3.fromRGB(70, 200, 255),
	Color3.fromRGB(255, 255, 255),
}
local function addColorPicker(parent: Instance, label: string, cb: (Color3?, boolean) -> ())
	-- cb(color, isRainbow). When rainbow, color is nil and effect should animate.
	local row = new("Frame", {
		Parent = parent,
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundColor3 = THEME.bgInput,
		BorderSizePixel = 0,
		ZIndex = 12,
	}, { corner(10) })
	new("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -24, 0, 16),
		BackgroundTransparency = 1,
		Font = THEME.font,
		Text = label,
		TextSize = 13,
		TextColor3 = THEME.textDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
	})
	local strip = new("Frame", {
		Parent = row,
		Position = UDim2.fromOffset(12, 28),
		Size = UDim2.new(1, -24, 0, 26),
		BackgroundTransparency = 1,
		ZIndex = 13,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
	})

	local selected: Frame? = nil
	local function makeSwatch(color: Color3?, rainbow: boolean)
		local sw = new("TextButton", {
			Parent = strip,
			Size = UDim2.fromOffset(26, 26),
			BackgroundColor3 = color or Color3.fromRGB(255, 255, 255),
			Text = rainbow and "\u{1F308}" or "",
			TextSize = 14,
			AutoButtonColor = false,
			ZIndex = 14,
		}, { corner(13), stroke(THEME.bg, 2) })
		onTap(sw, function()
			if selected then (selected:FindFirstChildOfClass("UIStroke") :: UIStroke).Color = THEME.bg end
			selected = sw
			(sw:FindFirstChildOfClass("UIStroke") :: UIStroke).Color = Color3.fromRGB(255, 255, 255)
			cb(color, rainbow)
		end)
		return sw
	end
	for _, c in ipairs(PALETTE) do makeSwatch(c, false) end
	makeSwatch(nil, true)
end

-- ============================================================
--  Cosmetic effects state (self only)
-- ============================================================
local FX = {
	Trail        = false,
	TrailColor   = PALETTE[1] :: Color3?,
	TrailRainbow = false,
	TrailWidth   = 1.0,
	TrailLife    = 0.6,

	Glow         = false,
	GlowColor    = PALETTE[1] :: Color3?,
	GlowRainbow  = false,

	Neon         = false,
	NeonColor    = PALETTE[6] :: Color3?,
	NeonRainbow  = false,

	Sparkles     = false,
	Aura         = false,
	AuraColor    = PALETTE[5] :: Color3?,
	AuraRainbow  = false,
}

-- Per-character instances we create so we can clean them up.
local created: { Instance } = {}
local function track(inst: Instance): Instance
	table.insert(created, inst)
	return inst
end

local function getChar(): (Model?, BasePart?)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	return char, hrp :: BasePart?
end

-- ---- Trail --------------------------------------------------------------
local trailA: Attachment? = nil
local trailB: Attachment? = nil
local trailObj: Trail? = nil
local function buildTrail()
	local _, hrp = getChar()
	if not hrp then return end
	if trailObj then trailObj:Destroy() end
	if trailA then trailA:Destroy() end
	if trailB then trailB:Destroy() end
	trailA = track(new("Attachment", { Name = "Vis_TrailA", Position = Vector3.new(0, 1.5, 0), Parent = hrp })) :: Attachment
	trailB = track(new("Attachment", { Name = "Vis_TrailB", Position = Vector3.new(0, -1.5, 0), Parent = hrp })) :: Attachment
	trailObj = track(new("Trail", {
		Name = "Vis_Trail",
		Attachment0 = trailA,
		Attachment1 = trailB,
		Lifetime = FX.TrailLife,
		WidthScale = NumberSequence.new(FX.TrailWidth),
		LightEmission = 1,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		FaceCamera = true,
		Parent = hrp,
	})) :: Trail
end
local function destroyTrail()
	if trailObj then trailObj:Destroy(); trailObj = nil end
	if trailA then trailA:Destroy(); trailA = nil end
	if trailB then trailB:Destroy(); trailB = nil end
end

-- ---- Glow (Highlight) ---------------------------------------------------
local glowObj: Highlight? = nil
local function buildGlow()
	local char = getChar()
	if not char then return end
	if glowObj then glowObj:Destroy() end
	glowObj = track(new("Highlight", {
		Name = "Vis_Glow",
		Adornee = char,
		FillTransparency = 0.6,
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		Parent = char,
	})) :: Highlight
end
local function destroyGlow()
	if glowObj then glowObj:Destroy(); glowObj = nil end
end

-- ---- Neon body ----------------------------------------------------------
local neonParts: { [BasePart]: {mat: Enum.Material, col: Color3} } = {}
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
			end
		end
	else
		for p, saved in pairs(neonParts) do
			if p and p.Parent then
				p.Material = saved.mat
				p.Color = saved.col
			end
		end
		neonParts = {}
	end
end

-- ---- Sparkles -----------------------------------------------------------
local sparkleObj: ParticleEmitter? = nil
local function buildSparkles()
	local _, hrp = getChar()
	if not hrp then return end
	if sparkleObj then sparkleObj:Destroy() end
	sparkleObj = track(new("ParticleEmitter", {
		Name = "Vis_Sparkles",
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Rate = 40,
		Lifetime = NumberRange.new(0.6, 1.0),
		Speed = NumberRange.new(1, 2),
		SpreadAngle = Vector2.new(180, 180),
		Size = NumberSequence.new(0.4),
		LightEmission = 1,
		Parent = hrp,
	})) :: ParticleEmitter
end
local function destroySparkles()
	if sparkleObj then sparkleObj:Destroy(); sparkleObj = nil end
end

-- ---- Aura (particle ring) ----------------------------------------------
local auraObj: ParticleEmitter? = nil
local function buildAura()
	local _, hrp = getChar()
	if not hrp then return end
	if auraObj then auraObj:Destroy() end
	auraObj = track(new("ParticleEmitter", {
		Name = "Vis_Aura",
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Rate = 60,
		Lifetime = NumberRange.new(0.8, 1.2),
		Speed = NumberRange.new(0, 1),
		SpreadAngle = Vector2.new(360, 360),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.5),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		}),
		LightEmission = 0.8,
		Parent = hrp,
	})) :: ParticleEmitter
end
local function destroyAura()
	if auraObj then auraObj:Destroy(); auraObj = nil end
end

-- Re-apply everything currently enabled (e.g. after respawn).
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
--  Build the menu UI
-- ============================================================
local trailCat = addCategory("Trail")
addToggle(trailCat, "Enabled", false, function(v)
	FX.Trail = v
	if v then buildTrail() else destroyTrail() end
end)
addColorPicker(trailCat, "Color", function(color, rainbow)
	FX.TrailRainbow = rainbow
	FX.TrailColor = color
	if trailObj and not rainbow and color then
		trailObj.Color = ColorSequence.new(color)
	end
end)
addSlider(trailCat, "Width", 0.2, 4, 1, function(v)
	FX.TrailWidth = v
	if trailObj then trailObj.WidthScale = NumberSequence.new(v) end
end)
addSlider(trailCat, "Lifetime", 0.2, 2, 0.6, function(v)
	FX.TrailLife = v
	if trailObj then trailObj.Lifetime = v end
end)

local glowCat = addCategory("Character Glow")
addToggle(glowCat, "Enabled", false, function(v)
	FX.Glow = v
	if v then buildGlow() else destroyGlow() end
end)
addColorPicker(glowCat, "Color", function(color, rainbow)
	FX.GlowRainbow = rainbow
	FX.GlowColor = color
	if glowObj and not rainbow and color then
		glowObj.FillColor = color
		glowObj.OutlineColor = color
	end
end)

local neonCat = addCategory("Neon Body")
addToggle(neonCat, "Enabled", false, function(v)
	FX.Neon = v
	applyNeon(v)
end)
addColorPicker(neonCat, "Color", function(color, rainbow)
	FX.NeonRainbow = rainbow
	FX.NeonColor = color
	if FX.Neon and not rainbow and color then
		for p in pairs(neonParts) do
			if p and p.Parent then p.Color = color end
		end
	end
end)

local particlesCat = addCategory("Particles")
addToggle(particlesCat, "Sparkles", false, function(v)
	FX.Sparkles = v
	if v then buildSparkles() else destroySparkles() end
end)
addToggle(particlesCat, "Aura", false, function(v)
	FX.Aura = v
	if v then buildAura() else destroyAura() end
end)
addColorPicker(particlesCat, "Aura Color", function(color, rainbow)
	FX.AuraRainbow = rainbow
	FX.AuraColor = color
	if auraObj and not rainbow and color then
		auraObj.Color = ColorSequence.new(color)
	end
end)

local infoCat = addCategory("Info")
new("TextLabel", {
	Parent = infoCat,
	Size = UDim2.new(1, 0, 0, 36),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Font = THEME.font,
	Text = "Cosmetic effects only — applied to your own character. Tap the sparkle button to open/close. Drag the title bar to move.",
	TextSize = 12,
	TextColor3 = THEME.textDim,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
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

-- ============================================================
--  Cleanup on GUI destroy
-- ============================================================
gui.Destroying:Connect(function()
	destroyTrail(); destroyGlow(); destroySparkles(); destroyAura()
	applyNeon(false)
	for _, inst in ipairs(created) do
		if inst and inst.Parent then pcall(function() inst:Destroy() end) end
	end
end)
