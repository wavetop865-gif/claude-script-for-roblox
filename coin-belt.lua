--[[
	coin belt — убирает кулдаун и спамит взятие монет
	RightShift — меню
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local C = {
	bg = Color3.fromRGB(10, 14, 12),
	elev = Color3.fromRGB(24, 34, 30),
	line = Color3.fromRGB(40, 58, 50),
	accent = Color3.fromRGB(255, 210, 70),
	ink = Color3.fromRGB(28, 22, 8),
	off = Color3.fromRGB(60, 68, 64),
	text = Color3.fromRGB(240, 245, 238),
	mute = Color3.fromRGB(130, 145, 135),
	ok = Color3.fromRGB(120, 220, 150),
	danger = Color3.fromRGB(235, 100, 110),
}

local enabled = false
local visible = true
local hits = 0
local lastStatus = ""

local COIN_NAMES = {
	Coin = true, coin = true, Coins = true, coins = true,
	Money = true, money = true, Cash = true, cash = true,
	Gem = true, gem = true, Token = true, token = true,
	TouchPart = true, Pad = true, Collect = true,
}

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

local function looksLikeCoin(obj)
	if not obj:IsA("BasePart") then return false end
	local n = obj.Name
	if COIN_NAMES[n] then return true end
	local lower = string.lower(n)
	if lower:find("coin", 1, true) or lower:find("money", 1, true)
		or lower:find("cash", 1, true) or lower:find("token", 1, true)
		or lower:find("gem", 1, true) or lower:find("reward", 1, true) then
		return true
	end
	-- пад с реестром (как HardObby.TouchPart)
	if obj:FindFirstChild("PadRegistry") or obj:FindFirstChild("TouchInterest") then
		if obj.Parent and (obj.Parent.Name == "HardObby" or string.lower(obj.Parent.Name):find("obby", 1, true)) then
			return true
		end
		if n == "TouchPart" then return true end
	end
	return false
end

local function clearCooldown(obj)
	-- частые клиентские кулдауны / дебаунсы
	local keys = {
		"Cooldown", "cooldown", "Debounce", "debounce", "CanCollect",
		"Collected", "OnCooldown", "LastCollect", "Delay", "WaitTime",
		"CD", "cd", "Taken", "Claimed",
	}
	for _, k in ipairs(keys) do
		pcall(function()
			if obj:GetAttribute(k) ~= nil then
				local v = obj:GetAttribute(k)
				if typeof(v) == "boolean" then
					obj:SetAttribute(k, k == "CanCollect")
				elseif typeof(v) == "number" then
					obj:SetAttribute(k, 0)
				end
			end
		end)
	end
	for _, ch in ipairs(obj:GetChildren()) do
		if ch:IsA("BoolValue") then
			local ln = string.lower(ch.Name)
			if ln:find("cool") or ln:find("debun") or ln:find("taken") or ln:find("claim") then
				pcall(function() ch.Value = false end)
			elseif ln:find("can") or ln:find("ready") then
				pcall(function() ch.Value = true end)
			end
		elseif ch:IsA("NumberValue") or ch:IsA("IntValue") then
			local ln = string.lower(ch.Name)
			if ln:find("cool") or ln:find("delay") or ln:find("wait") or ln:find("cd") then
				pcall(function() ch.Value = 0 end)
			end
		end
	end
end

local function getRoot()
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("Torso")
		or char:FindFirstChild("UpperTorso")
		or char.PrimaryPart
end

local function fireTouch(root, part)
	if not root or not part then return end
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
end

local function collectTargets()
	local list = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if looksLikeCoin(obj) then
			list[#list + 1] = obj
		end
	end
	-- HardObby.TouchPart всегда в приоритете
	local hard = workspace:FindFirstChild("HardObby") or workspace:FindFirstChild("HardObby", true)
	if hard then
		local tp = hard:FindFirstChild("TouchPart") or hard:FindFirstChild("TouchPart", true)
		if tp and tp:IsA("BasePart") then
			local has = false
			for _, p in ipairs(list) do
				if p == tp then has = true break end
			end
			if not has then list[#list + 1] = tp end
		end
	end
	return list
end

local function beltTick()
	local root = getRoot()
	if not root then return 0, "нет персонажа" end

	local targets = collectTargets()
	if #targets == 0 then
		return 0, "монет/падов нет"
	end

	local n = 0
	for _, part in ipairs(targets) do
		if part and part.Parent then
			clearCooldown(part)
			if part.Parent then clearCooldown(part.Parent) end
			fireTouch(root, part)
			n += 1
		end
	end
	hits += n
	return n, string.format("спам %d · всего %d", n, hits)
end

-- иногда кулдаун в LocalScript / ModuleScript значениями
local function wipePlayerCooldowns()
	local pg = player:FindFirstChild("PlayerGui")
	local bags = { player, player:FindFirstChild("PlayerScripts"), pg }
	for _, bag in ipairs(bags) do
		if not bag then continue end
		for _, obj in ipairs(bag:GetDescendants()) do
			if obj:IsA("NumberValue") or obj:IsA("IntValue") then
				local ln = string.lower(obj.Name)
				if ln:find("cool") or ln:find("delay") or ln:find("cd") or ln:find("wait") then
					pcall(function() obj.Value = 0 end)
				end
			elseif obj:IsA("BoolValue") then
				local ln = string.lower(obj.Name)
				if ln:find("cool") or ln:find("debun") or ln:find("busy") then
					pcall(function() obj.Value = false end)
				end
			end
		end
	end
end

-- UI
do
	local old = playerGui:FindFirstChild("CoinBelt")
	if old then old:Destroy() end
end

local gui = new("ScreenGui", {
	Name = "CoinBelt",
	Parent = playerGui,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 210,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local frame = new("Frame", {
	Parent = gui,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.62, 0),
	Size = UDim2.fromOffset(250, 168),
	BackgroundColor3 = C.bg,
	BorderSizePixel = 0,
	Active = true,
})
corner(18, frame)
stroke(C.accent, 1.5, frame, 0.7)

new("TextLabel", {
	Parent = frame,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 12),
	Size = UDim2.fromOffset(180, 26),
	Font = Enum.Font.GothamBlack,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = C.text,
	Text = "belt",
})

new("TextLabel", {
	Parent = frame,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 36),
	Size = UDim2.fromOffset(210, 16),
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = C.mute,
	Text = "монеты без кулдауна · конвейер",
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
	Size = UDim2.new(1, -32, 0, 44),
	BackgroundColor3 = C.off,
	Text = "Выкл",
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextColor3 = C.text,
	AutoButtonColor = false,
})
corner(12, toggle)

local status = new("TextLabel", {
	Parent = frame,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 120),
	Size = UDim2.new(1, -32, 0, 34),
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	TextColor3 = C.mute,
	Text = "жми Вкл — спам взятия",
})

local function setStatus(msg, col)
	lastStatus = tostring(msg)
	status.Text = lastStatus
	status.TextColor3 = col or C.mute
end

local function setEnabled(on)
	enabled = on
	hits = 0
	if on then
		toggle.BackgroundColor3 = C.accent
		toggle.TextColor3 = C.ink
		toggle.Text = "Вкл · конвейер"
		setStatus("кручу…", C.accent)
	else
		toggle.BackgroundColor3 = C.off
		toggle.TextColor3 = C.text
		toggle.Text = "Выкл"
		setStatus("пауза", C.mute)
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

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	if not enabled then return end
	acc += dt
	-- очень часто: каждый кадр touch + раз в 0.15с чистка кулдаунов
	local n, msg = beltTick()
	if acc >= 0.15 then
		acc = 0
		wipePlayerCooldowns()
		setStatus(msg, n > 0 and C.ok or C.danger)
	end
end)

print("[belt] coin conveyor loaded")
return gui
