--[[
	pad — HardObby.TouchPart
	вставь ЦЕЛИКОМ в execute (без HttpGet)
	RightShift — меню
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

local enabled = false
local visible = true
local cached = nil
local noclipConn = nil

local function new(class, props)
	local i = Instance.new(class)
	for k, v in pairs(props or {}) do i[k] = v end
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
	TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

local function findPad(force)
	if not force and cached and cached.Parent and cached:IsA("BasePart") then
		return cached
	end
	cached = nil

	local function take(part)
		if part and part:IsA("BasePart") then
			cached = part
			return part
		end
	end

	-- прямые пути
	local hard = workspace:FindFirstChild("HardObby")
	if hard then
		local p = take(hard:FindFirstChild("TouchPart"))
		if p then return p end
	end

	hard = workspace:FindFirstChild("HardObby", true)
	if hard then
		local p = take(hard:FindFirstChild("TouchPart")) or take(hard:FindFirstChild("TouchPart", true))
		if p then return p end
	end

	-- полный скан
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "HardObby" then
			local p = obj:FindFirstChild("TouchPart") or obj:FindFirstChild("TouchPart", true)
			if take(p) then return cached end
		end
	end

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == "TouchPart" then
			if obj.Parent and obj.Parent.Name == "HardObby" then
				return take(obj)
			end
		end
	end

	return nil
end

local function getRoot()
	local char = player.Character
	if not char then return nil, nil end
	local root = char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("Torso")
		or char:FindFirstChild("UpperTorso")
		or char.PrimaryPart
	return char, root
end

local function setNoclip(on)
	if noclipConn then
		noclipConn:Disconnect()
		noclipConn = nil
	end
	if not on then return end
	noclipConn = RunService.Stepped:Connect(function()
		local char = player.Character
		if not char then return end
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CanCollide = false
			end
		end
	end)
end

local function fireTouch(root, part)
	pcall(function()
		if firetouchinterest then
			firetouchinterest(root, part, 0)
			firetouchinterest(root, part, 1)
		end
	end)
	pcall(function()
		if firetouchinterest then
			firetouchinterest(part, root, 0)
			firetouchinterest(part, root, 1)
		end
	end)
	-- запасной touch через .Touched
	pcall(function()
		for _, side in ipairs({ root, part }) do
			local ti = side:FindFirstChildOfClass("TouchTransmitter") or side:FindFirstChild("TouchInterest")
			if ti then
				-- noop, просто есть
			end
		end
	end)
end

local function doTp()
	local part = findPad(false) or findPad(true)
	local char, root = getRoot()
	if not part then return false, "не нашёл HardObby.TouchPart" end
	if not char or not root then return false, "нет персонажа (зайди в игру)" end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local anim = char:FindFirstChild("Animate")
	local cf = part.CFrame + Vector3.new(0, 3, 0)

	pcall(function()
		if anim then anim.Disabled = true end
		if hum then
			hum.Sit = false
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end
	end)

	-- жёсткий тп
	for _ = 1, 5 do
		pcall(function() char:PivotTo(CFrame.new(cf.Position)) end)
		pcall(function() root.CFrame = CFrame.new(cf.Position) end)
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
	end

	fireTouch(root, part)

	pcall(function()
		root.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
	end)

	task.defer(function()
		if anim and anim.Parent then
			task.delay(0.08, function()
				pcall(function() anim.Disabled = false end)
			end)
		end
	end)

	return true, "ok · " .. tostring(part:GetFullName())
end

-- UI
do
	local old = playerGui:FindFirstChild("HardObbyPad")
	if old then old:Destroy() end
end

local gui = new("ScreenGui", {
	Name = "HardObbyPad",
	Parent = playerGui,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 200,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local frame = new("Frame", {
	Parent = gui,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 0),
	Size = UDim2.fromOffset(260, 210),
	BackgroundColor3 = C.bg,
	BorderSizePixel = 0,
	Active = true,
})
corner(18, frame)
stroke(C.accent, 1.6, frame, 0.65)

new("TextLabel", {
	Parent = frame,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 12),
	Size = UDim2.fromOffset(180, 26),
	Font = Enum.Font.GothamBlack,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = C.text,
	Text = "pad",
})

new("TextLabel", {
	Parent = frame,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 36),
	Size = UDim2.fromOffset(220, 16),
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = C.mute,
	Text = "HardObby.TouchPart",
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
})
corner(8, closeBtn)

local toggle = new("TextButton", {
	Parent = frame,
	Position = UDim2.fromOffset(16, 64),
	Size = UDim2.new(1, -32, 0, 42),
	BackgroundColor3 = C.off,
	Text = "Выкл · авто тп",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = C.text,
	AutoButtonColor = false,
})
corner(12, toggle)

local onceBtn = new("TextButton", {
	Parent = frame,
	Position = UDim2.fromOffset(16, 114),
	Size = UDim2.new(0.5, -20, 0, 36),
	BackgroundColor3 = C.elev,
	Text = "ТП сейчас",
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = C.text,
	AutoButtonColor = false,
})
corner(10, onceBtn)

local scanBtn = new("TextButton", {
	Parent = frame,
	Position = UDim2.new(0.5, 4, 0, 114),
	Size = UDim2.new(0.5, -20, 0, 36),
	BackgroundColor3 = C.elev,
	Text = "Найти пад",
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = C.text,
	AutoButtonColor = false,
})
corner(10, scanBtn)

local status = new("TextLabel", {
	Parent = frame,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 160),
	Size = UDim2.new(1, -32, 0, 36),
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	TextColor3 = C.mute,
	Text = "жми «Найти пад» или Вкл",
})

local function setStatus(msg, col)
	status.Text = tostring(msg)
	status.TextColor3 = col or C.mute
	print("[pad]", msg)
end

local function setEnabled(on)
	enabled = on
	setNoclip(on)
	if on then
		cached = nil
		toggle.BackgroundColor3 = C.accent
		toggle.TextColor3 = C.ink
		toggle.Text = "Вкл · авто тп"
		local p = findPad(true)
		if p then
			setStatus("авто · " .. p:GetFullName(), C.accent)
		else
			setStatus("пад не найден в Workspace", C.danger)
		end
	else
		toggle.BackgroundColor3 = C.off
		toggle.TextColor3 = C.text
		toggle.Text = "Выкл · авто тп"
		setStatus("пауза", C.mute)
	end
end

toggle.MouseButton1Click:Connect(function()
	setEnabled(not enabled)
end)

onceBtn.MouseButton1Click:Connect(function()
	cached = nil
	local ok, msg = doTp()
	setStatus(msg, ok and C.ok or C.danger)
end)

scanBtn.MouseButton1Click:Connect(function()
	cached = nil
	local p = findPad(true)
	if p then
		setStatus("нашёл:\n" .. p:GetFullName(), C.ok)
	else
		-- список похожих
		local names = {}
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj.Name == "TouchPart" or obj.Name == "HardObby" then
				names[#names + 1] = obj:GetFullName()
				if #names >= 6 then break end
			end
		end
		if #names > 0 then
			setStatus("похожее:\n" .. table.concat(names, "\n"), C.danger)
		else
			setStatus("в Workspace нет HardObby/TouchPart", C.danger)
		end
	end
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
	local start, origin = input.Position, frame.Position
	local move, ended
	move = UserInputService.InputChanged:Connect(function(ch)
		if ch.UserInputType ~= Enum.UserInputType.MouseMovement
			and ch.UserInputType ~= Enum.UserInputType.Touch then return end
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

-- авто тп каждый кадр
RunService.RenderStepped:Connect(function()
	if not enabled then return end
	local ok, msg = doTp()
	if not ok then
		setStatus(msg, C.danger)
	else
		status.TextColor3 = C.ok
		status.Text = "тп…"
	end
end)

player.CharacterAdded:Connect(function()
	cached = nil
	if enabled then
		task.wait(0.4)
		setNoclip(true)
	end
end)

setStatus("жми «Найти пад»", C.mute)
print("[pad] loaded — вставь целиком, без HttpGet")
return gui
