--[[
	hardobby pad — тп только на HardObby.TouchPart
	каждые 0.1 сек · без анимки · RightShift — меню
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local C = {
	bg = Color3.fromRGB(14, 12, 18),
	elev = Color3.fromRGB(32, 28, 42),
	line = Color3.fromRGB(58, 48, 72),
	accent = Color3.fromRGB(255, 140, 90),
	accentDim = Color3.fromRGB(180, 80, 50),
	ink = Color3.fromRGB(28, 14, 10),
	off = Color3.fromRGB(72, 68, 82),
	text = Color3.fromRGB(245, 238, 232),
	mute = Color3.fromRGB(140, 128, 138),
	danger = Color3.fromRGB(235, 100, 110),
	ok = Color3.fromRGB(120, 210, 150),
}

local INTERVAL = 0.1
local enabled = false
local visible = true
local lastTp = 0
local cachedPart = nil

local function new(class, props)
	local i = Instance.new(class)
	for k, v in pairs(props or {}) do
		i[k] = v
	end
	return i
end

local function corner(r, p)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = p
	return c
end

local function stroke(col, th, p, tr)
	local s = Instance.new("UIStroke")
	s.Color = col
	s.Thickness = th or 1
	s.Transparency = tr or 0
	s.Parent = p
	return s
end

local function tween(obj, t, props)
	local tw = TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- строго HardObby → TouchPart
local function findTouchPart()
	if cachedPart and cachedPart.Parent then
		return cachedPart
	end
	cachedPart = nil

	local hard = workspace:FindFirstChild("HardObby")
	if not hard then
		hard = workspace:FindFirstChild("HardObby", true)
	end
	if not hard then
		return nil
	end

	local part = hard:FindFirstChild("TouchPart")
	if part and part:IsA("BasePart") then
		cachedPart = part
		return part
	end

	part = hard:FindFirstChild("TouchPart", true)
	if part and part:IsA("BasePart") then
		cachedPart = part
		return part
	end

	return nil
end

local function getRoot()
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("Torso")
		or char.PrimaryPart
end

local function teleportHere()
	local part = findTouchPart()
	local char = player.Character
	local root = getRoot()
	if not part then return false, "нет HardObby.TouchPart" end
	if not char or not root then return false, "нет персонажа" end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local animate = char:FindFirstChild("Animate")
	local cf = part.CFrame * CFrame.new(0, (part.Size.Y * 0.5) + 3, 0)

	local ok = pcall(function()
		if animate then animate.Disabled = true end
		if hum then
			pcall(function()
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
				hum:ChangeState(Enum.HumanoidStateType.Running)
			end)
		end

		if char.PrimaryPart then
			char:PivotTo(cf)
		else
			root.CFrame = cf
		end

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		pcall(function()
			root.Velocity = Vector3.zero
			root.RotVelocity = Vector3.zero
		end)

		task.defer(function()
			if not root or not root.Parent then return end
			if char.PrimaryPart then
				char:PivotTo(cf)
			else
				root.CFrame = cf
			end
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			if animate then
				task.delay(0.04, function()
					if animate.Parent then animate.Disabled = false end
				end)
			end
			if hum then
				pcall(function()
					hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
					hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
					hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
				end)
			end
		end)
	end)

	return ok, ok and "тп · TouchPart" or "ошибка"
end

do
	local old = playerGui:FindFirstChild("HardObbyPad")
	if old then old:Destroy() end
end

local gui = new("ScreenGui", {
	Name = "HardObbyPad",
	Parent = playerGui,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 130,
})

local frame = new("Frame", {
	Parent = gui,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 18, 0.55, 0),
	Size = UDim2.fromOffset(228, 150),
	BackgroundColor3 = C.bg,
	BorderSizePixel = 0,
	Active = true,
	ClipsDescendants = true,
})
corner(18, frame)
stroke(C.accent, 1.5, frame, 0.7)

new("Frame", {
	Parent = frame,
	Size = UDim2.new(1, 0, 0, 64),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 1,
})
-- sheen
do
	local s = frame:FindFirstChildOfClass("Frame")
	new("UIGradient", {
		Parent = s,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.92),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = 90,
	})
end

local mark = new("Frame", {
	Parent = frame,
	Position = UDim2.fromOffset(16, 16),
	Size = UDim2.fromOffset(8, 22),
	BackgroundColor3 = C.accent,
	BorderSizePixel = 0,
	ZIndex = 2,
})
corner(3, mark)

new("TextLabel", {
	Parent = frame,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(32, 12),
	Size = UDim2.fromOffset(150, 26),
	Font = Enum.Font.GothamBlack,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = C.text,
	Text = "pad",
	ZIndex = 2,
})

new("TextLabel", {
	Parent = frame,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(32, 34),
	Size = UDim2.fromOffset(170, 16),
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = C.mute,
	Text = "HardObby.TouchPart · 0.1s",
	ZIndex = 2,
})

local closeBtn = new("TextButton", {
	Parent = frame,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 12),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = C.elev,
	Text = "✕",
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = C.mute,
	AutoButtonColor = false,
	ZIndex = 3,
})
corner(8, closeBtn)

local toggle = new("TextButton", {
	Parent = frame,
	Position = UDim2.fromOffset(16, 64),
	Size = UDim2.new(1, -32, 0, 44),
	BackgroundColor3 = C.off,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 2,
})
corner(12, toggle)
local toggleStroke = stroke(C.line, 1, toggle, 0.2)

local knob = new("Frame", {
	Parent = toggle,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 6, 0.5, 0),
	Size = UDim2.fromOffset(32, 32),
	BackgroundColor3 = C.text,
	BorderSizePixel = 0,
	ZIndex = 3,
})
corner(10, knob)

local toggleLbl = new("TextLabel", {
	Parent = toggle,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(48, 0),
	Size = UDim2.new(1, -56, 1, 0),
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = C.text,
	Text = "Выкл",
	ZIndex = 3,
})

local status = new("TextLabel", {
	Parent = frame,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 118),
	Size = UDim2.new(1, -32, 0, 20),
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = C.mute,
	Text = "ожидание…",
	ZIndex = 2,
})

local function setEnabled(on)
	enabled = on
	if on then
		lastTp = 0
		cachedPart = nil
		toggle.BackgroundColor3 = C.accent
		toggleLbl.Text = "Вкл"
		toggleLbl.TextColor3 = C.ink
		toggleStroke.Color = C.accentDim
		tween(knob, 0.2, { Position = UDim2.new(1, -38, 0.5, 0), BackgroundColor3 = C.ink })
		local p = findTouchPart()
		if p then
			status.Text = "цель: TouchPart"
			status.TextColor3 = C.accent
		else
			status.Text = "нет HardObby.TouchPart"
			status.TextColor3 = C.danger
		end
	else
		toggle.BackgroundColor3 = C.off
		toggleLbl.Text = "Выкл"
		toggleLbl.TextColor3 = C.text
		toggleStroke.Color = C.line
		tween(knob, 0.2, { Position = UDim2.new(0, 6, 0.5, 0), BackgroundColor3 = C.text })
		status.Text = "пауза"
		status.TextColor3 = C.mute
	end
end

toggle.MouseButton1Click:Connect(function()
	setEnabled(not enabled)
end)

closeBtn.MouseButton1Click:Connect(function()
	visible = false
	frame.Visible = false
end)

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.RightShift then
		visible = not visible
		frame.Visible = visible
	end
end)

-- drag
frame.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local objs = playerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
	for _, o in ipairs(objs) do
		if o:IsA("TextButton") then return end
	end
	local start = input.Position
	local origin = frame.Position
	local move, ended
	move = UserInputService.InputChanged:Connect(function(ch)
		if ch.UserInputType ~= Enum.UserInputType.MouseMovement
			and ch.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local d = ch.Position - start
		frame.Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, origin.Y.Scale, origin.Y.Offset + d.Y)
	end)
	ended = UserInputService.InputEnded:Connect(function(e)
		if e.UserInputType == Enum.UserInputType.MouseButton1
			or e.UserInputType == Enum.UserInputType.Touch then
			move:Disconnect()
			ended:Disconnect()
		end
	end)
end)

RunService.Heartbeat:Connect(function()
	if not enabled then return end
	local now = os.clock()
	if now - lastTp < INTERVAL then
		status.Text = string.format("pad · %.2fs", INTERVAL - (now - lastTp))
		status.TextColor3 = C.mute
		return
	end
	lastTp = now
	local ok, msg = teleportHere()
	status.Text = tostring(msg)
	status.TextColor3 = ok and C.ok or C.danger
	if ok then
		tween(mark, 0.08, { BackgroundTransparency = 0.45 })
		task.delay(0.1, function()
			tween(mark, 0.15, { BackgroundTransparency = 0 })
		end)
	end
end)

frame.BackgroundTransparency = 0.45
frame.Position = UDim2.new(0, -36, 0.55, 0)
tween(frame, 0.35, { BackgroundTransparency = 0, Position = UDim2.new(0, 18, 0.55, 0) })

print("[pad] HardObby.TouchPart · RightShift")
return gui
