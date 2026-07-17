--[[
	union blink — тп к Union раз в 3 сек
	RightShift — скрыть/показать меню
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local C = {
	bg = Color3.fromRGB(12, 14, 18),
	panel = Color3.fromRGB(20, 23, 30),
	elev = Color3.fromRGB(30, 34, 44),
	line = Color3.fromRGB(48, 54, 68),
	accent = Color3.fromRGB(90, 220, 180),
	accentDim = Color3.fromRGB(40, 120, 100),
	ink = Color3.fromRGB(10, 24, 20),
	off = Color3.fromRGB(70, 74, 86),
	text = Color3.fromRGB(236, 240, 244),
	mute = Color3.fromRGB(120, 128, 140),
	danger = Color3.fromRGB(235, 100, 110),
	ok = Color3.fromRGB(110, 210, 160),
}

local INTERVAL = 3
local enabled = false
local visible = true
local lastTp = 0
local foundUnion = nil

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

local function findUnion()
	if foundUnion and foundUnion.Parent then
		return foundUnion
	end
	foundUnion = nil
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and (obj.Name == "Union" or obj:IsA("UnionOperation")) then
			foundUnion = obj
			return obj
		end
	end
	return nil
end

local function getRoot()
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart
end

local function doTeleport()
	local part = findUnion()
	local root = getRoot()
	if not part or not root then return false, part == nil and "нет Union" or "нет персонажа" end
	local ok = pcall(function()
		root.CFrame = part.CFrame + Vector3.new(0, part.Size.Y * 0.5 + 3, 0)
	end)
	return ok, ok and "тп" or "ошибка"
end

-- ui
do
	local old = playerGui:FindFirstChild("UnionBlink")
	if old then old:Destroy() end
end

local gui = new("ScreenGui", {
	Name = "UnionBlink",
	Parent = playerGui,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 120,
})

local root = new("Frame", {
	Name = "Root",
	Parent = gui,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 18, 0.5, 0),
	Size = UDim2.fromOffset(220, 148),
	BackgroundColor3 = C.bg,
	BorderSizePixel = 0,
	Active = true,
	ClipsDescendants = true,
})
corner(18, root)
stroke(C.accent, 1.5, root, 0.75)

local sheen = new("Frame", {
	Parent = root,
	Size = UDim2.new(1, 0, 0, 70),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 1,
})
new("UIGradient", {
	Parent = sheen,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.93),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Rotation = 90,
})

local mark = new("Frame", {
	Parent = root,
	Position = UDim2.fromOffset(16, 16),
	Size = UDim2.fromOffset(8, 22),
	BackgroundColor3 = C.accent,
	BorderSizePixel = 0,
	ZIndex = 2,
})
corner(3, mark)

local title = new("TextLabel", {
	Parent = root,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(32, 12),
	Size = UDim2.fromOffset(140, 26),
	Font = Enum.Font.GothamBlack,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = C.text,
	Text = "blink",
	ZIndex = 2,
})

local sub = new("TextLabel", {
	Parent = root,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(32, 34),
	Size = UDim2.fromOffset(160, 16),
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = C.mute,
	Text = "тп к Union · 3 сек",
	ZIndex = 2,
})

local closeBtn = new("TextButton", {
	Parent = root,
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
	Parent = root,
	Position = UDim2.fromOffset(16, 62),
	Size = UDim2.new(1, -32, 0, 44),
	BackgroundColor3 = C.off,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 2,
})
corner(12, toggle)
local toggleStroke = stroke(C.line, 1, toggle, 0.2)

local toggleKnob = new("Frame", {
	Parent = toggle,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 6, 0.5, 0),
	Size = UDim2.fromOffset(32, 32),
	BackgroundColor3 = C.text,
	BorderSizePixel = 0,
	ZIndex = 3,
})
corner(10, toggleKnob)

local toggleLabel = new("TextLabel", {
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
	Parent = root,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 116),
	Size = UDim2.new(1, -32, 0, 18),
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
		toggle.BackgroundColor3 = C.accent
		toggleLabel.Text = "Вкл"
		toggleLabel.TextColor3 = C.ink
		toggleStroke.Color = C.accentDim
		tween(toggleKnob, 0.22, { Position = UDim2.new(1, -38, 0.5, 0), BackgroundColor3 = C.ink })
		status.Text = "поиск Union…"
		status.TextColor3 = C.accent
	else
		toggle.BackgroundColor3 = C.off
		toggleLabel.Text = "Выкл"
		toggleLabel.TextColor3 = C.text
		toggleStroke.Color = C.line
		tween(toggleKnob, 0.22, { Position = UDim2.new(0, 6, 0.5, 0), BackgroundColor3 = C.text })
		status.Text = "пауза"
		status.TextColor3 = C.mute
	end
end

toggle.MouseButton1Click:Connect(function()
	setEnabled(not enabled)
end)

local function setVisible(v)
	visible = v
	root.Visible = v
end

closeBtn.MouseButton1Click:Connect(function()
	setVisible(false)
end)

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.RightShift then
		setVisible(not visible)
	end
end)

-- drag
do
	root.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local objs = playerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
		for _, o in ipairs(objs) do
			if o:IsA("TextButton") then return end
		end
		local start = input.Position
		local origin = root.Position
		local move, ended
		move = UserInputService.InputChanged:Connect(function(ch)
			if ch.UserInputType ~= Enum.UserInputType.MouseMovement
				and ch.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local d = ch.Position - start
			root.Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, origin.Y.Scale, origin.Y.Offset + d.Y)
		end)
		ended = UserInputService.InputEnded:Connect(function(e)
			if e.UserInputType == Enum.UserInputType.MouseButton1
				or e.UserInputType == Enum.UserInputType.Touch then
				move:Disconnect()
				ended:Disconnect()
			end
		end)
	end)
end

-- loop
RunService.Heartbeat:Connect(function()
	if not enabled then return end
	local now = os.clock()
	local left = INTERVAL - (now - lastTp)
	if left > 0 then
		status.Text = string.format("след. тп через %.1fs", left)
		status.TextColor3 = C.mute
		return
	end
	lastTp = now
	local ok, msg = doTeleport()
	if ok then
		status.Text = "тп · ok"
		status.TextColor3 = C.ok
		tween(mark, 0.12, { BackgroundTransparency = 0.4 })
		task.delay(0.15, function()
			tween(mark, 0.2, { BackgroundTransparency = 0 })
		end)
	else
		status.Text = tostring(msg)
		status.TextColor3 = C.danger
	end
end)

-- появление
root.BackgroundTransparency = 0.5
root.Position = UDim2.new(0, -40, 0.5, 0)
tween(root, 0.4, { BackgroundTransparency = 0, Position = UDim2.new(0, 18, 0.5, 0) })

print("[blink] union tp · RightShift — меню")
return gui
