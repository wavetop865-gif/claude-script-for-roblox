--[[
	Lingo — красивый переводчик для Roblox-экзекютора
	• Смена языка интерфейса (RU / EN / UA)
	• Перевод текста (авто-определение + десятки языков)
	• Swap, Copy, History, анимации
	Запуск: вставь в экзекютор и Execute
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- Theme
-- ============================================================
local THEME = {
	bg         = Color3.fromRGB(12, 14, 18),
	panel      = Color3.fromRGB(18, 22, 28),
	card       = Color3.fromRGB(24, 30, 38),
	cardHover  = Color3.fromRGB(30, 38, 48),
	input      = Color3.fromRGB(16, 20, 26),
	stroke     = Color3.fromRGB(42, 52, 64),
	strokeSoft = Color3.fromRGB(32, 40, 50),

	accent     = Color3.fromRGB(56, 189, 168),
	accentSoft = Color3.fromRGB(36, 120, 110),
	accentGlow = Color3.fromRGB(80, 220, 200),
	danger     = Color3.fromRGB(220, 90, 100),
	ok         = Color3.fromRGB(90, 200, 140),

	text       = Color3.fromRGB(232, 238, 244),
	textDim    = Color3.fromRGB(150, 162, 176),
	textMuted  = Color3.fromRGB(100, 112, 126),

	font       = Enum.Font.GothamMedium,
	fontBold   = Enum.Font.GothamBold,
	fontLight  = Enum.Font.Gotham,

	fast = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	med  = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	slow = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
}

-- ============================================================
-- UI language packs (interface itself)
-- ============================================================
local UI_LANGS = { "ru", "en", "ua" }

local I18N = {
	ru = {
		brand       = "LINGO",
		tagline     = "переводчик",
		from        = "Откуда",
		to          = "Куда",
		auto        = "Авто",
		placeholder = "Введите текст для перевода…",
		result      = "Перевод появится здесь",
		translate   = "Перевести",
		translating = "Перевожу…",
		swap        = "Поменять",
		copy        = "Копировать",
		copied      = "Скопировано",
		clear       = "Очистить",
		history     = "История",
		noHistory   = "Пока пусто",
		uiLang      = "Язык UI",
		errorEmpty  = "Введите текст",
		errorHttp   = "Ошибка сети / API",
		errorParse  = "Не удалось разобрать ответ",
		done        = "Готово",
		chars       = "симв.",
		hint        = "Enter — перевести · Esc — скрыть · RightShift — меню",
	},
	en = {
		brand       = "LINGO",
		tagline     = "translator",
		from        = "From",
		to          = "To",
		auto        = "Auto",
		placeholder = "Type text to translate…",
		result      = "Translation appears here",
		translate   = "Translate",
		translating = "Translating…",
		swap        = "Swap",
		copy        = "Copy",
		copied      = "Copied",
		clear       = "Clear",
		history     = "History",
		noHistory   = "Nothing yet",
		uiLang      = "UI language",
		errorEmpty  = "Enter some text",
		errorHttp   = "Network / API error",
		errorParse  = "Could not parse response",
		done        = "Done",
		chars       = "chars",
		hint        = "Enter — translate · Esc — hide · RightShift — menu",
	},
	ua = {
		brand       = "LINGO",
		tagline     = "перекладач",
		from        = "Звідки",
		to          = "Куди",
		auto        = "Авто",
		placeholder = "Введіть текст для перекладу…",
		result      = "Переклад з’явиться тут",
		translate   = "Перекласти",
		translating = "Перекладаю…",
		swap        = "Поміняти",
		copy        = "Копіювати",
		copied      = "Скопійовано",
		clear       = "Очистити",
		history     = "Історія",
		noHistory   = "Поки порожньо",
		uiLang      = "Мова UI",
		errorEmpty  = "Введіть текст",
		errorHttp   = "Помилка мережі / API",
		errorParse  = "Не вдалося розібрати відповідь",
		done        = "Готово",
		chars       = "симв.",
		hint        = "Enter — перекласти · Esc — сховати · RightShift — меню",
	},
}

-- Translation target languages (code → display)
local LANGS = {
	{ code = "auto", name = "Auto / Авто" },
	{ code = "ru",   name = "Русский" },
	{ code = "en",   name = "English" },
	{ code = "uk",   name = "Українська" },
	{ code = "de",   name = "Deutsch" },
	{ code = "fr",   name = "Français" },
	{ code = "es",   name = "Español" },
	{ code = "it",   name = "Italiano" },
	{ code = "pt",   name = "Português" },
	{ code = "pl",   name = "Polski" },
	{ code = "tr",   name = "Türkçe" },
	{ code = "ar",   name = "العربية" },
	{ code = "zh-CN",name = "中文" },
	{ code = "ja",   name = "日本語" },
	{ code = "ko",   name = "한국어" },
	{ code = "hi",   name = "हिन्दी" },
	{ code = "nl",   name = "Nederlands" },
	{ code = "sv",   name = "Svenska" },
	{ code = "cs",   name = "Čeština" },
	{ code = "ro",   name = "Română" },
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

local function stroke(color: Color3, thickness: number?, parent: Instance?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
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
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function makeDraggable(handle: GuiObject, target: GuiObject)
	local dragging = false
	local startMouse: Vector3
	local startPos: UDim2

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startMouse = input.Position
			startPos = target.Position
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

-- Soft ambient particles behind the card
local function makeAmbient(parent: Frame)
	local layer = new("Frame", {
		Name = "Ambient",
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 0,
	})
	corner(16, layer)

	local orbs = {}
	for i = 1, 5 do
		local size = math.random(80, 160)
		local orb = new("Frame", {
			Parent = layer,
			Size = UDim2.fromOffset(size, size),
			BackgroundColor3 = (i % 2 == 0) and THEME.accent or THEME.accentSoft,
			BackgroundTransparency = 0.92,
			BorderSizePixel = 0,
			ZIndex = 0,
			Position = UDim2.fromOffset(math.random(0, 400), math.random(0, 300)),
		})
		corner(999, orb)
		table.insert(orbs, {
			obj = orb,
			x = orb.Position.X.Offset,
			y = orb.Position.Y.Offset,
			vx = (math.random() - 0.5) * 12,
			vy = (math.random() - 0.5) * 10,
			phase = math.random() * math.pi * 2,
		})
	end

	local conn = RunService.Heartbeat:Connect(function(dt)
		local w = math.max(layer.AbsoluteSize.X, 1)
		local h = math.max(layer.AbsoluteSize.Y, 1)
		for _, o in ipairs(orbs) do
			o.x += o.vx * dt
			o.y += o.vy * dt
			o.phase += dt * 0.7
			if o.x < -80 then o.x = w + 40 end
			if o.x > w + 80 then o.x = -40 end
			if o.y < -80 then o.y = h + 40 end
			if o.y > h + 80 then o.y = -40 end
			local pulse = 0.90 + math.sin(o.phase) * 0.04
			o.obj.BackgroundTransparency = pulse
			o.obj.Position = UDim2.fromOffset(math.floor(o.x), math.floor(o.y))
		end
	end)

	return conn
end

-- ============================================================
-- HTTP / Translate
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

	-- Fallback: HttpService (games with AllowHTTP)
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
	-- Google Translate unofficial endpoint (widely used by executor scripts)
	local url = string.format(
		"https://translate.googleapis.com/translate_a/single?client=gtx&sl=%s&tl=%s&dt=t&q=%s",
		urlEncode(sl),
		urlEncode(tl),
		urlEncode(text)
	)

	local ok, body = httpRequest({
		Url = url,
		Method = "GET",
		Headers = { ["User-Agent"] = "Mozilla/5.0" },
	})

	if not ok or not body or body == "" then
		return false, "", "http"
	end

	-- Response shape: [[["translated","original",...],...],null,"detected"]
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

local function textLen(s: string): number
	local n = utf8 and utf8.len(s)
	return n or #s
end

-- ============================================================
-- Cleanup previous
-- ============================================================
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

-- Soft vignette
local vignette = new("Frame", {
	Parent = gui,
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.72,
	BorderSizePixel = 0,
	ZIndex = 0,
})

local root = new("Frame", {
	Name = "Root",
	Parent = gui,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(560, 520),
	BackgroundColor3 = THEME.bg,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 1,
})
corner(16, root)
stroke(THEME.stroke, 1, root)

local _ambientConn = makeAmbient(root)

-- Top accent line
local accentLine = new("Frame", {
	Parent = root,
	Size = UDim2.new(1, 0, 0, 2),
	BackgroundColor3 = THEME.accent,
	BorderSizePixel = 0,
	ZIndex = 5,
})
new("UIGradient", {
	Parent = accentLine,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.accentSoft),
		ColorSequenceKeypoint.new(0.5, THEME.accentGlow),
		ColorSequenceKeypoint.new(1, THEME.accentSoft),
	}),
})

-- Header
local header = new("Frame", {
	Parent = root,
	Size = UDim2.new(1, 0, 0, 56),
	BackgroundColor3 = THEME.panel,
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
	ZIndex = 2,
})
makeDraggable(header, root)

local brand = new("TextLabel", {
	Name = "Brand",
	Parent = header,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(18, 8),
	Size = UDim2.fromOffset(200, 24),
	Font = THEME.fontBold,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.accentGlow,
	Text = "LINGO",
	ZIndex = 3,
})

local tagline = new("TextLabel", {
	Name = "Tagline",
	Parent = header,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(18, 30),
	Size = UDim2.fromOffset(220, 18),
	Font = THEME.fontLight,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.textMuted,
	Text = t("tagline"),
	ZIndex = 3,
})

-- UI language chips
local uiChipRow = new("Frame", {
	Name = "UiLangs",
	Parent = header,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -52, 0.5, 0),
	Size = UDim2.fromOffset(150, 28),
	BackgroundTransparency = 1,
	ZIndex = 3,
})
new("UIListLayout", {
	Parent = uiChipRow,
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

local uiChips: {[string]: TextButton} = {}

local closeBtn = new("TextButton", {
	Parent = header,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, 0),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = THEME.card,
	Text = "×",
	Font = THEME.fontBold,
	TextSize = 18,
	TextColor3 = THEME.textDim,
	AutoButtonColor = false,
	ZIndex = 4,
})
corner(8, closeBtn)
stroke(THEME.strokeSoft, 1, closeBtn)

-- Body
local body = new("Frame", {
	Parent = root,
	Position = UDim2.fromOffset(0, 56),
	Size = UDim2.new(1, 0, 1, -56),
	BackgroundTransparency = 1,
	ZIndex = 2,
})
pad(16, 18, 14, 18, body)

-- Language selectors row
local langRow = new("Frame", {
	Name = "LangRow",
	Parent = body,
	Size = UDim2.new(1, 0, 0, 64),
	BackgroundTransparency = 1,
	ZIndex = 3,
})

local function makeLangPicker(parent: Frame, labelKey: string, side: string)
	local box = new("Frame", {
		Parent = parent,
		Size = UDim2.new(0.42, 0, 1, 0),
		Position = side == "left" and UDim2.fromScale(0, 0) or UDim2.new(0.58, 0, 0, 0),
		BackgroundColor3 = THEME.card,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
	corner(10, box)
	stroke(THEME.strokeSoft, 1, box)

	local lbl = new("TextLabel", {
		Name = "Caption",
		Parent = box,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -24, 0, 14),
		Font = THEME.fontLight,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.textMuted,
		Text = t(labelKey),
		ZIndex = 4,
	})

	local value = new("TextButton", {
		Name = "Value",
		Parent = box,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 22),
		Size = UDim2.new(1, -36, 0, 30),
		Font = THEME.fontBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.text,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 4,
	})

	local chevron = new("TextLabel", {
		Parent = box,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 6),
		Size = UDim2.fromOffset(16, 16),
		Font = THEME.fontBold,
		TextSize = 12,
		TextColor3 = THEME.accent,
		Text = "▾",
		ZIndex = 4,
	})

	return { Box = box, Caption = lbl, Value = value, Chevron = chevron }
end

local fromPicker = makeLangPicker(langRow, "from", "left")
local toPicker   = makeLangPicker(langRow, "to", "right")

local swapBtn = new("TextButton", {
	Parent = langRow,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.fromOffset(40, 40),
	BackgroundColor3 = THEME.card,
	Text = "⇄",
	Font = THEME.fontBold,
	TextSize = 18,
	TextColor3 = THEME.accent,
	AutoButtonColor = false,
	ZIndex = 5,
})
corner(12, swapBtn)
stroke(THEME.stroke, 1, swapBtn)

-- Input card
local inputCard = new("Frame", {
	Parent = body,
	Position = UDim2.fromOffset(0, 76),
	Size = UDim2.new(1, 0, 0, 130),
	BackgroundColor3 = THEME.card,
	BorderSizePixel = 0,
	ZIndex = 3,
})
corner(12, inputCard)
stroke(THEME.strokeSoft, 1, inputCard)

local inputBox = new("TextBox", {
	Name = "Input",
	Parent = inputCard,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(14, 12),
	Size = UDim2.new(1, -28, 1, -40),
	Font = THEME.font,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = THEME.text,
	PlaceholderColor3 = THEME.textMuted,
	PlaceholderText = t("placeholder"),
	Text = "",
	ClearTextOnFocus = false,
	MultiLine = true,
	TextWrapped = true,
	ZIndex = 4,
})

local charCount = new("TextLabel", {
	Name = "Chars",
	Parent = inputCard,
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -12, 1, -8),
	Size = UDim2.fromOffset(120, 16),
	Font = THEME.fontLight,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = THEME.textMuted,
	Text = "0 " .. t("chars"),
	ZIndex = 4,
})

-- Output card
local outputCard = new("Frame", {
	Parent = body,
	Position = UDim2.fromOffset(0, 218),
	Size = UDim2.new(1, 0, 0, 130),
	BackgroundColor3 = THEME.input,
	BorderSizePixel = 0,
	ZIndex = 3,
})
corner(12, outputCard)
local outStroke = stroke(THEME.strokeSoft, 1, outputCard)

local outputLabel = new("TextLabel", {
	Name = "Output",
	Parent = outputCard,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(14, 12),
	Size = UDim2.new(1, -28, 1, -24),
	Font = THEME.font,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = THEME.textDim,
	Text = t("result"),
	TextWrapped = true,
	ZIndex = 4,
})

-- Action row
local actionRow = new("Frame", {
	Parent = body,
	Position = UDim2.fromOffset(0, 360),
	Size = UDim2.new(1, 0, 0, 42),
	BackgroundTransparency = 1,
	ZIndex = 3,
})
new("UIListLayout", {
	Parent = actionRow,
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

local function makeAction(text: string, primary: boolean?, order: number?): TextButton
	local btn = new("TextButton", {
		Parent = actionRow,
		Size = UDim2.new(primary and 0.38 or 0.2, 0, 1, 0),
		BackgroundColor3 = primary and THEME.accent or THEME.card,
		Text = text,
		Font = THEME.fontBold,
		TextSize = 13,
		TextColor3 = primary and Color3.fromRGB(8, 18, 16) or THEME.text,
		AutoButtonColor = false,
		LayoutOrder = order or 1,
		ZIndex = 4,
	})
	corner(10, btn)
	if not primary then stroke(THEME.strokeSoft, 1, btn) end
	btn.MouseEnter:Connect(function()
		tween(btn, THEME.fast, {
			BackgroundColor3 = primary and THEME.accentGlow or THEME.cardHover,
		})
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, THEME.fast, {
			BackgroundColor3 = primary and THEME.accent or THEME.card,
		})
	end)
	return btn
end

local translateBtn = makeAction(t("translate"), true, 1)
local copyBtn      = makeAction(t("copy"), false, 2)
local clearBtn     = makeAction(t("clear"), false, 3)

-- Status + hint
local statusLbl = new("TextLabel", {
	Name = "Status",
	Parent = body,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 410),
	Size = UDim2.new(1, 0, 0, 16),
	Font = THEME.fontLight,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.textMuted,
	Text = "",
	ZIndex = 3,
})

local hintLbl = new("TextLabel", {
	Name = "Hint",
	Parent = body,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 428),
	Size = UDim2.new(1, 0, 0, 14),
	Font = THEME.fontLight,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.textMuted,
	Text = t("hint"),
	ZIndex = 3,
})

-- History strip
local histTitle = new("TextLabel", {
	Name = "HistTitle",
	Parent = body,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 448),
	Size = UDim2.new(1, 0, 0, 14),
	Font = THEME.fontBold,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.textDim,
	Text = t("history"),
	ZIndex = 3,
})

local histScroll = new("ScrollingFrame", {
	Parent = body,
	Position = UDim2.fromOffset(0, 464),
	Size = UDim2.new(1, 0, 0, 28),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 0,
	ScrollingDirection = Enum.ScrollingDirection.X,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ZIndex = 3,
})
local histLayout = new("UIListLayout", {
	Parent = histScroll,
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

-- ============================================================
-- Dropdown overlay
-- ============================================================
local dropOverlay = new("TextButton", {
	Name = "DropOverlay",
	Parent = root,
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "",
	Visible = false,
	ZIndex = 20,
	AutoButtonColor = false,
})

local dropdown = new("ScrollingFrame", {
	Name = "Dropdown",
	Parent = root,
	Size = UDim2.fromOffset(220, 220),
	BackgroundColor3 = THEME.panel,
	BorderSizePixel = 0,
	Visible = false,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = THEME.accent,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ZIndex = 21,
	ClipsDescendants = true,
})
corner(10, dropdown)
stroke(THEME.stroke, 1, dropdown)
pad(6, 6, 6, 6, dropdown)
local dropLayout = new("UIListLayout", {
	Parent = dropdown,
	Padding = UDim.new(0, 2),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

local dropTarget: string? = nil -- "from" | "to"

local function closeDropdown()
	dropdown.Visible = false
	dropOverlay.Visible = false
	dropTarget = nil
end

local function openDropdown(which: string, anchor: Frame)
	dropTarget = which
	-- Clear old items
	for _, ch in ipairs(dropdown:GetChildren()) do
		if ch:IsA("TextButton") then ch:Destroy() end
	end

	local list = LANGS
	local skipAuto = which == "to"
	local order = 0
	for _, L in ipairs(list) do
		if skipAuto and L.code == "auto" then continue end
		order += 1
		local item = new("TextButton", {
			Parent = dropdown,
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = THEME.card,
			BackgroundTransparency = 1,
			Text = "  " .. L.name,
			Font = THEME.font,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = THEME.text,
			AutoButtonColor = false,
			LayoutOrder = order,
			ZIndex = 22,
		})
		corner(6, item)
		item.MouseEnter:Connect(function()
			item.BackgroundTransparency = 0
			item.BackgroundColor3 = THEME.cardHover
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

	dropdown.CanvasSize = UDim2.fromOffset(0, order * 30 + 12)
	local abs = anchor.AbsolutePosition
	local rootAbs = root.AbsolutePosition
	dropdown.Position = UDim2.fromOffset(
		math.clamp(abs.X - rootAbs.X, 8, 560 - 228),
		math.clamp(abs.Y - rootAbs.Y + anchor.AbsoluteSize.Y + 4, 60, 280)
	)
	dropdown.Visible = true
	dropOverlay.Visible = true
end

dropOverlay.MouseButton1Click:Connect(closeDropdown)
fromPicker.Value.MouseButton1Click:Connect(function()
	openDropdown("from", fromPicker.Box)
end)
fromPicker.Box.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		openDropdown("from", fromPicker.Box)
	end
end)
toPicker.Value.MouseButton1Click:Connect(function()
	openDropdown("to", toPicker.Box)
end)
toPicker.Box.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		openDropdown("to", toPicker.Box)
	end
end)

-- ============================================================
-- UI refresh / i18n apply
-- ============================================================
local function refreshHistory()
	for _, ch in ipairs(histScroll:GetChildren()) do
		if ch:IsA("TextButton") then ch:Destroy() end
	end
	if #state.history == 0 then
		local empty = new("TextLabel", {
			Parent = histScroll,
			Size = UDim2.fromOffset(140, 24),
			BackgroundTransparency = 1,
			Font = THEME.fontLight,
			TextSize = 11,
			TextColor3 = THEME.textMuted,
			Text = t("noHistory"),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 4,
		})
		histScroll.CanvasSize = UDim2.fromOffset(140, 0)
		return
	end

	local totalW = 0
	for i = #state.history, 1, -1 do
		local h = state.history[i]
		local preview = h.src
		if #preview > 28 then preview = string.sub(preview, 1, 28) .. "…" end
		local chip = new("TextButton", {
			Parent = histScroll,
			Size = UDim2.fromOffset(0, 24),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = THEME.card,
			Text = "  " .. preview .. "  ",
			Font = THEME.fontLight,
			TextSize = 11,
			TextColor3 = THEME.textDim,
			AutoButtonColor = false,
			LayoutOrder = #state.history - i,
			ZIndex = 4,
		})
		corner(8, chip)
		stroke(THEME.strokeSoft, 1, chip)
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
		totalW += 100
	end
	histScroll.CanvasSize = UDim2.fromOffset(math.max(totalW, 200), 0)
end

local function applyUiLang()
	tagline.Text = t("tagline")
	fromPicker.Caption.Text = t("from")
	toPicker.Caption.Text = t("to")
	fromPicker.Value.Text = state.fromCode == "auto" and t("auto") or langName(state.fromCode)
	toPicker.Value.Text = langName(state.toCode)
	inputBox.PlaceholderText = t("placeholder")
	if outputLabel.TextColor3 == THEME.textDim then
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
		chip.BackgroundColor3 = active and THEME.accent or THEME.card
		chip.TextColor3 = active and Color3.fromRGB(8, 18, 16) or THEME.textDim
	end
	refreshHistory()
end

-- Build UI language chips
for i, code in ipairs(UI_LANGS) do
	local chip = new("TextButton", {
		Parent = uiChipRow,
		Size = UDim2.fromOffset(36, 26),
		BackgroundColor3 = THEME.card,
		Text = string.upper(code),
		Font = THEME.fontBold,
		TextSize = 11,
		TextColor3 = THEME.textDim,
		AutoButtonColor = false,
		LayoutOrder = i,
		ZIndex = 4,
	})
	corner(7, chip)
	stroke(THEME.strokeSoft, 1, chip)
	chip.MouseButton1Click:Connect(function()
		state.uiLang = code
		applyUiLang()
		statusLbl.Text = t("uiLang") .. ": " .. string.upper(code)
		statusLbl.TextColor3 = THEME.accent
		task.delay(1.2, function()
			if statusLbl then statusLbl.Text = "" end
		end)
	end)
	uiChips[code] = chip
end

-- ============================================================
-- Interactions
-- ============================================================
local function setStatus(msg: string, color: Color3?)
	statusLbl.Text = msg
	statusLbl.TextColor3 = color or THEME.textMuted
end

local function pulseOutput(ok: boolean)
	outStroke.Color = ok and THEME.accent or THEME.danger
	tween(outStroke, THEME.med, { Color = THEME.strokeSoft })
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
	outputLabel.TextColor3 = THEME.textDim

	task.spawn(function()
		local ok, result, detected = translateText(text, state.fromCode, state.toCode)
		state.busy = false
		translateBtn.Text = t("translate")

		if not ok then
			local errKey = (detected == "parse") and "errorParse" or "errorHttp"
			setStatus(t(errKey), THEME.danger)
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
			src = text,
			dst = result,
			from = fromShown,
			to = state.toCode,
		})
		if #state.history > 12 then
			table.remove(state.history, 1)
		end
		refreshHistory()
		setStatus(t("done"), THEME.ok)
		task.delay(1.5, function()
			if statusLbl.Text == t("done") then statusLbl.Text = "" end
		end)
	end)
end

translateBtn.MouseButton1Click:Connect(doTranslate)

swapBtn.MouseButton1Click:Connect(function()
	-- Don't swap if from is auto — keep auto, just flip texts if we have output
	local a, b = state.fromCode, state.toCode
	if a == "auto" then
		-- swap text boxes only
		local tmp = inputBox.Text
		if outputLabel.TextColor3 == THEME.text then
			inputBox.Text = outputLabel.Text
			outputLabel.Text = tmp
		end
	else
		state.fromCode, state.toCode = b, a
		fromPicker.Value.Text = langName(state.fromCode)
		toPicker.Value.Text = langName(state.toCode)
		local tmp = inputBox.Text
		if outputLabel.TextColor3 == THEME.text then
			inputBox.Text = outputLabel.Text
			outputLabel.Text = tmp
		end
	end
	-- Spin feel
	tween(swapBtn, THEME.fast, { Rotation = 180 })
	task.delay(0.2, function()
		swapBtn.Rotation = 0
	end)
	charCount.Text = tostring(textLen(inputBox.Text)) .. " " .. t("chars")
end)

copyBtn.MouseButton1Click:Connect(function()
	local txt = outputLabel.Text
	if outputLabel.TextColor3 == THEME.textDim or txt == "" then
		setStatus(t("errorEmpty"), THEME.danger)
		return
	end
	local ok = pcall(function()
		if setclipboard then
			setclipboard(txt)
		elseif toclipboard then
			toclipboard(txt)
		elseif Clipboard and Clipboard.set then
			Clipboard.set(txt)
		else
			error("no clipboard")
		end
	end)
	if ok then
		copyBtn.Text = t("copied")
		setStatus(t("copied"), THEME.ok)
		task.delay(1.2, function()
			copyBtn.Text = t("copy")
		end)
	else
		-- Fallback: select via notify
		setStatus("Clipboard unavailable — select & Ctrl+C", THEME.danger)
	end
end)

clearBtn.MouseButton1Click:Connect(function()
	inputBox.Text = ""
	outputLabel.Text = t("result")
	outputLabel.TextColor3 = THEME.textDim
	charCount.Text = "0 " .. t("chars")
	setStatus("")
end)

inputBox:GetPropertyChangedSignal("Text"):Connect(function()
	charCount.Text = tostring(textLen(inputBox.Text)) .. " " .. t("chars")
end)

-- Hover polish on swap / close
swapBtn.MouseEnter:Connect(function()
	tween(swapBtn, THEME.fast, { BackgroundColor3 = THEME.cardHover })
end)
swapBtn.MouseLeave:Connect(function()
	tween(swapBtn, THEME.fast, { BackgroundColor3 = THEME.card })
end)
closeBtn.MouseEnter:Connect(function()
	tween(closeBtn, THEME.fast, { BackgroundColor3 = THEME.danger, TextColor3 = THEME.text })
end)
closeBtn.MouseLeave:Connect(function()
	tween(closeBtn, THEME.fast, { BackgroundColor3 = THEME.card, TextColor3 = THEME.textDim })
end)

local function setVisible(v: boolean)
	state.visible = v
	root.Visible = v
	vignette.Visible = v
	if v then
		root.Size = UDim2.fromOffset(520, 480)
		root.BackgroundTransparency = 0.4
		tween(root, THEME.slow, {
			Size = UDim2.fromOffset(560, 520),
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
		if dropdown.Visible then
			closeDropdown()
		else
			setVisible(false)
		end
		return
	end
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.Return and not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		-- Translate on Enter when not multiline-shift
		if inputBox:IsFocused() then
			doTranslate()
		end
	end
end)

-- Entrance animation
root.Size = UDim2.fromOffset(480, 440)
root.BackgroundTransparency = 0.5
vignette.BackgroundTransparency = 1
tween(root, THEME.slow, {
	Size = UDim2.fromOffset(560, 520),
	BackgroundTransparency = 0,
})
tween(vignette, THEME.slow, { BackgroundTransparency = 0.72 })

applyUiLang()
setStatus("")

print("[LINGO] Translator loaded · RightShift to toggle · UI: RU/EN/UA")
return gui
