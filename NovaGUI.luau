--!strict
--[[
  NOVA GUI v1.0.0 — Immediate-mode Luau GUI library for Roblox executors.
  Glassmorphism, chromatic aberration, per-element transparency, animated,
  zero-dependency. Mounts to CoreGui/PlayerGui.
]]

local NovaGUI = {}
NovaGUI.__index = NovaGUI
NovaGUI.Version = "1.0.0"

--// Services (defensive) \\--
local RunService, UserInputService, TweenService, CoreGui, Players, LocalPlayer, PlayerGui
local function _getServices()
	local ok = pcall(function()
		RunService = game:GetService("RunService")
		UserInputService = game:GetService("UserInputService")
		TweenService = game:GetService("TweenService")
		CoreGui = game:GetService("CoreGui")
		Players = game:GetService("Players")
		LocalPlayer = Players.LocalPlayer
		PlayerGui = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui") or nil
	end)
	return ok
end
_getServices()

--// Utilities \\--
local function isInstance(v) return type(v) == "userdata" and v:IsA and v:IsA("Instance") end
local function default(v, d) return v ~= nil and v or d end
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function lerp(a, b, t) return a + (b - a) * t end

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local function hex(s)
	s = tostring(s):gsub("#", "")
	if #s == 3 then s = s:sub(1,1):rep(2) .. s:sub(2,2):rep(2) .. s:sub(3,3):rep(2) end
	local r = tonumber(s:sub(1,2), 16) or 255
	local g = tonumber(s:sub(3,4), 16) or 255
	local b = tonumber(s:sub(5,6), 16) or 255
	return Color3.fromRGB(r, g, b)
end
local function toHex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

-- Safe enum resolution (some executors strip newer enums)
local function safeEnum(tbl, path)
	local ok, v = pcall(function()
		local cur = tbl
		for part in path:gmatch("[^%.]+") do cur = cur[part] end
		return cur
	end)
	return ok and v or nil
end
local TXA_Left = safeEnum(Enum, "TextXAlign.Left")
local TYA_Center = safeEnum(Enum, "TextYAlign.Center")
local FMono = safeEnum(Enum, "Font.GothamMonospace") or Enum.Font.Gotham

-- HSV helpers
local function hsvToRgb(h, s, v)
	local r, g, b
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	i = i % 6
	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	else r, g, b = v, p, q end
	return Color3.new(r, g, b)
end
local function rgbToHsv(c)
	local r, g, b = c.R, c.G, c.B
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local d = max - min
	local h, s
	if d == 0 then h = 0 else
		if max == r then h = (g - b) / d % 6
		elseif max == g then h = (b - r) / d + 2
		else h = (r - g) / d + 4 end
		h = h / 6
	end
	s = max == 0 and 0 or d / max
	return h, s, max
end

--// Deep copy & merge \\--
local function deepCopy(t)
	if type(t) ~= "table" then return t end
	local nt = {}
	for k, v in pairs(t) do
		if type(v) == "table" then nt[k] = deepCopy(v) else nt[k] = v end
	end
	return nt
end
local function merge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" and type(dst[k]) == "table" then merge(dst[k], v)
		else dst[k] = v end
	end
	return dst
end

--// ID counter \\--
local idCounter = 0
local function genId() idCounter += 1; return "nova_" .. idCounter end

--// Theme tokens \\--
local DEFAULT_THEME = {
	-- colours
	bg = rgb(18, 18, 22), bgTransparency = 0.15,
	bgAlt = rgb(24, 24, 30), bgAltTransparency = 0.2,
	surface = rgb(28, 28, 36), surfaceTransparency = 0.35,
	surfaceHover = rgb(38, 38, 48), surfaceHoverTransparency = 0.3,
	surfaceActive = rgb(50, 50, 62), surfaceActiveTransparency = 0.28,
	card = rgb(30, 30, 38), cardTransparency = 0.4,
	cardHover = rgb(40, 40, 50), cardHoverTransparency = 0.36,
	popover = rgb(26, 26, 34), popoverTransparency = 0.2,
	input = rgb(34, 34, 44), inputTransparency = 0.5,
	inputHover = rgb(44, 44, 56), inputHoverTransparency = 0.45,
	inputFocus = rgb(56, 56, 70), inputFocusTransparency = 0.4,
	track = rgb(40, 40, 52), trackTransparency = 0.5,
	trackFill = rgb(100, 210, 255), trackFillTransparency = 0.2,
	overlay = rgb(0, 0, 0), overlayTransparency = 0.55,
	primary = rgb(100, 210, 255), primaryTransparency = 0.15,
	primaryHover = rgb(120, 225, 255), primaryHoverTransparency = 0.12,
	primaryActive = rgb(80, 190, 235), primaryActiveTransparency = 0.18,
	primaryText = rgb(100, 210, 255), primaryTextTransparency = 0,
	primarySubtle = rgb(60, 140, 180), primarySubtleTransparency = 0.5,
	secondary = rgb(90, 90, 110), secondaryTransparency = 0.3,
	secondaryHover = rgb(110, 110, 135), secondaryHoverTransparency = 0.28,
	secondaryText = rgb(200, 200, 210), secondaryTextTransparency = 0.15,
	accent = rgb(255, 80, 140), accentTransparency = 0.2,
	accentText = rgb(255, 255, 255), accentTextTransparency = 0,
	text = rgb(230, 230, 240), textTransparency = 0.05,
	textStrong = rgb(255, 255, 255), textStrongTransparency = 0,
	textMuted = rgb(160, 160, 175), textMutedTransparency = 0.25,
	textFaint = rgb(100, 100, 115), textFaintTransparency = 0.45,
	textDisabled = rgb(90, 90, 100), textDisabledTransparency = 0.6,
	textInverse = rgb(20, 20, 24), textInverseTransparency = 0,
	border = rgb(255, 255, 255), borderTransparency = 0.75,
	borderHover = rgb(255, 255, 255), borderHoverTransparency = 0.55,
	borderFocus = rgb(100, 210, 255), borderFocusTransparency = 0.4,
	divider = rgb(60, 60, 70), dividerTransparency = 0.6,
	success = rgb(60, 220, 140), successTransparency = 0.2,
	successText = rgb(255, 255, 255), successTextTransparency = 0,
	warning = rgb(255, 190, 60), warningTransparency = 0.2,
	warningText = rgb(20, 20, 24), warningTextTransparency = 0,
	error = rgb(255, 70, 90), errorTransparency = 0.2,
	errorText = rgb(255, 255, 255), errorTextTransparency = 0,
	info = rgb(100, 180, 255), infoTransparency = 0.2,
	infoText = rgb(255, 255, 255), infoTextTransparency = 0,
	shadowColor = rgb(0, 0, 0), shadowTransparency = 0.55,
	glowColor = rgb(100, 210, 255), glowTransparency = 0.8,
	scrollbar = rgb(80, 80, 95), scrollbarTransparency = 0.6,
	scrollbarHover = rgb(120, 120, 140), scrollbarHoverTransparency = 0.5,
	selection = rgb(100, 210, 255), selectionTransparency = 0.35,
	caret = rgb(230, 230, 240), caretTransparency = 0,
	badgeBg = rgb(100, 210, 255), badgeBgTransparency = 0.35,
	badgeText = rgb(20, 20, 24), badgeTextTransparency = 0,
	focusRing = rgb(100, 210, 255), focusRingTransparency = 0.5,
	backdrop = rgb(0, 0, 0), backdropTransparency = 0.6,

	-- advanced effects
	textGlowEnabled = false, textGlowColor = rgb(255, 255, 255), textGlowIntensity = 1,
	chromaticAberrationEnabled = false, chromaticAberrationOffset = 1.5,
	shadowBlur = 16, shadowSpread = 4, buttonTransparency = 0.3, inputTransparency = 0.5, cardTransparency = 0.4,

	-- metrics
	radius = 10, radiusSm = 6, radiusLg = 16, borderWidth = 1, outlineWidth = 2,
	padX = 12, padY = 10, gap = 8, gapSm = 4, gapLg = 16,
	rowHeight = 32, controlHeight = 36, sliderTrackHeight = 6, sliderThumbSize = 18,
	toggleWidth = 48, toggleHeight = 24, toggleThumb = 18,
	checkboxSize = 20, scrollbarWidth = 10, iconSize = 18,
	-- motion
	motionFast = 0.14, motionStandard = 0.22, motionSlow = 0.34,
	easingStandard = Enum.EasingStyle.Quad, easingDirection = Enum.EasingDirection.Out,
}

-- Built-in themes
local BUILTIN_THEMES = {}
local function theme(name, overrides)
	local t = deepCopy(DEFAULT_THEME)
	if overrides then merge(t, overrides) end
	BUILTIN_THEMES[name] = t
	return t
end

theme("Glassmorphism", {
	bg = rgb(20, 20, 26), bgTransparency = 0.5,
	surface = rgb(30, 30, 38), surfaceTransparency = 0.45,
	card = rgb(35, 35, 44), cardTransparency = 0.55,
	border = rgb(255, 255, 255), borderTransparency = 0.62,
	primary = rgb(100, 210, 255), glowColor = rgb(100, 210, 255),
	textGlowEnabled = true, chromaticAberrationEnabled = true, chromaticAberrationOffset = 1.2,
})
theme("Frosted", {
	bg = rgb(24, 24, 30), bgTransparency = 0.35,
	card = rgb(32, 32, 40), cardTransparency = 0.5,
	border = rgb(255, 255, 255), borderTransparency = 0.5,
	primary = rgb(120, 180, 255),
})
theme("Dark", {
	bg = rgb(16, 16, 20), bgTransparency = 0.05,
	surface = rgb(24, 24, 30), surfaceTransparency = 0.1,
	card = rgb(28, 28, 34), cardTransparency = 0.15,
	border = rgb(60, 60, 70), borderTransparency = 0.3,
	primary = rgb(100, 210, 255),
})
theme("Light", {
	bg = rgb(240, 240, 245), bgTransparency = 0.05,
	surface = rgb(250, 250, 252), surfaceTransparency = 0.05,
	card = rgb(255, 255, 255), cardTransparency = 0.0,
	border = rgb(200, 200, 210), borderTransparency = 0.25,
	text = rgb(20, 20, 24), textStrong = rgb(0, 0, 0), textMuted = rgb(110, 110, 120),
	primary = rgb(60, 130, 220), primaryText = rgb(0, 0, 0),
	borderFocus = rgb(60, 130, 220), glowColor = rgb(60, 130, 220),
	shadowColor = rgb(0, 0, 0), shadowTransparency = 0.15,
	textInverse = rgb(255, 255, 255), badgeText = rgb(0, 0, 0), warningText = rgb(0, 0, 0), errorText = rgb(0, 0, 0), infoText = rgb(0, 0, 0),
})
theme("Amoled", { bg = rgb(0, 0, 0), bgTransparency = 0, surface = rgb(6, 6, 6), card = rgb(10, 10, 10), primary = rgb(0, 255, 120) })
theme("Midnight", { bg = rgb(10, 12, 24), surface = rgb(16, 18, 34), primary = rgb(140, 120, 255) })
theme("Slate", { bg = rgb(30, 34, 40), surface = rgb(42, 48, 56), primary = rgb(140, 180, 210) })
theme("Mono", { bg = rgb(18, 18, 18), surface = rgb(28, 28, 28), primary = rgb(200, 200, 200), text = rgb(220, 220, 220) })
theme("Graphite", { bg = rgb(24, 26, 28), surface = rgb(38, 40, 44), primary = rgb(160, 160, 160) })
theme("Aqua", { bg = rgb(15, 24, 28), surface = rgb(22, 34, 40), primary = rgb(60, 220, 200), glowColor = rgb(60, 220, 200) })
theme("Aqua Light", { bg = rgb(230, 250, 248), surface = rgb(245, 255, 252), primary = rgb(40, 160, 140), text = rgb(15, 30, 28) })
theme("Serika", { bg = rgb(26, 24, 30), surface = rgb(36, 32, 42), primary = rgb(200, 130, 255), glowColor = rgb(200, 130, 255) })
theme("Rust", { bg = rgb(24, 20, 16), surface = rgb(38, 30, 22), primary = rgb(190, 90, 40), glowColor = rgb(190, 90, 40) })
theme("Iris", { bg = rgb(28, 24, 36), surface = rgb(40, 34, 52), primary = rgb(170, 120, 255), glowColor = rgb(170, 120, 255) })
theme("Neon", { bg = rgb(8, 8, 12), surface = rgb(14, 14, 22), primary = rgb(0, 255, 255), accent = rgb(255, 0, 255), glowColor = rgb(0, 255, 255), textGlowEnabled = true, chromaticAberrationEnabled = true, chromaticAberrationOffset = 2 })
theme("Cyberpunk", { bg = rgb(10, 10, 16), surface = rgb(18, 18, 28), primary = rgb(0, 255, 120), accent = rgb(255, 40, 120), glowColor = rgb(0, 255, 120), textGlowEnabled = true, chromaticAberrationEnabled = true })
theme("Vaporwave", { bg = rgb(20, 12, 28), surface = rgb(34, 22, 48), primary = rgb(220, 120, 255), accent = rgb(120, 200, 255), glowColor = rgb(220, 120, 255) })
theme("Synthwave", { bg = rgb(24, 16, 40), surface = rgb(40, 24, 64), primary = rgb(255, 40, 160), accent = rgb(80, 180, 255), glowColor = rgb(255, 40, 160) })
theme("Terminal", { bg = rgb(10, 10, 10), surface = rgb(20, 20, 20), primary = rgb(40, 255, 40), text = rgb(40, 255, 40), textMuted = rgb(100, 255, 100) })
theme("Matrix", { bg = rgb(0, 0, 0), surface = rgb(2, 8, 2), primary = rgb(0, 255, 0), text = rgb(0, 255, 0) })
theme("Nord", { bg = rgb(46, 52, 64), surface = rgb(59, 66, 82), primary = rgb(136, 192, 208), text = rgb(216, 222, 233) })
theme("Dracula", { bg = rgb(40, 42, 54), surface = rgb(68, 71, 90), primary = rgb(189, 147, 249), text = rgb(248, 248, 242) })
theme("Gruvbox", { bg = rgb(40, 34, 22), surface = rgb(58, 50, 34), primary = rgb(215, 153, 33), text = rgb(242, 229, 188) })
theme("Tokyo Night", { bg = rgb(24, 24, 36), surface = rgb(34, 34, 50), primary = rgb(127, 157, 241), text = rgb(237, 231, 246) })
theme("Catppuccin", { bg = rgb(30, 30, 46), surface = rgb(45, 45, 68), primary = rgb(180, 167, 214), text = rgb(245, 224, 220) })
theme("Rose Pine", { bg = rgb(25, 23, 30), surface = rgb(39, 35, 46), primary = rgb(190, 154, 208), text = rgb(232, 214, 220) })
theme("Solarized", { bg = rgb(7, 54, 66), surface = rgb(13, 76, 90), primary = rgb(42, 161, 152), text = rgb(253, 246, 227) })
theme("Forest", { bg = rgb(22, 30, 24), surface = rgb(32, 44, 34), primary = rgb(90, 200, 100), text = rgb(220, 240, 220) })
theme("Ocean", { bg = rgb(14, 22, 34), surface = rgb(20, 34, 50), primary = rgb(60, 140, 220), text = rgb(220, 235, 245) })
theme("Sunset", { bg = rgb(34, 20, 20), surface = rgb(52, 28, 28), primary = rgb(255, 120, 60), text = rgb(255, 230, 220) })
theme("Coffee", { bg = rgb(30, 26, 22), surface = rgb(46, 38, 30), primary = rgb(180, 120, 70), text = rgb(230, 220, 205) })
theme("Candy", { bg = rgb(30, 24, 36), surface = rgb(50, 32, 56), primary = rgb(255, 100, 180), accent = rgb(180, 100, 255), textGlowEnabled = true })
theme("Brutal", { bg = rgb(24, 24, 24), surface = rgb(40, 40, 40), primary = rgb(255, 255, 255), border = rgb(255, 255, 255), borderTransparency = 0, borderWidth = 3, radius = 0, radiusSm = 0, radiusLg = 0 })
theme("Paper", { bg = rgb(255, 252, 245), surface = rgb(255, 255, 255), primary = rgb(120, 80, 50), text = rgb(40, 35, 30), border = rgb(160, 140, 120) })
theme("Pastel", { bg = rgb(245, 240, 250), surface = rgb(255, 250, 255), primary = rgb(200, 160, 255), text = rgb(80, 60, 100) })
theme("Retro95", { bg = rgb(192, 192, 192), surface = rgb(220, 220, 220), primary = rgb(0, 0, 128), text = rgb(0, 0, 0), border = rgb(0, 0, 0), borderTransparency = 0 })

local function resolveTheme(spec)
	if type(spec) == "table" then return deepCopy(spec) end
	if type(spec) == "string" then
		local t = BUILTIN_THEMES[spec]
		if t then return deepCopy(t) end
	end
	return deepCopy(DEFAULT_THEME)
end

--// Animation engine \\--
local Animation = {}
Animation.__index = Animation
local animations = {}
local heartbeatConn

local function ensureHeartbeat()
	if heartbeatConn then return end
	heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		local now = tick()
		local dead = {}
		for id, anim in pairs(animations) do
			anim:update(now, dt)
			if anim.done then table.insert(dead, id) end
		end
		for _, id in ipairs(dead) do animations[id] = nil end
		if next(animations) == nil and heartbeatConn then
			heartbeatConn:Disconnect(); heartbeatConn = nil
		end
	end)
end

function Animation.new(target, prop, from, to, duration, easing, cb)
	local self = setmetatable({}, Animation)
	self.target = target; self.prop = prop; self.from = from; self.to = to
	self.duration = duration or 0.2; self.start = tick(); self.cb = cb
	self.done = false; self.easing = easing or function(t) return t end
	animations[tostring(target) .. "." .. prop] = self
	ensureHeartbeat()
	return self
end

local easings = {
	linear = function(t) return t end,
	quad = function(t) return t * t end,
	outQuad = function(t) return -t * (t - 2) end,
	inOutQuad = function(t) t = t * 2; if t < 1 then return 0.5 * t * t end; t -= 1; return -0.5 * (t * (t - 2) - 1) end,
	spring = function(t) return 1 - math.pow(2, -10 * t) * math.sin((t - 0.1) * (2 * math.pi) / 0.4) end,
}
function Animation:update(now, dt)
	local elapsed = now - self.start
	local t = clamp(elapsed / self.duration, 0, 1)
	local e = self.easing(t)
	local v = lerp(self.from, self.to, e)
	if typeof(self.target) == "Instance" and self.prop then
		local ok, err = pcall(function() self.target[self.prop] = v end)
		if not ok then self.done = true end
	end
	if self.cb then self.cb(v, t) end
	if t >= 1 then self.done = true end
end

--// Instance helpers \\--
local function new(className, props)
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			if k ~= "Children" then pcall(function() inst[k] = v end) end
		end
		if props.Children then
			for _, c in ipairs(props.Children) do c.Parent = inst end
		end
	end
	return inst
end

local function setTransparency(inst, alpha)
	if inst:IsA("GuiObject") then inst.BackgroundTransparency = alpha end
	if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
		inst.TextTransparency = alpha
	end
	if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then inst.ImageTransparency = alpha end
	if inst:IsA("UIStroke") then inst.Transparency = alpha end
end

--// Chromatic aberration text \\--
local function makeText(parent, text, theme, opts)
	opts = opts or {}
	local size = default(opts.size, 16)
	local font = default(opts.font, safeEnum(Enum, "Font.GothamSemibold") or Enum.Font.Gotham)
	local color = default(opts.color, theme.text)
	local trans = default(opts.transparency, theme.textTransparency)
	local glow = default(opts.glow, default(theme.textGlowEnabled, false))
	local offset = default(opts.chromaOffset, default(theme.chromaticAberrationOffset, 1.5))
	local chroma = default(opts.chroma, default(theme.chromaticAberrationEnabled, false))
	local container = new("Frame", {
		Name = "NovaText", Size = UDim2.new(1, 0, 0, size), BackgroundTransparency = 1,
		ClipsDescendants = false,
	})
	local function makeLayer(dx, dy, col, tr, z)
		local lab = new("TextLabel", {
			Name = "Layer" .. z, Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, dx, 0, dy),
			BackgroundTransparency = 1, Text = text, TextColor3 = col, TextTransparency = tr,
			Font = font, TextSize = size, TextXAlign = TXA_Left, TextYAlign = TYA_Center,
			ZIndex = z,
		})
		if glow then
			local glowLab = lab:Clone()
			glowLab.Name = "Glow" .. z
			glowLab.TextColor3 = default(opts.glowColor, theme.textGlowColor)
			glowLab.TextTransparency = 1 - (1 - tr) * (1 - default(theme.textGlowIntensity, 1))
			glowLab.ZIndex = z - 1
			glowLab.Parent = container
		end
		lab.Parent = container
		return lab
	end
	if chroma then
		makeLayer(-offset, 0, Color3.new(1, 0, 0), trans, 3)
		makeLayer(offset, 0, Color3.new(0, 0.6, 1), trans, 2)
		makeLayer(0, 0, color, trans, 4)
	else
		makeLayer(0, 0, color, trans, 1)
	end
	container.Parent = parent
	return container
end

local function setText(container, text)
	for _, c in ipairs(container:GetChildren()) do
		if c:IsA("TextLabel") and c.Name:sub(1,5) == "Layer" then c.Text = text end
	end
end

--// Render context \\--
local RenderCtx = {}
RenderCtx.__index = RenderCtx

function RenderCtx.new(gui)
	local self = setmetatable({}, RenderCtx)
	self.gui = gui
	self.theme = gui.theme
	self.elements = {}       -- id -> element handle
	self.frames = {}         -- window/container frames
	self.focused = nil
	self.hovered = nil
	self.dragging = nil
	self.dragStart = nil
	self.dragOffset = nil
	self.inputs = {}
	self.nextZ = 10
	self.screen = gui.screen
	self.content = gui.content
	return self
end

function RenderCtx:get(id)
	if not self.elements[id] then
		self.elements[id] = { id = id, state = {}, frame = nil }
	end
	return self.elements[id]
end

function RenderCtx:z() self.nextZ += 1; return self.nextZ end

--// Base element builder \\--
local Element = {}
Element.__index = Element

function Element:container(id, parent, size, pos)
	local el = RenderCtx.get(self.ctx, id)
	local f = el.frame
	if not f then
		f = new("Frame", {
			Name = id, Size = size or UDim2.new(0, 200, 0, 30), Position = pos or UDim2.new(),
			BackgroundTransparency = 1, Parent = parent,
			ZIndex = self:z(),
		})
		el.frame = f
	else
		f.Size = size; f.Position = pos; f.Parent = parent; f.ZIndex = self:z()
	end
	return f
end

--// Widget: Label \\--
function RenderCtx:Label(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local f = self:container(id, parent, UDim2.new(0, 200, 0, opts.height or 24), opts.position)
	local text = default(opts.text, id)
	local color = opts.color or self.theme.text
	local trans = default(opts.transparency, self.theme.textTransparency)
	local glow = default(opts.glow, self.theme.textGlowEnabled)
	local chroma = default(opts.chroma, self.theme.chromaticAberrationEnabled)
	if not el.textContainer then
		el.textContainer = makeText(f, text, self.theme, {
			size = opts.size or 16, font = opts.font or Enum.Font.Gotham,
			color = color, transparency = trans, glow = glow, glowColor = opts.glowColor or self.theme.textGlowColor,
			chroma = chroma, chromaOffset = opts.chromaOffset or self.theme.chromaticAberrationOffset,
		})
		el.textContainer.Size = UDim2.new(1, 0, 1, 0)
		el.textContainer.Position = UDim2.new()
	else
		setText(el.textContainer, text)
	end
	return f
end

--// Widget: Button \\--
local function styleButton(f, theme, variant, hovered, active)
	local variants = {
		primary = { bg = theme.primary, bgT = theme.primaryTransparency, text = theme.primaryText, textT = theme.primaryTextTransparency },
		secondary = { bg = theme.secondary, bgT = theme.secondaryTransparency, text = theme.secondaryText, textT = theme.secondaryTextTransparency },
		ghost = { bg = theme.surface, bgT = theme.surfaceTransparency, text = theme.text, textT = theme.textTransparency },
		outline = { bg = theme.bg, bgT = theme.bgTransparency, text = theme.text, textT = theme.textTransparency },
		danger = { bg = theme.error, bgT = theme.errorTransparency, text = theme.errorText, textT = theme.errorTextTransparency },
		success = { bg = theme.success, bgT = theme.successTransparency, text = theme.successText, textT = theme.successTextTransparency },
	}
	local v = variants[variant] or variants.primary
	local c = hovered and (variant == "primary" and theme.primaryHover or theme.surfaceHover) or v.bg
	local ct = hovered and (variant == "primary" and theme.primaryHoverTransparency or theme.surfaceHoverTransparency) or v.bgT
	if active then c = theme.primaryActive; ct = theme.primaryActiveTransparency end
	f.BackgroundColor3 = c; f.BackgroundTransparency = default(theme.buttonTransparency, ct)
	local stroke = f:FindFirstChild("NovaBorder") or new("UIStroke", { Name = "NovaBorder", Parent = f })
	stroke.Color = hovered and theme.borderHover or theme.border
	stroke.Transparency = hovered and theme.borderHoverTransparency or theme.borderTransparency
	stroke.Thickness = theme.borderWidth
end

function RenderCtx:Button(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local variant = default(opts.variant, "primary")
	local text = default(opts.text, id)
	local w = default(opts.width, self.theme.controlHeight * 2.4)
	local h = default(opts.height, self.theme.controlHeight)
	local f = self:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	local corner = f:FindFirstChild("NovaCorner") or new("UICorner", { Name = "NovaCorner", CornerRadius = UDim.new(0, self.theme.radiusSm), Parent = f })
	-- button text
	if not el.btnText then
		el.btnText = new("TextLabel", {
			Name = "Text", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
			Text = text, 			TextColor3 = self.theme.text, TextTransparency = self.theme.textTransparency,
			Font = Enum.Font.GothamBold, TextSize = 15, Parent = f,
		})
	else
		el.btnText.Text = text
	end
	local hovered = false
	local clicked = false
	local entered = f.MouseEnter:Connect(function() hovered = true end)
	local left = f.MouseLeave:Connect(function() hovered = false end)
	local act = f.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then clicked = true end
	end)
	el._connections = el._connections or {}; table.insert(el._connections, entered); table.insert(el._connections, left); table.insert(el._connections, act)
	styleButton(f, self.theme, variant, hovered, false)
	return clicked, hovered
end

--// Widget: Toggle \\--
function RenderCtx:Toggle(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local value = default(opts.value, false)
	local onChange = opts.onChange
	local w = default(opts.width, self.theme.toggleWidth)
	local h = default(opts.height, self.theme.toggleHeight)
	local f = self:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	local track = f:FindFirstChild("Track") or new("Frame", { Name = "Track", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = self.theme.surface, BackgroundTransparency = self.theme.surfaceTransparency, Parent = f })
	local thumb = f:FindFirstChild("Thumb") or new("Frame", { Name = "Thumb", Size = UDim2.new(0, self.theme.toggleThumb, 0, self.theme.toggleThumb), BackgroundColor3 = self.theme.primary, Position = UDim2.new(0, value and (w - self.theme.toggleThumb) or 3, 0, (h - self.theme.toggleThumb)/2), Parent = f })
	new("UICorner", { Parent = track, CornerRadius = UDim.new(0, h/2) })
	new("UICorner", { Parent = thumb, CornerRadius = UDim.new(0, 100) })
	if not el.label then
		el.label = makeText(f, default(opts.label, id), self.theme, { size = 14, color = self.theme.textMuted })
		el.label.Position = UDim2.new(0, w + self.theme.gapSm, 0, 0); el.label.Size = UDim2.new(0, 200, 0, h); el.label.Parent = f
	end
	local hovered = false
	local entered = f.MouseEnter:Connect(function() hovered = true end)
	local left = f.MouseLeave:Connect(function() hovered = false end)
	local act = f.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			value = not value
			TweenService:Create(thumb, TweenInfo.new(self.theme.motionFast, self.theme.easingStandard, self.theme.easingDirection), { Position = UDim2.new(0, value and (w - self.theme.toggleThumb) or 3, 0, (h - self.theme.toggleThumb)/2) }):Play()
			TweenService:Create(track, TweenInfo.new(self.theme.motionFast), { BackgroundColor3 = value and self.theme.primary or self.theme.surface, BackgroundTransparency = value and self.theme.primaryTransparency or self.theme.surfaceTransparency }):Play()
			if onChange then onChange(value) end
		end
	end)
	el._connections = el._connections or {}
	table.insert(el._connections, entered); table.insert(el._connections, left); table.insert(el._connections, act)
	track.BackgroundColor3 = value and self.theme.primary or self.theme.surface
	track.BackgroundTransparency = value and self.theme.primaryTransparency or self.theme.surfaceTransparency
	thumb.Position = UDim2.new(0, value and (w - self.theme.toggleThumb) or 3, 0, (h - self.theme.toggleThumb)/2)
	thumb.BackgroundColor3 = value and self.theme.primary or self.theme.surface
	return value, hovered
end

--// Widget: Checkbox \\--
function RenderCtx:Checkbox(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local value = default(opts.value, false)
	local onChange = opts.onChange
	local s = default(opts.size, self.theme.checkboxSize)
	local f = self:container(id, parent, UDim2.new(0, s + 200, 0, s), opts.position)
	local box = f:FindFirstChild("Box") or new("Frame", { Name = "Box", Size = UDim2.new(0, s, 0, s), BackgroundColor3 = self.theme.surface, BackgroundTransparency = self.theme.surfaceTransparency, Parent = f })
	local check = f:FindFirstChild("Check") or new("Frame", { Name = "Check", Size = UDim2.new(0, s*0.5, 0, s*0.5), BackgroundColor3 = self.theme.primary, Position = UDim2.new(0, s*0.25, 0, s*0.25), Visible = false, Parent = f })
	new("UICorner", { Parent = box, CornerRadius = UDim.new(0, self.theme.radiusSm) })
	new("UICorner", { Parent = check, CornerRadius = UDim.new(0, 4) })
	if not el.label then
		el.label = makeText(f, default(opts.label, id), self.theme, { size = 14, color = self.theme.text })
		el.label.Position = UDim2.new(0, s + self.theme.gapSm, 0, 0); el.label.Size = UDim2.new(0, 200, 0, s); el.label.Parent = f
	end
	local hovered = false
	local entered = f.MouseEnter:Connect(function() hovered = true end)
	local left = f.MouseLeave:Connect(function() hovered = false end)
	local act = f.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			value = not value
			check.Visible = value
			if onChange then onChange(value) end
		end
	end)
	el._connections = el._connections or {}
	table.insert(el._connections, entered); table.insert(el._connections, left); table.insert(el._connections, act)
	box.BackgroundColor3 = value and self.theme.primary or self.theme.surface
	box.BackgroundTransparency = value and self.theme.primaryTransparency or self.theme.surfaceTransparency
	check.Visible = value
	return value, hovered
end

--// Widget: Slider \\--
function RenderCtx:Slider(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local min = default(opts.min, 0); local max = default(opts.max, 100)
	local value = default(opts.value, min)
	local onChange = opts.onChange
	local w = default(opts.width, 200)
	local h = default(opts.height, self.theme.controlHeight)
	local f = self:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	local track = f:FindFirstChild("Track") or new("Frame", { Name = "Track", Size = UDim2.new(1, -40, 0, self.theme.sliderTrackHeight), Position = UDim2.new(0, 20, 0.5, -self.theme.sliderTrackHeight/2), BackgroundColor3 = self.theme.track, BackgroundTransparency = self.theme.trackTransparency, Parent = f })
	local fill = f:FindFirstChild("Fill") or new("Frame", { Name = "Fill", Size = UDim2.new(), Position = UDim2.new(), BackgroundColor3 = self.theme.trackFill, BackgroundTransparency = self.theme.trackFillTransparency, Parent = f })
	local thumb = f:FindFirstChild("Thumb") or new("Frame", { Name = "Thumb", Size = UDim2.new(0, self.theme.sliderThumbSize, 0, self.theme.sliderThumbSize), Position = UDim2.new(), BackgroundColor3 = self.theme.primary, Parent = f })
	new("UICorner", { Parent = track, CornerRadius = UDim.new(0, 100) })
	new("UICorner", { Parent = fill, CornerRadius = UDim.new(0, 100) })
	new("UICorner", { Parent = thumb, CornerRadius = UDim.new(0, 100) })
	if not el.label then
		el.label = makeText(f, default(opts.label, id), self.theme, { size = 14, color = self.theme.textMuted })
		el.label.Size = UDim2.new(0, 200, 0, h); el.label.Position = UDim2.new(0, 0, 0, -h - self.theme.gapSm); el.label.Parent = f
	end
	if not el.valueText then
		el.valueText = makeText(f, string.format("%.0f", value), self.theme, { size = 13, color = self.theme.text, font = FMono })
		el.valueText.Position = UDim2.new(1, -60, 0, -h - self.theme.gapSm); el.valueText.Size = UDim2.new(0, 50, 0, h); el.valueText.Parent = f
	end
	local function setValueRaw(v)
		value = clamp(v, min, max)
		local pct = (max == min) and 1 or (value - min) / (max - min)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		thumb.Position = UDim2.new(pct, -self.theme.sliderThumbSize/2, 0.5, -self.theme.sliderThumbSize/2)
		setText(el.valueText, string.format("%.0f", value))
	end
	setValueRaw(value)
	local dragging = false
	local hovered = false
	local entered = f.MouseEnter:Connect(function() hovered = true end)
	local left = f.MouseLeave:Connect(function() hovered = false end)
	local inputBegan = f.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end)
	local inputEnded = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	local moved = UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mx = input.Position.X
			local absLeft = track.AbsolutePosition.X
			local absRight = absLeft + track.AbsoluteSize.X
			local pct = clamp((mx - absLeft) / (absRight - absLeft), 0, 1)
			setValueRaw(min + pct * (max - min))
			if onChange then onChange(value) end
		end
	end)
	el._connections = el._connections or {}
	table.insert(el._connections, entered); table.insert(el._connections, left); table.insert(el._connections, inputBegan); table.insert(el._connections, inputEnded); table.insert(el._connections, moved)
	return value, hovered
end

--// Widget: Dropdown \\--
function RenderCtx:Dropdown(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local options = opts.options or {}
	local value = default(opts.value, options[1] or "")
	local onChange = opts.onChange
	local w = default(opts.width, 200)
	local h = default(opts.height, self.theme.controlHeight)
	local open = el.open or false
	local f = self:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	local button = f:FindFirstChild("Button") or new("TextButton", { Name = "Button", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = self.theme.surface, BackgroundTransparency = self.theme.surfaceTransparency, Text = "", Parent = f })
	local label = f:FindFirstChild("Label") or new("TextLabel", { Name = "Label", Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = value, TextColor3 = self.theme.text, TextTransparency = self.theme.textTransparency, 		Font = Enum.Font.Gotham, TextSize = 14, TextXAlign = TXA_Left, Parent = button })
	local arrow = f:FindFirstChild("Arrow") or new("TextLabel", { Name = "Arrow", Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -22, 0, 0), BackgroundTransparency = 1, Text = "▼", TextColor3 = self.theme.textMuted, TextTransparency = self.theme.textMutedTransparency, Font = Enum.Font.Gotham, TextSize = 14, Parent = button })
	new("UICorner", { Parent = button, CornerRadius = UDim.new(0, self.theme.radiusSm) })
	local list = f:FindFirstChild("List") or new("Frame", { Name = "List", Size = UDim2.new(1, 0, 0, #options * self.theme.rowHeight), Position = UDim2.new(0, 0, 1, 4), BackgroundColor3 = self.theme.popover, BackgroundTransparency = self.theme.popoverTransparency, Visible = false, Parent = f, ZIndex = 50 })
	new("UICorner", { Parent = list, CornerRadius = UDim.new(0, self.theme.radius) })
	new("UIStroke", { Parent = list, Color = self.theme.border, Transparency = self.theme.borderTransparency, Thickness = self.theme.borderWidth })
	local layout = list:FindFirstChild("Layout") or new("UIListLayout", { Name = "Layout", Parent = list, SortOrder = Enum.SortOrder.LayoutOrder })
	-- rebuild options
	for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	for i, opt in ipairs(options) do
		local b = new("TextButton", { Name = "Opt" .. i, Size = UDim2.new(1, 0, 0, self.theme.rowHeight), BackgroundTransparency = 1, Text = opt, TextColor3 = self.theme.text, TextTransparency = self.theme.textTransparency, Font = Enum.Font.Gotham, TextSize = 14, Parent = list, ZIndex = 51, LayoutOrder = i })
		b.MouseEnter:Connect(function() b.BackgroundColor3 = self.theme.surfaceHover; b.BackgroundTransparency = self.theme.surfaceHoverTransparency end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
		b.Activated:Connect(function()
			value = opt; open = false; list.Visible = false; arrow.Text = "▼"
			label.Text = opt
			if onChange then onChange(value) end
		end)
	end
	local hovered = false
	local entered = f.MouseEnter:Connect(function() hovered = true end)
	local left = f.MouseLeave:Connect(function() hovered = false end)
	local act = button.Activated:Connect(function()
		open = not open; list.Visible = open; arrow.Text = open and "▲" or "▼"
	end)
	el._connections = el._connections or {}
	table.insert(el._connections, entered); table.insert(el._connections, left); table.insert(el._connections, act)
	list.Size = UDim2.new(1, 0, 0, #options * self.theme.rowHeight)
	button.BackgroundColor3 = self.theme.surface; button.BackgroundTransparency = self.theme.surfaceTransparency
	return value, open
end

--// Widget: ColorPicker (button opens popover) \\--
function RenderCtx:ColorPicker(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local value = default(opts.value, Color3.new(1, 1, 1))
	local onChange = opts.onChange
	local s = default(opts.size, self.theme.controlHeight)
	local f = self:container(id, parent, UDim2.new(0, s, 0, s), opts.position)
	local swatch = f:FindFirstChild("Swatch") or new("Frame", { Name = "Swatch", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = value, BorderSizePixel = 0, Parent = f })
	local hue, sat, val = rgbToHsv(value)
	new("UICorner", { Parent = swatch, CornerRadius = UDim.new(0, self.theme.radiusSm) })
	new("UIStroke", { Parent = swatch, Color = self.theme.border, Transparency = self.theme.borderTransparency, Thickness = self.theme.borderWidth })
	if not el.label then
		el.label = makeText(f, default(opts.label, id), self.theme, { size = 13, color = self.theme.textMuted })
		el.label.Position = UDim2.new(0, s + self.theme.gapSm, 0, 0); el.label.Size = UDim2.new(0, 200, 0, s); el.label.Parent = f
	end
	local opened = false
	local hovered = false
	local entered = f.MouseEnter:Connect(function() hovered = true end)
	local left = f.MouseLeave:Connect(function() hovered = false end)
	local act = f.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then opened = not opened end
	end)
	el._connections = el._connections or {}
	table.insert(el._connections, entered); table.insert(el._connections, left); table.insert(el._connections, act)
	swatch.BackgroundColor3 = value
	if opened then
		-- inline mini picker below
		if el.pickerFrame then el.pickerFrame:Destroy() end
		local pf = new("Frame", { Name = "Picker", Size = UDim2.new(0, 180, 0, 180), Position = UDim2.new(0, 0, 1, 6), BackgroundColor3 = self.theme.surface, BackgroundTransparency = self.theme.surfaceTransparency, Parent = f, ZIndex = 60 })
		new("UICorner", { Parent = pf, CornerRadius = UDim.new(0, self.theme.radius) })
		new("UIStroke", { Parent = pf, Color = self.theme.border, Transparency = self.theme.borderTransparency, Thickness = self.theme.borderWidth })
		local hueStrip = new("Frame", { Name = "Hue", Size = UDim2.new(1, -16, 0, 16), Position = UDim2.new(0, 8, 0, 8), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = pf, ZIndex = 61 })
		-- simple hue gradient via children
		for i = 0, 6 do
			local seg = new("Frame", { Size = UDim2.new(1/7, 0, 1, 0), Position = UDim2.new(i/7, 0, 0, 0), BackgroundColor3 = hsvToRgb(i/6, 1, 1), BorderSizePixel = 0, Parent = hueStrip, ZIndex = 62 })
		end
		el.pickerFrame = pf
	end
	return value, opened
end

--// Widget: Textbox \\--
function RenderCtx:Textbox(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local text = default(opts.text, "")
	local placeholder = default(opts.placeholder, "")
	local onChange = opts.onChange
	local w = default(opts.width, 200)
	local h = default(opts.height, self.theme.controlHeight)
	local f = self:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	local box = f:FindFirstChild("Box") or new("TextBox", { Name = "Box", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = self.theme.input, BackgroundTransparency = self.theme.inputTransparency, Text = text, PlaceholderText = placeholder, PlaceholderColor3 = self.theme.textMuted, TextColor3 = self.theme.text, TextTransparency = self.theme.textTransparency, Font = Enum.Font.Gotham, TextSize = 14, Parent = f })
	new("UICorner", { Parent = box, CornerRadius = UDim.new(0, self.theme.radiusSm) })
	new("UIStroke", { Parent = box, Color = self.theme.border, Transparency = self.theme.borderTransparency, Thickness = self.theme.borderWidth })
	if not el.label then
		el.label = makeText(f, default(opts.label, id), self.theme, { size = 13, color = self.theme.textMuted })
		el.label.Position = UDim2.new(0, 0, 0, -h - self.theme.gapSm); el.label.Size = UDim2.new(0, 200, 0, h); el.label.Parent = f
	end
	local changed = false
	local focus = false
	local entered = f.MouseEnter:Connect(function() end)
	local left = f.MouseLeave:Connect(function() end)
	local foc = box.Focused:Connect(function() focus = true; box.BackgroundColor3 = self.theme.inputFocus; box.BackgroundTransparency = self.theme.inputFocusTransparency end)
	local blur = box.FocusLost:Connect(function()
		focus = false; box.BackgroundColor3 = self.theme.input; box.BackgroundTransparency = self.theme.inputTransparency
		if box.Text ~= text then text = box.Text; changed = true; if onChange then onChange(text) end end
	end)
	local c = box.Changed:Connect(function(p)
		if p == "Text" then text = box.Text; changed = true end
	end)
	el._connections = el._connections or {}
	table.insert(el._connections, entered); table.insert(el._connections, left); table.insert(el._connections, foc); table.insert(el._connections, blur); table.insert(el._connections, c)
	box.Text = text
	return text, changed
end

--// Widget: Keybind \\--
function RenderCtx:Keybind(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local value = default(opts.value, { key = Enum.KeyCode.Unknown })
	local onChange = opts.onChange
	local w = default(opts.width, 140)
	local h = default(opts.height, self.theme.controlHeight)
	local f = self:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	local box = f:FindFirstChild("Box") or new("TextButton", { Name = "Box", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = self.theme.input, BackgroundTransparency = self.theme.inputTransparency, Text = value.key == Enum.KeyCode.Unknown and "None" or tostring(value.key):gsub("Enum.KeyCode.", ""), TextColor3 = self.theme.text, TextTransparency = self.theme.textTransparency, Font = Enum.Font.Gotham, TextSize = 14, Parent = f })
	new("UICorner", { Parent = box, CornerRadius = UDim.new(0, self.theme.radiusSm) })
	new("UIStroke", { Parent = box, Color = self.theme.border, Transparency = self.theme.borderTransparency, Thickness = self.theme.borderWidth })
	if not el.label then
		el.label = makeText(f, default(opts.label, id), self.theme, { size = 13, color = self.theme.textMuted })
		el.label.Position = UDim2.new(0, 0, 0, -h - self.theme.gapSm); el.label.Size = UDim2.new(0, 200, 0, h); el.label.Parent = f
	end
	local listening = false
	local hovered = false
	local entered = f.MouseEnter:Connect(function() hovered = true end)
	local left = f.MouseLeave:Connect(function() hovered = false end)
	local act = f.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			listening = true
			box.Text = "..."
		end
	end)
	local inputBegan = UserInputService.InputBegan:Connect(function(input)
		if not listening then return end
		listening = false
		if input.UserInputType == Enum.UserInputType.Keyboard then
			value = { key = input.KeyCode }
			box.Text = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
		end
		if onChange then onChange(value) end
	end)
	el._connections = el._connections or {}
	table.insert(el._connections, entered); table.insert(el._connections, left); table.insert(el._connections, act); table.insert(el._connections, inputBegan)
	return value, listening
end

--// Widget: Badge \\--
function RenderCtx:Badge(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local text = default(opts.text, id)
	local w = default(opts.width, 80)
	local h = default(opts.height, 22)
	local f = self:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	f.BackgroundColor3 = opts.color or self.theme.badgeBg
	f.BackgroundTransparency = default(opts.transparency, self.theme.badgeBgTransparency)
	if not el.label then
		el.label = makeText(f, text, self.theme, { size = 12, color = opts.textColor or self.theme.badgeText, transparency = default(opts.textTransparency, self.theme.badgeTextTransparency), font = Enum.Font.GothamBold })
		el.label.Size = UDim2.new(1, 0, 1, 0); el.label.Position = UDim2.new(); el.label.Parent = f
	else
		setText(el.label, text)
	end
	new("UICorner", { Parent = f, CornerRadius = UDim.new(0, 100) })
	return f
end

--// Widget: ProgressBar \\--
function RenderCtx:ProgressBar(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local value = default(opts.value, 0)
	local min = default(opts.min, 0); local max = default(opts.max, 100)
	local w = default(opts.width, 200)
	local h = default(opts.height, self.theme.sliderTrackHeight)
	local f = self:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	local track = f:FindFirstChild("Track") or new("Frame", { Name = "Track", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = self.theme.track, BackgroundTransparency = self.theme.trackTransparency, Parent = f })
	local fill = f:FindFirstChild("Fill") or new("Frame", { Name = "Fill", Size = UDim2.new(), Position = UDim2.new(), BackgroundColor3 = self.theme.primary, BackgroundTransparency = self.theme.primaryTransparency, Parent = f })
	new("UICorner", { Parent = track, CornerRadius = UDim.new(0, 100) })
	new("UICorner", { Parent = fill, CornerRadius = UDim.new(0, 100) })
	local pct = (max == min) and 1 or clamp((value - min) / (max - min), 0, 1)
	fill.Size = UDim2.new(pct, 0, 1, 0)
	return f
end

--// Widget: Separator \\--
function RenderCtx:Separator(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local text = opts.text
	local w = default(opts.width, 200)
	local h = default(opts.height, 24)
	local f = self:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	f.BackgroundTransparency = 1
	local line = f:FindFirstChild("Line") or new("Frame", { Name = "Line", Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = self.theme.divider, BackgroundTransparency = self.theme.dividerTransparency, Parent = f })
	if text then
		if not el.label then
			el.label = makeText(f, text, self.theme, { size = 12, color = self.theme.textMuted })
			el.label.Position = UDim2.new(0, 10, 0, 0); el.label.Size = UDim2.new(0, 120, 0, h); el.label.Parent = f
		else setText(el.label, text) end
	end
	return f
end

--// Widget: Spacer \\--
function RenderCtx:Spacer(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local h = default(opts.height, 8)
	local w = default(opts.width, 0)
	local f = self:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	f.BackgroundTransparency = 1
	return f
end

--// Widget: Segmented \\--
function RenderCtx:Segmented(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local options = opts.options or {}
	local value = default(opts.value, options[1] or "")
	local onChange = opts.onChange
	local w = default(opts.width, 200)
	local h = default(opts.height, self.theme.controlHeight)
	local f = self:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	f.BackgroundColor3 = self.theme.surface; f.BackgroundTransparency = self.theme.surfaceTransparency
	new("UICorner", { Parent = f, CornerRadius = UDim.new(0, self.theme.radiusSm) })
	new("UIStroke", { Parent = f, Color = self.theme.border, Transparency = self.theme.borderTransparency, Thickness = self.theme.borderWidth })
	local segW = w / #options
	for i, opt in ipairs(options) do
		local b = new("TextButton", { Name = "Seg" .. i, Size = UDim2.new(1/#options, 0, 1, 0), Position = UDim2.new((i-1)/#options, 0, 0, 0), BackgroundTransparency = 1, Text = opt, TextColor3 = self.theme.textMuted, TextTransparency = self.theme.textMutedTransparency, Font = Enum.Font.GothamBold, TextSize = 13, Parent = f, ZIndex = 2 })
		local active = opt == value
		if active then
			b.BackgroundColor3 = self.theme.primary; b.BackgroundTransparency = self.theme.primaryTransparency; b.TextColor3 = self.theme.primaryText; b.TextTransparency = self.theme.primaryTextTransparency
			new("UICorner", { Parent = b, CornerRadius = UDim.new(0, self.theme.radiusSm) })
		end
		b.Activated:Connect(function()
			value = opt
			if onChange then onChange(value) end
		end)
	end
	return value
end

--// Widget: RadioGroup \\--
function RenderCtx:RadioGroup(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local options = opts.options or {}
	local value = default(opts.value, options[1] or "")
	local onChange = opts.onChange
	local w = default(opts.width, 200)
	local h = default(opts.height, #options * self.theme.rowHeight)
	local f = self:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	for i, opt in ipairs(options) do
		local row = new("Frame", { Name = "Row" .. i, Size = UDim2.new(1, 0, 0, self.theme.rowHeight), BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, (i-1) * self.theme.rowHeight), Parent = f })
		local circ = new("Frame", { Name = "Circle", Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 8, 0.5, -9), BackgroundColor3 = self.theme.surface, BackgroundTransparency = self.theme.surfaceTransparency, Parent = row })
		new("UICorner", { Parent = circ, CornerRadius = UDim.new(0, 100) })
		new("UIStroke", { Parent = circ, Color = self.theme.border, Transparency = self.theme.borderTransparency, Thickness = self.theme.borderWidth })
		local inner = new("Frame", { Name = "Inner", Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0.5, -4, 0.5, -4), BackgroundColor3 = self.theme.primary, Visible = opt == value, Parent = circ })
		new("UICorner", { Parent = inner, CornerRadius = UDim.new(0, 100) })
		local lab = new("TextLabel", { Name = "Label", Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 34, 0, 0), BackgroundTransparency = 1, Text = opt, TextColor3 = self.theme.text, TextTransparency = self.theme.textTransparency, Font = Enum.Font.Gotham, TextSize = 14, TextXAlign = TXA_Left, Parent = row })
		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				value = opt
				if onChange then onChange(value) end
			end
		end)
	end
	return value
end

--// Widget: SearchBox \\--
function RenderCtx:SearchBox(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local text = default(opts.text, "")
	local onChange = opts.onChange
	local w = default(opts.width, 200)
	local h = default(opts.height, self.theme.controlHeight)
	local f = self:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	local box = f:FindFirstChild("Box") or new("TextBox", { Name = "Box", Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = text, PlaceholderText = "Search", PlaceholderColor3 = self.theme.textMuted, TextColor3 = self.theme.text, TextTransparency = self.theme.textTransparency, Font = Enum.Font.Gotham, TextSize = 14, TextXAlign = TXA_Left, Parent = f })
	local icon = f:FindFirstChild("Icon") or new("TextLabel", { Name = "Icon", Size = UDim2.new(0, 24, 1, 0), Position = UDim2.new(1, -26, 0, 0), BackgroundTransparency = 1, Text = "🔍", TextColor3 = self.theme.textMuted, TextTransparency = self.theme.textMutedTransparency, Font = Enum.Font.Gotham, TextSize = 16, Parent = f })
	new("UIStroke", { Parent = f, Color = self.theme.border, Transparency = self.theme.borderTransparency, Thickness = self.theme.borderWidth })
	new("UICorner", { Parent = f, CornerRadius = UDim.new(0, self.theme.radiusSm) })
	local changed = false
	local c = box.Changed:Connect(function(p)
		if p == "Text" then text = box.Text; changed = true; if onChange then onChange(text) end end
	end)
	el._connections = el._connections or {}; table.insert(el._connections, c)
	return text, changed
end

--// Widget: NumberBox \\--
function RenderCtx:NumberBox(id, opts)
	opts = opts or {}
	local el = self:get(id)
	local parent = opts.parent or self.content
	local value = default(opts.value, 0)
	local min = default(opts.min, -math.huge); local max = default(opts.max, math.huge)
	local step = default(opts.step, 1)
	local onChange = opts.onChange
	local w = default(opts.width, 120)
	local h = default(opts.height, self.theme.controlHeight)
	local f = self:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	local box = f:FindFirstChild("Box") or new("TextBox", { Name = "Box", Size = UDim2.new(1, -44, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = tostring(value), TextColor3 = self.theme.text, TextTransparency = self.theme.textTransparency, Font = FMono, TextSize = 14, Parent = f })
	new("UIStroke", { Parent = f, Color = self.theme.border, Transparency = self.theme.borderTransparency, Thickness = self.theme.borderWidth })
	new("UICorner", { Parent = f, CornerRadius = UDim.new(0, self.theme.radiusSm) })
	f.BackgroundColor3 = self.theme.input; f.BackgroundTransparency = self.theme.inputTransparency
	local changed = false
	local c = box.Changed:Connect(function(p)
		if p == "Text" then
			local n = tonumber(box.Text)
			if n then value = clamp(n, min, max); box.Text = tostring(value); changed = true; if onChange then onChange(value) end end
		end
	end)
	el._connections = el._connections or {}; table.insert(el._connections, c)
	return value, changed
end

--// Group (section) \\--
local Group = {}
Group.__index = Group

-- Bind all widget methods onto Group by referencing ctx methods
local widgetNames = {"Label","Button","Toggle","Checkbox","Slider","Dropdown","ColorPicker","Textbox","Keybind","Badge","ProgressBar","Separator","Spacer","Segmented","RadioGroup","SearchBox","NumberBox"}
for _, name in ipairs(widgetNames) do
	Group[name] = function(self, id, opts)
		opts = opts or {}
		if not opts.parent then opts.parent = self.content end
		return self.ctx[name](self.ctx, id, opts)
	end
end

function Group:Window(...) error("Group:Window not supported; use gui:Window") end

local function ctxGroup(ctx, id, opts)
	opts = opts or {}
	local el = ctx:get(id)
	local parent = opts.parent or ctx.content
	local title = opts.title
	local w = default(opts.width, 200)
	local h = default(opts.height, 0)
	local f = ctx:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	f.BackgroundColor3 = ctx.theme.card; f.BackgroundTransparency = ctx.theme.cardTransparency
	new("UICorner", { Parent = f, CornerRadius = UDim.new(0, ctx.theme.radius) })
	new("UIStroke", { Parent = f, Color = ctx.theme.border, Transparency = ctx.theme.borderTransparency, Thickness = ctx.theme.borderWidth })
	local content = f:FindFirstChild("Content") or new("Frame", { Name = "Content", Size = UDim2.new(1, -2*ctx.theme.padX, 1, -40), Position = UDim2.new(0, ctx.theme.padX, 0, 38), BackgroundTransparency = 1, Parent = f })
	if title then
		if not el.titleLabel then
			el.titleLabel = makeText(f, title, ctx.theme, { size = 15, color = ctx.theme.textStrong, font = Enum.Font.GothamBold })
			el.titleLabel.Position = UDim2.new(0, ctx.theme.padX, 0, 8); el.titleLabel.Size = UDim2.new(1, -40, 0, 24); el.titleLabel.Parent = f
		else setText(el.titleLabel, title) end
	end
	return setmetatable({ ctx = ctx, id = id, content = content, parent = f, el = el }, Group)
end

--// Window \\--
local Window = {}
Window.__index = Window

function Window:render(ctx)
	local theme = ctx.theme
	local f = ctx:container(self.id, self.parent or ctx.content, self.size, self.position)
	f.BackgroundColor3 = theme.surface; f.BackgroundTransparency = theme.surfaceTransparency
	new("UICorner", { Parent = f, CornerRadius = UDim.new(0, theme.radius) })
	new("UIStroke", { Parent = f, Color = theme.border, Transparency = theme.borderTransparency, Thickness = theme.borderWidth })
	-- title bar
	local bar = f:FindFirstChild("Bar") or new("Frame", { Name = "Bar", Size = UDim2.new(1, 0, 0, theme.controlHeight), BackgroundColor3 = theme.bgAlt, BackgroundTransparency = theme.bgAltTransparency, Parent = f })
	new("UICorner", { Parent = bar, CornerRadius = UDim.new(0, theme.radius) })
	if not self.titleLabel then
		self.titleLabel = makeText(bar, self.title, theme, { size = 15, color = theme.text, font = Enum.Font.GothamBold })
		self.titleLabel.Position = UDim2.new(0, theme.padX, 0, 0); self.titleLabel.Size = UDim2.new(1, -80, 1, 0); self.titleLabel.Parent = bar
	else setText(self.titleLabel, self.title) end
	-- close button
	local close = f:FindFirstChild("Close") or new("TextButton", { Name = "Close", Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -30, 0.5, -12), BackgroundTransparency = 1, Text = "✕", TextColor3 = theme.textMuted, TextTransparency = theme.textMutedTransparency, Font = Enum.Font.GothamBold, TextSize = 16, Parent = bar, ZIndex = 3 })
	close.Activated:Connect(function()
		self.visible = false
		if self.onClose then self.onClose() end
	end)
	local content = f:FindFirstChild("Content") or new("Frame", { Name = "Content", Size = UDim2.new(1, -2*theme.padX, 1, -theme.controlHeight - theme.padY), Position = UDim2.new(0, theme.padX, 0, theme.controlHeight), BackgroundTransparency = 1, Parent = f })
	-- drag
	local dragging = false
	local dragStart, dragOffset
	local inputBegan = bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true; dragStart = input.Position; dragOffset = f.Position
			ctx.dragging = self
		end
	end)
	local inputEnded = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false; ctx.dragging = nil end
	end)
	local moved = UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			f.Position = UDim2.new(dragOffset.X.Scale, dragOffset.X.Offset + delta.X, dragOffset.Y.Scale, dragOffset.Y.Offset + delta.Y)
		end
	end)
	ctx._connections = ctx._connections or {}
	table.insert(ctx._connections, inputBegan); table.insert(ctx._connections, inputEnded); table.insert(ctx._connections, moved)
	f.Visible = default(self.visible, true)
	return f, content
end

function Window:Group(id, opts)
	opts = opts or {}
	opts.parent = self.content
	return ctxGroup(self.ctx, id, opts)
end

--// Gui object \\--
function NovaGUI.new(options)
	options = options or {}
	local self = setmetatable({}, NovaGUI)
	_getServices()
	local screen = CoreGui:FindFirstChild("NovaGUI") or new("ScreenGui", { Name = "NovaGUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
	if screen.Parent ~= CoreGui then pcall(function() screen.Parent = CoreGui end) end
	if screen.Parent == nil then screen.Parent = PlayerGui or CoreGui end
	local content = screen:FindFirstChild("NovaContent") or new("Frame", { Name = "NovaContent", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = screen })
	local theme = resolveTheme(options.theme)
	self.theme = theme
	self.screen = screen
	self.content = content
	self.ctx = RenderCtx.new(self)
	self.windows = {}
	self.groups = {}
	self.slots = {}
	self.events = {}
	self.scale = default(options.scale, 1)
	self.persist = default(options.persist, true)
	self.persistKey = default(options.persistKey, "nova")
	return self
end

function NovaGUI:setTheme(spec)
	self.theme = resolveTheme(spec)
	self.ctx.theme = self.theme
end

function NovaGUI:getTheme() return deepCopy(self.theme) end

function NovaGUI:patchTheme(partial)
	if type(partial) == "table" then merge(self.theme, partial) end
	self.ctx.theme = self.theme
end

function NovaGUI:resetTheme()
	self.theme = deepCopy(DEFAULT_THEME)
	self.ctx.theme = self.theme
end

function NovaGUI:Window(id, opts)
	opts = opts or {}
	opts.parent = self.content
	local w = setmetatable({ ctx = self.ctx, id = id, title = default(opts.title, id), size = default(opts.size, UDim2.new(0, 420, 0, 300)), position = default(opts.position, UDim2.new(0.5, -210, 0.5, -150)), visible = true, parent = self.content, onClose = opts.onClose }, Window)
	self.windows[id] = w
	return w
end

function NovaGUI:TabBar(id, opts)
	-- minimal tabbar
	opts = opts or {}
	local el = self.ctx:get(id)
	local parent = opts.parent or self.content
	local tabs = opts.tabs or {}
	local active = opts.active or tabs[1] or ""
	local w = default(opts.width, 400)
	local h = default(opts.height, 40)
	local f = self.ctx:container(id, parent, UDim2.new(0, w, 0, h), opts.position)
	f.BackgroundColor3 = self.theme.surface; f.BackgroundTransparency = self.theme.surfaceTransparency
	new("UICorner", { Parent = f, CornerRadius = UDim.new(0, self.theme.radiusSm) })
	new("UIStroke", { Parent = f, Color = self.theme.border, Transparency = self.theme.borderTransparency, Thickness = self.theme.borderWidth })
	for i, tname in ipairs(tabs) do
		local b = new("TextButton", { Name = "Tab" .. i, Size = UDim2.new(1/#tabs, 0, 1, 0), Position = UDim2.new((i-1)/#tabs, 0, 0, 0), BackgroundTransparency = 1, Text = tname, TextColor3 = self.theme.textMuted, TextTransparency = self.theme.textMutedTransparency, Font = Enum.Font.GothamBold, TextSize = 14, Parent = f })
		if tname == active then b.BackgroundColor3 = self.theme.primary; b.BackgroundTransparency = self.theme.primaryTransparency; b.TextColor3 = self.theme.primaryText; b.TextTransparency = self.theme.primaryTextTransparency end
		b.Activated:Connect(function()
			active = tname
			if opts.onChange then opts.onChange(active) end
		end)
	end
	return active
end

function NovaGUI:Notify(text, opts)
	opts = opts or {}
	local duration = default(opts.duration, 4)
	local f = new("Frame", { Name = "Notify", Size = UDim2.new(0, 300, 0, 50), Position = UDim2.new(1, -320, 1, -70), BackgroundColor3 = self.theme.surface, BackgroundTransparency = self.theme.surfaceTransparency, Parent = self.screen, ZIndex = 100 })
	new("UICorner", { Parent = f, CornerRadius = UDim.new(0, self.theme.radiusSm) })
	new("UIStroke", { Parent = f, Color = self.theme.border, Transparency = self.theme.borderTransparency, Thickness = self.theme.borderWidth })
	local lab = makeText(f, text, self.theme, { size = 14, color = self.theme.text })
	lab.Size = UDim2.new(1, -20, 1, 0); lab.Position = UDim2.new(0, 10, 0, 0); lab.Parent = f
	task.delay(duration, function()
		TweenService:Create(f, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		task.delay(0.3, function() f:Destroy() end)
	end)
	return f
end

function NovaGUI:Modal(id, opts)
	-- placeholder modal
	opts = opts or {}
	local f = new("Frame", { Name = "Modal_" .. id, Size = UDim2.new(0, 400, 0, 250), Position = UDim2.new(0.5, -200, 0.5, -125), BackgroundColor3 = self.theme.popover, BackgroundTransparency = self.theme.popoverTransparency, Parent = self.screen, ZIndex = 200 })
	new("UICorner", { Parent = f, CornerRadius = UDim.new(0, self.theme.radiusLg) })
	new("UIStroke", { Parent = f, Color = self.theme.border, Transparency = self.theme.borderTransparency, Thickness = self.theme.borderWidth })
	return setmetatable({ ctx = self.ctx, id = id, content = f, parent = f, visible = true }, Group)
end

function NovaGUI:ContextMenu(id, opts)
	return self:Modal(id, opts)
end

function NovaGUI:Tooltip(text, anchor) end

function NovaGUI:ExportTheme(format)
	format = default(format, "lua")
	if format == "json" then
		return game:GetService("HttpService"):JSONEncode(self.theme)
	end
	return toHex  -- placeholder
end

function NovaGUI:ImportTheme(spec)
	self:setTheme(spec)
end

function NovaGUI:Save(slot)
	self.slots[slot or "default"] = { theme = deepCopy(self.theme), time = tick() }
end

function NovaGUI:Load(slot)
	local s = self.slots[slot or "default"]
	if s then self:setTheme(s.theme) end
end

function NovaGUI:ClearSlots() self.slots = {} end

function NovaGUI:SetScale(n) self.scale = clamp(n, 0.5, 2); self.content.Size = UDim2.new(1, 0, 1, 0) end

function NovaGUI:On(event, handler)
	self.events[event] = self.events[event] or {}
	table.insert(self.events[event], handler)
end

function NovaGUI:Off(event, handler)
	if not self.events[event] then return end
	for i, h in ipairs(self.events[event]) do if h == handler then table.remove(self.events[event], i); break end end
end

function NovaGUI:Destroy()
	for _, c in pairs(self.ctx._connections or {}) do pcall(function() c:Disconnect() end) end
	self.screen:Destroy()
end

--// Render loop (immediate mode driver) \\--
local function renderLoop(gui)
	local conn = RunService.RenderStepped:Connect(function()
		-- nothing automatic; user drives widget calls
	end)
	return conn
end

NovaGUI._renderLoop = renderLoop

--// Expose element utilities \\--
NovaGUI.makeText = makeText
NovaGUI.newInstance = new

return NovaGUI