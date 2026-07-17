--[[
  HardObby.TouchPart — TP каждые 0.1с
  Режимы: Обыч / Последний
  RightShift — скрыть/показать
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local INTERVAL = 0.1
local TP_HEIGHT = 7 -- чуть выше пада

local gui = Instance.new("ScreenGui")
gui.Name = "HardObbyTP"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
	gui.Parent = game:GetService("CoreGui")
end)
if not gui.Parent then
	gui.Parent = LP:WaitForChild("PlayerGui")
end

local frame = Instance.new("Frame")
frame.Name = "Panel"
frame.Size = UDim2.new(0, 200, 0, 168)
frame.Position = UDim2.new(0, 18, 0.5, -84)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(55, 55, 65)
stroke.Thickness = 1
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 26)
title.Position = UDim2.new(0, 8, 0, 6)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(235, 235, 245)
title.Text = "HardObby Pad"
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -16, 0, 18)
status.Position = UDim2.new(0, 8, 0, 30)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = Color3.fromRGB(140, 140, 155)
status.Text = "ищем TouchPart…"
status.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -16, 0, 34)
toggleBtn.Position = UDim2.new(0, 8, 0, 54)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 70)
toggleBtn.BorderSizePixel = 0
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Text = "ВКЛ"
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = frame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(1, -16, 0, 30)
modeBtn.Position = UDim2.new(0, 8, 0, 94)
modeBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
modeBtn.BorderSizePixel = 0
modeBtn.Font = Enum.Font.GothamBold
modeBtn.TextSize = 12
modeBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
modeBtn.Text = "Режим: Обыч"
modeBtn.AutoButtonColor = false
modeBtn.Parent = frame

local modeCorner = Instance.new("UICorner")
modeCorner.CornerRadius = UDim.new(0, 8)
modeCorner.Parent = modeBtn

local modeStroke = Instance.new("UIStroke")
modeStroke.Color = Color3.fromRGB(55, 55, 65)
modeStroke.Thickness = 1
modeStroke.Parent = modeBtn

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -16, 0, 32)
hint.Position = UDim2.new(0, 8, 0, 128)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 10
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextYAlignment = Enum.TextYAlignment.Top
hint.TextColor3 = Color3.fromRGB(110, 110, 125)
hint.Text = "Обыч — все пады  |  Последний — конец\nRightShift — скрыть"
hint.Parent = frame

-- drag
do
	local dragging = false
	local dragStart, startPos
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.RightShift then
		frame.Visible = not frame.Visible
	end
end)

local function getHRP()
	local char = LP.Character
	if not char then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart")
end

local function getCF(part)
	local ok, cf = pcall(function()
		return part:GetPivot()
	end)
	if ok and typeof(cf) == "CFrame" then
		return cf
	end
	if part:IsA("BasePart") then
		return part.CFrame
	end
	local bp = part:FindFirstChildWhichIsA("BasePart", true)
	if bp then
		return bp.CFrame
	end
	return nil
end

local function getSize(part)
	if part:IsA("BasePart") then
		return part.Size
	end
	local ok, size = pcall(function()
		return part:GetExtentsSize()
	end)
	if ok and typeof(size) == "Vector3" then
		return size
	end
	local bp = part:FindFirstChildWhichIsA("BasePart", true)
	if bp then
		return bp.Size
	end
	return Vector3.new(4, 1, 4)
end

local function tpAbove(part)
	local hrp = getHRP()
	if not hrp or not part then
		return false
	end
	local cf = getCF(part)
	if not cf then
		return false
	end
	local size = getSize(part)
	local target = cf * CFrame.new(0, size.Y / 2 + TP_HEIGHT, 0)

	-- просто телепорт выше пада, без обходов
	pcall(function()
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end)
	pcall(function()
		hrp.CFrame = target
	end)
	pcall(function()
		hrp:PivotTo(target)
	end)
	local char = LP.Character
	if char then
		pcall(function()
			char:PivotTo(target)
		end)
	end
	return true
end

local function looksLikePad(inst)
	if not inst then
		return false
	end
	local n = string.lower(inst.Name)
	if n == "touchpart" or n:find("touchpart", 1, true) or n:find("pad", 1, true) then
		return true
	end
	if inst:FindFirstChild("PadRegistry") or inst:FindFirstChild("TouchInterest") then
		return true
	end
	return false
end

local function findHardObby()
	local direct = Workspace:FindFirstChild("HardObby")
	if direct then
		return direct
	end
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d.Name == "HardObby" then
			return d
		end
	end
	return nil
end

local function collectPads()
	local pads = {}
	local seen = {}

	local function add(inst)
		if not inst or seen[inst] then
			return
		end
		if not (inst:IsA("BasePart") or inst:IsA("Model") or inst:IsA("Folder")) then
			return
		end
		if not getCF(inst) then
			return
		end
		seen[inst] = true
		table.insert(pads, inst)
	end

	local hard = findHardObby()
	if hard then
		local tp = hard:FindFirstChild("TouchPart")
		if tp then
			add(tp)
		end
		for _, d in ipairs(hard:GetDescendants()) do
			if looksLikePad(d) then
				add(d)
			end
		end
	end

	if #pads == 0 then
		for _, d in ipairs(Workspace:GetDescendants()) do
			if looksLikePad(d) then
				add(d)
			end
		end
	end

	table.sort(pads, function(a, b)
		local cfa = getCF(a)
		local cfb = getCF(b)
		if not cfa or not cfb then
			return false
		end
		if math.abs(cfa.Z - cfb.Z) > 2 then
			return cfa.Z < cfb.Z
		end
		if math.abs(cfa.X - cfb.X) > 2 then
			return cfa.X < cfb.X
		end
		return cfa.Y < cfb.Y
	end)

	return pads, hard ~= nil
end

local running = false
local mode = "normal" -- normal | last
local loopThread = nil
local cachedPads = {}
local foundHard = false

local function refreshStatus()
	cachedPads, foundHard = collectPads()
	local n = #cachedPads
	if n == 0 then
		status.Text = "пад не найден"
		status.TextColor3 = Color3.fromRGB(220, 90, 90)
	elseif mode == "last" then
		status.Text = (foundHard and "HardObby · " or "") .. "последний из " .. n
		status.TextColor3 = Color3.fromRGB(120, 200, 255)
	else
		status.Text = (foundHard and "HardObby · " or "") .. n .. " пад(ов) · 0.1с"
		status.TextColor3 = Color3.fromRGB(120, 200, 140)
	end
end

local function setRunning(on)
	running = on
	if on then
		toggleBtn.Text = "ВЫКЛ"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(160, 55, 55)
	else
		toggleBtn.Text = "ВКЛ"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 70)
	end
end

local function runLoop()
	local i = 1
	while running do
		refreshStatus()
		local pads = cachedPads
		if #pads > 0 then
			local target
			if mode == "last" then
				target = pads[#pads]
			else
				if i > #pads then
					i = 1
				end
				target = pads[i]
				i = i + 1
			end
			if target then
				tpAbove(target)
				status.Text = (mode == "last" and "TP конец: " or "TP: ") .. target.Name
				status.TextColor3 = Color3.fromRGB(180, 220, 255)
			end
		end
		task.wait(INTERVAL)
	end
end

toggleBtn.MouseButton1Click:Connect(function()
	if running then
		setRunning(false)
		refreshStatus()
	else
		setRunning(true)
		if loopThread then
			task.cancel(loopThread)
		end
		loopThread = task.spawn(runLoop)
	end
end)

modeBtn.MouseButton1Click:Connect(function()
	if mode == "normal" then
		mode = "last"
		modeBtn.Text = "Режим: Последний"
		modeBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 90)
	else
		mode = "normal"
		modeBtn.Text = "Режим: Обыч"
		modeBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
	end
	refreshStatus()
end)

task.spawn(function()
	while gui.Parent do
		if not running then
			refreshStatus()
		end
		task.wait(2)
	end
end)

Workspace.DescendantAdded:Connect(function(d)
	if d.Name == "HardObby" or d.Name == "TouchPart" or looksLikePad(d) then
		task.defer(refreshStatus)
	end
end)

refreshStatus()
print("[HardObby TP] ready · TouchPart · RightShift")
