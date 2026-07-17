--[[
	blink — тп к HardObby.TouchPart раз в 1 сек
	режимы: обыч (все TouchPart в HardObby) / последний
	анимка скипается · RightShift — меню
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local C = {
	bg = Color3.fromRGB(12, 14, 18),
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

local INTERVAL = 1
local FOLDER_NAME = "HardObby"
local PART_NAME = "TouchPart"

local enabled = false
local visible = true
local mode = "normal" -- normal | last
local lastTp = 0
local targetList = {}
local targetIndex = 0

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

local function getHardObby()
	return workspace:FindFirstChild(FOLDER_NAME)
		or workspace:FindFirstChild(FOLDER_NAME, true)
end

local function collectTargets()
	local list = {}
	local folder = getHardObby()
	if not folder then
		targetList = list
		targetIndex = 0
		return list
	end

	-- прямой дочерний TouchPart — приоритет
	local direct = folder:FindFirstChild(PART_NAME)
	if direct and direct:IsA("BasePart") then
		list[#list + 1] = direct
	end

	for _, obj in ipairs(folder:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == PART_NAME and obj ~= direct then
			list[#list + 1] = obj
		end
	end

	targetList = list
	if targetIndex > #targetList then
		targetIndex = 0
	end
	return list
end

local function pruneTargets()
	local alive = {}
	for _, p in ipairs(targetList) do
		if p and p.Parent then
			alive[#alive + 1] = p
		end
	end
	targetList = alive
	if #targetList == 0 then
		collectTargets()
	end
	return #targetList
end

local function pickTarget()
	if pruneTargets() == 0 then
		return nil, 0, 0
	end

	if mode == "last" then
		targetIndex = #targetList
		return targetList[targetIndex], targetIndex, #targetList
	end

	targetIndex += 1
	if targetIndex > #targetList then
		targetIndex = 1
		collectTargets()
		if #targetList == 0 then return nil, 0, 0 end
		if targetIndex > #targetList then targetIndex = 1 end
	end
	return targetList[targetIndex], targetIndex, #targetList
end

local function getChar()
	return player.Character
end

local function getRoot(char)
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart
end

local function teleportNoAnim(part)
	local char = getChar()
	local root = getRoot(char)
	if not char or not root or not part then
		return false, "нет персонажа"
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local animate = char:FindFirstChild("Animate")
	local cf = part.CFrame * CFrame.new(0, part.Size.Y * 0.5 + 3, 0)

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
			if root and root.Parent then
				if char.PrimaryPart then
					char:PivotTo(cf)
				else
					root.CFrame = cf
				end
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
			if animate then
				task.delay(0.05, function()
					if animate and animate.Parent then
						animate.Disabled = false
					end
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

	return ok, ok and "ok" or "ошибка"
end

local function doTeleport()
	local part, idx, total = pickTarget()
	if not part then
		return false, "нет HardObby.TouchPart", 0, 0
	end
	local ok, msg = teleportNoAnim(part)
	return ok, msg, idx, total
end

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
	Size = UDim2.fromOffset(232, 196),
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

new("TextLabel", {
	Parent = root,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(32, 12),
	Size = UDim2.fromOffset(150, 26),
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
	Size = UDim2.fromOffset(170, 16),
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = C.mute,
	Text = "HardObby.TouchPart · 1 сек",
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

local modeRow = new("Frame", {
	Parent = root,
	Position = UDim2.fromOffset(16, 58),
	Size = UDim2.new(1, -32, 0, 32),
	BackgroundTransparency = 1,
	ZIndex = 2,
})

local modeNormal = new("TextButton", {
	Parent = modeRow,
	Size = UDim2.new(0.5, -4, 1, 0),
	BackgroundColor3 = C.accent,
	Text = "Обыч",
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = C.ink,
	AutoButtonColor = false,
	ZIndex = 3,
})
corner(9, modeNormal)

local modeLast = new("TextButton", {
	Parent = modeRow,
	Position = UDim2.new(0.5, 4, 0, 0),
	Size = UDim2.new(0.5, -4, 1, 0),
	BackgroundColor3 = C.elev,
	Text = "Последний",
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = C.mute,
	AutoButtonColor = false,
	ZIndex = 3,
})
corner(9, modeLast)

local function refreshModeUI()
	if mode == "normal" then
		modeNormal.BackgroundColor3 = C.accent
		modeNormal.TextColor3 = C.ink
		modeLast.BackgroundColor3 = C.elev
		modeLast.TextColor3 = C.mute
		sub.Text = "TouchPart по кругу · 1 сек"
	else
		modeLast.BackgroundColor3 = C.accent
		modeLast.TextColor3 = C.ink
		modeNormal.BackgroundColor3 = C.elev
		modeNormal.TextColor3 = C.mute
		sub.Text = "последний TouchPart · 1 сек"
	end
end

modeNormal.MouseButton1Click:Connect(function()
	mode = "normal"
	targetIndex = 0
	refreshModeUI()
end)

modeLast.MouseButton1Click:Connect(function()
	mode = "last"
	refreshModeUI()
end)

local toggle = new("TextButton", {
	Parent = root,
	Position = UDim2.fromOffset(16, 100),
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
	Position = UDim2.fromOffset(16, 156),
	Size = UDim2.new(1, -32, 0, 24),
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
		targetIndex = 0
		collectTargets()
		toggle.BackgroundColor3 = C.accent
		toggleLabel.Text = "Вкл"
		toggleLabel.TextColor3 = C.ink
		toggleStroke.Color = C.accentDim
		tween(toggleKnob, 0.22, { Position = UDim2.new(1, -38, 0.5, 0), BackgroundColor3 = C.ink })
		if #targetList == 0 then
			status.Text = "нет HardObby.TouchPart"
			status.TextColor3 = C.danger
		else
			status.Text = string.format("TouchPart: %d", #targetList)
			status.TextColor3 = C.accent
		end
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

RunService.Heartbeat:Connect(function()
	if not enabled then return end
	local now = os.clock()
	local left = INTERVAL - (now - lastTp)
	if left > 0 then
		if mode == "last" then
			status.Text = string.format("последний · через %.1fs", left)
		else
			status.Text = string.format("%d/%d · через %.1fs", targetIndex, math.max(#targetList, 1), left)
		end
		status.TextColor3 = C.mute
		return
	end
	lastTp = now
	local ok, msg, idx, total = doTeleport()
	if ok then
		if mode == "last" then
			status.Text = string.format("тп последний %d/%d", idx, total)
		else
			status.Text = string.format("тп %d/%d · TouchPart", idx, total)
		end
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

refreshModeUI()
root.BackgroundTransparency = 0.5
root.Position = UDim2.new(0, -40, 0.5, 0)
tween(root, 0.4, { BackgroundTransparency = 0, Position = UDim2.new(0, 18, 0.5, 0) })

collectTargets()
print("[blink] HardObby.TouchPart · RightShift — меню")
return gui
