--!strict
-- Dark UI menu for Roblox (AWP.GG-style monochrome dark theme).
-- Includes a starfield particle background that drifts inside the menu frame.
-- Self-contained: UI library + working ESP / Movement / Combat / Misc / World.
-- Drop into StarterPlayer.StarterPlayerScripts as a LocalScript, or run via executor.

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")

local TeleportService: TeleportService? = nil
pcall(function() TeleportService = game:GetService("TeleportService") end)
local VirtualUser: any = nil
pcall(function() VirtualUser = game:GetService("VirtualUser") end)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

-- ============================================================
-- Theme (dark monochrome, AWP.GG-style)
-- ============================================================
local THEME = {
	bg            = Color3.fromRGB(22, 22, 24),
	bgPanel       = Color3.fromRGB(16, 16, 18),
	bgSection     = Color3.fromRGB(26, 26, 28),
	bgInput       = Color3.fromRGB(32, 32, 34),
	stroke        = Color3.fromRGB(46, 46, 50),
	strokeSoft    = Color3.fromRGB(38, 38, 42),

	accent        = Color3.fromRGB(210, 210, 215),
	accentBright  = Color3.fromRGB(245, 245, 250),
	accentDim     = Color3.fromRGB(95, 95, 100),

	text          = Color3.fromRGB(220, 220, 224),
	textDim       = Color3.fromRGB(150, 150, 158),
	textMuted     = Color3.fromRGB(105, 105, 112),

	font          = Enum.Font.GothamMedium,
	fontBold      = Enum.Font.GothamBold,

	tweenFast     = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	tweenMed      = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

local R_OUTER = 0
local R_INNER = 0

-- ============================================================
-- Helpers
-- ============================================================
local function new(class: string, props: {[string]: any}?, children: {Instance}?): Instance
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			(inst :: any)[k] = v
		end
	end
	if children then
		for _, c in ipairs(children) do c.Parent = inst end
	end
	return inst
end

local function corner(r: number): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	return c
end

local function stroke(color: Color3, thickness: number?, transparency: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

local function padding(t: number, r: number?, b: number?, l: number?): UIPadding
	local p = Instance.new("UIPadding")
	p.PaddingTop    = UDim.new(0, t)
	p.PaddingRight  = UDim.new(0, r or t)
	p.PaddingBottom = UDim.new(0, b or t)
	p.PaddingLeft   = UDim.new(0, l or r or t)
	return p
end

local function tween(obj: Instance, info: TweenInfo, props: {[string]: any}): Tween
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function tryDrawing(class: string)
	local d
	local ok = pcall(function() d = Drawing.new(class) end)
	if ok then return d end
	return nil
end

-- ============================================================
-- Starfield (drifting points within a bounded frame)
-- ============================================================
local function makeStarfield(parent: Frame, count: number)
	local layer = new("Frame", {
		Name = "Starfield",
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 0,
	}) :: Frame
	new("UICorner", { CornerRadius = UDim.new(0, R_OUTER), Parent = layer })

	local stars = {}

	for _ = 1, count do
		local size = (math.random() < 0.7) and 1 or 2
		local star = new("Frame", {
			Parent = layer,
			Size = UDim2.fromOffset(size, size),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = (math.random(30, 85)) / 100,
			BorderSizePixel = 0,
			ZIndex = 0,
		}) :: Frame
		table.insert(stars, {
			obj   = star,
			size  = size,
			x     = math.random() * 620,
			y     = math.random() * 360,
			vx    = (math.random() - 0.5) * (size == 2 and 18 or 8),
			vy    = (math.random() - 0.5) * (size == 2 and 12 or 6),
			baseT = (math.random(30, 85)) / 100,
			tw    = math.random() * math.pi * 2,
		})
	end

	local conn = RunService.Heartbeat:Connect(function(dt)
		local abs = layer.AbsoluteSize
		local w, h = abs.X, abs.Y
		if w <= 1 or h <= 1 then return end
		for _, s in ipairs(stars) do
			s.x = s.x + s.vx * dt
			s.y = s.y + s.vy * dt
			if s.x < -2 then s.x = w + 2 end
			if s.x > w + 2 then s.x = -2 end
			if s.y < -2 then s.y = h + 2 end
			if s.y > h + 2 then s.y = -2 end
			s.tw = s.tw + dt * (s.size == 2 and 2.2 or 3.4)
			local twinkle = (math.sin(s.tw) + 1) * 0.15
			s.obj.BackgroundTransparency = math.clamp(s.baseT - twinkle, 0.05, 0.95)
			s.obj.Position = UDim2.fromOffset(math.floor(s.x), math.floor(s.y))
		end
	end)

	return { Layer = layer, Connection = conn, Stars = stars }
end

-- ============================================================
-- Cleanup previous mount
-- ============================================================
do
	local prev = playerGui:FindFirstChild("DarkUI")
	if prev then prev:Destroy() end
end

-- ============================================================
-- UI Library
-- ============================================================
local Window  = {} ; Window.__index  = Window
local Tab     = {} ; Tab.__index     = Tab
local Section = {} ; Section.__index = Section

-- Shared "currently open sub-settings popup" reference. Right-clicking a
-- toggle opens its popup; opening another closes the previous one.
local openPopup: Frame? = nil

-- ---------------------------------------------------------------
-- Generic draggable handle. Drag `target`'s Position when the
-- user holds LMB / touches `handle`.
-- ---------------------------------------------------------------
local function makeDraggable(handle: GuiObject, target: GuiObject)
	local dragging   = false
	local startMouse: Vector3
	local startPos:   UDim2

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging   = true
			startMouse = input.Position
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
			local d = input.Position - startMouse
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
end

-- ---------------------------------------------------------------
-- Keybind helpers: a "key" can be either an Enum.KeyCode (keyboard)
-- or an Enum.UserInputType (MouseButton1/2/3).
-- ---------------------------------------------------------------
local MOUSE_DISPLAY = {
	MouseButton1 = "M1",
	MouseButton2 = "M2",
	MouseButton3 = "M3",
}

local function isMouseInput(t: any): boolean
	if typeof(t) ~= "EnumItem" then return false end
	if t.EnumType ~= Enum.UserInputType then return false end
	return t == Enum.UserInputType.MouseButton1
		or t == Enum.UserInputType.MouseButton2
		or t == Enum.UserInputType.MouseButton3
end

local function isKeyboardKey(t: any): boolean
	if typeof(t) ~= "EnumItem" then return false end
	return t.EnumType == Enum.KeyCode and t ~= Enum.KeyCode.Unknown
end

local function keyDisplayName(k: any): string
	if isMouseInput(k) then
		return MOUSE_DISPLAY[k.Name] or k.Name
	end
	if isKeyboardKey(k) then
		return k.Name
	end
	return "?"
end

local function inputMatchesKey(input: InputObject, k: any): boolean
	if not k then return false end
	if isMouseInput(k) then
		return input.UserInputType == k
	end
	if isKeyboardKey(k) then
		return input.UserInputType == Enum.UserInputType.Keyboard
			and input.KeyCode == k
	end
	return false
end

local Library = {}

function Library.new(title: string)
	local self = setmetatable({}, Window)
	self._tabs      = {}
	self._tabOrder  = {}
	self._activeTab = nil

	local gui = new("ScreenGui", {
		Name = "DarkUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1000,
		Parent = playerGui,
	}) :: ScreenGui
	self._gui = gui

	local root = new("Frame", {
		Name = "Root",
		Size = UDim2.fromOffset(620, 360),
		Position = UDim2.new(0.5, -310, 0.5, -180),
		BackgroundColor3 = THEME.bg,
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
		Parent = gui,
	}, {
		corner(R_OUTER),
		stroke(THEME.stroke, 1, 0.1),
	}) :: Frame
	self._root = root

	-- Starfield sits behind everything
	self._starfield = makeStarfield(root, 60)

	-- Title bar
	local titleBar = new("Frame", {
		Parent = root,
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = THEME.bgPanel,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, { corner(R_OUTER) }) :: Frame
	new("Frame", {
		Parent = titleBar,
		Size = UDim2.new(1, 0, 0, 8),
		Position = UDim2.new(0, 0, 1, -8),
		BackgroundColor3 = THEME.bgPanel,
		BorderSizePixel = 0,
		ZIndex = 5,
	})
	new("Frame", {
		Parent = titleBar,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = THEME.stroke,
		BorderSizePixel = 0,
		ZIndex = 5,
	})

	local titleLbl = new("TextLabel", {
		Parent = titleBar,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -100, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.fontBold,
		TextSize = 13,
		TextColor3 = THEME.text,
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 5,
	}) :: TextLabel
	self._title = titleLbl

	local function ctrlBtn(symbol: string, xOffset: number, hover: Color3, cb: () -> ()): TextButton
		local b = new("TextButton", {
			Parent = titleBar,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, xOffset, 0.5, 0),
			Size = UDim2.fromOffset(22, 20),
			BackgroundColor3 = THEME.bgInput,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = symbol,
			Font = THEME.fontBold,
			TextSize = 14,
			TextColor3 = THEME.textDim,
			AutoButtonColor = false,
			ZIndex = 6,
		}, { corner(R_INNER) }) :: TextButton
		b.MouseEnter:Connect(function()
			tween(b, THEME.tweenFast, { BackgroundTransparency = 0, TextColor3 = hover })
		end)
		b.MouseLeave:Connect(function()
			tween(b, THEME.tweenFast, { BackgroundTransparency = 1, TextColor3 = THEME.textDim })
		end)
		b.MouseButton1Click:Connect(cb)
		return b
	end

	ctrlBtn("\u{2715}", -6,  THEME.accentBright, function() self:Destroy() end)
	ctrlBtn("\u{2013}", -32, THEME.text, function()
		local minimized = root:GetAttribute("Minimized") == true
		root:SetAttribute("Minimized", not minimized)
		local target = minimized and UDim2.fromOffset(620, 360) or UDim2.fromOffset(620, 28)
		tween(root, THEME.tweenMed, { Size = target })
	end)

	-- Body
	local body = new("Frame", {
		Parent = root,
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 1, -28),
		BackgroundTransparency = 1,
		ZIndex = 2,
	}) :: Frame

	-- Sidebar
	local sidebar = new("Frame", {
		Parent = body,
		Size = UDim2.new(0, 110, 1, 0),
		BackgroundColor3 = THEME.bgPanel,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 3,
	}) :: Frame

	local tabHolder = new("Frame", {
		Parent = sidebar,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, {
		padding(8),
		new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
	}) :: Frame
	self._tabHolder = tabHolder

	local content = new("Frame", {
		Parent = body,
		Position = UDim2.fromOffset(110, 0),
		Size = UDim2.new(1, -110, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}) :: Frame
	self._content = content

	self:_makeDraggable(titleBar, root)
	return self
end

function Window:_makeDraggable(handle: GuiObject, target: GuiObject)
	makeDraggable(handle, target)
end

function Window:Show()    self._gui.Enabled = true  end
function Window:Hide()    self._gui.Enabled = false end
function Window:Toggle()  self._gui.Enabled = not self._gui.Enabled end
function Window:Destroy()
	if self._starfield and self._starfield.Connection then
		self._starfield.Connection:Disconnect()
	end
	self._gui:Destroy()
end
function Window:SetTitle(t: string) self._title.Text = t end

function Window:AddTab(name: string)
	local self_w = self
	local tab = setmetatable({}, Tab)
	tab._name = name; tab._window = self_w

	local btn = new("TextButton", {
		Parent = self_w._tabHolder,
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundColor3 = THEME.bgSection,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = THEME.font,
		TextSize = 13,
		TextColor3 = THEME.textDim,
		Text = name,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		ZIndex = 5,
	}, {
		corner(R_INNER),
		padding(0, 0, 0, 12),
	}) :: TextButton

	local page = new("Frame", {
		Parent = self_w._content,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 3,
	}, { padding(10) }) :: Frame

	local function col(side: string): ScrollingFrame
		return new("ScrollingFrame", {
			Parent = page,
			Position = side == "Right" and UDim2.new(0.5, 6, 0, 0) or UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(0.5, -6, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = THEME.accentDim,
			CanvasSize = UDim2.fromOffset(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ZIndex = 3,
		}, {
			new("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}),
		}) :: ScrollingFrame
	end

	tab._btn       = btn
	tab._page      = page
	tab._leftCol   = col("Left")
	tab._rightCol  = col("Right")

	btn.MouseEnter:Connect(function()
		if self_w._activeTab ~= tab then
			tween(btn, THEME.tweenFast, { TextColor3 = THEME.text })
		end
	end)
	btn.MouseLeave:Connect(function()
		if self_w._activeTab ~= tab then
			tween(btn, THEME.tweenFast, { TextColor3 = THEME.textDim })
		end
	end)
	btn.MouseButton1Click:Connect(function() self_w:_selectTab(tab) end)

	table.insert(self_w._tabOrder, tab)
	self_w._tabs[name] = tab
	if not self_w._activeTab then self_w:_selectTab(tab) end
	return tab
end

function Window:_selectTab(tab)
	if self._activeTab == tab then return end
	for _, t in ipairs(self._tabOrder) do
		t._page.Visible = false
		tween(t._btn, THEME.tweenFast, { TextColor3 = THEME.textDim })
	end
	self._activeTab = tab
	tab._page.Visible = true
	tween(tab._btn, THEME.tweenFast, { TextColor3 = THEME.accentBright })
end

-- ============================================================
-- Section
-- ============================================================
function Tab:AddSection(name: string, side: string?)
	side = side or "Left"
	local parent = side == "Right" and self._rightCol or self._leftCol

	local sec = setmetatable({}, Section)
	sec._collapsed = false

	local frame = new("Frame", {
		Parent = parent,
		Size = UDim2.new(1, -4, 0, 28),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.bgSection,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, {
		corner(R_INNER),
		stroke(THEME.strokeSoft, 1, 0),
	}) :: Frame

	local header = new("TextButton", {
		Parent = frame,
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 4,
	}) :: TextButton

	new("TextLabel", {
		Parent = header,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -32, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.fontBold,
		TextSize = 13,
		TextColor3 = THEME.text,
		Text = name,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
	})

	local arrow = new("TextLabel", {
		Parent = header,
		Position = UDim2.new(1, -22, 0, 0),
		Size = UDim2.fromOffset(18, 26),
		BackgroundTransparency = 1,
		Font = THEME.fontBold,
		TextSize = 11,
		TextColor3 = THEME.accent,
		Text = "\u{25B2}",
		ZIndex = 4,
	}) :: TextLabel

	new("Frame", {
		Parent = frame,
		Position = UDim2.fromOffset(8, 26),
		Size = UDim2.new(1, -16, 0, 1),
		BackgroundColor3 = THEME.stroke,
		BorderSizePixel = 0,
		ZIndex = 4,
	})

	local items = new("Frame", {
		Parent = frame,
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, {
		padding(6, 8, 8, 8),
		new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
	}) :: Frame

	sec._frame = frame; sec._items = items; sec._arrow = arrow

	header.MouseButton1Click:Connect(function()
		sec._collapsed = not sec._collapsed
		items.Visible = not sec._collapsed
		tween(arrow, THEME.tweenFast, { Rotation = sec._collapsed and 180 or 0 })
	end)
	return sec
end

-- ============================================================
-- Row helper
-- ============================================================
local function makeRow(parent: Instance, height: number): Frame
	return new("Frame", {
		Parent = parent,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = THEME.bgInput,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, {
		corner(R_INNER),
		stroke(THEME.strokeSoft, 1, 0.2),
	}) :: Frame
end

-- ============================================================
-- Toggle / Button / Label / Keybind / Slider
-- ============================================================
function Section:AddToggle(name: string, default: boolean?, callback: ((boolean) -> ())?)
	local state = default == true

	-- Entire row is the click target. No checkbox indicator: enabled state
	-- is conveyed by the label text color shifting to "dark white" (accent).
	local row = new("TextButton", {
		Parent = self._items,
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundColor3 = THEME.bgInput,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 5,
	}, {
		corner(R_INNER),
		stroke(THEME.strokeSoft, 1, 0.2),
	}) :: TextButton

	local label = new("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -28, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.font,
		TextSize = 12,
		TextColor3 = THEME.textDim,
		Text = name,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	}) :: TextLabel

	-- Subtle "more settings" gear icon. Stays dim — only shows that this
	-- toggle has sub-settings reachable via right-click.
	local gearLabel = new("TextLabel", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		Font = THEME.fontBold,
		TextSize = 11,
		TextColor3 = THEME.textMuted,
		Text = "",
		TextTransparency = 0.4,
		ZIndex = 6,
	}) :: TextLabel

	-- ----------------------------------------------------------------
	-- Sub-settings popup (hidden by default, shown on right-click).
	-- Styled like the main menu: bg + outer stroke, a darker
	-- bgPanel title bar with a hairline separator, then the items.
	-- Draggable by the title bar.
	-- ----------------------------------------------------------------
	local rootGui = row:FindFirstAncestorOfClass("ScreenGui")
	local popup = new("Frame", {
		Parent = rootGui,
		Visible = false,
		Size = UDim2.fromOffset(220, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.bg,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Active = true,
		ZIndex = 80,
	}, {
		corner(R_OUTER),
		stroke(THEME.stroke, 1, 0.1),
	}) :: Frame

	-- Title bar (same look as the main window's title bar)
	local popupHeader = new("Frame", {
		Parent = popup,
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = THEME.bgPanel,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 81,
	}) :: Frame
	new("Frame", {
		Parent = popupHeader,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = THEME.stroke,
		BorderSizePixel = 0,
		ZIndex = 81,
	})

	new("TextLabel", {
		Parent = popupHeader,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -36, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.fontBold,
		TextSize = 13,
		TextColor3 = THEME.text,
		Text = name,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 82,
	})

	local closeBtn = new("TextButton", {
		Parent = popupHeader,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(22, 20),
		BackgroundColor3 = THEME.bgInput,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = THEME.fontBold,
		TextSize = 14,
		TextColor3 = THEME.textDim,
		Text = "\u{2715}",
		ZIndex = 82,
	}, { corner(R_INNER) }) :: TextButton
	closeBtn.MouseEnter:Connect(function()
		tween(closeBtn, THEME.tweenFast, {
			BackgroundTransparency = 0, TextColor3 = THEME.accentBright,
		})
	end)
	closeBtn.MouseLeave:Connect(function()
		tween(closeBtn, THEME.tweenFast, {
			BackgroundTransparency = 1, TextColor3 = THEME.textDim,
		})
	end)

	local popupItems = new("Frame", {
		Parent = popup,
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 82,
	}, {
		padding(8, 10, 10, 10),
		new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
	}) :: Frame

	-- Make the title bar a drag handle for the popup
	makeDraggable(popupHeader, popup)

	local function hidePopup()
		popup.Visible = false
		if openPopup == popup then openPopup = nil end
	end
	closeBtn.MouseButton1Click:Connect(hidePopup)

	local function hasSubItems(): boolean
		for _, ch in ipairs(popupItems:GetChildren()) do
			if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
				return true
			end
		end
		return false
	end

	local function showPopupNearRow()
		if not rootGui then return end
		if openPopup and openPopup ~= popup then
			openPopup.Visible = false
		end
		-- Initial show (so AbsoluteSize is computed for clamping).
		popup.Visible = true
		openPopup = popup

		-- Position to the right of the row, clamped to viewport.
		local vp     = camera.ViewportSize
		local rowPos = row.AbsolutePosition
		local rowSz  = row.AbsoluteSize
		local pSz    = popup.AbsoluteSize
		local px     = rowPos.X + rowSz.X + 8
		local py     = rowPos.Y
		if px + pSz.X > vp.X - 6 then
			px = rowPos.X - pSz.X - 8
		end
		if px < 6 then px = 6 end
		if py + pSz.Y > vp.Y - 6 then
			py = math.max(6, vp.Y - 6 - pSz.Y)
		end
		popup.Position = UDim2.fromOffset(math.floor(px), math.floor(py))
	end

	-- Sub-section that inherits Section's :AddToggle / :AddSlider / :AddKeybind
	local sub = setmetatable({_items = popupItems}, Section)

	local function refresh()
		tween(label, THEME.tweenFast, {
			TextColor3 = state and THEME.accent or THEME.textDim,
		})
		tween(gearLabel, THEME.tweenFast, {
			TextTransparency = hasSubItems() and 0.2 or 1,
		})
	end
	refresh()
	if callback then task.spawn(callback, state) end

	-- Left-click toggles state; right-click opens sub-settings popup
	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			state = not state
			refresh()
			if callback then task.spawn(callback, state) end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			if not hasSubItems() then return end
			if popup.Visible then
				hidePopup()
			else
				showPopupNearRow()
			end
		end
	end)

	-- Recompute gear visibility whenever children are added to popupItems
	popupItems.ChildAdded:Connect(function(ch)
		if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
			tween(gearLabel, THEME.tweenFast, { TextTransparency = 0.2 })
		end
	end)

	return {
		Set = function(_, v: boolean)
			state = v == true
			refresh()
			if callback then task.spawn(callback, state) end
		end,
		Get  = function() return state end,
		Sub  = sub,
		Hide = hidePopup,
	}
end

function Section:AddButton(name: string, callback: (() -> ())?)
	local btn = new("TextButton", {
		Parent = self._items,
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundColor3 = THEME.bgInput,
		BorderSizePixel = 0,
		Font = THEME.font,
		TextSize = 12,
		TextColor3 = THEME.text,
		Text = name,
		AutoButtonColor = false,
		ZIndex = 6,
	}, {
		corner(R_INNER),
		stroke(THEME.strokeSoft, 1, 0),
	}) :: TextButton
	local btnStroke = btn:FindFirstChildOfClass("UIStroke") :: UIStroke

	btn.MouseEnter:Connect(function()
		tween(btn,       THEME.tweenFast, { BackgroundColor3 = THEME.bgSection })
		tween(btnStroke, THEME.tweenFast, { Color = THEME.accent, Transparency = 0.4 })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn,       THEME.tweenFast, { BackgroundColor3 = THEME.bgInput })
		tween(btnStroke, THEME.tweenFast, { Color = THEME.strokeSoft, Transparency = 0 })
	end)
	btn.MouseButton1Down:Connect(function()
		tween(btn, THEME.tweenFast, { BackgroundColor3 = THEME.accentDim })
	end)
	btn.MouseButton1Up:Connect(function()
		tween(btn, THEME.tweenFast, { BackgroundColor3 = THEME.bgSection })
	end)
	btn.MouseButton1Click:Connect(function()
		if callback then task.spawn(callback) end
	end)
	return btn
end

function Section:AddLabel(text: string, color: Color3?)
	return new("TextLabel", {
		Parent = self._items,
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = THEME.font,
		TextSize = 12,
		TextColor3 = color or THEME.textMuted,
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 6,
	})
end

function Section:AddKeybind(name: string, defaultKey: any, callback: ((any) -> ())?)
	-- A "key" can be either an Enum.KeyCode (keyboard) or an
	-- Enum.UserInputType (MouseButton1/2/3). The callback fires
	-- once with the initial binding, and again whenever the binding
	-- is changed (so consumers can track the current binding in a
	-- module-level variable).
	local key: any = defaultKey
	local binding = false

	local row = makeRow(self._items, 24)
	new("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -76, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.font,
		TextSize = 12,
		TextColor3 = THEME.text,
		Text = name,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	})

	local keyBtn = new("TextButton", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(64, 18),
		BackgroundColor3 = THEME.bg,
		BorderSizePixel = 0,
		Font = THEME.fontBold,
		TextSize = 11,
		TextColor3 = THEME.accent,
		Text = "[" .. keyDisplayName(key) .. "]",
		AutoButtonColor = false,
		ZIndex = 6,
	}, {
		corner(R_INNER),
		stroke(THEME.strokeSoft, 1, 0.15),
	}) :: TextButton

	local function setKey(k: any)
		key = k
		keyBtn.Text = "[" .. keyDisplayName(k) .. "]"
		if callback then task.spawn(callback, key) end
	end

	-- Initial emit so consumers register the default binding.
	if callback then task.spawn(callback, key) end

	keyBtn.MouseButton1Click:Connect(function()
		binding = true
		keyBtn.Text = "[...]"
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if binding then
			-- Cancel via Escape without changing the binding.
			if input.UserInputType == Enum.UserInputType.Keyboard
				and input.KeyCode == Enum.KeyCode.Escape then
				binding = false
				keyBtn.Text = "[" .. keyDisplayName(key) .. "]"
				return
			end
			-- Bind to a mouse button.
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3 then
				setKey(input.UserInputType)
				binding = false
				return
			end
			-- Bind to a keyboard key.
			if input.UserInputType == Enum.UserInputType.Keyboard
				and input.KeyCode ~= Enum.KeyCode.Unknown then
				setKey(input.KeyCode)
				binding = false
				return
			end
		end
	end)

	return {
		Set = function(_, k: any) setKey(k) end,
		Get = function() return key end,
	}
end

function Section:AddSlider(name: string, min: number, max: number, default: number, callback: ((number) -> ())?)
	local value = math.clamp(default, min, max)
	local row = new("Frame", {
		Parent = self._items,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = THEME.bgInput,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, {
		corner(R_INNER),
		stroke(THEME.strokeSoft, 1, 0.2),
	}) :: Frame

	new("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(10, 4),
		Size = UDim2.new(1, -60, 0, 14),
		BackgroundTransparency = 1,
		Font = THEME.font,
		TextSize = 12,
		TextColor3 = THEME.text,
		Text = name,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	})

	local valueLbl = new("TextLabel", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 4),
		Size = UDim2.fromOffset(50, 14),
		BackgroundTransparency = 1,
		Font = THEME.fontBold,
		TextSize = 11,
		TextColor3 = THEME.accent,
		Text = tostring(value),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 6,
	}) :: TextLabel

	local track = new("Frame", {
		Parent = row,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -8),
		Size = UDim2.new(1, -20, 0, 4),
		BackgroundColor3 = THEME.bg,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, {
		stroke(THEME.strokeSoft, 1, 0),
	}) :: Frame

	local fill = new("Frame", {
		Parent = track,
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = THEME.accent,
		BorderSizePixel = 0,
		ZIndex = 7,
	}) :: Frame

	local dragging = false
	local function update(inputX: number)
		local rel = (inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X
		rel = math.clamp(rel, 0, 1)
		local v = min + (max - min) * rel
		v = math.floor(v + 0.5)
		if v ~= value then
			value = v
			valueLbl.Text = tostring(value)
			fill.Size = UDim2.new(rel, 0, 1, 0)
			if callback then task.spawn(callback, value) end
		end
	end

	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(input.Position.X)
		end
	end)
	row.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			update(input.Position.X)
		end
	end)

	if callback then task.spawn(callback, value) end

	return {
		Set = function(_, v: number)
			value = math.clamp(v, min, max)
			valueLbl.Text = tostring(value)
			fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
			if callback then task.spawn(callback, value) end
		end,
		Get = function() return value end,
	}
end

-- ============================================================
-- Build menu
-- ============================================================
local Menu = Library.new("awp.gg")

local visuals  = Menu:AddTab("Visuals")
local combat   = Menu:AddTab("Combat")
local movement = Menu:AddTab("Movement")
local misc     = Menu:AddTab("Misc")
local settings = Menu:AddTab("Settings")

-- ============================================================
-- Centralized state read by all feature loops
-- ============================================================
local S = {
	-- ESP
	EspEnabled    = false,
	Box           = false,
	NameTag       = false,
	Health        = false,
	HealthText    = false,
	Distance      = false,
	Tracers       = false,
	Chams         = false,
	Skeleton      = false,
	HeadDot       = false,
	ToolEsp       = false,
	OffScreen     = false,
	TeamColor     = false,
	TeamCheck     = false,
	VisibleCheck  = false,
	ShowSelf      = false,
	MaxDistance   = 1000,

	-- World
	Fullbright    = false,
	NoFog         = false,
	CameraFOV     = 70,

	-- Crosshair
	Crosshair     = false,
	CrosshairSize = 8,

	-- Combat / Aimbot
	Aimbot        = false,
	AimbotFOV     = 80,
	AimbotSmooth  = 5,
	AimbotTeam    = true,
	AimbotVisible = true,
	AimbotShowFOV = false,
	AimKey        = Enum.KeyCode.E,
	AimKeyHeld    = false,

	-- Target ESP (highlights the current aimbot target)
	TargetEsp     = false,

	-- Trigger Bot (raycast through crosshair, no key required)
	TriggerBot    = false,
	TriggerTeam   = true,
	TriggerVis    = true,  -- raycast respects walls/cover
	TriggerDelay  = 0.05,  -- delay before first shot once target acquired
	TriggerCD     = 0.08,  -- cooldown between consecutive shots

	-- Movement
	InfJump       = false,
	Fly           = false,
	FlySpeed      = 50,
	Noclip        = false,
	WalkSpeed     = 16,
	JumpPower     = 50,
	BHop          = false,

	-- Misc
	AntiAFK       = false,

	-- HUD
	Watermark     = false,
}

-- ============================================================
-- Visuals tab
-- ============================================================
local pEsp = visuals:AddSection("Player ESP", "Left")
pEsp:AddToggle("Enabled",       false, function(v) S.EspEnabled = v end)
pEsp:AddToggle("Box",           false, function(v) S.Box        = v end)
pEsp:AddToggle("Name",          false, function(v) S.NameTag    = v end)
pEsp:AddToggle("Health Bar",    false, function(v) S.Health     = v end)
pEsp:AddToggle("Health Text",   false, function(v) S.HealthText = v end)
pEsp:AddToggle("Distance",      false, function(v) S.Distance   = v end)
pEsp:AddToggle("Tracers",       false, function(v) S.Tracers    = v end)
pEsp:AddToggle("Chams",         false, function(v) S.Chams      = v end)
pEsp:AddToggle("Glow",          false, function(v) S.Glow       = v end)
pEsp:AddToggle("Skeleton",      false, function(v) S.Skeleton   = v end)
pEsp:AddToggle("Head Dot",      false, function(v) S.HeadDot    = v end)
pEsp:AddToggle("Tool",          false, function(v) S.ToolEsp    = v end)
pEsp:AddToggle("Off-Screen",    false, function(v) S.OffScreen  = v end)
pEsp:AddToggle("Team Color",    false, function(v) S.TeamColor  = v end)

local filters = visuals:AddSection("Filters", "Right")
filters:AddToggle("Team Check",    false, function(v) S.TeamCheck    = v end)
filters:AddToggle("Visible Check", false, function(v) S.VisibleCheck = v end)
filters:AddToggle("Show Self",     false, function(v) S.ShowSelf     = v end)
filters:AddSlider("Max Distance", 50, 5000, 1000, function(v) S.MaxDistance = v end)

local world = visuals:AddSection("World", "Right")
local origLighting = {
	Ambient        = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	Brightness     = Lighting.Brightness,
	ClockTime      = Lighting.ClockTime,
	FogEnd         = Lighting.FogEnd,
	FogStart       = Lighting.FogStart,
	GlobalShadows  = Lighting.GlobalShadows,
}
local function applyWorld()
	if S.Fullbright then
		Lighting.Ambient        = Color3.new(1, 1, 1)
		Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
		Lighting.Brightness     = 2
		Lighting.ClockTime      = 14
		Lighting.GlobalShadows  = false
	else
		Lighting.Ambient        = origLighting.Ambient
		Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
		Lighting.Brightness     = origLighting.Brightness
		Lighting.ClockTime      = origLighting.ClockTime
		Lighting.GlobalShadows  = origLighting.GlobalShadows
	end
	if S.NoFog then
		Lighting.FogEnd   = 1e10
		Lighting.FogStart = 1e10
	else
		Lighting.FogEnd   = origLighting.FogEnd
		Lighting.FogStart = origLighting.FogStart
	end
end
world:AddToggle("Fullbright", false, function(v) S.Fullbright = v; applyWorld() end)
world:AddToggle("No Fog",     false, function(v) S.NoFog      = v; applyWorld() end)
world:AddSlider("Camera FOV", 70, 120, 70, function(v) S.CameraFOV = v end)

local cross = visuals:AddSection("Crosshair", "Right")
cross:AddToggle("Enabled", false, function(v) S.Crosshair = v end)
cross:AddSlider("Size",    2, 30, 8, function(v) S.CrosshairSize = v end)

-- ============================================================
-- Combat tab
-- ============================================================
local aimSec = combat:AddSection("Aimbot", "Left")
local aimbot = aimSec:AddToggle("Aimbot", false, function(v) S.Aimbot = v end)
aimbot.Sub:AddSlider ("FOV",          20, 400, 80, function(v) S.AimbotFOV     = v end)
aimbot.Sub:AddSlider ("Smoothness",   1,  20,  5,  function(v) S.AimbotSmooth  = v end)
aimbot.Sub:AddToggle ("Team Check",   true,  function(v) S.AimbotTeam    = v end)
aimbot.Sub:AddToggle ("Visible Check", true, function(v) S.AimbotVisible = v end)
aimbot.Sub:AddToggle ("Show FOV",     false, function(v) S.AimbotShowFOV = v end)
aimbot.Sub:AddToggle ("Target ESP",   false, function(v) S.TargetEsp     = v end)
aimbot.Sub:AddKeybind("Aim Key",      Enum.KeyCode.E, function(k) S.AimKey = k end)

local trigSec = combat:AddSection("Trigger Bot", "Right")
local trigger = trigSec:AddToggle("Trigger Bot", false, function(v) S.TriggerBot = v end)
trigger.Sub:AddToggle("Team Check",    true,  function(v) S.TriggerTeam = v end)
trigger.Sub:AddToggle("Visible Check", true,  function(v) S.TriggerVis  = v end)
trigger.Sub:AddSlider("Delay (ms)",    0, 500, 50, function(v) S.TriggerDelay = v / 1000 end)
trigger.Sub:AddSlider("Cooldown (ms)", 0, 500, 80, function(v) S.TriggerCD    = v / 1000 end)

-- Aim key state tracking (S.AimKey may be a keyboard key OR a mouse button)
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if inputMatchesKey(input, S.AimKey) then S.AimKeyHeld = true end
end)
UserInputService.InputEnded:Connect(function(input)
	if inputMatchesKey(input, S.AimKey) then S.AimKeyHeld = false end
end)

-- ============================================================
-- Movement tab
-- ============================================================
local mv = movement:AddSection("Movement", "Left")
mv:AddToggle("Infinite Jump", false, function(v) S.InfJump = v end)
mv:AddToggle("Bunny Hop",     false, function(v) S.BHop    = v end)
mv:AddToggle("Fly",           false, function(v) S.Fly     = v end)
mv:AddToggle("Noclip",        false, function(v) S.Noclip  = v end)

local mvSpeed = movement:AddSection("Speed", "Right")

-- Walk Speed lives behind a Speed Boost toggle (default WalkSpeed otherwise).
-- ПКМ по тогглу открывает слайдер Walk Speed.
local speedBoost = mvSpeed:AddToggle("Speed Boost", false, function(v) S.SpeedBoost = v end)
speedBoost.Sub:AddSlider("Walk Speed", 16, 500, 16, function(v) S.WalkSpeed = v end)

-- Jump Power lives behind a Jump Boost toggle (default JumpPower otherwise).
local jumpBoost = mvSpeed:AddToggle("Jump Boost", false, function(v) S.JumpBoost = v end)
jumpBoost.Sub:AddSlider("Jump Power", 50, 500, 50, function(v) S.JumpPower = v end)

-- Fly speed is part of the Fly toggle.
mvSpeed:AddSlider("Fly Speed",  10, 300, 50, function(v) S.FlySpeed = v end)

-- ============================================================
-- Misc tab
-- ============================================================
local m = misc:AddSection("Utility", "Left")
m:AddToggle("Anti-AFK", false, function(v) S.AntiAFK = v end)
m:AddButton("Reset Character", function()
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.Health = 0 end
	end
end)
m:AddButton("Rejoin Server", function()
	if not TeleportService then return end
	pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
end)

-- ============================================================
-- Settings tab
-- ============================================================
local st = settings:AddSection("UI", "Left")
local toggleKey: any = Enum.KeyCode.LeftControl
st:AddKeybind("Toggle Menu", Enum.KeyCode.LeftControl, function(k) toggleKey = k end)
st:AddButton("Unload Menu", function() Menu:Destroy() end)

local stHud = settings:AddSection("HUD", "Left")
stHud:AddToggle("Watermark (FPS)", false, function(v) S.Watermark   = v end)
stHud:AddToggle("Target HUD",      false, function(v) S.TargetHud   = v end)
stHud:AddToggle("Keybinds HUD",    false, function(v) S.KeybindsHud = v end)
stHud:AddToggle("Velocity HUD",    false, function(v) S.VelocityHud = v end)

local stInfo = settings:AddSection("Info", "Right")
stInfo:AddLabel("awp.gg v1.0")
stInfo:AddLabel("Drag the title bar to move")
stInfo:AddLabel("LeftCTRL: show / hide")

-- ============================================================
-- Implementations
-- ============================================================

-- Player ESP -------------------------------------------------
local espObjects: { [Player]: any } = {}

-- Drawing-based parts (cleaned up via :Remove())
local ESP_DRAW_PARTS = {
	"boxFill", "boxOut", "box",
	"glow1", "glow2", "glow3",
	"tracerOut", "tracer",
	"nameTxt", "distTxt", "hpTxt", "toolTxt", "targetTxt",
	"headDot",
	"arrow",
	"ringOut", "ring",
}

local R15_BONES = {
	{"Head",           "UpperTorso"},
	{"UpperTorso",     "LowerTorso"},
	{"UpperTorso",     "LeftUpperArm"},
	{"LeftUpperArm",   "LeftLowerArm"},
	{"LeftLowerArm",   "LeftHand"},
	{"UpperTorso",     "RightUpperArm"},
	{"RightUpperArm",  "RightLowerArm"},
	{"RightLowerArm",  "RightHand"},
	{"LowerTorso",     "LeftUpperLeg"},
	{"LeftUpperLeg",   "LeftLowerLeg"},
	{"LeftLowerLeg",   "LeftFoot"},
	{"LowerTorso",     "RightUpperLeg"},
	{"RightUpperLeg",  "RightLowerLeg"},
	{"RightLowerLeg",  "RightFoot"},
}
local R6_BONES = {
	{"Head",    "Torso"},
	{"Torso",   "Left Arm"},
	{"Torso",   "Right Arm"},
	{"Torso",   "Left Leg"},
	{"Torso",   "Right Leg"},
}
local MAX_BONES = math.max(#R15_BONES, #R6_BONES)

-- Shared ScreenGui for GUI-based ESP elements (HP bar with gradient)
local espGui: ScreenGui? = nil
local function ensureEspGui(): ScreenGui
	if espGui and espGui.Parent then return espGui end
	local sg = Instance.new("ScreenGui")
	sg.Name           = "DarkMenuEsp"
	sg.ResetOnSpawn   = false
	sg.IgnoreGuiInset = true
	sg.DisplayOrder   = 9999
	sg.Parent         = playerGui
	espGui = sg
	return sg
end

local function clearEsp(plr: Player)
	local e = espObjects[plr]
	if not e then return end
	for _, k in ipairs(ESP_DRAW_PARTS) do
		if e[k] then pcall(function() e[k]:Remove() end) end
	end
	if e.headDotOut then pcall(function() e.headDotOut:Remove() end) end
	if e.boneOut then
		for _, d in ipairs(e.boneOut) do pcall(function() d:Remove() end) end
	end
	if e.bone then
		for _, d in ipairs(e.bone) do pcall(function() d:Remove() end) end
	end
	if e.hpFrame  then e.hpFrame:Destroy() end
	if e.highlight then e.highlight:Destroy() end
	espObjects[plr] = nil
end

local COL_WHITE = Color3.fromRGB(245, 245, 250)
local COL_BLACK = Color3.new(0, 0, 0)
local COL_DIM   = Color3.fromRGB(200, 200, 210)

local function makeSquare(filled: boolean, color: Color3, thickness: number, z: number)
	local d = tryDrawing("Square")
	if not d then return nil end
	d.Filled       = filled
	d.Color        = color
	d.Thickness    = thickness
	d.Transparency = 1
	d.ZIndex       = z
	d.Visible      = false
	return d
end

local function makeLine(color: Color3, thickness: number, z: number)
	local d = tryDrawing("Line")
	if not d then return nil end
	d.Color        = color
	d.Thickness    = thickness
	d.Transparency = 1
	d.ZIndex       = z
	d.Visible      = false
	return d
end

local function makeText(size: number, color: Color3, z: number)
	local d = tryDrawing("Text")
	if not d then return nil end
	d.Size         = size
	d.Color        = color
	d.Center       = true
	d.Outline      = true
	d.OutlineColor = COL_BLACK
	d.Transparency = 1
	d.ZIndex       = z
	d.Visible      = false
	pcall(function() d.Font = 2 end) -- Plex (clean)
	return d
end

local function makeCircle(filled: boolean, color: Color3, thickness: number, z: number)
	local d = tryDrawing("Circle")
	if not d then return nil end
	d.Color        = color
	d.Filled       = filled
	d.Thickness    = thickness
	d.NumSides     = 24
	d.Transparency = 1
	d.ZIndex       = z
	d.Visible      = false
	return d
end

local function makeTriangle(color: Color3, z: number)
	local d = tryDrawing("Triangle")
	if not d then return nil end
	d.Color        = color
	d.Filled       = true
	d.Thickness    = 1
	d.Transparency = 1
	d.ZIndex       = z
	d.Visible      = false
	return d
end

local function buildEsp(plr: Player)
	if espObjects[plr] then return espObjects[plr] end
	local e: any = {}

	-- Glow halo: 3 progressively larger / dimmer outlines drawn BEHIND the
	-- box so the box outline reads cleanly on top. Each layer is hollow
	-- with low thickness — the effect looks like a soft light bloom.
	e.glow1 = makeSquare(false, COL_WHITE, 2, 0) -- innermost (brightest)
	e.glow2 = makeSquare(false, COL_WHITE, 2, 0)
	e.glow3 = makeSquare(false, COL_WHITE, 2, 0) -- outermost (softest)

	-- Box: filled tint (z=1) underneath a thin black outline (z=2)
	-- and a thin team-color outline on top (z=3).
	e.boxFill = makeSquare(true,  COL_WHITE, 1, 1)
	if e.boxFill then e.boxFill.Transparency = 0.22 end -- Drawing alpha: ~22% opaque tint
	e.boxOut  = makeSquare(false, COL_BLACK, 3, 2)
	e.box     = makeSquare(false, COL_WHITE, 1, 3)

	-- Skeleton bones: pairs of (outline, line) for double-stroke
	e.boneOut = {}
	e.bone    = {}
	for i = 1, MAX_BONES do
		e.boneOut[i] = makeLine(COL_BLACK, 2, 1)
		e.bone[i]    = makeLine(COL_WHITE, 1, 2)
	end

	-- Head dot (circle outlined)
	e.headDotOut = makeCircle(false, COL_BLACK, 3, 1)
	e.headDot    = makeCircle(true,  COL_WHITE, 1, 2)

	-- Off-screen arrow
	e.arrow = makeTriangle(COL_WHITE, 4)

	-- Target ring + label (only shown when this player is the aimbot target)
	e.ringOut   = makeCircle(false, COL_BLACK, 4,  9)
	e.ring      = makeCircle(false, COL_WHITE, 2, 10)
	e.targetTxt = makeText(11, COL_WHITE, 11)
	if e.targetTxt then e.targetTxt.Text = "TARGET" end

	-- Vertical health bar — layered, anchored fill (no UIGradient hack).
	-- Structure (z-order):
	--   hpFrame     (outer, dark inner background + black UIStroke)
	--     padding  (1px inset so fill doesn't touch outline)
	--     hpEmpty  (very dim background tint shown behind the fill)
	--     hpFill   (anchored bottom-left, height = HP%, dynamic color
	--               red→yellow→green based on HP fraction)
	--       hpHi   (1px bright highlight on top edge of fill = "gloss")
	local gui = ensureEspGui()
	local hpFrame = Instance.new("Frame")
	hpFrame.Name             = "Hp"
	hpFrame.BorderSizePixel  = 0
	hpFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	hpFrame.BackgroundTransparency = 0.05
	hpFrame.Visible          = false
	hpFrame.ZIndex           = 5
	hpFrame.Parent           = gui

	local hpStroke = Instance.new("UIStroke")
	hpStroke.Color     = Color3.new(0, 0, 0)
	hpStroke.Thickness = 1
	hpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	hpStroke.Parent    = hpFrame

	local hpPad = Instance.new("UIPadding")
	hpPad.PaddingTop    = UDim.new(0, 1)
	hpPad.PaddingBottom = UDim.new(0, 1)
	hpPad.PaddingLeft   = UDim.new(0, 1)
	hpPad.PaddingRight  = UDim.new(0, 1)
	hpPad.Parent        = hpFrame

	local hpEmpty = Instance.new("Frame")
	hpEmpty.Name             = "Empty"
	hpEmpty.BorderSizePixel  = 0
	hpEmpty.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
	hpEmpty.BackgroundTransparency = 0.45
	hpEmpty.Size             = UDim2.fromScale(1, 1)
	hpEmpty.ZIndex           = 6
	hpEmpty.Parent           = hpFrame

	local hpFill = Instance.new("Frame")
	hpFill.Name             = "Fill"
	hpFill.BorderSizePixel  = 0
	hpFill.BackgroundColor3 = Color3.fromRGB(90, 210, 90) -- updated each frame
	hpFill.AnchorPoint      = Vector2.new(0, 1)
	hpFill.Position         = UDim2.new(0, 0, 1, 0)
	hpFill.Size             = UDim2.fromScale(1, 1)
	hpFill.ZIndex           = 7
	hpFill.Parent           = hpFrame

	local hpHi = Instance.new("Frame")
	hpHi.Name             = "Hi"
	hpHi.BorderSizePixel  = 0
	hpHi.BackgroundColor3 = Color3.new(1, 1, 1)
	hpHi.BackgroundTransparency = 0.4
	hpHi.Size             = UDim2.new(1, 0, 0, 1)
	hpHi.Position         = UDim2.fromOffset(0, 0)
	hpHi.ZIndex           = 8
	hpHi.Parent           = hpFill

	e.hpFrame = hpFrame
	e.hpFill  = hpFill
	e.hpHi    = hpHi

	-- Tracer: thick black under + thin white over
	e.tracerOut = makeLine(COL_BLACK, 3, 1)
	e.tracer    = makeLine(COL_WHITE, 1, 2)

	-- Text: name above, distance below, hp number near bar, tool below distance
	e.nameTxt = makeText(14, COL_WHITE, 4)
	if e.nameTxt then e.nameTxt.Text = plr.Name end
	e.distTxt = makeText(13, COL_DIM,   4)
	e.hpTxt   = makeText(12, COL_WHITE, 4)
	e.toolTxt = makeText(12, COL_DIM,   4)
	if e.hpTxt then e.hpTxt.Center = false end -- left-anchor, near bar

	-- Chams via Highlight
	local hl = Instance.new("Highlight")
	hl.FillTransparency    = 0.55
	hl.OutlineTransparency = 0
	hl.FillColor           = COL_WHITE
	hl.OutlineColor        = COL_WHITE
	hl.Enabled             = false
	hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent              = playerGui
	e.highlight = hl

	espObjects[plr] = e
	return e
end

local function setHidden(e: any)
	for _, k in ipairs(ESP_DRAW_PARTS) do
		if e[k] then e[k].Visible = false end
	end
	if e.headDotOut then e.headDotOut.Visible = false end
	if e.boneOut then for _, d in ipairs(e.boneOut) do d.Visible = false end end
	if e.bone    then for _, d in ipairs(e.bone)    do d.Visible = false end end
	if e.hpFrame   then e.hpFrame.Visible = false end
	if e.highlight then e.highlight.Enabled = false end
end

local function isVisibleTo(target: BasePart): boolean
	local origin = camera.CFrame.Position
	local dir = target.Position - origin
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = { camera }
	if player.Character then table.insert(exclude, player.Character) end
	params.FilterDescendantsInstances = exclude
	local hit = workspace:Raycast(origin, dir, params)
	if not hit then return true end
	return hit.Instance:IsDescendantOf(target.Parent)
end

-- Pick bone set for an R15 or R6 character
local function getBones(char: Instance): { { string } }
	if char:FindFirstChild("UpperTorso") then return R15_BONES end
	if char:FindFirstChild("Torso")      then return R6_BONES  end
	return R15_BONES
end

local VP_REF = 720 -- reference viewport height (used only for head-dot scaling)
-- Box ESP is sized from the character's real bounding box, projected to
-- screen-space, clamped to a maximum so it doesn't blow up when the target
-- is very close. Minimum bound keeps it readable when far away.
local MAX_BOX_H    = 220
local MAX_BOX_W    = 130
local MIN_BOX_H    = 28
local MIN_BOX_W    = 14
local BOX_ASPECT   = 0.55 -- fallback width / height ratio

local function teamHighlightColor(plr: Player): Color3
	if plr.TeamColor then
		return plr.TeamColor.Color
	end
	return COL_WHITE
end

-- The current aimbot/target ESP target. Refreshed each frame in the main
-- render loop so target ESP highlights the same player aimbot picks. Declared
-- here (before updateEsp) so the function captures it as an upvalue rather
-- than as a global.
local currentTarget: Player? = nil

local function updateEsp()
	if not S.EspEnabled then
		for _, e in pairs(espObjects) do setHidden(e) end
		return
	end
	local vpY  = camera.ViewportSize.Y
	local vpX  = camera.ViewportSize.X
	-- sScale is now used only for head-dot/arrow visuals (not for box).
	local sScale = math.clamp(vpY / VP_REF, 0.7, 2)

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == player and not S.ShowSelf then continue end
		local e = espObjects[plr] or buildEsp(plr)
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (char and hrp and hum and hum.Health > 0) then
			setHidden(e); continue
		end
		if S.TeamCheck and plr.Team and plr.Team == player.Team then
			setHidden(e); continue
		end

		local hrpPart = hrp :: BasePart
		local hrpScreen, onScreen = camera:WorldToViewportPoint(hrpPart.Position)
		local dist = (camera.CFrame.Position - hrpPart.Position).Magnitude

		-- Off-screen arrow (only if Off-Screen is on AND target is off-screen/in range)
		if e.arrow then
			local showArrow = S.OffScreen and (not onScreen or hrpScreen.Z < 0)
				and dist <= S.MaxDistance
				and (not S.VisibleCheck or isVisibleTo(hrpPart))
			if showArrow then
				-- Compute direction from screen center to target's screen position
				-- (mirror Z<0 so behind-camera targets project away from forward).
				local cx, cy = vpX / 2, vpY / 2
				local sx, sy = hrpScreen.X, hrpScreen.Y
				if hrpScreen.Z < 0 then
					sx, sy = vpX - sx, vpY - sy
				end
				local dx, dy = sx - cx, sy - cy
				local mag = math.max(math.sqrt(dx * dx + dy * dy), 1)
				dx, dy = dx / mag, dy / mag
				local r = math.min(vpX, vpY) * 0.35
				local ax, ay = cx + dx * r, cy + dy * r
				local sz = 10 * sScale
				-- Triangle pointing in (dx,dy) direction
				local nx, ny = -dy, dx -- perpendicular
				e.arrow.Visible = true
				e.arrow.Color   = S.TeamColor and teamHighlightColor(plr) or COL_WHITE
				e.arrow.PointA  = Vector2.new(ax + dx * sz,           ay + dy * sz)
				e.arrow.PointB  = Vector2.new(ax - dx * sz + nx * sz, ay - dy * sz + ny * sz)
				e.arrow.PointC  = Vector2.new(ax - dx * sz - nx * sz, ay - dy * sz - ny * sz)
			else
				e.arrow.Visible = false
			end
		end

		if not onScreen then
			-- Hide everything except arrow for off-screen targets
			if e.box       then e.box.Visible       = false end
			if e.boxOut    then e.boxOut.Visible    = false end
			if e.headDot   then e.headDot.Visible   = false end
			if e.headDotOut then e.headDotOut.Visible = false end
			if e.bone      then for _, d in ipairs(e.bone)    do d.Visible = false end end
			if e.boneOut   then for _, d in ipairs(e.boneOut) do d.Visible = false end end
			if e.tracer    then e.tracer.Visible    = false end
			if e.tracerOut then e.tracerOut.Visible = false end
			if e.nameTxt   then e.nameTxt.Visible   = false end
			if e.distTxt   then e.distTxt.Visible   = false end
			if e.hpTxt     then e.hpTxt.Visible     = false end
			if e.toolTxt   then e.toolTxt.Visible   = false end
			if e.hpFrame   then e.hpFrame.Visible   = false end
			if e.highlight then e.highlight.Enabled = S.Chams end
			if e.highlight then e.highlight.Adornee = char end
			continue
		end

		if dist > S.MaxDistance then setHidden(e); continue end

		if S.VisibleCheck and not isVisibleTo(hrpPart) then
			setHidden(e); continue
		end

		-- ---------------------------------------------------------------
		-- Box size is computed from the character's real world bounding
		-- box (Model:GetBoundingBox) projected to screen space, then
		-- clamped to MIN/MAX so it neither blows up at point-blank
		-- range nor shrinks to nothing at long range.
		-- ---------------------------------------------------------------
		local boxX, boxY, boxW, boxH
		do
			local ok, boxCF, boxSize = pcall(char.GetBoundingBox, char)
			if ok and boxCF and boxSize then
				local hx, hy, hz = boxSize.X * 0.5, boxSize.Y * 0.5, boxSize.Z * 0.5
				local minX, minY = math.huge,  math.huge
				local maxX, maxY = -math.huge, -math.huge
				local anyOn = false
				local CORNERS = {
					Vector3.new(-hx, -hy, -hz), Vector3.new( hx, -hy, -hz),
					Vector3.new(-hx,  hy, -hz), Vector3.new( hx,  hy, -hz),
					Vector3.new(-hx, -hy,  hz), Vector3.new( hx, -hy,  hz),
					Vector3.new(-hx,  hy,  hz), Vector3.new( hx,  hy,  hz),
				}
				for _, c in ipairs(CORNERS) do
					local w = boxCF * c
					local sp, on = camera:WorldToViewportPoint(w)
					if on and sp.Z > 0 then anyOn = true end
					if sp.X < minX then minX = sp.X end
					if sp.Y < minY then minY = sp.Y end
					if sp.X > maxX then maxX = sp.X end
					if sp.Y > maxY then maxY = sp.Y end
				end
				if anyOn and maxX > minX and maxY > minY then
					boxW = maxX - minX
					boxH = maxY - minY
					-- Clamp to bounds (max prevents blow-up close-up,
					-- min keeps the box readable from far away)
					boxW = math.clamp(boxW, MIN_BOX_W, MAX_BOX_W)
					boxH = math.clamp(boxH, MIN_BOX_H, MAX_BOX_H)
					boxX = (minX + maxX) * 0.5 - boxW * 0.5
					boxY = (minY + maxY) * 0.5 - boxH * 0.5
				end
			end
			-- Fallback to hrp-centered aspect-ratio box if projection failed
			if not boxX then
				boxH = math.clamp(80, MIN_BOX_H, MAX_BOX_H)
				boxW = boxH * BOX_ASPECT
				boxX = hrpScreen.X - boxW * 0.5
				boxY = hrpScreen.Y - boxH * 0.55
			end
		end

		-- Team color for box / tracer / name
		local boxColor = (S.TeamColor and teamHighlightColor(plr)) or COL_WHITE

		-- Box: filled tint (z=1) + black drop-stroke (z=2) + thin top stroke (z=3)
		if e.boxFill then
			e.boxFill.Visible  = S.Box
			e.boxFill.Color    = boxColor
			e.boxFill.Size     = Vector2.new(boxW, boxH)
			e.boxFill.Position = Vector2.new(boxX, boxY)
		end
		if e.box then
			e.box.Visible  = S.Box
			e.box.Color    = boxColor
			e.box.Size     = Vector2.new(boxW, boxH)
			e.box.Position = Vector2.new(boxX, boxY)
		end
		if e.boxOut then
			e.boxOut.Visible  = S.Box
			e.boxOut.Size     = Vector2.new(boxW, boxH)
			e.boxOut.Position = Vector2.new(boxX, boxY)
		end

		-- Glow halo: 3 outlines drawn behind the box, progressively
		-- larger and more transparent.
		if e.glow1 and e.glow2 and e.glow3 then
			if S.Glow then
				local layers = {
					{ d = e.glow1, off = 3,  t = 0.55 },
					{ d = e.glow2, off = 7,  t = 0.75 },
					{ d = e.glow3, off = 12, t = 0.88 },
				}
				for _, L in ipairs(layers) do
					L.d.Visible      = true
					L.d.Color        = boxColor
					L.d.Transparency = L.t
					L.d.Size         = Vector2.new(boxW + L.off * 2, boxH + L.off * 2)
					L.d.Position     = Vector2.new(boxX - L.off,     boxY - L.off)
				end
			else
				e.glow1.Visible = false
				e.glow2.Visible = false
				e.glow3.Visible = false
			end
		end

		-- Skeleton (project each bone pair to screen)
		local boneList = getBones(char)
		for i = 1, MAX_BONES do
			local outD, mainD = e.boneOut[i], e.bone[i]
			local pair = boneList[i]
			if pair and S.Skeleton then
				local a = char:FindFirstChild(pair[1])
				local b = char:FindFirstChild(pair[2])
				if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
					local sa = camera:WorldToViewportPoint(a.Position)
					local sb = camera:WorldToViewportPoint(b.Position)
					if outD then
						outD.Visible = true
						outD.From    = Vector2.new(sa.X, sa.Y)
						outD.To      = Vector2.new(sb.X, sb.Y)
					end
					if mainD then
						mainD.Visible = true
						mainD.Color   = boxColor
						mainD.From    = Vector2.new(sa.X, sa.Y)
						mainD.To      = Vector2.new(sb.X, sb.Y)
					end
				else
					if outD  then outD.Visible  = false end
					if mainD then mainD.Visible = false end
				end
			else
				if outD  then outD.Visible  = false end
				if mainD then mainD.Visible = false end
			end
		end

		-- Head dot (small filled circle on the head)
		do
			local head = char:FindFirstChild("Head")
			local show = S.HeadDot and head and head:IsA("BasePart")
			if show then
				local headPart = head :: BasePart
				local hp = camera:WorldToViewportPoint(headPart.Position)
				local r = math.clamp(boxW * 0.18, 2, 6)
				if e.headDot then
					e.headDot.Visible  = true
					e.headDot.Color    = boxColor
					e.headDot.Radius   = r
					e.headDot.Position = Vector2.new(hp.X, hp.Y)
				end
				if e.headDotOut then
					e.headDotOut.Visible  = true
					e.headDotOut.Radius   = r + 1
					e.headDotOut.Position = Vector2.new(hp.X, hp.Y)
				end
			else
				if e.headDot    then e.headDot.Visible    = false end
				if e.headDotOut then e.headDotOut.Visible = false end
			end
		end

		-- Health bar (vertical, on the left of the box).
		-- Fill is sized by HP fraction (anchored bottom) so it grows up
		-- from empty. Color lerps red → yellow → green by fraction.
		local hpct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		local hpW = 5
		local hpX = boxX - 8
		local hpY = boxY
		local hpH = boxH
		if e.hpFrame then
			e.hpFrame.Visible  = S.Health
			e.hpFrame.Position = UDim2.fromOffset(math.floor(hpX), math.floor(hpY))
			e.hpFrame.Size     = UDim2.fromOffset(hpW, math.floor(hpH))
		end
		if e.hpFill then
			-- Dynamic color: red (low) → yellow (mid) → green (high)
			local r, g, b
			if hpct < 0.5 then
				local k = hpct / 0.5
				r = (220 * (1 - k) + 230 * k) / 255
				g = ( 70 * (1 - k) + 190 * k) / 255
				b = ( 70 * (1 - k) +  70 * k) / 255
			else
				local k = (hpct - 0.5) / 0.5
				r = (230 * (1 - k) +  90 * k) / 255
				g = (190 * (1 - k) + 210 * k) / 255
				b = ( 70 * (1 - k) +  90 * k) / 255
			end
			e.hpFill.BackgroundColor3 = Color3.new(r, g, b)
			e.hpFill.Size = UDim2.new(1, 0, hpct, 0)
			e.hpFill.Visible = hpct > 0.001
		end
		if e.hpHi then
			-- Hide the glossy highlight when HP is so low the fill is < 2px
			-- to avoid the 1px line being the only thing visible.
			e.hpHi.Visible = (hpct * math.max(hpH - 2, 0)) >= 2
		end

		-- HP text (numeric, next to bar)
		if e.hpTxt then
			e.hpTxt.Visible  = S.HealthText
			e.hpTxt.Text     = tostring(math.floor(hum.Health + 0.5))
			e.hpTxt.Position = Vector2.new(hpX - 18, boxY + boxH - 14)
		end

		-- Name (above box)
		if e.nameTxt then
			e.nameTxt.Visible  = S.NameTag
			e.nameTxt.Color    = boxColor
			e.nameTxt.Text     = plr.Name
			e.nameTxt.Position = Vector2.new(centerX, boxY - 17)
		end

		-- Distance (below box)
		if e.distTxt then
			e.distTxt.Visible  = S.Distance
			e.distTxt.Text     = string.format("%d m", math.floor(dist))
			e.distTxt.Position = Vector2.new(centerX, boxY + boxH + 3)
		end

		-- Tool (under distance)
		if e.toolTxt then
			local tool = char:FindFirstChildOfClass("Tool")
			if S.ToolEsp and tool then
				e.toolTxt.Visible  = true
				e.toolTxt.Text     = "[" .. tool.Name .. "]"
				e.toolTxt.Position = Vector2.new(centerX, boxY + boxH + (S.Distance and 18 or 3))
			else
				e.toolTxt.Visible = false
			end
		end

		-- Tracer (double-stroked, anchored to bottom-center of viewport)
		if e.tracer and e.tracerOut then
			local from = Vector2.new(vpX / 2, vpY)
			local to   = Vector2.new(centerX, boxY + boxH)
			e.tracerOut.Visible = S.Tracers
			e.tracer.Visible    = S.Tracers
			e.tracer.Color      = boxColor
			e.tracerOut.From = from
			e.tracerOut.To   = to
			e.tracer.From    = from
			e.tracer.To      = to
		end

		-- Chams
		if e.highlight then
			e.highlight.Enabled  = S.Chams
			e.highlight.Adornee  = char
			e.highlight.FillColor = boxColor
			e.highlight.OutlineColor = boxColor
		end

		-- Target ESP: pulsing ring + "TARGET" label on the current aim target
		local isTarget = S.TargetEsp and (plr == currentTarget)
		if e.ring and e.ringOut then
			if isTarget then
				local pulse = 1 + math.sin(time() * 6) * 0.10
				local rr    = math.clamp(boxH * 0.55, 16, 60) * pulse
				local cy    = boxY + boxH * 0.5
				e.ringOut.Visible  = true
				e.ringOut.Radius   = rr
				e.ringOut.Position = Vector2.new(centerX, cy)
				e.ring.Visible     = true
				e.ring.Radius      = rr
				e.ring.Position    = Vector2.new(centerX, cy)
				e.ring.Color       = THEME.accentBright
				if e.targetTxt then
					e.targetTxt.Visible  = true
					e.targetTxt.Color    = THEME.accentBright
					e.targetTxt.Position = Vector2.new(centerX, boxY - 32)
				end
			else
				e.ringOut.Visible  = false
				e.ring.Visible     = false
				if e.targetTxt then e.targetTxt.Visible = false end
			end
		end
	end
end

Players.PlayerRemoving:Connect(clearEsp)

-- Hide the default Roblox player nametag + health bar floating above
-- characters, since our ESP renders its own.
local function disableDefaultDisplay(plr: Player)
	if plr == player then return end
	local function apply()
		local char = plr.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then
			local ok, h = pcall(function() return char:WaitForChild("Humanoid", 5) end)
			if ok then hum = h end
		end
		if hum then
			hum.DisplayDistanceType    = Enum.HumanoidDisplayDistanceType.None
			hum.NameDisplayDistance    = 0
			hum.HealthDisplayDistance  = 0
		end
	end
	task.spawn(apply)
	plr.CharacterAdded:Connect(function() task.spawn(apply) end)
end
for _, p in ipairs(Players:GetPlayers()) do disableDefaultDisplay(p) end
Players.PlayerAdded:Connect(disableDefaultDisplay)

-- Aimbot -----------------------------------------------------
local function getClosestTarget(): (Player?, BasePart?)
	local center = camera.ViewportSize / 2
	local best: Player? = nil
	local bestDist = math.huge
	local bestPart: BasePart? = nil
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == player then continue end
		local char = plr.Character
		local head = char and char:FindFirstChild("Head")
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if not (head and hum and hum.Health > 0) then continue end
		if S.AimbotTeam and plr.Team and plr.Team == player.Team then continue end
		local headPart = head :: BasePart
		local sp, onScreen = camera:WorldToViewportPoint(headPart.Position)
		if not onScreen then continue end
		local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
		if d > S.AimbotFOV then continue end
		if S.AimbotVisible and not isVisibleTo(headPart) then continue end
		if d < bestDist then
			best, bestDist, bestPart = plr, d, headPart
		end
	end
	return best, bestPart
end

-- Trigger bot: returns the player whose character is hit by a forward
-- raycast from the camera (i.e. the crosshair is literally on them).
local function getCrosshairHit(): Player?
	local origin = camera.CFrame.Position
	local dir    = camera.CFrame.LookVector * 1000
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = { camera }
	if player.Character then table.insert(exclude, player.Character) end
	params.FilterDescendantsInstances = exclude
	local hit = workspace:Raycast(origin, dir, params)
	if not hit or not hit.Instance then return nil end
	local model = hit.Instance:FindFirstAncestorOfClass("Model")
	while model do
		local hum = model:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			local plr = Players:GetPlayerFromCharacter(model)
			if plr then return plr end
			return nil
		end
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
	end
	return nil
end

-- (currentTarget declared earlier so updateEsp can see it lexically)

local fovCircle = tryDrawing("Circle")
if fovCircle then
	fovCircle.Thickness    = 1
	fovCircle.NumSides     = 64
	fovCircle.Color        = Color3.fromRGB(235, 235, 240)
	fovCircle.Filled       = false
	fovCircle.Transparency = 0.6
	fovCircle.Visible      = false
end

-- Crosshair (two perpendicular lines, double-stroked) ------
local function makeCrosshairLine(thick: number, color: Color3, z: number)
	local d = tryDrawing("Line")
	if not d then return nil end
	d.Thickness    = thick
	d.Color        = color
	d.Transparency = 1
	d.ZIndex       = z
	d.Visible      = false
	return d
end
local crossH    = makeCrosshairLine(1, COL_WHITE, 11)
local crossV    = makeCrosshairLine(1, COL_WHITE, 11)
local crossHout = makeCrosshairLine(3, COL_BLACK, 10)
local crossVout = makeCrosshairLine(3, COL_BLACK, 10)

-- Watermark / FPS HUD ------------------------------------
local hudGui = Instance.new("ScreenGui")
hudGui.Name             = "DarkMenuHUD"
hudGui.ResetOnSpawn     = false
hudGui.IgnoreGuiInset   = true
hudGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
hudGui.DisplayOrder     = 250
pcall(function() hudGui.Parent = (gethui and gethui()) or playerGui end)

local wmFrame = Instance.new("Frame")
wmFrame.Name             = "Watermark"
wmFrame.Position         = UDim2.fromOffset(12, 12)
wmFrame.Size             = UDim2.fromOffset(190, 24)
wmFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
wmFrame.BackgroundTransparency = 0.15
wmFrame.BorderSizePixel  = 0
wmFrame.Visible          = false
wmFrame.Parent           = hudGui

local wmStroke = Instance.new("UIStroke")
wmStroke.Color     = Color3.fromRGB(40, 40, 44)
wmStroke.Thickness = 1
wmStroke.Parent    = wmFrame

local wmLabel = Instance.new("TextLabel")
wmLabel.Name             = "Label"
wmLabel.BackgroundTransparency = 1
wmLabel.Size             = UDim2.fromScale(1, 1)
wmLabel.Position         = UDim2.fromOffset(8, 0)
wmLabel.Size             = UDim2.new(1, -10, 1, 0)
wmLabel.TextXAlignment   = Enum.TextXAlignment.Left
wmLabel.Font             = Enum.Font.Code
wmLabel.TextSize         = 14
wmLabel.TextColor3       = Color3.fromRGB(235, 235, 240)
wmLabel.Text             = "awp.gg | 0 fps"
wmLabel.Parent           = wmFrame

-- ============================================================
-- Extra HUD widgets (Target / Keybinds / Velocity)
-- All styled like the main menu and draggable from their title bar.
-- ============================================================
local function makeHudPanel(panelName: string, w: number, h: number, x: number, y: number)
	local frame = Instance.new("Frame")
	frame.Name             = panelName
	frame.Size             = UDim2.fromOffset(w, h)
	frame.Position         = UDim2.fromOffset(x, y)
	frame.BackgroundColor3 = THEME.bg
	frame.BorderSizePixel  = 0
	frame.Visible          = false
	frame.Active           = true
	frame.Parent           = hudGui

	local strokeInst = Instance.new("UIStroke")
	strokeInst.Color     = THEME.stroke
	strokeInst.Thickness = 1
	strokeInst.Transparency = 0.1
	strokeInst.Parent    = frame

	local titleBar = Instance.new("Frame")
	titleBar.Name             = "TitleBar"
	titleBar.Size             = UDim2.new(1, 0, 0, 22)
	titleBar.BackgroundColor3 = THEME.bgPanel
	titleBar.BorderSizePixel  = 0
	titleBar.Active           = true
	titleBar.Parent           = frame

	local titleSep = Instance.new("Frame")
	titleSep.Size             = UDim2.new(1, 0, 0, 1)
	titleSep.Position         = UDim2.new(0, 0, 1, -1)
	titleSep.BackgroundColor3 = THEME.stroke
	titleSep.BorderSizePixel  = 0
	titleSep.Parent           = titleBar

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Position               = UDim2.fromOffset(8, 0)
	titleLbl.Size                   = UDim2.new(1, -16, 1, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font                   = THEME.fontBold
	titleLbl.TextSize               = 12
	titleLbl.TextColor3             = THEME.text
	titleLbl.Text                   = panelName
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	titleLbl.Parent                 = titleBar

	local body = Instance.new("Frame")
	body.Name                   = "Body"
	body.Position               = UDim2.fromOffset(0, 22)
	body.Size                   = UDim2.new(1, 0, 1, -22)
	body.BackgroundTransparency = 1
	body.Parent                 = frame

	makeDraggable(titleBar, frame)
	return frame, body
end

-- ---------- Target HUD ----------
local tgtFrame, tgtBody = makeHudPanel("Target", 240, 78, 12, 46)
tgtFrame.AutomaticSize = Enum.AutomaticSize.None

local tgtName = Instance.new("TextLabel")
tgtName.Position               = UDim2.fromOffset(10, 6)
tgtName.Size                   = UDim2.new(1, -20, 0, 18)
tgtName.BackgroundTransparency = 1
tgtName.Font                   = THEME.fontBold
tgtName.TextSize               = 14
tgtName.TextColor3             = THEME.text
tgtName.Text                   = "no target"
tgtName.TextXAlignment         = Enum.TextXAlignment.Left
tgtName.TextTruncate           = Enum.TextTruncate.AtEnd
tgtName.Parent                 = tgtBody

local tgtDist = Instance.new("TextLabel")
tgtDist.AnchorPoint             = Vector2.new(1, 0)
tgtDist.Position                = UDim2.new(1, -10, 0, 6)
tgtDist.Size                    = UDim2.fromOffset(80, 18)
tgtDist.BackgroundTransparency  = 1
tgtDist.Font                    = THEME.font
tgtDist.TextSize                = 12
tgtDist.TextColor3              = THEME.textDim
tgtDist.Text                    = ""
tgtDist.TextXAlignment          = Enum.TextXAlignment.Right
tgtDist.Parent                  = tgtBody

local tgtHpBack = Instance.new("Frame")
tgtHpBack.Position         = UDim2.fromOffset(10, 30)
tgtHpBack.Size             = UDim2.new(1, -20, 0, 8)
tgtHpBack.BackgroundColor3 = THEME.bgInput
tgtHpBack.BorderSizePixel  = 0
tgtHpBack.Parent           = tgtBody

local tgtHpFill = Instance.new("Frame")
tgtHpFill.Size             = UDim2.fromScale(1, 1)
tgtHpFill.BackgroundColor3 = THEME.accentBright
tgtHpFill.BorderSizePixel  = 0
tgtHpFill.Parent           = tgtHpBack

local tgtHpGrad = Instance.new("UIGradient")
tgtHpGrad.Rotation = 0
tgtHpGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(220, 50, 50)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 200, 60)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(80, 220, 120)),
})
tgtHpGrad.Parent = tgtHpFill

local tgtHpTxt = Instance.new("TextLabel")
tgtHpTxt.Position               = UDim2.fromOffset(10, 42)
tgtHpTxt.Size                   = UDim2.new(1, -20, 0, 16)
tgtHpTxt.BackgroundTransparency = 1
tgtHpTxt.Font                   = THEME.font
tgtHpTxt.TextSize               = 11
tgtHpTxt.TextColor3             = THEME.textDim
tgtHpTxt.Text                   = ""
tgtHpTxt.TextXAlignment         = Enum.TextXAlignment.Left
tgtHpTxt.Parent                 = tgtBody

-- ---------- Keybinds HUD ----------
local kbFrame, kbBody = makeHudPanel("Keybinds", 200, 66, 12, 134)
local kbLayout = Instance.new("UIListLayout")
kbLayout.Padding         = UDim.new(0, 2)
kbLayout.SortOrder       = Enum.SortOrder.LayoutOrder
kbLayout.Parent          = kbBody
local kbPadding = Instance.new("UIPadding")
kbPadding.PaddingTop    = UDim.new(0, 6)
kbPadding.PaddingLeft   = UDim.new(0, 10)
kbPadding.PaddingRight  = UDim.new(0, 10)
kbPadding.PaddingBottom = UDim.new(0, 6)
kbPadding.Parent        = kbBody

local function makeKbRow(name: string): (TextLabel, TextLabel)
	local row = Instance.new("Frame")
	row.Size                   = UDim2.new(1, 0, 0, 16)
	row.BackgroundTransparency = 1
	row.Parent                 = kbBody

	local nm = Instance.new("TextLabel")
	nm.Size                   = UDim2.new(1, -56, 1, 0)
	nm.BackgroundTransparency = 1
	nm.Font                   = THEME.font
	nm.TextSize               = 12
	nm.TextColor3             = THEME.text
	nm.Text                   = name
	nm.TextXAlignment         = Enum.TextXAlignment.Left
	nm.Parent                 = row

	local key = Instance.new("TextLabel")
	key.AnchorPoint             = Vector2.new(1, 0.5)
	key.Position                = UDim2.new(1, 0, 0.5, 0)
	key.Size                    = UDim2.fromOffset(54, 14)
	key.BackgroundTransparency  = 1
	key.Font                    = THEME.fontBold
	key.TextSize                = 11
	key.TextColor3              = THEME.textDim
	key.Text                    = "[?]"
	key.TextXAlignment          = Enum.TextXAlignment.Right
	key.Parent                  = row

	return nm, key
end
local kbAimName,    kbAimKey    = makeKbRow("Aimbot")
local kbMenuName,   kbMenuKey   = makeKbRow("Menu")

-- ---------- Velocity HUD ----------
local velFrame, velBody = makeHudPanel("Velocity", 180, 44, 12, 210)
local velLbl = Instance.new("TextLabel")
velLbl.Position               = UDim2.fromOffset(10, 0)
velLbl.Size                   = UDim2.new(1, -20, 1, 0)
velLbl.BackgroundTransparency = 1
velLbl.Font                   = THEME.fontBold
velLbl.TextSize               = 16
velLbl.TextColor3             = THEME.text
velLbl.Text                   = "0  studs/s"
velLbl.TextXAlignment         = Enum.TextXAlignment.Left
velLbl.Parent                 = velBody

-- Click helper for Trigger Bot (best-effort across executors)
local VIM: any = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)
local function fireClick()
	local mp = rawget(_G, "mouse1press")  or rawget(getfenv(), "mouse1press")
	local mr = rawget(_G, "mouse1release") or rawget(getfenv(), "mouse1release")
	local mc = rawget(_G, "mouse1click")   or rawget(getfenv(), "mouse1click")
	if type(mc) == "function" then
		pcall(mc)
		return true
	elseif type(mp) == "function" and type(mr) == "function" then
		pcall(mp); task.wait(0.01); pcall(mr)
		return true
	elseif VIM then
		local ok = pcall(function()
			VIM:SendMouseButtonEvent(0, 0, 0, true,  game, 1)
			task.wait(0.01)
			VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
		end)
		return ok
	end
	return false
end

-- Camera FOV: remember original, restore on unload
local origFOV = camera.FieldOfView

-- Fly / Noclip / Speed --------------------------------------
local flyBV: BodyVelocity? = nil
local flyBG: BodyGyro?     = nil
local function startFly()
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local hrpPart = hrp :: BasePart
	if flyBV then flyBV:Destroy() end
	if flyBG then flyBG:Destroy() end
	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	flyBV.Velocity = Vector3.zero
	flyBV.Parent   = hrpPart
	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	flyBG.P         = 9000
	flyBG.CFrame    = hrpPart.CFrame
	flyBG.Parent    = hrpPart
end
local function stopFly()
	if flyBV then flyBV:Destroy(); flyBV = nil end
	if flyBG then flyBG:Destroy(); flyBG = nil end
end

-- React when Fly toggle changes
local prevFly = false

-- Infinite jump / Bunny hop (JumpRequest fires while Space is held)
UserInputService.JumpRequest:Connect(function()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if S.InfJump then
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
		return
	end
	if S.BHop then
		local st = hum:GetState()
		if st == Enum.HumanoidStateType.Landed
			or st == Enum.HumanoidStateType.Running
			or st == Enum.HumanoidStateType.RunningNoPhysics then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

-- Default Roblox movement values (used when boost toggles are off).
local DEFAULT_WALK = 16
local DEFAULT_JUMP = 50

-- Character re-apply: respect the Speed Boost / Jump Boost toggles so the
-- sliders only have effect when their toggle is on. Otherwise restore the
-- default Roblox values.
local function applyCharacterSettings()
	local char = player.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.UseJumpPower = true
		hum.WalkSpeed = S.SpeedBoost and S.WalkSpeed or DEFAULT_WALK
		hum.JumpPower = S.JumpBoost  and S.JumpPower or DEFAULT_JUMP
	end
end
player.CharacterAdded:Connect(function()
	stopFly()
	prevFly = false
	task.wait(0.5)
	applyCharacterSettings()
end)
applyCharacterSettings()

-- ============================================================
-- Main render loop
-- ============================================================
local fpsSmoothed       = 60
local lastTriggerAt     = 0
local triggerTarget: Player? = nil
local triggerAcquiredAt = 0
RunService.RenderStepped:Connect(function(dt)
	-- Resolve current aimbot target once per frame so target ESP and aimbot
	-- agree on who's selected. We also use the same target part for aiming.
	local target, targetPart = getClosestTarget()
	currentTarget = target

	-- ESP
	local ok = pcall(updateEsp)
	if not ok then end

	-- Camera FOV
	if S.CameraFOV and S.CameraFOV > 0 then
		if math.abs(camera.FieldOfView - S.CameraFOV) > 0.05 then
			camera.FieldOfView = S.CameraFOV
		end
	end

	-- Aimbot
	if fovCircle then
		fovCircle.Visible = S.Aimbot and S.AimbotShowFOV
		fovCircle.Position = camera.ViewportSize / 2
		fovCircle.Radius   = S.AimbotFOV
	end
	if S.Aimbot and S.AimKeyHeld and targetPart then
		local goal = CFrame.lookAt(camera.CFrame.Position, targetPart.Position)
		local alpha = math.clamp(1 / math.max(S.AimbotSmooth, 1), 0.05, 1)
		camera.CFrame = camera.CFrame:Lerp(goal, alpha)
	end

	-- Trigger Bot: auto-fires when crosshair is literally on a player
	-- (forward raycast from camera hits a character). Delay = reaction
	-- time before the first shot, Cooldown = gap between shots.
	if S.TriggerBot then
		local hitPlr = getCrosshairHit()
		if hitPlr then
			local sameTeam = S.TriggerTeam and hitPlr.Team and hitPlr.Team == player.Team
			if sameTeam then
				triggerTarget = nil
			else
				local now = tick()
				if triggerTarget ~= hitPlr then
					triggerTarget     = hitPlr
					triggerAcquiredAt = now
				elseif (now - triggerAcquiredAt) >= S.TriggerDelay
					and (now - lastTriggerAt) >= S.TriggerCD then
					if fireClick() then lastTriggerAt = now end
				end
			end
		else
			triggerTarget = nil
		end
	else
		triggerTarget = nil
	end

	-- Crosshair (perpendicular lines anchored to viewport center)
	local cx = camera.ViewportSize.X / 2
	local cy = camera.ViewportSize.Y / 2
	local cs = math.max(S.CrosshairSize, 1)
	local showX = S.Crosshair
	if crossH    then crossH.Visible    = showX end
	if crossV    then crossV.Visible    = showX end
	if crossHout then crossHout.Visible = showX end
	if crossVout then crossVout.Visible = showX end
	if showX then
		if crossH    then crossH.From    = Vector2.new(cx - cs, cy); crossH.To    = Vector2.new(cx + cs, cy) end
		if crossV    then crossV.From    = Vector2.new(cx, cy - cs); crossV.To    = Vector2.new(cx, cy + cs) end
		if crossHout then crossHout.From = Vector2.new(cx - cs, cy); crossHout.To = Vector2.new(cx + cs, cy) end
		if crossVout then crossVout.From = Vector2.new(cx, cy - cs); crossVout.To = Vector2.new(cx, cy + cs) end
	end

	-- Watermark / FPS HUD
	if dt > 0 then
		local fpsInst = 1 / dt
		fpsSmoothed = fpsSmoothed + (fpsInst - fpsSmoothed) * math.clamp(dt * 4, 0, 1)
	end
	if wmFrame then
		wmFrame.Visible = S.Watermark
		if S.Watermark then
			wmLabel.Text = string.format("awp.gg  |  %d fps", math.floor(fpsSmoothed + 0.5))
		end
	end

	-- ---------- Target HUD ----------
	if tgtFrame then
		local show = S.TargetHud and (currentTarget ~= nil)
		tgtFrame.Visible = show
		if show and currentTarget then
			local char = currentTarget.Character
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")
			local hp, mhp = 0, 100
			if hum then hp = hum.Health; mhp = math.max(hum.MaxHealth, 1) end
			local frac = math.clamp(hp / mhp, 0, 1)
			tgtName.Text = currentTarget.DisplayName ~= "" and currentTarget.DisplayName or currentTarget.Name
			tgtHpFill.Size = UDim2.new(frac, 0, 1, 0)
			tgtHpTxt.Text  = string.format("%d / %d HP", math.floor(hp + 0.5), math.floor(mhp + 0.5))
			local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp and myHrp then
				tgtDist.Text = string.format("%d m", math.floor((hrp.Position - myHrp.Position).Magnitude + 0.5))
			else
				tgtDist.Text = ""
			end
		end
	end

	-- ---------- Keybinds HUD ----------
	if kbFrame then
		kbFrame.Visible = S.KeybindsHud
		if S.KeybindsHud then
			local aimHeld  = S.AimKeyHeld
			local menuOpen = Menu._gui and Menu._gui.Enabled or false
			kbAimKey.Text     = "[" .. keyDisplayName(S.AimKey) .. "]"
			kbAimKey.TextColor3 = aimHeld and THEME.accentBright or THEME.textDim
			kbAimName.TextColor3 = aimHeld and THEME.text         or THEME.textDim
			kbMenuKey.Text    = "[" .. keyDisplayName(toggleKey) .. "]"
			kbMenuKey.TextColor3 = menuOpen and THEME.accentBright or THEME.textDim
			kbMenuName.TextColor3 = menuOpen and THEME.text         or THEME.textDim
		end
	end

	-- ---------- Velocity HUD ----------
	if velFrame then
		velFrame.Visible = S.VelocityHud
		if S.VelocityHud then
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local speed = 0
			if hrp then
				local v = hrp.AssemblyLinearVelocity or hrp.Velocity
				speed = Vector3.new(v.X, 0, v.Z).Magnitude
			end
			velLbl.Text = string.format("%d  studs/s", math.floor(speed + 0.5))
		end
	end

	-- Fly turn-on / turn-off
	if S.Fly ~= prevFly then
		prevFly = S.Fly
		if S.Fly then startFly() else stopFly() end
	end
	if S.Fly and flyBV and flyBG then
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local move = Vector3.zero
			local camCF = camera.CFrame
			if UserInputService:IsKeyDown(Enum.KeyCode.W)         then move += camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S)         then move -= camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A)         then move -= camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D)         then move += camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then move += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end
			flyBV.Velocity = (move.Magnitude > 0) and move.Unit * S.FlySpeed or Vector3.zero
			flyBG.CFrame   = camCF
		end
	end
end)

RunService.Stepped:Connect(function()
	-- Noclip
	if S.Noclip then
		local char = player.Character
		if char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then
					p.CanCollide = false
				end
			end
		end
	end
	-- Apply walk / jump power — only when the corresponding boost toggle
	-- is on. When off, restore Roblox's default values.
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		local targetWS = S.SpeedBoost and S.WalkSpeed or DEFAULT_WALK
		local targetJP = S.JumpBoost  and S.JumpPower or DEFAULT_JUMP
		if hum.WalkSpeed ~= targetWS then hum.WalkSpeed = targetWS end
		if hum.JumpPower ~= targetJP then hum.JumpPower = targetJP end
	end
end)

-- Anti-AFK
player.Idled:Connect(function()
	if not S.AntiAFK or not VirtualUser then return end
	pcall(function()
		VirtualUser:Button2Down(Vector2.new(0, 0), camera.CFrame)
		task.wait(1)
		VirtualUser:Button2Up(Vector2.new(0, 0), camera.CFrame)
	end)
end)

-- ============================================================
-- Toggle menu visibility (toggleKey may be a keyboard key OR a mouse button)
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if inputMatchesKey(input, toggleKey) then
		Menu:Toggle()
	end
end)

-- Cleanup ESP visuals when menu destroyed
Menu._gui.Destroying:Connect(function()
	for plr, _ in pairs(espObjects) do clearEsp(plr) end
	if fovCircle  then pcall(function() fovCircle:Remove()  end) end
	if crossH     then pcall(function() crossH:Remove()     end) end
	if crossV     then pcall(function() crossV:Remove()     end) end
	if crossHout  then pcall(function() crossHout:Remove()  end) end
	if crossVout  then pcall(function() crossVout:Remove()  end) end
	if hudGui     then pcall(function() hudGui:Destroy()    end) end
	pcall(function() camera.FieldOfView = origFOV end)
	stopFly()
	-- restore lighting
	Lighting.Ambient        = origLighting.Ambient
	Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
	Lighting.Brightness     = origLighting.Brightness
	Lighting.ClockTime      = origLighting.ClockTime
	Lighting.FogEnd         = origLighting.FogEnd
	Lighting.FogStart       = origLighting.FogStart
	Lighting.GlobalShadows  = origLighting.GlobalShadows
end)

return Menu
