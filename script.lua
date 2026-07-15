--[[
	Lingo — переводчик для Roblox-экзекютора
	Дизайн: Ink & Apricot — глубокий ink-фон, тёплый акцент, мягкое стекло.
	RU / EN / UA · drag за шапку · RightShift — показать/скрыть
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- Theme — Ink & Apricot
-- ============================================================
local THEME = {
	bg         = Color3.fromRGB(11, 12, 16),
	panel      = Color3.fromRGB(17, 18, 24),
	elevated   = Color3.fromRGB(24, 26, 34),
	field      = Color3.fromRGB(15, 16, 22),
	fieldAlt   = Color3.fromRGB(20, 22, 30),
	hover      = Color3.fromRGB(32, 34, 44),
	line       = Color3.fromRGB(48, 50, 62),
	lineSoft   = Color3.fromRGB(36, 38, 48),

	accent     = Color3.fromRGB(255, 156, 102),
	accentDeep = Color3.fromRGB(210, 110, 70),
	accentSoft = Color3.fromRGB(255, 186, 140),
	inkOnAccent= Color3.fromRGB(28, 16, 10),

	ok         = Color3.fromRGB(110, 200, 150),
	danger     = Color3.fromRGB(235, 100, 110),

	text       = Color3.fromRGB(240, 236, 230),
	textDim    = Color3.fromRGB(160, 156, 150),
	textMute   = Color3.fromRGB(105, 102, 98),

	font       = Enum.Font.GothamMedium,
	fontBold   = Enum.Font.GothamBold,
	fontBlack  = Enum.Font.GothamBlack,
	fontLight  = Enum.Font.Gotham,

	fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	med  = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	slow = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	spring = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

local WIN_W, WIN_H = 580, 540

-- ============================================================
-- i18n
-- ============================================================
local UI_LANGS = { "ru", "en", "ua" }

local I18N = {
	ru = {
		tagline     = "переводчик",
		from        = "Откуда",
		to          = "Куда",
		auto        = "Авто",
		placeholder = "Напишите или вставьте текст…",
		result      = "Здесь появится перевод",
		translate   = "Перевести",
		translating = "Перевожу…",
		copy        = "Копировать",
		copied      = "Скопировано",
		clear       = "Очистить",
		history     = "Недавние",
		noHistory   = "История пуста",
		uiLang      = "Язык UI",
		errorEmpty  = "Введите текст",
		errorHttp   = "Ошибка сети",
		errorParse  = "Ошибка ответа",
		done        = "Готово",
		chars       = "симв.",
		hint        = "RightShift — скрыть · тяни шапку",
	},
	en = {
		tagline     = "translator",
		from        = "From",
		to          = "To",
		auto        = "Auto",
		placeholder = "Type or paste text…",
		result      = "Translation shows up here",
		translate   = "Translate",
		translating = "Translating…",
		copy        = "Copy",
		copied      = "Copied",
		clear       = "Clear",
		history     = "Recent",
		noHistory   = "No history yet",
		uiLang      = "UI language",
		errorEmpty  = "Enter some text",
		errorHttp   = "Network error",
		errorParse  = "Bad response",
		done        = "Done",
		chars       = "chars",
		hint        = "RightShift — hide · drag header",
	},
	ua = {
		tagline     = "перекладач",
		from        = "Звідки",
		to          = "Куди",
		auto        = "Авто",
		placeholder = "Напишіть або вставте текст…",
		result      = "Тут з’явиться переклад",
		translate   = "Перекласти",
		translating = "Перекладаю…",
		copy        = "Копіювати",
		copied      = "Скопійовано",
		clear       = "Очистити",
		history     = "Нещодавні",
		noHistory   = "Історія порожня",
		uiLang      = "Мова UI",
		errorEmpty  = "Введіть текст",
		errorHttp   = "Помилка мережі",
		errorParse  = "Помилка відповіді",
		done        = "Готово",
		chars       = "симв.",
		hint        = "RightShift — сховати · тягни шапку",
	},
}

local LANGS = {
	{ code = "auto",  name = "Auto" },
	{ code = "ru",    name = "Русский" },
	{ code = "en",    name = "English" },
	{ code = "uk",    name = "Українська" },
	{ code = "de",    name = "Deutsch" },
	{ code = "fr",    name = "Français" },
	{ code = "es",    name = "Español" },
	{ code = "it",    name = "Italiano" },
	{ code = "pt",    name = "Português" },
	{ code = "pl",    name = "Polski" },
	{ code = "tr",    name = "Türkçe" },
	{ code = "ar",    name = "العربية" },
	{ code = "zh-CN", name = "中文" },
	{ code = "ja",    name = "日本語" },
	{ code = "ko",    name = "한국어" },
	{ code = "hi",    name = "हिन्दी" },
	{ code = "nl",    name = "Nederlands" },
	{ code = "sv",    name = "Svenska" },
	{ code = "cs",    name = "Čeština" },
	{ code = "ro",    name = "Română" },
}

local function langName(code: string): string
	for _, L in ipairs(LANGS) do
		if L.code == code then return L.name end
	end
	return code
end

-- ============================================================
-- Helpers
-- ============================================================
local function new(class: string, props: {[string]: any}?, kids: {Instance}?): any
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			(inst :: any)[k] = v
		end
	end
	if kids then
		for _, c in ipairs(kids) do c.Parent = inst end
	end
	return inst
end

local function corner(r: number, parent: Instance?): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	if parent then c.Parent = parent end
	return c
end

local function stroke(color: Color3, thickness: number?, parent: Instance?, transparency: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	if parent then s.Parent = parent end
	return s
end

local function pad(t: number, r: number?, b: number?, l: number?, parent: Instance?): UIPadding
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t)
	p.PaddingRight = UDim.new(0, r or t)
	p.PaddingBottom = UDim.new(0, b or t)
	p.PaddingLeft = UDim.new(0, l or r or t)
	if parent then p.Parent = parent end
	return p
end

local function tween(obj: Instance, info: TweenInfo, props: {[string]: any}): Tween
	local tw = TweenService:Create(obj, info, props)
	tw:Play()
	return tw
end

local function makeDraggable(handle: GuiObject, target: GuiObject)
	local dragging = false
	local startMouse: Vector3
	local startPos: UDim2
	handle.Active = true

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startMouse = input.Position
			startPos = target.Position
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
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

local function textLen(s: string): number
	local n = utf8 and utf8.len(s)
	return n or #s
end

-- Soft mesh blobs (atmosphere, not clutter)
local function makeAtmosphere(parent: Frame)
	local layer = new("Frame", {
		Name = "Atmosphere",
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 0,
	})
	corner(24, layer)

	local blobs = {
		{ c = THEME.accentDeep, t = 0.93, x = -40, y = -30, s = 220, vx = 6, vy = 4 },
		{ c = Color3.fromRGB(70, 90, 140), t = 0.94, x = 340, y = 280, s = 260, vx = -5, vy = -3 },
		{ c = THEME.accent, t = 0.96, x = 200, y = 80, s = 160, vx = 3, vy = -5 },
	}
	local objs = {}
	for _, b in ipairs(blobs) do
		local f = new("Frame", {
			Parent = layer,
			Size = UDim2.fromOffset(b.s, b.s),
			Position = UDim2.fromOffset(b.x, b.y),
			BackgroundColor3 = b.c,
			BackgroundTransparency = b.t,
			BorderSizePixel = 0,
			ZIndex = 0,
		})
		corner(999, f)
		table.insert(objs, {
			obj = f, x = b.x, y = b.y, vx = b.vx, vy = b.vy,
			baseT = b.t, phase = math.random() * 6.28, s = b.s,
		})
	end

	return RunService.Heartbeat:Connect(function(dt)
		local w = math.max(layer.AbsoluteSize.X, 1)
		local h = math.max(layer.AbsoluteSize.Y, 1)
		for _, o in ipairs(objs) do
			o.x += o.vx * dt
			o.y += o.vy * dt
			o.phase += dt * 0.55
			if o.x < -o.s then o.x = w end
			if o.x > w then o.x = -o.s end
			if o.y < -o.s then o.y = h end
			if o.y > h then o.y = -o.s end
			o.obj.BackgroundTransparency = o.baseT + math.sin(o.phase) * 0.02
			o.obj.Position = UDim2.fromOffset(math.floor(o.x), math.floor(o.y))
		end
	end)
end

-- ============================================================
-- HTTP translate
-- ============================================================
local function httpRequest(opts: {[string]: any}): (boolean, string?)
	local fn = (syn and syn.request)
		or (http and http.request)
		or http_request
		or request
		or (fluxus and fluxus.request)

	if fn then
		local ok, res = pcall(fn, opts)
		if ok and res then
			local body = res.Body or res.body or ""
			local code = res.StatusCode or res.status_code or 0
			if code >= 200 and code < 300 then
				return true, body
			end
			return false, body
		end
		return false, nil
	end

	local ok, body = pcall(function()
		return HttpService:GetAsync(opts.Url, true)
	end)
	if ok then return true, body end
	return false, nil
end

local function urlEncode(s: string): string
	s = s:gsub("\n", " ")
	return (s:gsub("([^%w%-_%.%~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

local function translateText(text: string, sl: string, tl: string): (boolean, string, string?)
	local url = string.format(
		"https://translate.googleapis.com/translate_a/single?client=gtx&sl=%s&tl=%s&dt=t&q=%s",
		urlEncode(sl), urlEncode(tl), urlEncode(text)
	)
	local ok, body = httpRequest({
		Url = url,
		Method = "GET",
		Headers = { ["User-Agent"] = "Mozilla/5.0" },
	})
	if not ok or not body or body == "" then
		return false, "", "http"
	end

	local okParse, data = pcall(function()
		return HttpService:JSONDecode(body)
	end)
	if not okParse or type(data) ~= "table" then
		return false, "", "parse"
	end

	local chunks = data[1]
	local detected = data[3]
	if type(chunks) ~= "table" then
		return false, "", "parse"
	end

	local out = {}
	for _, part in ipairs(chunks) do
		if type(part) == "table" and type(part[1]) == "string" then
			table.insert(out, part[1])
		end
	end
	local result = table.concat(out, "")
	if result == "" then
		return false, "", "parse"
	end
	return true, result, typeof(detected) == "string" and detected or nil
end

-- ============================================================
-- State
-- ============================================================
local state = {
	uiLang   = "ru",
	fromCode = "auto",
	toCode   = "en",
	busy     = false,
	history  = {} :: {{src: string, dst: string, from: string, to: string}},
	visible  = true,
}

local function t(key: string): string
	local pack = I18N[state.uiLang] or I18N.ru
	return pack[key] or key
end

do
	local prev = playerGui:FindFirstChild("LingoTranslator")
	if prev then prev:Destroy() end
end

-- ============================================================
-- Build UI
-- ============================================================
local gui = new("ScreenGui", {
	Name = "LingoTranslator",
	Parent = playerGui,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
	DisplayOrder = 100,
})

-- Soft halo (no fullscreen dim)
local halo = new("Frame", {
	Name = "Halo",
	Parent = gui,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(WIN_W + 18, WIN_H + 18),
	BackgroundTransparency = 1,
	ZIndex = 0,
})
corner(30, halo)
stroke(THEME.accent, 2.5, halo, 0.88)

local root = new("Frame", {
	Name = "Root",
	Parent = gui,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(WIN_W, WIN_H),
	BackgroundColor3 = THEME.bg,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Active = true,
	ZIndex = 1,
})
corner(24, root)
stroke(THEME.line, 1, root, 0.25)

RunService.RenderStepped:Connect(function()
	halo.Position = root.Position
	halo.Size = UDim2.fromOffset(root.AbsoluteSize.X + 18, root.AbsoluteSize.Y + 18)
	halo.Visible = root.Visible
end)

local _atm = makeAtmosphere(root)

-- Inner glass sheen
local sheen = new("Frame", {
	Parent = root,
	Size = UDim2.new(1, 0, 0, 120),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 1,
})
new("UIGradient", {
	Parent = sheen,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	}),
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.94),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Rotation = 90,
})

-- ---------- Header ----------
local header = new("Frame", {
	Parent = root,
	Size = UDim2.new(1, 0, 0, 72),
	BackgroundTransparency = 1,
	Active = true,
	ZIndex = 3,
})
makeDraggable(header, root)

local grip = new("Frame", {
	Parent = header,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 10),
	Size = UDim2.fromOffset(42, 4),
	BackgroundColor3 = THEME.textMute,
	BackgroundTransparency = 0.4,
	BorderSizePixel = 0,
	ZIndex = 5,
})
corner(99, grip)
makeDraggable(grip, root)

local brandMark = new("Frame", {
	Parent = header,
	Position = UDim2.fromOffset(22, 26),
	Size = UDim2.fromOffset(10, 28),
	BackgroundColor3 = THEME.accent,
	BorderSizePixel = 0,
	ZIndex = 4,
})
corner(4, brandMark)
new("UIGradient", {
	Parent = brandMark,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.accentSoft),
		ColorSequenceKeypoint.new(1, THEME.accentDeep),
	}),
	Rotation = 90,
})

local brand = new("TextLabel", {
	Parent = header,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(42, 22),
	Size = UDim2.fromOffset(180, 28),
	Font = THEME.fontBlack,
	TextSize = 26,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.text,
	Text = "lingo",
	ZIndex = 4,
})

local tagline = new("TextLabel", {
	Parent = header,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(42, 48),
	Size = UDim2.fromOffset(200, 16),
	Font = THEME.fontLight,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.textMute,
	Text = t("tagline"),
	ZIndex = 4,
})

-- Segmented UI lang switch
local seg = new("Frame", {
	Parent = header,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -56, 0.5, 6),
	Size = UDim2.fromOffset(118, 32),
	BackgroundColor3 = THEME.elevated,
	BorderSizePixel = 0,
	ZIndex = 4,
})
corner(10, seg)
stroke(THEME.lineSoft, 1, seg, 0.2)
new("UIListLayout", {
	Parent = seg,
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 2),
	SortOrder = Enum.SortOrder.LayoutOrder,
})
pad(3, 3, 3, 3, seg)

local uiChips: {[string]: TextButton} = {}
local closeBtn = new("TextButton", {
	Parent = header,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -18, 0.5, 6),
	Size = UDim2.fromOffset(32, 32),
	BackgroundColor3 = THEME.elevated,
	Text = "✕",
	Font = THEME.fontBold,
	TextSize = 13,
	TextColor3 = THEME.textDim,
	AutoButtonColor = false,
	ZIndex = 5,
})
corner(10, closeBtn)
stroke(THEME.lineSoft, 1, closeBtn, 0.25)

-- Divider under header
local divider = new("Frame", {
	Parent = root,
	Position = UDim2.fromOffset(22, 72),
	Size = UDim2.new(1, -44, 0, 1),
	BackgroundColor3 = THEME.lineSoft,
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	ZIndex = 3,
})

-- ---------- Body ----------
local body = new("Frame", {
	Parent = root,
	Position = UDim2.fromOffset(0, 80),
	Size = UDim2.new(1, 0, 1, -80),
	BackgroundTransparency = 1,
	ZIndex = 3,
})
pad(8, 22, 18, 22, body)

-- Language row
local langRow = new("Frame", {
	Parent = body,
	Size = UDim2.new(1, 0, 0, 56),
	BackgroundTransparency = 1,
	ZIndex = 4,
})

local function makeLangPicker(side: string)
	local box = new("TextButton", {
		Parent = langRow,
		Size = UDim2.new(0.42, 0, 1, 0),
		Position = side == "left" and UDim2.fromScale(0, 0) or UDim2.new(0.58, 0, 0, 0),
		BackgroundColor3 = THEME.elevated,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 4,
	})
	corner(16, box)
	stroke(THEME.lineSoft, 1, box, 0.15)

	local cap = new("TextLabel", {
		Name = "Caption",
		Parent = box,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -28, 0, 14),
		Font = THEME.fontLight,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.textMute,
		Text = "",
		ZIndex = 5,
	})
	local val = new("TextLabel", {
		Name = "Value",
		Parent = box,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 24),
		Size = UDim2.new(1, -40, 0, 22),
		Font = THEME.fontBold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.text,
		Text = "",
		ZIndex = 5,
	})
	local chev = new("TextLabel", {
		Parent = box,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 4),
		Size = UDim2.fromOffset(16, 16),
		Font = THEME.fontBold,
		TextSize = 12,
		TextColor3 = THEME.accent,
		Text = "▾",
		ZIndex = 5,
	})

	box.MouseEnter:Connect(function()
		tween(box, THEME.fast, { BackgroundColor3 = THEME.hover })
	end)
	box.MouseLeave:Connect(function()
		tween(box, THEME.fast, { BackgroundColor3 = THEME.elevated })
	end)

	return { Box = box, Caption = cap, Value = val, Chevron = chev }
end

local fromPicker = makeLangPicker("left")
local toPicker   = makeLangPicker("right")

local swapBtn = new("TextButton", {
	Parent = langRow,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.fromOffset(44, 44),
	BackgroundColor3 = THEME.field,
	Text = "⇄",
	Font = THEME.fontBold,
	TextSize = 18,
	TextColor3 = THEME.accent,
	AutoButtonColor = false,
	ZIndex = 6,
})
corner(14, swapBtn)
stroke(THEME.accent, 1.2, swapBtn, 0.55)

-- Text fields stack
local inputCard = new("Frame", {
	Parent = body,
	Position = UDim2.fromOffset(0, 68),
	Size = UDim2.new(1, 0, 0, 128),
	BackgroundColor3 = THEME.field,
	BorderSizePixel = 0,
	ZIndex = 4,
})
corner(18, inputCard)
local inStroke = stroke(THEME.lineSoft, 1, inputCard, 0.1)

local inputBox = new("TextBox", {
	Parent = inputCard,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 14),
	Size = UDim2.new(1, -32, 1, -42),
	Font = THEME.font,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = THEME.text,
	PlaceholderColor3 = THEME.textMute,
	PlaceholderText = t("placeholder"),
	Text = "",
	ClearTextOnFocus = false,
	MultiLine = true,
	TextWrapped = true,
	ZIndex = 5,
})

local charCount = new("TextLabel", {
	Parent = inputCard,
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -14, 1, -10),
	Size = UDim2.fromOffset(100, 14),
	Font = THEME.fontLight,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = THEME.textMute,
	Text = "0",
	ZIndex = 5,
})

local outputCard = new("Frame", {
	Parent = body,
	Position = UDim2.fromOffset(0, 208),
	Size = UDim2.new(1, 0, 0, 128),
	BackgroundColor3 = THEME.fieldAlt,
	BorderSizePixel = 0,
	ZIndex = 4,
})
corner(18, outputCard)
local outStroke = stroke(THEME.lineSoft, 1, outputCard, 0.1)

local outBadge = new("TextLabel", {
	Parent = outputCard,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 8),
	Size = UDim2.fromOffset(120, 14),
	Font = THEME.fontLight,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.accent,
	Text = "→",
	ZIndex = 5,
})

local outputLabel = new("TextLabel", {
	Parent = outputCard,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 26),
	Size = UDim2.new(1, -32, 1, -38),
	Font = THEME.font,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = THEME.textMute,
	Text = t("result"),
	TextWrapped = true,
	ZIndex = 5,
})

-- Actions
local actionRow = new("Frame", {
	Parent = body,
	Position = UDim2.fromOffset(0, 350),
	Size = UDim2.new(1, 0, 0, 46),
	BackgroundTransparency = 1,
	ZIndex = 4,
})

local translateBtn = new("TextButton", {
	Parent = actionRow,
	Size = UDim2.new(0.52, -6, 1, 0),
	BackgroundColor3 = THEME.accent,
	Text = t("translate"),
	Font = THEME.fontBold,
	TextSize = 15,
	TextColor3 = THEME.inkOnAccent,
	AutoButtonColor = false,
	ZIndex = 5,
})
corner(14, translateBtn)
new("UIGradient", {
	Parent = translateBtn,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.accentSoft),
		ColorSequenceKeypoint.new(1, THEME.accent),
	}),
	Rotation = 12,
})

local copyBtn = new("TextButton", {
	Parent = actionRow,
	Position = UDim2.new(0.52, 6, 0, 0),
	Size = UDim2.new(0.24, -9, 1, 0),
	BackgroundColor3 = THEME.elevated,
	Text = t("copy"),
	Font = THEME.fontBold,
	TextSize = 13,
	TextColor3 = THEME.text,
	AutoButtonColor = false,
	ZIndex = 5,
})
corner(14, copyBtn)
stroke(THEME.lineSoft, 1, copyBtn, 0.2)

local clearBtn = new("TextButton", {
	Parent = actionRow,
	Position = UDim2.new(0.76, 3, 0, 0),
	Size = UDim2.new(0.24, -3, 1, 0),
	BackgroundColor3 = THEME.elevated,
	Text = t("clear"),
	Font = THEME.fontBold,
	TextSize = 13,
	TextColor3 = THEME.textDim,
	AutoButtonColor = false,
	ZIndex = 5,
})
corner(14, clearBtn)
stroke(THEME.lineSoft, 1, clearBtn, 0.2)

local statusLbl = new("TextLabel", {
	Parent = body,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 404),
	Size = UDim2.new(0.55, 0, 0, 16),
	Font = THEME.fontLight,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.textMute,
	Text = "",
	ZIndex = 4,
})

local hintLbl = new("TextLabel", {
	Parent = body,
	BackgroundTransparency = 1,
	Position = UDim2.new(0.45, 0, 0, 404),
	Size = UDim2.new(0.55, 0, 0, 16),
	Font = THEME.fontLight,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = THEME.textMute,
	Text = t("hint"),
	ZIndex = 4,
})

local histTitle = new("TextLabel", {
	Parent = body,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 428),
	Size = UDim2.new(1, 0, 0, 14),
	Font = THEME.fontBold,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.textDim,
	Text = t("history"),
	ZIndex = 4,
})

local histScroll = new("ScrollingFrame", {
	Parent = body,
	Position = UDim2.fromOffset(0, 446),
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 0,
	ScrollingDirection = Enum.ScrollingDirection.X,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ZIndex = 4,
})
new("UIListLayout", {
	Parent = histScroll,
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

-- Dropdown
local dropOverlay = new("TextButton", {
	Parent = root,
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "",
	Visible = false,
	ZIndex = 30,
	AutoButtonColor = false,
})

local dropdown = new("ScrollingFrame", {
	Parent = root,
	Size = UDim2.fromOffset(230, 240),
	BackgroundColor3 = THEME.panel,
	BorderSizePixel = 0,
	Visible = false,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = THEME.accent,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ZIndex = 31,
	ClipsDescendants = true,
})
corner(16, dropdown)
stroke(THEME.line, 1, dropdown, 0.15)
pad(8, 8, 8, 8, dropdown)
new("UIListLayout", {
	Parent = dropdown,
	Padding = UDim.new(0, 3),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

local dropTarget: string? = nil

local function closeDropdown()
	dropdown.Visible = false
	dropOverlay.Visible = false
	dropTarget = nil
end

local function openDropdown(which: string, anchor: GuiObject)
	dropTarget = which
	for _, ch in ipairs(dropdown:GetChildren()) do
		if ch:IsA("TextButton") then ch:Destroy() end
	end

	local order = 0
	for _, L in ipairs(LANGS) do
		if which == "to" and L.code == "auto" then continue end
		order += 1
		local item = new("TextButton", {
			Parent = dropdown,
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = THEME.elevated,
			BackgroundTransparency = 1,
			Text = "  " .. L.name,
			Font = THEME.font,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = THEME.text,
			AutoButtonColor = false,
			LayoutOrder = order,
			ZIndex = 32,
		})
		corner(10, item)
		item.MouseEnter:Connect(function()
			item.BackgroundTransparency = 0
		end)
		item.MouseLeave:Connect(function()
			item.BackgroundTransparency = 1
		end)
		item.MouseButton1Click:Connect(function()
			if dropTarget == "from" then
				state.fromCode = L.code
				fromPicker.Value.Text = L.code == "auto" and t("auto") or L.name
			else
				state.toCode = L.code
				toPicker.Value.Text = L.name
			end
			closeDropdown()
		end)
	end

	dropdown.CanvasSize = UDim2.fromOffset(0, order * 33 + 16)
	local abs = anchor.AbsolutePosition
	local rootAbs = root.AbsolutePosition
	dropdown.Position = UDim2.fromOffset(
		math.clamp(abs.X - rootAbs.X, 12, WIN_W - 242),
		math.clamp(abs.Y - rootAbs.Y + anchor.AbsoluteSize.Y + 6, 70, 260)
	)
	dropdown.Visible = true
	dropOverlay.Visible = true
	dropdown.BackgroundTransparency = 0.3
	tween(dropdown, THEME.fast, { BackgroundTransparency = 0 })
end

dropOverlay.MouseButton1Click:Connect(closeDropdown)
fromPicker.Box.MouseButton1Click:Connect(function()
	openDropdown("from", fromPicker.Box)
end)
toPicker.Box.MouseButton1Click:Connect(function()
	openDropdown("to", toPicker.Box)
end)

-- ============================================================
-- Refresh / history / chips
-- ============================================================
local function refreshHistory()
	for _, ch in ipairs(histScroll:GetChildren()) do
		if not ch:IsA("UIListLayout") then
			ch:Destroy()
		end
	end

	if #state.history == 0 then
		new("TextLabel", {
			Parent = histScroll,
			Size = UDim2.fromOffset(160, 26),
			BackgroundTransparency = 1,
			Font = THEME.fontLight,
			TextSize = 11,
			TextColor3 = THEME.textMute,
			Text = t("noHistory"),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
		})
		histScroll.CanvasSize = UDim2.fromOffset(160, 0)
		return
	end

	local totalW = 0
	for i = #state.history, 1, -1 do
		local h = state.history[i]
		local preview = h.src
		if textLen(preview) > 22 then
			preview = string.sub(preview, 1, 28) .. "…"
		end
		local chip = new("TextButton", {
			Parent = histScroll,
			Size = UDim2.fromOffset(0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = THEME.elevated,
			Text = "  " .. preview .. "  ",
			Font = THEME.fontLight,
			TextSize = 11,
			TextColor3 = THEME.textDim,
			AutoButtonColor = false,
			LayoutOrder = #state.history - i,
			ZIndex = 5,
		})
		corner(99, chip)
		stroke(THEME.lineSoft, 1, chip, 0.25)
		chip.MouseButton1Click:Connect(function()
			inputBox.Text = h.src
			outputLabel.Text = h.dst
			outputLabel.TextColor3 = THEME.text
			state.fromCode = h.from
			state.toCode = h.to
			fromPicker.Value.Text = h.from == "auto" and t("auto") or langName(h.from)
			toPicker.Value.Text = langName(h.to)
			charCount.Text = tostring(textLen(inputBox.Text)) .. " " .. t("chars")
		end)
		totalW += 110
	end
	histScroll.CanvasSize = UDim2.fromOffset(math.max(totalW, 220), 0)
end

local function applyUiLang()
	tagline.Text = t("tagline")
	fromPicker.Caption.Text = t("from")
	toPicker.Caption.Text = t("to")
	fromPicker.Value.Text = state.fromCode == "auto" and t("auto") or langName(state.fromCode)
	toPicker.Value.Text = langName(state.toCode)
	inputBox.PlaceholderText = t("placeholder")
	if outputLabel.TextColor3 == THEME.textMute then
		outputLabel.Text = t("result")
	end
	translateBtn.Text = state.busy and t("translating") or t("translate")
	copyBtn.Text = t("copy")
	clearBtn.Text = t("clear")
	histTitle.Text = t("history")
	hintLbl.Text = t("hint")
	charCount.Text = tostring(textLen(inputBox.Text)) .. " " .. t("chars")

	for code, chip in pairs(uiChips) do
		local active = code == state.uiLang
		chip.BackgroundColor3 = active and THEME.accent or Color3.fromRGB(0, 0, 0)
		chip.BackgroundTransparency = active and 0 or 1
		chip.TextColor3 = active and THEME.inkOnAccent or THEME.textDim
	end
	refreshHistory()
end

for i, code in ipairs(UI_LANGS) do
	local chip = new("TextButton", {
		Parent = seg,
		Size = UDim2.fromOffset(36, 26),
		BackgroundColor3 = THEME.accent,
		BackgroundTransparency = 1,
		Text = string.upper(code),
		Font = THEME.fontBold,
		TextSize = 10,
		TextColor3 = THEME.textDim,
		AutoButtonColor = false,
		LayoutOrder = i,
		ZIndex = 5,
	})
	corner(8, chip)
	chip.MouseButton1Click:Connect(function()
		state.uiLang = code
		applyUiLang()
		statusLbl.Text = t("uiLang") .. ": " .. string.upper(code)
		statusLbl.TextColor3 = THEME.accent
		task.delay(1.1, function()
			if statusLbl.TextColor3 == THEME.accent then statusLbl.Text = "" end
		end)
	end)
	uiChips[code] = chip
end

-- ============================================================
-- Interactions
-- ============================================================
local function setStatus(msg: string, color: Color3?)
	statusLbl.Text = msg
	statusLbl.TextColor3 = color or THEME.textMute
end

local function pulseOutput(okFlag: boolean)
	outStroke.Color = okFlag and THEME.accent or THEME.danger
	outStroke.Transparency = 0
	tween(outStroke, THEME.med, { Color = THEME.lineSoft, Transparency = 0.1 })
end

local function doTranslate()
	if state.busy then return end
	local text = inputBox.Text
	if not text or text:match("^%s*$") then
		setStatus(t("errorEmpty"), THEME.danger)
		pulseOutput(false)
		return
	end

	state.busy = true
	translateBtn.Text = t("translating")
	setStatus(t("translating"), THEME.accent)
	outputLabel.TextColor3 = THEME.textMute

	task.spawn(function()
		local ok, result, detected = translateText(text, state.fromCode, state.toCode)
		state.busy = false
		translateBtn.Text = t("translate")

		if not ok then
			setStatus(t(detected == "parse" and "errorParse" or "errorHttp"), THEME.danger)
			pulseOutput(false)
			return
		end

		outputLabel.Text = result
		outputLabel.TextColor3 = THEME.text
		pulseOutput(true)

		local fromShown = state.fromCode
		if state.fromCode == "auto" and detected then
			fromShown = detected
			fromPicker.Value.Text = langName(detected) .. " · " .. t("auto")
		end

		table.insert(state.history, {
			src = text, dst = result, from = fromShown, to = state.toCode,
		})
		if #state.history > 12 then table.remove(state.history, 1) end
		refreshHistory()
		setStatus(t("done"), THEME.ok)
		task.delay(1.4, function()
			if statusLbl.Text == t("done") then statusLbl.Text = "" end
		end)
	end)
end

translateBtn.MouseButton1Click:Connect(doTranslate)
translateBtn.MouseEnter:Connect(function()
	tween(translateBtn, THEME.fast, { BackgroundColor3 = THEME.accentSoft })
end)
translateBtn.MouseLeave:Connect(function()
	tween(translateBtn, THEME.fast, { BackgroundColor3 = THEME.accent })
end)

swapBtn.MouseButton1Click:Connect(function()
	if state.fromCode == "auto" then
		local tmp = inputBox.Text
		if outputLabel.TextColor3 == THEME.text then
			inputBox.Text = outputLabel.Text
			outputLabel.Text = tmp
		end
	else
		state.fromCode, state.toCode = state.toCode, state.fromCode
		fromPicker.Value.Text = langName(state.fromCode)
		toPicker.Value.Text = langName(state.toCode)
		local tmp = inputBox.Text
		if outputLabel.TextColor3 == THEME.text then
			inputBox.Text = outputLabel.Text
			outputLabel.Text = tmp
		end
	end
	tween(swapBtn, THEME.fast, { Rotation = 180 })
	task.delay(0.18, function() swapBtn.Rotation = 0 end)
	charCount.Text = tostring(textLen(inputBox.Text)) .. " " .. t("chars")
end)
swapBtn.MouseEnter:Connect(function()
	tween(swapBtn, THEME.fast, { BackgroundColor3 = THEME.hover })
end)
swapBtn.MouseLeave:Connect(function()
	tween(swapBtn, THEME.fast, { BackgroundColor3 = THEME.field })
end)

copyBtn.MouseButton1Click:Connect(function()
	local txt = outputLabel.Text
	if outputLabel.TextColor3 == THEME.textMute or txt == "" then
		setStatus(t("errorEmpty"), THEME.danger)
		return
	end
	local ok = pcall(function()
		if setclipboard then setclipboard(txt)
		elseif toclipboard then toclipboard(txt)
		elseif Clipboard and Clipboard.set then Clipboard.set(txt)
		else error("no clipboard") end
	end)
	if ok then
		copyBtn.Text = t("copied")
		setStatus(t("copied"), THEME.ok)
		task.delay(1.1, function() copyBtn.Text = t("copy") end)
	else
		setStatus("Clipboard n/a", THEME.danger)
	end
end)

clearBtn.MouseButton1Click:Connect(function()
	inputBox.Text = ""
	outputLabel.Text = t("result")
	outputLabel.TextColor3 = THEME.textMute
	charCount.Text = "0 " .. t("chars")
	setStatus("")
end)

inputBox:GetPropertyChangedSignal("Text"):Connect(function()
	charCount.Text = tostring(textLen(inputBox.Text)) .. " " .. t("chars")
end)

inputBox.Focused:Connect(function()
	tween(inStroke, THEME.fast, { Color = THEME.accent, Transparency = 0.35 })
end)
inputBox.FocusLost:Connect(function()
	tween(inStroke, THEME.fast, { Color = THEME.lineSoft, Transparency = 0.1 })
end)

closeBtn.MouseEnter:Connect(function()
	tween(closeBtn, THEME.fast, { BackgroundColor3 = THEME.danger, TextColor3 = THEME.text })
end)
closeBtn.MouseLeave:Connect(function()
	tween(closeBtn, THEME.fast, { BackgroundColor3 = THEME.elevated, TextColor3 = THEME.textDim })
end)

local function setVisible(v: boolean)
	state.visible = v
	root.Visible = v
	halo.Visible = v
	if v then
		root.Size = UDim2.fromOffset(WIN_W - 40, WIN_H - 36)
		root.BackgroundTransparency = 0.2
		tween(root, THEME.spring, {
			Size = UDim2.fromOffset(WIN_W, WIN_H),
			BackgroundTransparency = 0,
		})
	end
end

closeBtn.MouseButton1Click:Connect(function()
	setVisible(false)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if input.KeyCode == Enum.KeyCode.RightShift then
		setVisible(not state.visible)
		return
	end
	if not state.visible then return end
	if input.KeyCode == Enum.KeyCode.Escape then
		if dropdown.Visible then closeDropdown() else setVisible(false) end
		return
	end
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.Return
		and not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		and inputBox:IsFocused() then
		doTranslate()
	end
end)

-- Accent mark pulse
task.spawn(function()
	while brandMark and brandMark.Parent do
		tween(brandMark, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			BackgroundTransparency = 0.25,
		})
		task.wait(1.6)
		tween(brandMark, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			BackgroundTransparency = 0,
		})
		task.wait(1.6)
	end
end)

-- Entrance
root.Size = UDim2.fromOffset(WIN_W - 50, WIN_H - 40)
root.BackgroundTransparency = 0.35
tween(root, THEME.spring, {
	Size = UDim2.fromOffset(WIN_W, WIN_H),
	BackgroundTransparency = 0,
})

applyUiLang()
setStatus("")
print("[lingo] loaded · Ink & Apricot · RightShift to toggle")
return gui
