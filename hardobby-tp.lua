--[[
	pad — тп на HardObby.TouchPart каждые 0.1с
	ищет жёстко + firetouchinterest · RightShift — меню
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
local lastErr = ""

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

local function findTouchPart(force)
	if not force and cachedPart and cachedPart.Parent and cachedPart:IsA("BasePart") then
		return cachedPart
	end
	cachedPart = nil

	-- 1) workspace.HardObby.TouchPart
	local hard = workspace:FindFirstChild("HardObby")
	if hard then
		local tp = hard:FindFirstChild("TouchPart")
		if tp and tp:IsA("BasePart") then
			cachedPart = tp
			return tp
		end
	end

	-- 2) любой HardObby глубже
	hard = workspace:FindFirstChild("HardObby", true)
	if hard then
		local tp = hard:FindFirstChild("TouchPart") or hard:FindFirstChild("TouchPart", true)
		if tp and tp:IsA("BasePart") then
			cachedPart = tp
			return tp
		end
	end

	-- 3) полный обход: имя HardObby → внутри TouchPart
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "HardObby" then
			local tp = obj:FindFirstChild("TouchPart")
			if not tp then
				tp = obj:FindFirstChild("TouchPart", true)
			end
			if tp and tp:IsA("BasePart") then
				cachedPart = tp
				return tp
			end
		end
	end

	-- 4) запасной: любой TouchPart у которого рядом PadRegistry
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == "TouchPart" then
			if obj:FindFirstChild("PadRegistry") or obj:FindFirstChild("TouchInterest") then
				local parent = obj.Parent
				if parent and parent.Name == "HardObby" then
					cachedPart = obj
					return obj
				end
			end
		end
	end

	return nil
end

local function getChar()
	return player.Character or player.CharacterAdded:Wait()
end

local function getRoot(char)
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("Torso")
		or char:FindFirstChild("UpperTorso")
		or char.PrimaryPart
end

local function fireTouch(root, part)
	-- регистрируем касание пада (важно для чекпоинтов)
	pcall(function()
		if firetouchinterest then
			firetouchinterest(root, part, 0)
			task.wait()
			firetouchinterest(root, part, 1)
		end
	end)
	pcall(function()
		if firetouchinterest then
			firetouchinterest(part, root, 0)
			task.wait()
			firetouchinterest(part, root, 1)
		end
	end)
end

local function applyCFrame(char, root, cf)
	-- несколько способов — что-то да пролезет
	pcall(function()
		char:PivotTo(cf)
	end)
	pcall(function()
		root.CFrame = cf
	end)
	pcall(function()
		if char.PrimaryPart then
			char:SetPrimaryPartCFrame(cf)
		end
	end)
	pcall(function()
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)
	pcall(function()
		root.Velocity = Vector3.zero
		root.RotVelocity = Vector3.zero
	end)
end

local function teleportHere()
	local part = findTouchPart(false)
	if not part then
		part = findTouchPart(true)
	end
	if not part then
		lastErr = "нет HardObby.TouchPart"
		return false, lastErr
	end

	local char = player.Character
	if not char then
		lastErr = "нет персонажа"
		return false, lastErr
	end
	local root = getRoot(char)
	if not root then
		lastErr = "нет RootPart"
		return false, lastErr
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local animate = char:FindFirstChild("Animate")

	-- встаём прямо на пад (чуть выше центра)
	local offset = math.max(part.Size.Y * 0.5 + 2.5, 3)
	local cf = part.CFrame * CFrame.new(0, offset, 0)

	local ok, err = pcall(function()
		if animate then animate.Disabled = true end
		if hum then
			pcall(function()
				hum.Sit = false
				hum.PlatformStand = false
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
				hum:ChangeState(Enum.HumanoidStateType.Running)
			end)
		end

		-- тп 3 раза подряд против античита / интерполяции
		for _ = 1, 3 do
			applyCFrame(char, root, cf)
		end

		fireTouch(root, part)

		-- ещё раз после touch
		applyCFrame(char, root, cf)

		task.defer(function()
			if root and root.Parent and part and part.Parent then
				applyCFrame(char, root, cf)
				fireTouch(root, part)
			end
			if animate and animate.Parent then
				task.delay(0.05, function()
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

	if not ok then
		lastErr = tostring(err)
		return false, "ошибка тп"
	end
	return true, "тп · " .. part:GetFullName():gsub("^Workspace%.", "")
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
	Size = UDim2.fromOffset(250, 158),
	BackgroundColor3 = C.bg,
	BorderSizePixel = 0,
	Active = true,
	ClipsDescendants = true,
})
corner(18, frame)
stroke(C.accent, 1.5, frame, 0.7)

local sheen = new("Frame", {
	Parent = frame,
	Size = UDim2.new(1, 0, 0, 64),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 1,
})
new("UIGradient", {
	Parent = sheen,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.92),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Rotation = 90,
})

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
	Size = UDim2.fromOffset(170, 26),
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
	Size = UDim2.fromOffset(190, 16),
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
	Size = UDim2.new(1, -32, 0, 28),
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
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
		local p = findTouchPart(true)
		if p then
			status.Text = "нашёл: " .. p:GetFullName():gsub("^Workspace%.", "")
			status.TextColor3 = C.accent
		else
			status.Text = "нет HardObby.TouchPart в Workspace"
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

-- тп каждый кадр пока вкл (надёжнее чем только 0.1 таймер против античита)
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	if not enabled then return end
	acc += dt
	if acc < INTERVAL then return end
	acc = 0

	local ok, msg = teleportHere()
	status.Text = tostring(msg)
	status.TextColor3 = ok and C.ok or C.danger
	if ok then
		tween(mark, 0.06, { BackgroundTransparency = 0.45 })
		task.delay(0.08, function()
			tween(mark, 0.12, { BackgroundTransparency = 0 })
		end)
	end
end)

frame.BackgroundTransparency = 0.45
frame.Position = UDim2.new(0, -36, 0.55, 0)
tween(frame, 0.35, { BackgroundTransparency = 0, Position = UDim2.new(0, 18, 0.55, 0) })

task.defer(function()
	local p = findTouchPart(true)
	if p then
		print("[pad] цель:", p:GetFullName())
	else
		print("[pad] HardObby.TouchPart не найден в Workspace")
	end
end)

print("[pad] HardObby.TouchPart · RightShift")
return gui
