--[[
	lingo — переводчик для экзекютора
	языки ui: ru / en / ua
	RightShift — скрыть/показать, тащи за шапку
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- цвета / твина (текущая тема лежит в THEME, паки ниже)
local THEME = {}

local THEME_PACKS = {
	apricot = {
		nameKey = "themeApricot",
		bg = Color3.fromRGB(11, 12, 16),
		panel = Color3.fromRGB(17, 18, 24),
		elevated = Color3.fromRGB(24, 26, 34),
		field = Color3.fromRGB(15, 16, 22),
		fieldAlt = Color3.fromRGB(20, 22, 30),
		hover = Color3.fromRGB(32, 34, 44),
		line = Color3.fromRGB(48, 50, 62),
		lineSoft = Color3.fromRGB(36, 38, 48),
		accent = Color3.fromRGB(255, 156, 102),
		accentDeep = Color3.fromRGB(210, 110, 70),
		accentSoft = Color3.fromRGB(255, 186, 140),
		inkOnAccent = Color3.fromRGB(28, 16, 10),
		ok = Color3.fromRGB(110, 200, 150),
		danger = Color3.fromRGB(235, 100, 110),
		text = Color3.fromRGB(240, 236, 230),
		textDim = Color3.fromRGB(160, 156, 150),
		textMute = Color3.fromRGB(105, 102, 98),
	},
	mint = {
		nameKey = "themeMint",
		bg = Color3.fromRGB(10, 14, 14),
		panel = Color3.fromRGB(14, 20, 20),
		elevated = Color3.fromRGB(22, 32, 30),
		field = Color3.fromRGB(12, 18, 17),
		fieldAlt = Color3.fromRGB(18, 26, 24),
		hover = Color3.fromRGB(28, 40, 38),
		line = Color3.fromRGB(40, 58, 54),
		lineSoft = Color3.fromRGB(32, 46, 44),
		accent = Color3.fromRGB(72, 210, 180),
		accentDeep = Color3.fromRGB(40, 150, 130),
		accentSoft = Color3.fromRGB(130, 235, 210),
		inkOnAccent = Color3.fromRGB(8, 22, 18),
		ok = Color3.fromRGB(110, 210, 160),
		danger = Color3.fromRGB(235, 100, 110),
		text = Color3.fromRGB(230, 242, 238),
		textDim = Color3.fromRGB(150, 170, 165),
		textMute = Color3.fromRGB(95, 115, 110),
	},
	ocean = {
		nameKey = "themeOcean",
		bg = Color3.fromRGB(9, 12, 18),
		panel = Color3.fromRGB(14, 18, 28),
		elevated = Color3.fromRGB(22, 28, 42),
		field = Color3.fromRGB(12, 16, 24),
		fieldAlt = Color3.fromRGB(18, 24, 36),
		hover = Color3.fromRGB(30, 38, 55),
		line = Color3.fromRGB(42, 52, 72),
		lineSoft = Color3.fromRGB(32, 40, 58),
		accent = Color3.fromRGB(90, 160, 255),
		accentDeep = Color3.fromRGB(50, 100, 200),
		accentSoft = Color3.fromRGB(150, 195, 255),
		inkOnAccent = Color3.fromRGB(8, 16, 32),
		ok = Color3.fromRGB(100, 210, 170),
		danger = Color3.fromRGB(235, 100, 110),
		text = Color3.fromRGB(230, 236, 245),
		textDim = Color3.fromRGB(150, 160, 180),
		textMute = Color3.fromRGB(100, 110, 130),
	},
	rose = {
		nameKey = "themeRose",
		bg = Color3.fromRGB(14, 10, 12),
		panel = Color3.fromRGB(22, 14, 18),
		elevated = Color3.fromRGB(34, 22, 28),
		field = Color3.fromRGB(18, 12, 15),
		fieldAlt = Color3.fromRGB(26, 18, 22),
		hover = Color3.fromRGB(42, 28, 34),
		line = Color3.fromRGB(60, 40, 48),
		lineSoft = Color3.fromRGB(46, 32, 38),
		accent = Color3.fromRGB(255, 120, 150),
		accentDeep = Color3.fromRGB(200, 70, 100),
		accentSoft = Color3.fromRGB(255, 170, 190),
		inkOnAccent = Color3.fromRGB(30, 10, 16),
		ok = Color3.fromRGB(120, 200, 150),
		danger = Color3.fromRGB(240, 90, 100),
		text = Color3.fromRGB(245, 230, 235),
		textDim = Color3.fromRGB(175, 150, 160),
		textMute = Color3.fromRGB(120, 100, 110),
	},
}

local THEME_ORDER = { "apricot", "mint", "ocean", "rose" }

-- как окно ездит по экрану
local MOTION_STYLES = {
	smooth = { nameKey = "motionSmooth", follow = 18, friction = 8, dragScale = 1.018, inertia = true },
	snappy = { nameKey = "motionSnappy", follow = 42, friction = 14, dragScale = 1.01, inertia = true },
	heavy = { nameKey = "motionHeavy", follow = 8, friction = 4, dragScale = 1.03, inertia = true },
	float = { nameKey = "motionFloat", follow = 12, friction = 3, dragScale = 1.025, inertia = true },
	instant = { nameKey = "motionInstant", follow = 80, friction = 30, dragScale = 1.0, inertia = false },
}
local MOTION_ORDER = { "smooth", "snappy", "heavy", "float", "instant" }

-- анимация открытия/закрытия
local ANIM_STYLES = {
	spring = { nameKey = "animSpring" },
	slide = { nameKey = "animSlide" },
	fade = { nameKey = "animFade" },
	pop = { nameKey = "animPop" },
	none = { nameKey = "animNone" },
}
local ANIM_ORDER = { "spring", "slide", "fade", "pop", "none" }

local function copyTheme(id)
	local pack = THEME_PACKS[id] or THEME_PACKS.apricot
	for k, v in pairs(pack) do
		if k ~= "nameKey" then
			THEME[k] = v
		end
	end
	THEME.font = Enum.Font.GothamMedium
	THEME.fontBold = Enum.Font.GothamBold
	THEME.fontBlack = Enum.Font.GothamBlack
	THEME.fontLight = Enum.Font.Gotham
	THEME.fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	THEME.med = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	THEME.slow = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	THEME.spring = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	THEME.soft = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	THEME.close = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
end

copyTheme("apricot")

-- состояние (объявляем рано — drag/плазма замыкают именно этот local)
local state = {
	uiLang = "ru",
	fromCode = "auto",
	toCode = "en",
	busy = false,
	history = {},
	visible = true,
	themeId = "apricot",
	motionId = "smooth",
	animId = "spring",
	snow = true,
	settingsOpen = false,
	outputPlaceholder = true,
}

local WIN_W, WIN_H = 580, 540
local MIN_W, MIN_H = 420, 420
local MAX_W, MAX_H = 1100, 900
local winSize = { w = WIN_W, h = WIN_H }

-- тексты интерфейса
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
		hint        = "тяни края · шапку · RightShift",
		settings    = "Настройки",
		theme       = "Тема",
		motion      = "Перемещение",
		anim        = "Анимация",
		themeApricot = "Абрикос",
		themeMint    = "Мята",
		themeOcean   = "Океан",
		themeRose    = "Роза",
		motionSmooth = "Плавно",
		motionSnappy = "Резко",
		motionHeavy  = "Тяжело",
		motionFloat  = "Парит",
		motionInstant= "Мгновенно",
		animSpring = "Пружина",
		animSlide  = "Слайд",
		animFade   = "Фейд",
		animPop    = "Поп",
		animNone   = "Без аним.",
		back       = "Назад",
		snow       = "Снег / пыль",
		on         = "Вкл",
		off        = "Выкл",
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
		hint        = "drag edges · header · RightShift",
		settings    = "Settings",
		theme       = "Theme",
		motion      = "Movement",
		anim        = "Animation",
		themeApricot = "Apricot",
		themeMint    = "Mint",
		themeOcean   = "Ocean",
		themeRose    = "Rose",
		motionSmooth = "Smooth",
		motionSnappy = "Snappy",
		motionHeavy  = "Heavy",
		motionFloat  = "Float",
		motionInstant= "Instant",
		animSpring = "Spring",
		animSlide  = "Slide",
		animFade   = "Fade",
		animPop    = "Pop",
		animNone   = "None",
		back       = "Back",
		snow       = "Snow / dust",
		on         = "On",
		off        = "Off",
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
		hint        = "тягни краї · шапку · RightShift",
		settings    = "Налаштування",
		theme       = "Тема",
		motion      = "Переміщення",
		anim        = "Анімація",
		themeApricot = "Абрикос",
		themeMint    = "М’ята",
		themeOcean   = "Океан",
		themeRose    = "Троянда",
		motionSmooth = "Плавно",
		motionSnappy = "Різко",
		motionHeavy  = "Важко",
		motionFloat  = "Парить",
		motionInstant= "Миттєво",
		animSpring = "Пружина",
		animSlide  = "Слайд",
		animFade   = "Фейд",
		animPop    = "Поп",
		animNone   = "Без анім.",
		back       = "Назад",
		snow       = "Сніг / пил",
		on         = "Увімк",
		off        = "Вимк",
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

local LANG_MAP = {}
for _, L in ipairs(LANGS) do
	LANG_MAP[L.code] = L.name
end

local function langName(code)
	return LANG_MAP[code] or code
end

-- мелочи
local function new(class, props, kids)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			inst[k] = v
		end
	end
	if kids then
		for _, c in ipairs(kids) do
			c.Parent = inst
		end
	end
	return inst
end

local function corner(r, parent)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	if parent then c.Parent = parent end
	return c
end

local function stroke(color, thickness, parent, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	if parent then s.Parent = parent end
	return s
end

local function pad(t, r, b, l, parent)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t)
	p.PaddingRight = UDim.new(0, r or t)
	p.PaddingBottom = UDim.new(0, b or t)
	p.PaddingLeft = UDim.new(0, l or r or t)
	if parent then p.Parent = parent end
	return p
end

local function tween(obj, info, props)
	local tw = TweenService:Create(obj, info, props)
	tw:Play()
	return tw
end

-- анимация кнопок при наведении/клике (opts можно обновлять при смене темы)
local function bindPressFeel(btn, opts)
	opts = opts or {}
	local hovering = false

	local scale = btn:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = btn
	end

	btn.MouseEnter:Connect(function()
		hovering = true
		local hoverScale = opts.hoverScale or 1.03
		tween(scale, THEME.fast, { Scale = hoverScale })
		if opts.hoverColor then
			tween(btn, THEME.fast, { BackgroundColor3 = opts.hoverColor })
		end
	end)
	btn.MouseLeave:Connect(function()
		hovering = false
		tween(scale, THEME.med, { Scale = 1 })
		if opts.baseColor then
			tween(btn, THEME.fast, { BackgroundColor3 = opts.baseColor })
		end
	end)
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			tween(scale, THEME.fast, { Scale = opts.pressScale or 0.96 })
		end
	end)
	btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			local hoverScale = opts.hoverScale or 1.03
			tween(scale, THEME.med, { Scale = hovering and hoverScale or 1 })
		end
	end)
	return opts
end

-- плавное перетаскивание + инерция
local dragSmooth = {
	active = false,
	frozen = false,
	goalX = 0,
	goalY = 0,
	curX = 0,
	curY = 0,
	velX = 0,
	velY = 0,
	scale = 0.5,
	follow = 18,
	friction = 8,
}

local function syncDragFromTarget(target)
	local p = target.Position
	dragSmooth.scale = p.X.Scale
	dragSmooth.curX = p.X.Offset
	dragSmooth.curY = p.Y.Offset
	dragSmooth.goalX = p.X.Offset
	dragSmooth.goalY = p.Y.Offset
	dragSmooth.velX = 0
	dragSmooth.velY = 0
end

local resizeLooks = {}
local brandMarkGrad, translateGrad, swapStroke
local segStroke, closeStroke, settingsStroke
local fromStroke, toStroke

local function posFromSmooth()
	return UDim2.new(dragSmooth.scale, dragSmooth.curX, dragSmooth.scale, dragSmooth.curY)
end

local function makeDraggable(handle, target, onDragState)
	handle.Active = true
	handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local startMouse = input.Position
		local startPos = target.Position
		local moving = true
		local moveConn
		local endConn

		dragSmooth.active = true
		dragSmooth.scale = startPos.X.Scale
		dragSmooth.curX = startPos.X.Offset
		dragSmooth.curY = startPos.Y.Offset
		dragSmooth.goalX = startPos.X.Offset
		dragSmooth.goalY = startPos.Y.Offset
		dragSmooth.velX = 0
		dragSmooth.velY = 0

		if onDragState then onDragState(true) end

		local lastMouse = startMouse
		moveConn = UserInputService.InputChanged:Connect(function(changed)
			if not moving then return end
			if changed.UserInputType ~= Enum.UserInputType.MouseMovement
				and changed.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local d = changed.Position - startMouse
			dragSmooth.goalX = startPos.X.Offset + d.X
			dragSmooth.goalY = startPos.Y.Offset + d.Y
			local md = changed.Position - lastMouse
			dragSmooth.velX = md.X * 60
			dragSmooth.velY = md.Y * 60
			lastMouse = changed.Position
		end)

		endConn = UserInputService.InputEnded:Connect(function(ended)
			if ended.UserInputType == Enum.UserInputType.MouseButton1
				or ended.UserInputType == Enum.UserInputType.Touch then
				moving = false
				dragSmooth.active = false
				moveConn:Disconnect()
				endConn:Disconnect()
				if onDragState then onDragState(false) end
			end
		end)
	end)
end

-- двигаем окно каждый кадр
RunService.RenderStepped:Connect(function(dt)
	dt = math.clamp(dt, 0, 0.05)
	local ds = dragSmooth
	if ds.frozen then return end

	local style = MOTION_STYLES[state.motionId] or MOTION_STYLES.smooth
	ds.follow = style.follow
	ds.friction = style.friction

	if ds.active then
		if not style.inertia then
			ds.curX = ds.goalX
			ds.curY = ds.goalY
			ds.velX = 0
			ds.velY = 0
		else
			local ax = (ds.goalX - ds.curX) * ds.follow
			local ay = (ds.goalY - ds.curY) * ds.follow
			ds.velX = ds.velX + (ax - ds.velX) * math.clamp(dt * 20, 0, 1)
			ds.velY = ds.velY + (ay - ds.velY) * math.clamp(dt * 20, 0, 1)
			ds.curX += ds.velX * dt
			ds.curY += ds.velY * dt
			ds.curX += (ds.goalX - ds.curX) * math.clamp(dt * ds.follow, 0, 1)
			ds.curY += (ds.goalY - ds.curY) * math.clamp(dt * ds.follow, 0, 1)
		end
	elseif style.inertia and (math.abs(ds.velX) > 2 or math.abs(ds.velY) > 2) then
		ds.curX += ds.velX * dt
		ds.curY += ds.velY * dt
		local damp = math.exp(-ds.friction * dt)
		ds.velX *= damp
		ds.velY *= damp
	else
		return
	end

	if dragSmooth.apply then
		dragSmooth.apply(posFromSmooth())
	end
end)

-- стрелки по краям
local ARROW = {
	l = "◀", r = "▶", t = "▲", b = "▼",
	tl = "◤", tr = "◥", bl = "◣", br = "◢",
}

local function makeResizeHandle(parent, target, edge, sizeState)
	local EDGE = 10
	local CORNER = 16

	local props = {
		Parent = parent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 50,
		Name = "Resize_" .. edge,
	}

	if edge == "l" then
		props.Size = UDim2.new(0, EDGE, 1, -CORNER * 2)
		props.Position = UDim2.new(0, 0, 0, CORNER)
	elseif edge == "r" then
		props.Size = UDim2.new(0, EDGE, 1, -CORNER * 2)
		props.Position = UDim2.new(1, 0, 0, CORNER)
		props.AnchorPoint = Vector2.new(1, 0)
	elseif edge == "t" then
		props.Size = UDim2.new(1, -CORNER * 2, 0, EDGE)
		props.Position = UDim2.new(0, CORNER, 0, 0)
	elseif edge == "b" then
		props.Size = UDim2.new(1, -CORNER * 2, 0, EDGE)
		props.Position = UDim2.new(0, CORNER, 1, 0)
		props.AnchorPoint = Vector2.new(0, 1)
	elseif edge == "tl" then
		props.Size = UDim2.fromOffset(CORNER, CORNER)
		props.Position = UDim2.fromScale(0, 0)
	elseif edge == "tr" then
		props.Size = UDim2.fromOffset(CORNER, CORNER)
		props.Position = UDim2.new(1, 0, 0, 0)
		props.AnchorPoint = Vector2.new(1, 0)
	elseif edge == "bl" then
		props.Size = UDim2.fromOffset(CORNER, CORNER)
		props.Position = UDim2.new(0, 0, 1, 0)
		props.AnchorPoint = Vector2.new(0, 1)
	elseif edge == "br" then
		props.Size = UDim2.fromOffset(CORNER, CORNER)
		props.Position = UDim2.new(1, 0, 1, 0)
		props.AnchorPoint = Vector2.new(1, 1)
	end

	local handle = new("Frame", props)

	local chip = new("Frame", {
		Parent = handle,
		BackgroundColor3 = THEME.accent,
		BackgroundTransparency = 0.78,
		BorderSizePixel = 0,
		ZIndex = 51,
	})
	corner(4, chip)

	local isSide = edge == "l" or edge == "r" or edge == "t" or edge == "b"
	local arrow = new("TextLabel", {
		Parent = handle,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = THEME.fontBold,
		TextSize = isSide and 14 or 16,
		TextColor3 = THEME.accent,
		TextTransparency = 0.35,
		Text = ARROW[edge] or "•",
		ZIndex = 52,
	})

	if edge == "l" or edge == "r" then
		chip.AnchorPoint = Vector2.new(0.5, 0.5)
		chip.Position = UDim2.fromScale(0.5, 0.5)
		chip.Size = UDim2.new(0, 3, 0, 36)
	elseif edge == "t" or edge == "b" then
		chip.AnchorPoint = Vector2.new(0.5, 0.5)
		chip.Position = UDim2.fromScale(0.5, 0.5)
		chip.Size = UDim2.new(0, 36, 0, 3)
	else
		chip.Size = UDim2.fromScale(1, 1)
		chip.BackgroundTransparency = 0.85
	end

	local baseChipT = (edge == "l" or edge == "r" or edge == "t" or edge == "b") and 0.78 or 0.85
	local baseArrowSize = isSide and 14 or 16
	local resizing = false

	handle.MouseEnter:Connect(function()
		if resizing then return end
		tween(chip, THEME.fast, { BackgroundTransparency = 0.35 })
		tween(arrow, THEME.fast, { TextTransparency = 0, TextSize = baseArrowSize + 2 })
	end)
	handle.MouseLeave:Connect(function()
		if resizing then return end
		tween(chip, THEME.med, { BackgroundTransparency = baseChipT })
		tween(arrow, THEME.med, { TextTransparency = 0.35, TextSize = baseArrowSize })
	end)

	local hasL = edge == "l" or edge == "tl" or edge == "bl"
	local hasR = edge == "r" or edge == "tr" or edge == "br"
	local hasT = edge == "t" or edge == "tl" or edge == "tr"
	local hasB = edge == "b" or edge == "bl" or edge == "br"

	handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local startMouse = input.Position
		local startSize = Vector2.new(target.AbsoluteSize.X, target.AbsoluteSize.Y)
		local startPos = target.Position
		resizing = true
		local moveConn
		local endConn
		tween(chip, THEME.fast, { BackgroundTransparency = 0.15 })
		tween(arrow, THEME.fast, { TextTransparency = 0 })

		moveConn = UserInputService.InputChanged:Connect(function(changed)
			if not resizing then return end
			if changed.UserInputType ~= Enum.UserInputType.MouseMovement
				and changed.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			local d = changed.Position - startMouse
			local dw = hasR and d.X or (hasL and -d.X or 0)
			local dh = hasB and d.Y or (hasT and -d.Y or 0)
			local nw = math.clamp(startSize.X + dw, MIN_W, MAX_W)
			local nh = math.clamp(startSize.Y + dh, MIN_H, MAX_H)
			local appliedDw = nw - startSize.X
			local appliedDh = nh - startSize.Y

			local ox = hasL and (-appliedDw / 2) or (hasR and (appliedDw / 2) or 0)
			local oy = hasT and (-appliedDh / 2) or (hasB and (appliedDh / 2) or 0)

			sizeState.w = nw
			sizeState.h = nh
			target.Size = UDim2.fromOffset(nw, nh)
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + ox,
				startPos.Y.Scale, startPos.Y.Offset + oy
			)
			syncDragFromTarget(target)
		end)

		endConn = UserInputService.InputEnded:Connect(function(ended)
			if ended.UserInputType == Enum.UserInputType.MouseButton1
				or ended.UserInputType == Enum.UserInputType.Touch then
				resizing = false
				moveConn:Disconnect()
				endConn:Disconnect()
				syncDragFromTarget(target)
				tween(chip, THEME.med, { BackgroundTransparency = baseChipT })
				tween(arrow, THEME.med, { TextTransparency = 0.35 })
			end
		end)
	end)

	resizeLooks[#resizeLooks + 1] = { chip = chip, arrow = arrow }
	return handle
end

local function textLen(s)
	local n = utf8 and utf8.len(s)
	return n or #s
end

local function utf8Sub(s, maxChars)
	if not s or s == "" then return "" end
	if not utf8 or not utf8.offset then
		return string.sub(s, 1, maxChars)
	end
	local len = utf8.len(s)
	if not len or len <= maxChars then return s end
	local stop = utf8.offset(s, maxChars + 1)
	if not stop then return s end
	return string.sub(s, 1, stop - 1)
end

-- плазма на фоне (не каждый кадр, чтоб не лагало)
local function makeAtmosphere(parent)
	local layer = new("Frame", {
		Name = "Plasma",
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 0,
	})
	corner(24, layer)

	local wash = new("Frame", {
		Parent = layer,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = THEME.bg,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 0,
	})
	local washGrad = new("UIGradient", {
		Parent = wash,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 14, 22)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(40, 22, 28)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 18, 32)),
		}),
		Rotation = 35,
	})

	local ribbons = {}
	local ribbonDefs = {
		{ y = 0.08, h = 0.22, rot = -8,  c1 = THEME.accentDeep, c2 = Color3.fromRGB(80, 40, 90), t = 0.82 },
		{ y = 0.38, h = 0.28, rot = 12,  c1 = Color3.fromRGB(50, 70, 130), c2 = THEME.accent, t = 0.86 },
		{ y = 0.62, h = 0.24, rot = -14, c1 = THEME.accent, c2 = Color3.fromRGB(90, 50, 70), t = 0.84 },
		{ y = 0.82, h = 0.2,  rot = 6,   c1 = Color3.fromRGB(35, 50, 90), c2 = THEME.accentDeep, t = 0.88 },
	}
	for i, d in ipairs(ribbonDefs) do
		local band = new("Frame", {
			Parent = layer,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, d.y, 0),
			Size = UDim2.new(1.35, 0, d.h, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = d.t,
			BorderSizePixel = 0,
			Rotation = d.rot,
			ZIndex = 0,
		})
		corner(18, band)
		local g = new("UIGradient", {
			Parent = band,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, d.c1),
				ColorSequenceKeypoint.new(0.5, d.c2),
				ColorSequenceKeypoint.new(1, d.c1),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.55),
				NumberSequenceKeypoint.new(0.5, 0.05),
				NumberSequenceKeypoint.new(1, 0.55),
			}),
		})
		ribbons[i] = {
			band = band,
			grad = g,
			baseY = d.y,
			baseRot = d.rot,
			baseT = d.t,
			phase = i * 1.7,
			speed = 0.35 + i * 0.08,
		}
	end

	local COLS, ROWS = 10, 8
	local grid = new("Frame", {
		Parent = layer,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 0,
	})
	local cells = table.create(COLS * ROWS)
	local n = 0
	for row = 0, ROWS - 1 do
		for col = 0, COLS - 1 do
			n += 1
			local cell = new("Frame", {
				Parent = grid,
				Size = UDim2.new(1 / COLS, 1, 1 / ROWS, 1),
				Position = UDim2.new(col / COLS, 0, row / ROWS, 0),
				BackgroundColor3 = THEME.accent,
				BackgroundTransparency = 0.94,
				BorderSizePixel = 0,
				ZIndex = 0,
			})
			corner(4, cell)
			cells[n] = {
				obj = cell,
				nx = col / (COLS - 1),
				ny = row / (ROWS - 1),
				lastIdx = -1,
			}
		end
	end

	-- снежинки / пыль поверх
	local FLAKE_N = 28
	local snowLayer = new("Frame", {
		Name = "Snow",
		Parent = layer,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 1,
	})
	corner(24, snowLayer)
	local flakes = table.create(FLAKE_N)
	for i = 1, FLAKE_N do
		local sz = (math.random() < 0.55) and 2 or (math.random() < 0.8 and 3 or 4)
		local warm = math.random() < 0.35
		local flake = new("Frame", {
			Parent = snowLayer,
			Size = UDim2.fromOffset(sz, sz),
			BackgroundColor3 = warm and Color3.fromRGB(255, 210, 180) or Color3.fromRGB(245, 245, 250),
			BackgroundTransparency = 0.35 + math.random() * 0.45,
			BorderSizePixel = 0,
			ZIndex = 1,
			Position = UDim2.fromScale(math.random(), math.random()),
		})
		corner(99, flake)
		flakes[i] = {
			obj = flake,
			x = math.random(),
			y = math.random(),
			vy = 0.04 + math.random() * 0.08,
			vx = (math.random() - 0.5) * 0.04,
			phase = math.random() * 6.28,
			baseT = flake.BackgroundTransparency,
			sz = sz,
		}
	end

	local pal = {
		Color3.fromRGB(28, 18, 40),
		Color3.fromRGB(70, 35, 55),
		THEME.accentDeep,
		THEME.accent,
		Color3.fromRGB(90, 110, 180),
		Color3.fromRGB(40, 55, 100),
	}
	-- палитра цветов заранее, чтоб не считать каждый тик
	local LUT_N = 48
	local colorLut = table.create(LUT_N)
	local transLut = table.create(LUT_N)
	for i = 1, LUT_N do
		local v = (i - 1) / (LUT_N - 1)
		local scaled = v * (#pal - 1)
		local pi = math.floor(scaled) + 1
		local f = scaled - math.floor(scaled)
		colorLut[i] = pal[pi]:Lerp(pal[math.min(pi + 1, #pal)], f)
		transLut[i] = 0.88 + (1 - v) * 0.08
	end

	local controller = { enabled = true }
	local t0 = os.clock()
	local acc = 0
	local STEP = 1 / 14

	local conn = RunService.Heartbeat:Connect(function(dt)
		if not controller.enabled then return end

		-- снег каждый кадр, их мало
		if state.snow then
			for i = 1, FLAKE_N do
				local f = flakes[i]
				f.phase += dt * (1.2 + f.sz * 0.2)
				f.y += f.vy * dt
				f.x += (f.vx + math.sin(f.phase) * 0.03) * dt
				if f.y > 1.05 then
					f.y = -0.05
					f.x = math.random()
				end
				if f.x < -0.05 then f.x = 1.05 end
				if f.x > 1.05 then f.x = -0.05 end
				f.obj.Position = UDim2.fromScale(f.x, f.y)
				f.obj.BackgroundTransparency = math.clamp(f.baseT + math.sin(f.phase) * 0.12, 0.2, 0.92)
			end
		end

		acc += dt
		if acc < STEP then return end
		if acc > STEP * 3 then acc = STEP end
		acc -= STEP

		local t = (os.clock() - t0) * 0.85
		washGrad.Rotation = 35 + math.sin(t * 0.25) * 18

		for i = 1, #ribbons do
			local r = ribbons[i]
			local wave = math.sin(t * r.speed + r.phase)
			r.band.Rotation = r.baseRot + wave * 10
			r.band.Position = UDim2.new(0.5 + math.sin(t * 0.2 + r.phase) * 0.06, 0, r.baseY + wave * 0.03, 0)
			r.band.BackgroundTransparency = r.baseT + wave * 0.04
			r.grad.Offset = Vector2.new(math.sin(t * 0.4 + r.phase) * 0.35, 0)
		end

		for i = 1, n do
			local c = cells[i]
			local x, y = c.nx, c.ny
			local v = math.sin(x * 6.2 + t)
				+ math.sin(y * 5.1 + t * 1.25)
				+ math.sin((x + y) * 4.4 + t * 0.8)
				+ math.sin(math.sqrt(x * x + y * y) * 7.0 + t * 1.1)
			local idx = math.floor(((v + 4) / 8) * (LUT_N - 1) + 0.5) + 1
			if idx < 1 then idx = 1 elseif idx > LUT_N then idx = LUT_N end
			if idx ~= c.lastIdx then
				c.lastIdx = idx
				c.obj.BackgroundColor3 = colorLut[idx]
				c.obj.BackgroundTransparency = transLut[idx]
			end
		end
	end)

	controller.connection = conn
	function controller.setEnabled(on)
		controller.enabled = on
	end
	function controller.setSnow(on)
		snowLayer.Visible = on and true or false
	end
	snowLayer.Visible = state.snow
	return controller
end

-- перевод (с кэшем)
local httpFn = (syn and syn.request)
	or (http and http.request)
	or http_request
	or request
	or (fluxus and fluxus.request)

local translateCache = {}
local CACHE_MAX = 40
local cacheOrder = {}

local function cacheGet(key)
	return translateCache[key]
end

local function cacheSet(key, text, detected)
	if not translateCache[key] then
		table.insert(cacheOrder, key)
		if #cacheOrder > CACHE_MAX then
			local old = table.remove(cacheOrder, 1)
			if old then translateCache[old] = nil end
		end
	end
	translateCache[key] = { text = text, detected = detected }
end

local function httpRequest(opts)
	if httpFn then
		local ok, res = pcall(httpFn, opts)
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

local function urlEncode(s)
	s = s:gsub("\n", " ")
	return (s:gsub("([^%w%-_%.%~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

local function translateText(text, sl, tl)
	local cacheKey = sl .. "|" .. tl .. "|" .. text
	local hit = cacheGet(cacheKey)
	if hit then
		return true, hit.text, hit.detected
	end

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

	local out = table.create(#chunks)
	for i, part in ipairs(chunks) do
		if type(part) == "table" and type(part[1]) == "string" then
			out[#out + 1] = part[1]
		end
	end
	local result = table.concat(out)
	if result == "" then
		return false, "", "parse"
	end
	local det = typeof(detected) == "string" and detected or nil
	cacheSet(cacheKey, result, det)
	return true, result, det
end

-- состояние уже выше
local applyTheme, applyMotion, refreshSettingsLabels, openSettings, applyUiLang
local feelOpts = {}

local function t(key)
	local pack = I18N[state.uiLang] or I18N.ru
	return pack[key] or key
end

do
	local prev = playerGui:FindFirstChild("LingoTranslator")
	if prev then prev:Destroy() end
end

-- ui
local gui = new("ScreenGui", {
	Name = "LingoTranslator",
	Parent = playerGui,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
	DisplayOrder = 100,
})

-- обводка вокруг окна
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
local rootStroke = stroke(THEME.line, 1, root, 0.25)

local rootScale = Instance.new("UIScale")
rootScale.Scale = 1
rootScale.Parent = root

dragSmooth.apply = function(pos)
	root.Position = pos
end
do
	local p = root.Position
	dragSmooth.scale = p.X.Scale
	dragSmooth.curX = p.X.Offset
	dragSmooth.curY = p.Y.Offset
	dragSmooth.goalX = p.X.Offset
	dragSmooth.goalY = p.Y.Offset
end

local haloStroke = halo:FindFirstChildOfClass("UIStroke")

-- ресайз по краям
for _, edge in ipairs({ "l", "r", "t", "b", "tl", "tr", "bl", "br" }) do
	makeResizeHandle(root, root, edge, winSize)
end

local function syncHalo()
	halo.Position = root.Position
	halo.Size = UDim2.fromOffset(root.AbsoluteSize.X + 18, root.AbsoluteSize.Y + 18)
	halo.Visible = root.Visible
end
root:GetPropertyChangedSignal("Position"):Connect(syncHalo)
root:GetPropertyChangedSignal("Size"):Connect(syncHalo)
root:GetPropertyChangedSignal("Visible"):Connect(syncHalo)
syncHalo()

local atm = nil

-- блик сверху
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

-- шапка
local header = new("Frame", {
	Parent = root,
	Size = UDim2.new(1, 0, 0, 72),
	BackgroundTransparency = 1,
	Active = true,
	ZIndex = 3,
})

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

local function onWindowDrag(dragging)
	local style = MOTION_STYLES[state.motionId] or MOTION_STYLES.smooth
	local sc = style.dragScale or 1.018
	if dragging then
		tween(rootScale, THEME.fast, { Scale = sc })
		if haloStroke then
			tween(haloStroke, THEME.fast, { Transparency = 0.5, Thickness = 3.4 })
		end
		tween(grip, THEME.fast, {
			BackgroundColor3 = THEME.accent,
			BackgroundTransparency = 0.15,
			Size = UDim2.fromOffset(54, 5),
		})
	else
		tween(rootScale, THEME.spring, { Scale = 1 })
		if haloStroke then
			tween(haloStroke, THEME.med, { Transparency = 0.88, Thickness = 2.5 })
		end
		tween(grip, THEME.med, {
			BackgroundColor3 = THEME.textMute,
			BackgroundTransparency = 0.4,
			Size = UDim2.fromOffset(42, 4),
		})
	end
end

makeDraggable(header, root, onWindowDrag)
makeDraggable(grip, root, onWindowDrag)

local brandMark = new("Frame", {
	Parent = header,
	Position = UDim2.fromOffset(22, 26),
	Size = UDim2.fromOffset(10, 28),
	BackgroundColor3 = THEME.accent,
	BorderSizePixel = 0,
	ZIndex = 4,
})
corner(4, brandMark)
brandMarkGrad = new("UIGradient", {
	Parent = brandMark,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.accentSoft),
		ColorSequenceKeypoint.new(1, THEME.accentDeep),
	}),
	Rotation = 90,
})

atm = makeAtmosphere(root)

local brand = new("TextLabel", {
	Parent = header,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(42, 22),
	Size = UDim2.fromOffset(140, 28),
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
	Size = UDim2.fromOffset(150, 16),
	Font = THEME.fontLight,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.textMute,
	Text = t("tagline"),
	ZIndex = 4,
})

-- переключатель языка ui (слева от ⚙ и ✕)
local seg = new("Frame", {
	Parent = header,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -96, 0.5, 6),
	Size = UDim2.fromOffset(118, 32),
	BackgroundColor3 = THEME.elevated,
	BorderSizePixel = 0,
	ZIndex = 4,
})
corner(10, seg)
segStroke = stroke(THEME.lineSoft, 1, seg, 0.2)
new("UIListLayout", {
	Parent = seg,
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 2),
	SortOrder = Enum.SortOrder.LayoutOrder,
})
pad(3, 3, 3, 3, seg)

local uiChips = {}

local settingsBtn = new("TextButton", {
	Parent = header,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -54, 0.5, 6),
	Size = UDim2.fromOffset(32, 32),
	BackgroundColor3 = THEME.elevated,
	Text = "⚙",
	Font = THEME.fontBold,
	TextSize = 14,
	TextColor3 = THEME.textDim,
	AutoButtonColor = false,
	ZIndex = 5,
})
corner(10, settingsBtn)
settingsStroke = stroke(THEME.lineSoft, 1, settingsBtn, 0.25)

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
closeStroke = stroke(THEME.lineSoft, 1, closeBtn, 0.25)

-- линия под шапкой
local divider = new("Frame", {
	Parent = root,
	Position = UDim2.fromOffset(22, 72),
	Size = UDim2.new(1, -44, 0, 1),
	BackgroundColor3 = THEME.lineSoft,
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	ZIndex = 3,
})

-- контент
local body = new("Frame", {
	Parent = root,
	Position = UDim2.fromOffset(0, 80),
	Size = UDim2.new(1, 0, 1, -80),
	BackgroundTransparency = 1,
	ZIndex = 3,
})
pad(8, 22, 18, 22, body)

-- откуда / куда
local langRow = new("Frame", {
	Parent = body,
	Size = UDim2.new(1, 0, 0, 56),
	BackgroundTransparency = 1,
	ZIndex = 4,
})

local function makeLangPicker(side)
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
	local boxStroke = stroke(THEME.lineSoft, 1, box, 0.15)

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
	bindPressFeel(box, { hoverScale = 1.015, pressScale = 0.985 })

	return { Box = box, Caption = cap, Value = val, Chevron = chev, Stroke = boxStroke }
end

local fromPicker = makeLangPicker("left")
local toPicker   = makeLangPicker("right")
fromStroke = fromPicker.Stroke
toStroke = toPicker.Stroke

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
swapStroke = stroke(THEME.accent, 1.2, swapBtn, 0.55)

-- поля ввода/вывода (тянутся вместе с окном)
-- langRow 56 + gap ~12 = 68; footer 120 → fields = bodyH - 68 - 120 = bodyH - 188
local fields = new("Frame", {
	Parent = body,
	Position = UDim2.fromOffset(0, 68),
	Size = UDim2.new(1, 0, 1, -188),
	BackgroundTransparency = 1,
	ZIndex = 4,
})

local inputCard = new("Frame", {
	Parent = fields,
	Size = UDim2.new(1, 0, 0.5, -6),
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
	Parent = fields,
	Position = UDim2.new(0, 0, 0.5, 6),
	Size = UDim2.new(1, 0, 0.5, -6),
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
	TextTransparency = 0,
	ZIndex = 5,
})

local outRevealToken = 0
local function cancelTextReveal()
	outRevealToken += 1
end

local function revealText(label, full, color)
	cancelTextReveal()
	local token = outRevealToken
	state.outputPlaceholder = false
	label.TextColor3 = color
	label.TextTransparency = 0.55
	label.Position = UDim2.fromOffset(16, 34)
	label.Text = ""

	tween(label, THEME.soft, {
		Position = UDim2.fromOffset(16, 26),
		TextTransparency = 0,
	})

	task.spawn(function()
		-- печатаем текст по кускам
		local chars = {}
		if utf8 and utf8.len(full) then
			for _, code in utf8.codes(full) do
				chars[#chars + 1] = utf8.char(code)
			end
		else
			for i = 1, #full do
				chars[i] = string.sub(full, i, i)
			end
		end
		local total = #chars
		if total == 0 then
			if token == outRevealToken then label.Text = full end
			return
		end
		local step = math.max(1, math.floor(total / 40))
		local i = 0
		while i < total do
			if token ~= outRevealToken then return end
			i = math.min(i + step, total)
			label.Text = table.concat(chars, "", 1, i)
			task.wait(0.012)
		end
		if token == outRevealToken then
			label.Text = full
			label.TextTransparency = 0
		end
	end)
end

local translatePulse = false
local function setTranslatePulse(on)
	translatePulse = on
	if on then
		task.spawn(function()
			local dots = 0
			while translatePulse do
				dots = (dots % 3) + 1
				outputLabel.Text = t("translating") .. string.rep(".", dots)
				outputLabel.TextColor3 = THEME.textMute
				outputLabel.TextTransparency = 0.15
				tween(outStroke, THEME.fast, { Color = THEME.accent, Transparency = 0.4 })
				task.wait(0.28)
				if not translatePulse then break end
				tween(outStroke, THEME.fast, { Color = THEME.lineSoft, Transparency = 0.1 })
				task.wait(0.12)
			end
		end)
	else
		tween(outStroke, THEME.med, { Color = THEME.lineSoft, Transparency = 0.1 })
	end
end

-- низ: кнопки + история
local footer = new("Frame", {
	Parent = body,
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 120),
	BackgroundTransparency = 1,
	ZIndex = 4,
})

-- кнопки
local actionRow = new("Frame", {
	Parent = footer,
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
translateGrad = new("UIGradient", {
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
	Parent = footer,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 52),
	Size = UDim2.new(0.55, 0, 0, 16),
	Font = THEME.fontLight,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.textMute,
	Text = "",
	ZIndex = 4,
})

local hintLbl = new("TextLabel", {
	Parent = footer,
	BackgroundTransparency = 1,
	Position = UDim2.new(0.45, 0, 0, 52),
	Size = UDim2.new(0.55, 0, 0, 16),
	Font = THEME.fontLight,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = THEME.textMute,
	Text = t("hint"),
	ZIndex = 4,
})

local histTitle = new("TextLabel", {
	Parent = footer,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 74),
	Size = UDim2.new(1, 0, 0, 14),
	Font = THEME.fontBold,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.textDim,
	Text = t("history"),
	ZIndex = 4,
})

local histScroll = new("ScrollingFrame", {
	Parent = footer,
	Position = UDim2.fromOffset(0, 90),
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

-- настройки
local settingsPanel = new("ScrollingFrame", {
	Parent = root,
	Position = UDim2.fromOffset(0, 72),
	Size = UDim2.new(1, 0, 1, -72),
	BackgroundColor3 = THEME.bg,
	BackgroundTransparency = 0.08,
	Visible = false,
	ZIndex = 25,
	ClipsDescendants = true,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = THEME.accent,
	CanvasSize = UDim2.fromOffset(0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
})
corner(24, settingsPanel)
pad(16, 22, 18, 22, settingsPanel)

local settingsTitle = new("TextLabel", {
	Parent = settingsPanel,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -80, 0, 28),
	Font = THEME.fontBlack,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.text,
	Text = t("settings"),
	ZIndex = 26,
})

local backBtn = new("TextButton", {
	Parent = settingsPanel,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 0),
	Size = UDim2.fromOffset(72, 28),
	BackgroundColor3 = THEME.elevated,
	Text = t("back"),
	Font = THEME.fontBold,
	TextSize = 12,
	TextColor3 = THEME.text,
	AutoButtonColor = false,
	ZIndex = 26,
})
corner(8, backBtn)
stroke(THEME.lineSoft, 1, backBtn, 0.2)

local function makeSettingsSection(titleKey, y)
	local lbl = new("TextLabel", {
		Parent = settingsPanel,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, 18),
		Font = THEME.fontBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.textDim,
		Text = t(titleKey),
		ZIndex = 26,
	})
	local row = new("Frame", {
		Parent = settingsPanel,
		Position = UDim2.fromOffset(0, y + 22),
		Size = UDim2.new(1, 0, 0, 76),
		BackgroundTransparency = 1,
		ZIndex = 26,
	})
	new("UIListLayout", {
		Parent = row,
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Wraps = true,
	})
	return lbl, row
end

local themeLbl, themeRow = makeSettingsSection("theme", 44)
local motionLbl, motionRow = makeSettingsSection("motion", 140)
local animLbl, animRow = makeSettingsSection("anim", 236)

local snowLbl = new("TextLabel", {
	Parent = settingsPanel,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 332),
	Size = UDim2.new(0.5, 0, 0, 18),
	Font = THEME.fontBold,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.textDim,
	Text = t("snow"),
	ZIndex = 26,
})

local snowBtn = new("TextButton", {
	Parent = settingsPanel,
	Position = UDim2.fromOffset(0, 354),
	Size = UDim2.fromOffset(90, 32),
	BackgroundColor3 = THEME.accent,
	Text = t("on"),
	Font = THEME.fontBold,
	TextSize = 12,
	TextColor3 = THEME.inkOnAccent,
	AutoButtonColor = false,
	ZIndex = 26,
})
corner(10, snowBtn)

local settingsHint = new("TextLabel", {
	Parent = settingsPanel,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 400),
	Size = UDim2.new(1, 0, 0, 48),
	Font = THEME.fontLight,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = THEME.textMute,
	TextWrapped = true,
	Text = "",
	ZIndex = 26,
})

local themeChips = {}
local motionChips = {}
local animChips = {}

local function styleChip(btn, active)
	if active then
		btn.BackgroundColor3 = THEME.accent
		btn.TextColor3 = THEME.inkOnAccent
	else
		btn.BackgroundColor3 = THEME.elevated
		btn.TextColor3 = THEME.textDim
	end
end

refreshSettingsLabels = function()
	settingsTitle.Text = t("settings")
	backBtn.Text = t("back")
	themeLbl.Text = t("theme")
	motionLbl.Text = t("motion")
	animLbl.Text = t("anim")
	snowLbl.Text = t("snow")
	snowBtn.Text = state.snow and t("on") or t("off")
	styleChip(snowBtn, state.snow)
	for id, btn in pairs(themeChips) do
		btn.Text = "  " .. t(THEME_PACKS[id].nameKey) .. "  "
		styleChip(btn, id == state.themeId)
	end
	for id, btn in pairs(motionChips) do
		btn.Text = "  " .. t(MOTION_STYLES[id].nameKey) .. "  "
		styleChip(btn, id == state.motionId)
	end
	for id, btn in pairs(animChips) do
		btn.Text = "  " .. t(ANIM_STYLES[id].nameKey) .. "  "
		styleChip(btn, id == state.animId)
	end
	local m = MOTION_STYLES[state.motionId]
	local a = ANIM_STYLES[state.animId]
	settingsHint.Text = t(m.nameKey) .. " · " .. t(a.nameKey)
end

local function makeOptChip(parent, id, label, order, store, onPick)
	local btn = new("TextButton", {
		Parent = parent,
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = THEME.elevated,
		Text = "  " .. label .. "  ",
		Font = THEME.fontBold,
		TextSize = 11,
		TextColor3 = THEME.textDim,
		AutoButtonColor = false,
		LayoutOrder = order,
		ZIndex = 27,
	})
	corner(9, btn)
	stroke(THEME.lineSoft, 1, btn, 0.25)
	btn.MouseButton1Click:Connect(function()
		onPick(id)
	end)
	store[id] = btn
	return btn
end

for i, id in ipairs(THEME_ORDER) do
	makeOptChip(themeRow, id, t(THEME_PACKS[id].nameKey), i, themeChips, function(picked)
		state.themeId = picked
		applyTheme(picked)
		refreshSettingsLabels()
	end)
end
for i, id in ipairs(MOTION_ORDER) do
	makeOptChip(motionRow, id, t(MOTION_STYLES[id].nameKey), i, motionChips, function(picked)
		state.motionId = picked
		applyMotion(picked)
		refreshSettingsLabels()
	end)
end
for i, id in ipairs(ANIM_ORDER) do
	makeOptChip(animRow, id, t(ANIM_STYLES[id].nameKey), i, animChips, function(picked)
		state.animId = picked
		refreshSettingsLabels()
	end)
end

-- выпадающий список языков
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

local dropTarget = nil

local function closeDropdown()
	dropdown.Visible = false
	dropOverlay.Visible = false
	dropTarget = nil
end

local function openDropdown(which, anchor)
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
		math.clamp(abs.X - rootAbs.X, 12, math.max(winSize.w - 242, 12)),
		math.clamp(abs.Y - rootAbs.Y + anchor.AbsoluteSize.Y + 6, 70, math.max(winSize.h - 260, 70))
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

-- история и язык ui
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
	local histLayout = histScroll:FindFirstChildOfClass("UIListLayout")
	for i = #state.history, 1, -1 do
		local h = state.history[i]
		local preview = h.src
		if textLen(preview) > 22 then
			preview = utf8Sub(preview, 22) .. "…"
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
			revealText(outputLabel, h.dst, THEME.text)
			state.fromCode = h.from
			state.toCode = h.to
			fromPicker.Value.Text = h.from == "auto" and t("auto") or langName(h.from)
			toPicker.Value.Text = langName(h.to)
			charCount.Text = tostring(textLen(inputBox.Text)) .. " " .. t("chars")
		end)
	end
	task.defer(function()
		if histLayout then
			histScroll.CanvasSize = UDim2.fromOffset(math.max(histLayout.AbsoluteContentSize.X + 8, 220), 0)
		end
	end)
end

applyUiLang = function()
	tagline.Text = t("tagline")
	fromPicker.Caption.Text = t("from")
	toPicker.Caption.Text = t("to")
	fromPicker.Value.Text = state.fromCode == "auto" and t("auto") or langName(state.fromCode)
	toPicker.Value.Text = langName(state.toCode)
	inputBox.PlaceholderText = t("placeholder")
	if state.outputPlaceholder then
		outputLabel.Text = t("result")
		outputLabel.TextColor3 = THEME.textMute
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
	if refreshSettingsLabels then refreshSettingsLabels() end
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

-- применить тему / движение
applyMotion = function(id)
	state.motionId = id or state.motionId
	local style = MOTION_STYLES[state.motionId] or MOTION_STYLES.smooth
	dragSmooth.follow = style.follow
	dragSmooth.friction = style.friction
	if not style.inertia then
		dragSmooth.velX = 0
		dragSmooth.velY = 0
	end
end

applyTheme = function(id)
	state.themeId = id or state.themeId
	copyTheme(state.themeId)

	root.BackgroundColor3 = THEME.bg
	if rootStroke then rootStroke.Color = THEME.line end
	if haloStroke then haloStroke.Color = THEME.accent end
	settingsPanel.BackgroundColor3 = THEME.bg
	settingsPanel.ScrollBarImageColor3 = THEME.accent
	brand.TextColor3 = THEME.text
	tagline.TextColor3 = THEME.textMute
	brandMark.BackgroundColor3 = THEME.accent
	if brandMarkGrad then
		brandMarkGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.accentSoft),
			ColorSequenceKeypoint.new(1, THEME.accentDeep),
		})
	end
	grip.BackgroundColor3 = THEME.textMute
	seg.BackgroundColor3 = THEME.elevated
	if segStroke then segStroke.Color = THEME.lineSoft end
	closeBtn.BackgroundColor3 = THEME.elevated
	closeBtn.TextColor3 = THEME.textDim
	if closeStroke then closeStroke.Color = THEME.lineSoft end
	settingsBtn.BackgroundColor3 = THEME.elevated
	settingsBtn.TextColor3 = THEME.textDim
	if settingsStroke then settingsStroke.Color = THEME.lineSoft end
	divider.BackgroundColor3 = THEME.lineSoft

	inputCard.BackgroundColor3 = THEME.field
	outputCard.BackgroundColor3 = THEME.fieldAlt
	if inStroke then inStroke.Color = THEME.lineSoft end
	if outStroke then outStroke.Color = THEME.lineSoft end
	inputBox.TextColor3 = THEME.text
	inputBox.PlaceholderColor3 = THEME.textMute
	charCount.TextColor3 = THEME.textMute
	outBadge.TextColor3 = THEME.accent
	if state.outputPlaceholder then
		outputLabel.TextColor3 = THEME.textMute
	end

	translateBtn.BackgroundColor3 = THEME.accent
	translateBtn.TextColor3 = THEME.inkOnAccent
	if translateGrad then
		translateGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.accentSoft),
			ColorSequenceKeypoint.new(1, THEME.accent),
		})
	end
	copyBtn.BackgroundColor3 = THEME.elevated
	copyBtn.TextColor3 = THEME.text
	clearBtn.BackgroundColor3 = THEME.elevated
	clearBtn.TextColor3 = THEME.textDim
	swapBtn.BackgroundColor3 = THEME.field
	swapBtn.TextColor3 = THEME.accent
	if swapStroke then swapStroke.Color = THEME.accent end
	fromPicker.Box.BackgroundColor3 = THEME.elevated
	toPicker.Box.BackgroundColor3 = THEME.elevated
	if fromStroke then fromStroke.Color = THEME.lineSoft end
	if toStroke then toStroke.Color = THEME.lineSoft end
	fromPicker.Caption.TextColor3 = THEME.textMute
	toPicker.Caption.TextColor3 = THEME.textMute
	fromPicker.Value.TextColor3 = THEME.text
	toPicker.Value.TextColor3 = THEME.text
	fromPicker.Chevron.TextColor3 = THEME.accent
	toPicker.Chevron.TextColor3 = THEME.accent

	statusLbl.TextColor3 = THEME.textMute
	hintLbl.TextColor3 = THEME.textMute
	histTitle.TextColor3 = THEME.textDim
	settingsTitle.TextColor3 = THEME.text
	backBtn.BackgroundColor3 = THEME.elevated
	backBtn.TextColor3 = THEME.text
	themeLbl.TextColor3 = THEME.textDim
	motionLbl.TextColor3 = THEME.textDim
	animLbl.TextColor3 = THEME.textDim
	snowLbl.TextColor3 = THEME.textMute
	settingsHint.TextColor3 = THEME.textMute
	dropdown.BackgroundColor3 = THEME.panel
	dropdown.ScrollBarImageColor3 = THEME.accent

	for _, look in ipairs(resizeLooks) do
		if look.chip then look.chip.BackgroundColor3 = THEME.accent end
		if look.arrow then look.arrow.TextColor3 = THEME.accent end
	end

	if feelOpts.translate then
		feelOpts.translate.baseColor = THEME.accent
		feelOpts.translate.hoverColor = THEME.accentSoft
	end
	if feelOpts.swap then
		feelOpts.swap.baseColor = THEME.field
		feelOpts.swap.hoverColor = THEME.hover
	end
	if feelOpts.copy then
		feelOpts.copy.baseColor = THEME.elevated
		feelOpts.copy.hoverColor = THEME.hover
	end
	if feelOpts.clear then
		feelOpts.clear.baseColor = THEME.elevated
		feelOpts.clear.hoverColor = THEME.hover
	end
	if feelOpts.close then
		feelOpts.close.baseColor = THEME.elevated
		feelOpts.close.hoverColor = THEME.danger
	end
	if feelOpts.settings then
		feelOpts.settings.baseColor = THEME.elevated
		feelOpts.settings.hoverColor = THEME.hover
	end
	if feelOpts.back then
		feelOpts.back.baseColor = THEME.elevated
		feelOpts.back.hoverColor = THEME.hover
	end

	-- сначала отключаем тик, потом удаляем плазму
	if atm and atm.connection then
		pcall(function() atm.connection:Disconnect() end)
		atm.connection = nil
	end
	local oldPlasma = root:FindFirstChild("Plasma")
	if oldPlasma then oldPlasma:Destroy() end
	atm = makeAtmosphere(root)
	if atm.setSnow then atm.setSnow(state.snow) end

	if refreshSettingsLabels then refreshSettingsLabels() end
	if applyUiLang then applyUiLang() end
end

openSettings = function(on)
	if on and closeDropdown then closeDropdown() end
	state.settingsOpen = on
	settingsPanel.Visible = on
	body.Visible = not on
	if on then
		settingsPanel.BackgroundTransparency = 0.4
		tween(settingsPanel, THEME.soft, { BackgroundTransparency = 0.08 })
		refreshSettingsLabels()
	end
end

-- клики / хоткеи
local function setStatus(msg, color)
	statusLbl.Text = msg
	statusLbl.TextColor3 = color or THEME.textMute
end

local function pulseOutput(okFlag)
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
	cancelTextReveal()
	setTranslatePulse(true)

	task.spawn(function()
		local ok, result, detected = translateText(text, state.fromCode, state.toCode)
		state.busy = false
		translateBtn.Text = t("translate")
		setTranslatePulse(false)

		if not ok then
			state.outputPlaceholder = false
			setStatus(t(detected == "parse" and "errorParse" or "errorHttp"), THEME.danger)
			pulseOutput(false)
			outputLabel.Text = t(detected == "parse" and "errorParse" or "errorHttp")
			outputLabel.TextColor3 = THEME.danger
			outputLabel.TextTransparency = 0
			return
		end

		revealText(outputLabel, result, THEME.text)
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
feelOpts.translate = bindPressFeel(translateBtn, {
	hoverScale = 1.025,
	pressScale = 0.97,
	baseColor = THEME.accent,
	hoverColor = THEME.accentSoft,
})

swapBtn.MouseButton1Click:Connect(function()
	if state.fromCode == "auto" then
		local tmp = inputBox.Text
		if not state.outputPlaceholder then
			inputBox.Text = outputLabel.Text
			outputLabel.Text = tmp
			state.outputPlaceholder = (tmp == nil or tmp:match("^%s*$") ~= nil)
			if state.outputPlaceholder then
				outputLabel.Text = t("result")
				outputLabel.TextColor3 = THEME.textMute
			else
				outputLabel.TextColor3 = THEME.text
			end
		end
	else
		state.fromCode, state.toCode = state.toCode, state.fromCode
		fromPicker.Value.Text = langName(state.fromCode)
		toPicker.Value.Text = langName(state.toCode)
		local tmp = inputBox.Text
		if not state.outputPlaceholder then
			inputBox.Text = outputLabel.Text
			outputLabel.Text = tmp
			state.outputPlaceholder = (tmp == nil or tmp:match("^%s*$") ~= nil)
			if state.outputPlaceholder then
				outputLabel.Text = t("result")
				outputLabel.TextColor3 = THEME.textMute
			else
				outputLabel.TextColor3 = THEME.text
			end
		end
	end
	local s = swapBtn:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", swapBtn)
	s.Scale = 0.9
	tween(s, THEME.spring, { Scale = 1 })
	tween(swapBtn, THEME.fast, { Rotation = 180 })
	task.delay(0.22, function()
		swapBtn.Rotation = 0
	end)
	charCount.Text = tostring(textLen(inputBox.Text)) .. " " .. t("chars")
end)
feelOpts.swap = bindPressFeel(swapBtn, {
	hoverScale = 1.08,
	pressScale = 0.92,
	baseColor = THEME.field,
	hoverColor = THEME.hover,
})

copyBtn.MouseButton1Click:Connect(function()
	local txt = outputLabel.Text
	if state.outputPlaceholder or txt == "" then
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
feelOpts.copy = bindPressFeel(copyBtn, {
	baseColor = THEME.elevated,
	hoverColor = THEME.hover,
})

clearBtn.MouseButton1Click:Connect(function()
	inputBox.Text = ""
	cancelTextReveal()
	state.outputPlaceholder = true
	outputLabel.Text = t("result")
	outputLabel.TextColor3 = THEME.textMute
	outputLabel.TextTransparency = 0
	charCount.Text = "0 " .. t("chars")
	setStatus("")
end)
feelOpts.clear = bindPressFeel(clearBtn, {
	baseColor = THEME.elevated,
	hoverColor = THEME.hover,
})

inputBox:GetPropertyChangedSignal("Text"):Connect(function()
	charCount.Text = tostring(textLen(inputBox.Text)) .. " " .. t("chars")
end)

inputBox.Focused:Connect(function()
	tween(inStroke, THEME.fast, { Color = THEME.accent, Transparency = 0.35 })
end)
inputBox.FocusLost:Connect(function()
	tween(inStroke, THEME.fast, { Color = THEME.lineSoft, Transparency = 0.1 })
end)

feelOpts.close = bindPressFeel(closeBtn, {
	hoverScale = 1.08,
	pressScale = 0.9,
	baseColor = THEME.elevated,
	hoverColor = THEME.danger,
})
closeBtn.MouseEnter:Connect(function()
	tween(closeBtn, THEME.fast, { TextColor3 = THEME.text })
end)
closeBtn.MouseLeave:Connect(function()
	tween(closeBtn, THEME.fast, { TextColor3 = THEME.textDim })
end)

local animatingVis = false
local pendingVis = nil
local setVisible

local function finishVisAnim()
	animatingVis = false
	dragSmooth.frozen = false
	syncDragFromTarget(root)
	if pendingVis ~= nil then
		local next = pendingVis
		pendingVis = nil
		if next ~= state.visible or root.Visible ~= next then
			setVisible(next)
		end
	end
end

setVisible = function(v)
	if animatingVis then
		pendingVis = v
		return
	end
	if v == state.visible and root.Visible == v then return end

	local anim = state.animId or "spring"
	dragSmooth.frozen = true
	dragSmooth.velX = 0
	dragSmooth.velY = 0
	dragSmooth.active = false

	if v then
		animatingVis = true
		state.visible = true
		root.Visible = true
		halo.Visible = true
		if atm then atm.setEnabled(true) end

		local w, h = winSize.w, winSize.h
		local p = root.Position

		if anim == "none" then
			root.Size = UDim2.fromOffset(w, h)
			root.BackgroundTransparency = 0
			rootScale.Scale = 1
			root.Position = p
			brand.TextTransparency = 0
			tagline.TextTransparency = 0
			outputLabel.TextTransparency = 0
			if haloStroke then haloStroke.Transparency = 0.88 end
			finishVisAnim()
		elseif anim == "fade" then
			root.Size = UDim2.fromOffset(w, h)
			root.Position = p
			rootScale.Scale = 1
			root.BackgroundTransparency = 1
			brand.TextTransparency = 1
			tagline.TextTransparency = 1
			outputLabel.TextTransparency = 1
			if haloStroke then haloStroke.Transparency = 1 end
			tween(root, THEME.soft, { BackgroundTransparency = 0 })
			tween(brand, THEME.soft, { TextTransparency = 0 })
			tween(tagline, THEME.soft, { TextTransparency = 0 })
			tween(outputLabel, THEME.soft, { TextTransparency = 0 })
			if haloStroke then tween(haloStroke, THEME.soft, { Transparency = 0.88 }) end
			task.delay(0.35, finishVisAnim)
		elseif anim == "slide" then
			root.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + 80)
			root.Size = UDim2.fromOffset(w, h)
			rootScale.Scale = 1
			root.BackgroundTransparency = 0.3
			tween(root, THEME.soft, { Position = p, BackgroundTransparency = 0 })
			brand.TextTransparency = 0
			tagline.TextTransparency = 0
			outputLabel.TextTransparency = 0
			if haloStroke then
				haloStroke.Transparency = 1
				tween(haloStroke, THEME.soft, { Transparency = 0.88 })
			end
			task.delay(0.4, finishVisAnim)
		elseif anim == "pop" then
			root.Position = p
			root.Size = UDim2.fromOffset(w, h)
			rootScale.Scale = 0.7
			root.BackgroundTransparency = 0.4
			tween(rootScale, THEME.spring, { Scale = 1 })
			tween(root, THEME.spring, { BackgroundTransparency = 0 })
			brand.TextTransparency = 0
			tagline.TextTransparency = 0
			outputLabel.TextTransparency = 0
			if haloStroke then
				haloStroke.Transparency = 1
				tween(haloStroke, THEME.soft, { Transparency = 0.88 })
			end
			task.delay(0.45, finishVisAnim)
		else
			-- spring
			root.Size = UDim2.fromOffset(math.max(w - 36, MIN_W), math.max(h - 28, MIN_H))
			root.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + 28)
			rootScale.Scale = 0.88
			root.BackgroundTransparency = 0.55
			if haloStroke then haloStroke.Transparency = 1 end
			outputLabel.TextTransparency = 1
			brand.TextTransparency = 1
			tagline.TextTransparency = 1
			tween(root, THEME.spring, {
				Size = UDim2.fromOffset(w, h),
				BackgroundTransparency = 0,
				Position = p,
			})
			tween(rootScale, THEME.spring, { Scale = 1 })
			if haloStroke then tween(haloStroke, THEME.soft, { Transparency = 0.88 }) end
			tween(brand, THEME.soft, { TextTransparency = 0 })
			tween(tagline, THEME.soft, { TextTransparency = 0 })
			tween(outputLabel, THEME.soft, { TextTransparency = 0 })
			task.delay(0.45, finishVisAnim)
		end
	else
		animatingVis = true
		state.visible = false
		if state.settingsOpen then openSettings(false) end
		local p = root.Position

		if anim == "none" then
			root.Visible = false
			halo.Visible = false
			if atm then atm.setEnabled(false) end
			root.Position = p
			finishVisAnim()
		elseif anim == "fade" then
			tween(root, THEME.close, { BackgroundTransparency = 1 })
			tween(brand, THEME.close, { TextTransparency = 1 })
			tween(tagline, THEME.close, { TextTransparency = 1 })
			tween(outputLabel, THEME.close, { TextTransparency = 1 })
			if haloStroke then tween(haloStroke, THEME.close, { Transparency = 1 }) end
			task.delay(0.28, function()
				root.Visible = false
				halo.Visible = false
				if atm then atm.setEnabled(false) end
				root.BackgroundTransparency = 0
				brand.TextTransparency = 0
				tagline.TextTransparency = 0
				outputLabel.TextTransparency = 0
				if haloStroke then haloStroke.Transparency = 0.88 end
				root.Position = p
				finishVisAnim()
			end)
		elseif anim == "slide" then
			tween(root, THEME.close, {
				Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + 70),
				BackgroundTransparency = 0.5,
			})
			if haloStroke then tween(haloStroke, THEME.close, { Transparency = 1 }) end
			task.delay(0.3, function()
				root.Visible = false
				halo.Visible = false
				if atm then atm.setEnabled(false) end
				root.Position = p
				root.BackgroundTransparency = 0
				if haloStroke then haloStroke.Transparency = 0.88 end
				finishVisAnim()
			end)
		elseif anim == "pop" then
			tween(rootScale, THEME.close, { Scale = 0.75 })
			tween(root, THEME.close, { BackgroundTransparency = 0.7 })
			if haloStroke then tween(haloStroke, THEME.close, { Transparency = 1 }) end
			task.delay(0.28, function()
				root.Visible = false
				halo.Visible = false
				if atm then atm.setEnabled(false) end
				rootScale.Scale = 1
				root.BackgroundTransparency = 0
				if haloStroke then haloStroke.Transparency = 0.88 end
				finishVisAnim()
			end)
		else
			tween(rootScale, THEME.close, { Scale = 0.9 })
			tween(root, THEME.close, {
				BackgroundTransparency = 0.7,
				Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + 22),
			})
			if haloStroke then tween(haloStroke, THEME.close, { Transparency = 1 }) end
			tween(brand, THEME.close, { TextTransparency = 1 })
			tween(tagline, THEME.close, { TextTransparency = 1 })
			tween(outputLabel, THEME.close, { TextTransparency = 1 })
			task.delay(0.3, function()
				root.Visible = false
				halo.Visible = false
				if atm then atm.setEnabled(false) end
				root.Position = p
				root.BackgroundTransparency = 0
				rootScale.Scale = 1
				brand.TextTransparency = 0
				tagline.TextTransparency = 0
				outputLabel.TextTransparency = 0
				if haloStroke then haloStroke.Transparency = 0.88 end
				finishVisAnim()
			end)
		end
	end
end

settingsBtn.MouseButton1Click:Connect(function()
	openSettings(not state.settingsOpen)
end)
feelOpts.settings = bindPressFeel(settingsBtn, {
	hoverScale = 1.08,
	pressScale = 0.9,
	baseColor = THEME.elevated,
	hoverColor = THEME.hover,
})

backBtn.MouseButton1Click:Connect(function()
	openSettings(false)
end)
feelOpts.back = bindPressFeel(backBtn, { baseColor = THEME.elevated, hoverColor = THEME.hover })

snowBtn.MouseButton1Click:Connect(function()
	state.snow = not state.snow
	if atm and atm.setSnow then atm.setSnow(state.snow) end
	refreshSettingsLabels()
end)

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
		if state.settingsOpen then
			openSettings(false)
		elseif dropdown.Visible then
			closeDropdown()
		else
			setVisible(false)
		end
		return
	end
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.Return
		and not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		and inputBox:IsFocused() then
		doTranslate()
	end
end)

-- мигание полоски у названия
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

-- появление при запуске
do
	local p = root.Position
	root.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + 36)
	root.Size = UDim2.fromOffset(WIN_W - 40, WIN_H - 36)
	root.BackgroundTransparency = 0.55
	rootScale.Scale = 0.9
	brand.TextTransparency = 1
	tagline.TextTransparency = 1
	outputLabel.TextTransparency = 1
	if haloStroke then haloStroke.Transparency = 1 end

	tween(root, THEME.spring, {
		Size = UDim2.fromOffset(WIN_W, WIN_H),
		BackgroundTransparency = 0,
		Position = p,
	})
	tween(rootScale, THEME.spring, { Scale = 1 })
	tween(brand, THEME.soft, { TextTransparency = 0 })
	tween(tagline, THEME.soft, { TextTransparency = 0 })
	tween(outputLabel, THEME.soft, { TextTransparency = 0 })
	if haloStroke then
		tween(haloStroke, THEME.soft, { Transparency = 0.88 })
	end
	dragSmooth.curX = p.X.Offset
	dragSmooth.curY = p.Y.Offset
	dragSmooth.goalX = p.X.Offset
	dragSmooth.goalY = p.Y.Offset
end

applyMotion(state.motionId)
applyUiLang()
setStatus("")
print("[lingo] загружен, RightShift — меню")
return gui
