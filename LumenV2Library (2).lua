-- LUMEN V2 (library only: returns the Lumen table)
return (function()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Lumen = { Flags = {}, _setters = {}, _win = nil }

local Window = {}
Window.__index = Window

local Container = {}
Container.__index = Container

local Tab = setmetatable({}, { __index = Container })
Tab.__index = Tab

local Section = setmetatable({}, { __index = Container })
Section.__index = Section

---------------------------------------------------------------------
-- themes (colours taken from WindUI's theme reference)
---------------------------------------------------------------------
local function hex(h)
	return Color3.fromHex(h)
end

local function theme(t)
	t.Outline = t.Outline or Color3.new(1, 1, 1)
	t.Panel = t.Panel or Color3.new(1, 1, 1)
	t.Toggle = t.Toggle or t.Button
	t.Slider = t.Slider or t.Button
	t.Checkbox = t.Checkbox or t.Button
	return t
end

local Themes = {
	Dark = theme({
		Background = hex("#101010"),
		Accent = hex("#18181b"),
		Dialog = hex("#161616"),
		Text = hex("#ffffff"),
		Placeholder = hex("#7a7a7a"),
		Button = hex("#52525b"),
		Icon = hex("#a1a1aa"),
		Toggle = hex("#33c759"),
		Slider = hex("#0091ff"),
		Checkbox = hex("#0091ff"),
	}),
	Light = theme({
		Background = hex("#f4f4f5"),
		Accent = hex("#e4e4e7"),
		Dialog = hex("#ffffff"),
		Text = hex("#09090b"),
		Placeholder = hex("#71717a"),
		Button = hex("#18181b"),
		Icon = hex("#52525b"),
		Toggle = hex("#33c759"),
		Slider = hex("#0091ff"),
		Checkbox = hex("#0091ff"),
		Outline = Color3.new(0, 0, 0),
		Panel = Color3.new(0, 0, 0),
	}),
	Rose = theme({
		Background = hex("#1f0308"),
		Accent = hex("#be185d"),
		Dialog = hex("#4c0519"),
		Text = hex("#fdf2f8"),
		Placeholder = hex("#d67aa6"),
		Button = hex("#e95f74"),
		Icon = hex("#fb7185"),
	}),
	Plant = theme({
		Background = hex("#0a1b0f"),
		Accent = hex("#166534"),
		Dialog = hex("#052e16"),
		Text = hex("#f0fdf4"),
		Placeholder = hex("#4fbf7a"),
		Button = hex("#16a34a"),
		Icon = hex("#4ade80"),
	}),
	Red = theme({
		Background = hex("#1c0606"),
		Accent = hex("#991b1b"),
		Dialog = hex("#450a0a"),
		Text = hex("#fef2f2"),
		Placeholder = hex("#d95353"),
		Button = hex("#dc2626"),
		Icon = hex("#ef4444"),
	}),
	Indigo = theme({
		Background = hex("#0f0a2e"),
		Accent = hex("#3730a3"),
		Dialog = hex("#1e1b4b"),
		Text = hex("#f1f5f9"),
		Placeholder = hex("#7078d9"),
		Button = hex("#4f46e5"),
		Icon = hex("#6366f1"),
	}),
}

local F = {
	Regular = Enum.Font.BuilderSans,
	Medium = Enum.Font.BuilderSansMedium,
	Bold = Enum.Font.BuilderSansBold,
}

local PANEL_T = 0.95
local PANEL_HOVER = 0.91
local STROKE_T = 0.92

---------------------------------------------------------------------
-- icons
---------------------------------------------------------------------
Lumen.Icons = {
	home = "⌂",
	settings = "⚙",
	star = "★",
	sword = "⚔",
	user = "☻",
	info = "i",
	check = "✓",
	x = "×",
	bell = "♪",
	search = "⌕",
	palette = "◐",
	zap = "ϟ",
	bird = "✦",
	rocket = "➤",
	bug = "✱",
	wrench = "⚒",
}

function Lumen:AddIcons(map)
	for k, v in pairs(map) do
		self.Icons[k] = v
	end
end

---------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------
local function create(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, c in ipairs(children or {}) do
		c.Parent = inst
	end
	inst.Parent = parent
	return inst
end

local function tween(obj, props, t, style, dir)
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function corner(obj, r)
	return create("UICorner", { CornerRadius = UDim.new(0, r), Parent = obj })
end

local function stroke(obj, color, transparency, thickness)
	return create("UIStroke", {
		Color = color,
		Transparency = transparency or STROKE_T,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = obj,
	})
end

local function padding(obj, l, t, r, b)
	return create("UIPadding", {
		PaddingLeft = UDim.new(0, l),
		PaddingTop = UDim.new(0, t),
		PaddingRight = UDim.new(0, r),
		PaddingBottom = UDim.new(0, b),
		Parent = obj,
	})
end

local function listLayout(parent, pad, props)
	local p = { Padding = UDim.new(0, pad or 0), SortOrder = Enum.SortOrder.LayoutOrder, Parent = parent }
	for k, v in pairs(props or {}) do
		p[k] = v
	end
	return create("UIListLayout", p)
end

local function label(parent, str, size, font, color, props)
	local p = {
		BackgroundTransparency = 1,
		Text = str,
		Font = font or F.Medium,
		TextSize = size or 14,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	}
	for k, v in pairs(props or {}) do
		p[k] = v
	end
	return create("TextLabel", p)
end

local function fire(cb, ...)
	if type(cb) ~= "function" then
		return
	end
	task.spawn(function(...)
		local ok, err = pcall(cb, ...)
		if not ok then
			warn("[Lumen] callback error: " .. tostring(err))
		end
	end, ...)
end

local function panelT(s)
	return 0.86 + 0.11 * s -- s: 0 = frosted, 1 = clear
end

local function bgT(s)
	return 0.3 * s
end

local NSK = NumberSequenceKeypoint.new

-- Liquid Glass specular rim: bright at the top-left and bottom-right corners
local function glassStroke(obj, base)
	local s = stroke(obj, Color3.new(1, 1, 1), base or 0.45)
	create("UIGradient", {
		Rotation = 45,
		Transparency = NumberSequence.new({ NSK(0, 0), NSK(0.45, 0.7), NSK(0.55, 0.7), NSK(1, 0.1) }),
		Parent = s,
	})
	return s
end

-- diagonal sheen on a normal frame (top-left brighter)
local function sheen(obj, amt)
	return create("UIGradient", {
		Rotation = 60,
		Transparency = NumberSequence.new({ NSK(0, 0), NSK(1, amt or 0.6) }),
		Parent = obj,
	})
end

-- sheen overlay for CanvasGroups (a gradient on the group itself would fade its children)
local function sheenFrame(parent, radius)
	local s = create("Frame", {
		Name = "Sheen",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Parent = parent,
	})
	corner(s, radius)
	create("UIGradient", {
		Rotation = 55,
		Transparency = NumberSequence.new({ NSK(0, 0), NSK(0.55, 0.8), NSK(1, 1) }),
		Parent = s,
	})
	return s
end

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function isMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

local function hit(parent)
	return create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
		Parent = parent,
	})
end

local function makeIcon(parent, icon, size, color)
	if icon == nil or icon == "" then
		return nil
	end
	local resolved = Lumen.Icons[icon] or icon
	if type(resolved) == "number" then
		resolved = "rbxassetid://" .. resolved
	end
	if type(resolved) == "string" and string.find(resolved, "^rbx") or (type(resolved) == "string" and string.find(resolved, "^https?://")) then
		return create("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(size, size),
			Image = resolved,
			ImageColor3 = color,
			Parent = parent,
		})
	end
	local glyph = tostring(resolved)
	if not string.find(glyph, "[\128-\255]") and #glyph > 1 then
		glyph = string.upper(string.sub(glyph, 1, 1)) -- unknown icon name -> first letter
	end
	return label(parent, glyph, math.floor(size * 0.95), F.Bold, color, {
		Size = UDim2.fromOffset(size, size),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
end

local function toHex(c)
	return string.format("#%02X%02X%02X", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
end

---------------------------------------------------------------------
-- config
---------------------------------------------------------------------
function Lumen:SaveConfig()
	local out = {}
	for k, v in pairs(self.Flags) do
		out[k] = (typeof(v) == "Color3") and { __c = { v.R, v.G, v.B } } or v
	end
	return HttpService:JSONEncode(out)
end

function Lumen:LoadConfig(json)
	local ok, data = pcall(HttpService.JSONDecode, HttpService, json)
	if not ok or type(data) ~= "table" then
		return false
	end
	for k, v in pairs(data) do
		local setter = self._setters[k]
		if setter then
			if type(v) == "table" and v.__c then
				v = Color3.new(v.__c[1], v.__c[2], v.__c[3])
			end
			setter(v)
		end
	end
	return true
end

local function flagSet(o, v)
	if o.Flag then
		Lumen.Flags[o.Flag] = v
	end
end

local function flagReg(o, initial, setter)
	if o.Flag then
		Lumen.Flags[o.Flag] = initial
		Lumen._setters[o.Flag] = setter
	end
end

---------------------------------------------------------------------
-- window
---------------------------------------------------------------------
function Lumen:CreateWindow(o)
	o = o or {}
	local T = Themes[o.Theme or "Dark"] or Themes.Dark
	local size = o.Size or UDim2.fromOffset(580, 460)
	local sidebarW = o.SideBarWidth or 190

	local self = setmetatable({
		T = T,
		Tabs = {},
		Current = nil,
		Visible = true,
		Fullscreen = false, Glass = math.clamp(o.Glass or 0, 0, 1), _glassObjs = {}, _conns = {}, _popStore = {}, _order = 0,
	}, Window)
	Lumen._win = self

	local gui = create("ScreenGui", {
		Name = "Lumen_" .. tostring(o.Title or "UI"),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
		IgnoreGuiInset = true,
	})
	gui.Parent = o.Parent or Players.LocalPlayer:WaitForChild("PlayerGui")
	self.Gui = gui

	local main = create("CanvasGroup", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = size,
		BackgroundColor3 = T.Background,
		BackgroundTransparency = bgT(self.Glass),
		GroupTransparency = 1,
		Parent = gui,
	})
	corner(main, 30)
glassStroke(main, 0.5)
sheenFrame(main, 30)
	local uiScale = create("UIScale", { Scale = 0.94, Parent = main })
	self.Main, self.UIScale = main, uiScale
table.insert(self._glassObjs, { main, "bg" })
if o.Blur ~= false then
	local Lighting = game:GetService("Lighting")
	self._blur = Lighting:FindFirstChild("LumenBlur") or create("BlurEffect", { Name = "LumenBlur", Size = 0, Parent = Lighting })
	self._blurSize = o.BlurSize or 14
end

	local function fit()
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local vp = cam.ViewportSize
		self._fit = math.clamp(math.min(vp.X / (size.X.Offset + 120), vp.Y / (size.Y.Offset + 120), 1), 0.55, 1)
		if self.Visible then
			uiScale.Scale = self._fit
		end
		if self.Fullscreen then
			main.Size = UDim2.fromOffset((vp.X - 40) / self._fit, (vp.Y - 40) / self._fit)
		end
	end
	fit()
	if workspace.CurrentCamera then
		self:_track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit))
	end

	-- topbar ---------------------------------------------------------
	local topbar = create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
		Parent = main,
	})
	create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = T.Outline,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Parent = topbar,
	})

	local left = create("Frame", {
		Position = UDim2.fromOffset(88, 0),
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = topbar,
	})
	listLayout(left, 10, {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	local winIcon = makeIcon(left, o.Icon, 22, T.Text)
	if winIcon then
		winIcon.LayoutOrder = 1
	end
	local titleBlock = create("Frame", {
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = left,
	})
	listLayout(titleBlock, 0)
	label(titleBlock, tostring(o.Title or "Lumen"), 16, F.Bold, T.Text, {
		Size = UDim2.new(0, 0, 0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 1,
	})
	if o.Author then
		label(titleBlock, tostring(o.Author), 12, F.Regular, T.Text, {
			Size = UDim2.new(0, 0, 0, 14),
			AutomaticSize = Enum.AutomaticSize.X,
			TextTransparency = 0.5,
			LayoutOrder = 2,
		})
	end
	self.TagHolder = create("Frame", {
		Size = UDim2.new(0, 0, 0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = left,
	})
	listLayout(self.TagHolder, 6, { FillDirection = Enum.FillDirection.Horizontal })

	-- macOS traffic lights (close / minimise / zoom), top-left ----------
	local lights = create("Frame", {
		Name = "TrafficLights",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(60, 20),
		BackgroundTransparency = 1,
		Parent = topbar,
	})
	local glyphs = {} -- { object, property } pairs, revealed while the group is hovered
	local hovering = 0
	local function showGlyphs(on)
		for _, g in ipairs(glyphs) do
			tween(g[1], { [g[2]] = on and 0 or 1 }, 0.1)
		end
	end

	local function light(idx, color, border, pressedColor, glyphColor, build)
		local hitBtn = create("TextButton", {
			Position = UDim2.fromOffset((idx - 1) * 20, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Parent = lights,
		})
		local dot = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = color,
			Parent = hitBtn,
		})
		corner(dot, 6)
		create("UIStroke", { Color = border, Thickness = 1, Transparency = 0.3, Parent = dot })
		for _, g in ipairs(build(dot, glyphColor)) do
			table.insert(glyphs, g)
		end
		hitBtn.MouseEnter:Connect(function()
			hovering += 1
			showGlyphs(true)
		end)
		hitBtn.MouseLeave:Connect(function()
			hovering = math.max(hovering - 1, 0)
			task.delay(0.04, function()
				if hovering == 0 then
					showGlyphs(false)
				end
			end)
			tween(dot, { BackgroundColor3 = color }, 0.1)
		end)
		hitBtn.MouseButton1Down:Connect(function()
			tween(dot, { BackgroundColor3 = pressedColor }, 0.05)
		end)
		hitBtn.MouseButton1Up:Connect(function()
			tween(dot, { BackgroundColor3 = color }, 0.1)
		end)
		return hitBtn
	end

	local function bar(parent, w, rot, color)
		local f = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(w, 1.5),
			Rotation = rot,
			BackgroundColor3 = color,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = parent,
		})
		return { f, "BackgroundTransparency" }
	end
	local function tri(parent, glyph, pos, anchor, color)
		local l = label(parent, glyph, 7, F.Bold, color, {
			AnchorPoint = anchor,
			Position = pos,
			Size = UDim2.fromOffset(6, 6),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTransparency = 1,
		})
		return { l, "TextTransparency" }
	end

	local closeBtn = light(1, hex("#ff5f57"), hex("#e0443e"), hex("#bf4943"), hex("#4d0000"), function(dot, c)
		return { bar(dot, 7.5, 45, c), bar(dot, 7.5, -45, c) }
	end)
	local minBtn = light(2, hex("#febc2e"), hex("#dea123"), hex("#bf9123"), hex("#985600"), function(dot, c)
		return { bar(dot, 8, 0, c) }
	end)
	local fullBtn = light(3, hex("#28c840"), hex("#1aab29"), hex("#1f9a30"), hex("#0a640f"), function(dot, c)
		return {
			tri(dot, "◤", UDim2.new(0, 1, 0, 1), Vector2.new(0, 0), c),
			tri(dot, "◢", UDim2.new(1, -1, 1, -1), Vector2.new(1, 1), c),
		}
	end)

	do -- dragging
		local dragging, dragStart, startPos
		topbar.InputBegan:Connect(function(i)
			if isPress(i) and not self.Fullscreen then
				dragging, dragStart, startPos = true, i.Position, main.Position
			end
		end)
		self:_track(UserInputService.InputChanged:Connect(function(i)
			if dragging and isMove(i) then
				local d = i.Position - dragStart
				main.Position =
					UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end))
		self:_track(UserInputService.InputEnded:Connect(function(i)
			if isPress(i) then
				dragging = false
			end
		end))
	end

	-- sidebar --------------------------------------------------------
	local sidebar = create("Frame", {
		Name = "Sidebar",
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(0, sidebarW, 1, -52),
		BackgroundTransparency = 1,
		Parent = main,
	})
	create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = T.Outline,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Parent = sidebar,
	})

	local searchY = 0
	if not o.HideSearchBar then
		local sf = create("Frame", {
			Position = UDim2.fromOffset(12, 12),
			Size = UDim2.new(1, -25, 0, 34),
			BackgroundColor3 = T.Panel,
			BackgroundTransparency = 0.93,
			Parent = sidebar,
		})
		corner(sf, 17)
local sst = glassStroke(sf, 0.6)
		label(sf, "⌕", 18, F.Bold, T.Icon, {
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.fromOffset(18, 34),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		local search = create("TextBox", {
			Position = UDim2.fromOffset(34, 0),
			Size = UDim2.new(1, -42, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			PlaceholderText = "Search",
			PlaceholderColor3 = T.Placeholder,
			TextColor3 = T.Text,
			Font = F.Medium,
			TextSize = 14,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = sf,
		})
		search.Focused:Connect(function()
			tween(sst, { Transparency = 0.25 }, 0.15)
		end)
		search.FocusLost:Connect(function()
			tween(sst, { Transparency = 0.6 }, 0.15)
		end)
		search:GetPropertyChangedSignal("Text"):Connect(function()
			self:_applySearch()
		end)
		self.SearchBox = search
		searchY = 58
	end

	local userH = 0
	if o.User then
		userH = 56
		local uf = create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 12, 1, -12),
			Size = UDim2.new(1, -25, 0, 44),
			BackgroundColor3 = T.Panel,
			BackgroundTransparency = 0.95,
			Parent = sidebar,
		})
		corner(uf, 12)
		stroke(uf, T.Outline, STROKE_T)
		local lp = Players.LocalPlayer
		local av = create("ImageLabel", {
			Position = UDim2.fromOffset(8, 6),
			Size = UDim2.fromOffset(32, 32),
			BackgroundColor3 = T.Panel,
			BackgroundTransparency = 0.9,
			Parent = uf,
		})
		corner(av, 16)
		task.spawn(function()
			local ok, img = pcall(Players.GetUserThumbnailAsync, Players, lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			if ok and av.Parent then
				av.Image = img
			end
		end)
		label(uf, lp.DisplayName, 14, F.Bold, T.Text, {
			Position = UDim2.fromOffset(48, 6),
			Size = UDim2.new(1, -56, 0, 17),
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		label(uf, "@" .. lp.Name, 12, F.Regular, T.Text, {
			Position = UDim2.fromOffset(48, 23),
			Size = UDim2.new(1, -56, 0, 14),
			TextTransparency = 0.5,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
	end

	local tabList = create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, searchY),
		Size = UDim2.new(1, -1, 1, -(searchY + userH)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sidebar,
	})
	listLayout(tabList, 4)
	padding(tabList, 12, 4, 12, 8)
	self.TabList = tabList

	-- content --------------------------------------------------------
	self.Content = create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(sidebarW, 52),
		Size = UDim2.new(1, -sidebarW, 1, -52),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = main,
	})

	-- notifications --------------------------------------------------
	local holder = create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 300, 1, -32),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	listLayout(holder, 8, {
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	})
	self.NotifyHolder = holder

	-- dynamic island (shown while the window is closed) ---------------
	-- 126x37 pure-black capsule, 11px from the top, like the iPhone 14 Pro+ island.
	-- The window shrinks into it; it pops in with a spring, long-press peeks the
	-- title, and notifications expand it like a Live Activity.
	local RunService = game:GetService("RunService")
	local IW, IH, ITOP = 126, 37, 11
	local winTitle = tostring(o.Title or "Lumen")
	local BLACK, WHITE = Color3.new(0, 0, 0), Color3.new(1, 1, 1)

	local island = create("TextButton", {
		Name = "DynamicIsland",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, ITOP),
		Size = UDim2.fromOffset(IW, IH),
		BackgroundColor3 = BLACK,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 300,
		Parent = gui,
	})
	local islandCorner = create("UICorner", { CornerRadius = UDim.new(0, IH / 2), Parent = island })
	local islandScale = create("UIScale", { Scale = 1, Parent = island })
	self.Island = island

	-- compact layer: leading icon + trailing waveform
	local compact = create("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = island,
	})
	local cIcon = makeIcon(compact, o.Icon or "star", 16, WHITE)
	if cIcon then
		cIcon.AnchorPoint = Vector2.new(0, 0.5)
		cIcon.Position = UDim2.new(0, 14, 0.5, 0)
	end
	local waveHolder = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(17, 16),
		BackgroundTransparency = 1,
		Parent = compact,
	})
	local bars = {}
	for i = 1, 3 do
		local bar = create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, (i - 1) * 7, 0.5, 0),
			Size = UDim2.fromOffset(3, 6),
			BackgroundColor3 = T.Toggle,
			BorderSizePixel = 0,
			Parent = waveHolder,
		})
		corner(bar, 2)
		bars[i] = bar
	end
	self:_track(RunService.RenderStepped:Connect(function()
		if island.Visible then
			local t = os.clock()
			for i, bar in ipairs(bars) do
				bar.Size = UDim2.fromOffset(3, 4 + 11 * math.abs(math.sin(t * (3 + i * 1.3) + i)))
			end
		end
	end))

	-- expanded layer: icon + title + text
	local expanded = create("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Parent = island,
	})
	local expIcon = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 20, 0.5, 0),
		Size = UDim2.fromOffset(28, 28),
		BackgroundTransparency = 1,
		Parent = expanded,
	})
	local expTitle = label(expanded, "", 15, F.Bold, WHITE, {
		Position = UDim2.fromOffset(62, 16),
		Size = UDim2.new(1, -82, 0, 20),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local expBody = label(expanded, "", 13, F.Regular, WHITE, {
		Position = UDim2.fromOffset(62, 38),
		Size = UDim2.new(1, -82, 0, 18),
		TextTransparency = 0.45,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local function expand(w, h)
		tween(island, { Size = UDim2.fromOffset(w, h) }, 0.6, Enum.EasingStyle.Back)
		tween(islandCorner, { CornerRadius = UDim.new(0, math.min(h / 2, 40)) }, 0.6, Enum.EasingStyle.Back)
		tween(compact, { GroupTransparency = 1 }, 0.12)
		task.delay(0.12, function()
			tween(expanded, { GroupTransparency = 0 }, 0.3)
		end)
	end
	local function collapse()
		tween(expanded, { GroupTransparency = 1 }, 0.12)
		tween(island, { Size = UDim2.fromOffset(IW, IH) }, 0.55, Enum.EasingStyle.Back)
		tween(islandCorner, { CornerRadius = UDim.new(0, IH / 2) }, 0.55, Enum.EasingStyle.Back)
		tween(compact, { GroupTransparency = 0 }, 0.3)
	end
	local function islandShow()
		island.Visible = true
		islandScale.Scale = 0.55
		tween(islandScale, { Scale = 1 }, 0.6, Enum.EasingStyle.Back)
	end
	local function islandHide()
		tween(islandScale, { Scale = 0.6 }, 0.15)
		task.delay(0.15, function()
			if self.Visible then
				island.Visible = false
				island.Size = UDim2.fromOffset(IW, IH)
				islandCorner.CornerRadius = UDim.new(0, IH / 2)
				expanded.GroupTransparency = 1
				compact.GroupTransparency = 0
			end
		end)
	end

	-- peek: expand the island with a title + text (also used for notifications)
	function self:IslandPeek(n)
		self._peekToken = (self._peekToken or 0) + 1
		local token = self._peekToken
		expTitle.Text = tostring(n.Title or "Notification")
		expBody.Text = tostring(n.Content or "")
		expIcon:ClearAllChildren()
		makeIcon(expIcon, n.Icon or o.Icon or "star", 28, WHITE)
		if not island.Visible then
			islandShow()
		end
		expand(340, 74)
		task.delay(n.Duration or 4, function()
			if self._peekToken == token and not self.Visible then
				collapse()
			end
		end)
	end

	do -- press = squish up, hold = peek, tap = open
		local downId = 0
		local heldPeek = false
		island.MouseButton1Down:Connect(function()
			downId += 1
			local id = downId
			heldPeek = false
			tween(islandScale, { Scale = 1.06 }, 0.3, Enum.EasingStyle.Back)
			task.delay(0.4, function()
				if downId == id and not heldPeek then
					heldPeek = true
					self:IslandPeek({ Title = winTitle, Content = "Tap to open", Icon = o.Icon, Duration = 2.5 })
				end
			end)
		end)
		island.MouseButton1Up:Connect(function()
			local wasHold = heldPeek
			downId += 1
			tween(islandScale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
			if not wasHold then
				self:SetVisible(true)
			end
		end)
		island.MouseLeave:Connect(function()
			downId += 1
			tween(islandScale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
		end)
	end

	-- visibility: the window morphs into / out of the island -----------
	function self:SetVisible(state)
		local was = self.Visible
		self.Visible = state
		self:_closePopup()
		if self._blur then
			tween(self._blur, { Size = state and self._blurSize or 0 }, 0.35)
		end
		local islandPos = UDim2.new(0.5, 0, 0, ITOP + IH / 2)
		if state then
			self._animating = true
			self._peekToken = (self._peekToken or 0) + 1
			islandHide()
			local home = self._home or UDim2.fromScale(0.5, 0.5)
			main.Visible = true
			main.Position = islandPos
			main.GroupTransparency = 1
			uiScale.Scale = 0.04
			tween(main, { Position = home, GroupTransparency = 0 }, 0.5, Enum.EasingStyle.Quint)
			tween(uiScale, { Scale = self._fit or 1 }, 0.6, Enum.EasingStyle.Back)
			task.delay(0.6, function()
				self._animating = false
			end)
		else
			if was and not self._animating then
				self._home = main.Position
			end
			tween(main, { Position = islandPos, GroupTransparency = 1 }, 0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			tween(uiScale, { Scale = 0.04 }, 0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			task.delay(0.26, function()
				if not self.Visible then
					islandShow()
				end
			end)
			task.delay(0.4, function()
				if not self.Visible and main.Parent then
					main.Visible = false
				end
			end)
		end
	end
	function self:Toggle()
		self:SetVisible(not self.Visible)
	end

	minBtn.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		self:Destroy()
	end)
	fullBtn.MouseButton1Click:Connect(function()
		self.Fullscreen = not self.Fullscreen
		local cam = workspace.CurrentCamera
		if self.Fullscreen and cam then
			local vp = cam.ViewportSize
			self._prevPos = main.Position
			tween(main, { Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset((vp.X - 40) / uiScale.Scale, (vp.Y - 40) / uiScale.Scale) }, 0.35)
		else
			tween(main, { Position = self._prevPos or UDim2.fromScale(0.5, 0.5), Size = size }, 0.35)
		end
	end)

	local toggleKey = o.ToggleKey or Enum.KeyCode.RightShift
	self:_track(UserInputService.InputBegan:Connect(function(i, gp)
		if not gp and i.KeyCode == toggleKey then
			self:Toggle()
		end
	end))

	self:SetVisible(true)
	return self
end

-- iOS 27-style "Liquid Glass" strength: 0 = frosted/opaque, 1 = clear
function Window:SetGlass(s)
	s = math.clamp(s, 0, 1)
	self.Glass = s
	for _, e in ipairs(self._glassObjs) do
		if e[1].Parent then
			tween(e[1], { BackgroundTransparency = (e[2] == "bg") and bgT(s) or panelT(s) }, 0.25)
		end
	end
end

function Lumen:SetGlass(s)
	if self._win then
		self._win:SetGlass(s)
	end
end

function Window:_track(conn)
	table.insert(self._conns, conn)
	return conn
end

function Window:Destroy()
	if self._blur then
		self._blur:Destroy()
	end
	self:_closePopup()
	for _, c in ipairs(self._conns) do
		c:Disconnect()
	end
	table.clear(self._conns)
	self.Gui:Destroy()
end

function Window:_drag(hitObj, scroller, cb, store)
	store = store or self._conns
	local active = false
	hitObj.InputBegan:Connect(function(i)
		if isPress(i) then
			active = true
			if scroller then
				scroller.ScrollingEnabled = false
			end
			cb(Vector2.new(i.Position.X, i.Position.Y))
		end
	end)
	table.insert(store, UserInputService.InputChanged:Connect(function(i)
		if active and isMove(i) then
			cb(Vector2.new(i.Position.X, i.Position.Y))
		end
	end))
	table.insert(store, UserInputService.InputEnded:Connect(function(i)
		if active and isPress(i) then
			active = false
			if scroller then
				scroller.ScrollingEnabled = true
			end
		end
	end))
end

-- floating popup anchored under an element (dropdown / colour picker)
function Window:_popup(anchor, w, h, align)
	self:_closePopup()
	local gui = self.Gui
	local scale = self.UIScale.Scale
	local catcher = create("TextButton", {
		Name = "PopupCatcher",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 190,
		Parent = gui,
	})
	local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
	local vp = gui.AbsoluteSize
	local pw, ph = w * scale, h * scale
	local x = (align == "right") and (ap.X + as.X - pw) or ap.X
	x = math.clamp(x, 8, math.max(vp.X - pw - 8, 8))
	local y = ap.Y + as.Y + 6
	if y + ph > vp.Y - 8 then
		y = ap.Y - ph - 6
	end
	y = math.max(y, 8)
	local pop = create("Frame", {
		Name = "Popup",
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = self.T.Dialog,
		BackgroundTransparency = 0.05,
		ZIndex = 200,
		Parent = gui,
	})
	corner(pop, 24)
	glassStroke(pop, 0.5)
	sheen(pop, 0.35)
	local ps = create("UIScale", { Scale = scale * 0.94, Parent = pop })
	tween(ps, { Scale = scale }, 0.2, Enum.EasingStyle.Back)
	self._pop = { catcher, pop }
	catcher.MouseButton1Click:Connect(function()
		self:_closePopup()
	end)
	return pop
end

function Window:_closePopup()
	if self._pop then
		for _, o in ipairs(self._pop) do
			o:Destroy()
		end
		self._pop = nil
	end
	for _, c in ipairs(self._popStore) do
		c:Disconnect()
	end
	table.clear(self._popStore)
end

local function filter(list, q)
	local any = false
	for _, e in ipairs(list) do
		local own = (q == "") or (string.find(string.lower(e.Name), q, 1, true) ~= nil)
		local childAny = false
		if e.Children then
			childAny = filter(e.Children, own and "" or q)
		end
		local show = own or childAny
		e.Frame.Visible = show
		any = any or show
	end
	return any
end

function Window:_applySearch()
	if self.Current and self.SearchBox then
		filter(self.Current.Elements, string.lower(self.SearchBox.Text))
	end
end

---------------------------------------------------------------------
-- notifications / dialogs / tags
---------------------------------------------------------------------
function Window:Notify(o)
	if not self.Visible and self.IslandPeek then
		self:IslandPeek(o)
		return
	end
	local T = self.T
	local wrap = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = self.NotifyHolder,
	})
	local card = create("Frame", {
		Position = UDim2.new(1.2, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.Dialog,
		BackgroundTransparency = 0.05,
		ClipsDescendants = true,
		Parent = wrap,
	})
	corner(card, 22)
	glassStroke(card, 0.5)
	sheen(card, 0.35)
	padding(card, 14, 12, 14, 14)
	listLayout(card, 4)

	local head = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = card,
	})
	listLayout(head, 8, {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	local ic = makeIcon(head, o.Icon, 18, T.Text)
	if ic then
		ic.LayoutOrder = 1
	end
	label(head, tostring(o.Title or "Notification"), 15, F.Bold, T.Text, {
		Size = UDim2.new(1, ic and -26 or 0, 0, 20),
		LayoutOrder = 2,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	if o.Content and o.Content ~= "" then
		label(card, tostring(o.Content), 13, F.Regular, T.Text, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			TextTransparency = 0.4,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 2,
		})
	end

	local duration = o.Duration or 4
	local barBg = create("Frame", {
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		LayoutOrder = 3,
		Parent = card,
	})
	corner(barBg, 2)
	local bar = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = T.Slider,
		BorderSizePixel = 0,
		Parent = barBg,
	})

	tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.45, Enum.EasingStyle.Back)
	tween(bar, { Size = UDim2.fromScale(0, 1) }, duration, Enum.EasingStyle.Linear)
	task.delay(duration, function()
		if card.Parent then
			tween(card, { Position = UDim2.new(1.2, 0, 0, 0) }, 0.3)
			task.wait(0.3)
			wrap:Destroy()
		end
	end)
end

function Lumen:Notify(o)
	if self._win then
		self._win:Notify(o)
	end
end

function Window:Dialog(o)
	local T = self.T
	local overlay = create("TextButton", {
		Name = "DialogOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 100,
		Parent = self.Main,
	})
	tween(overlay, { BackgroundTransparency = 0.45 }, 0.2)
	local dlg = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.new(0, 340, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.Dialog,
		BackgroundTransparency = 0.04,
		ZIndex = 101,
		Parent = overlay,
	})
	corner(dlg, 30)
	glassStroke(dlg, 0.5)
	sheen(dlg, 0.35)
	padding(dlg, 18, 18, 18, 16)
	listLayout(dlg, 10)
	tween(dlg, { Position = UDim2.fromScale(0.5, 0.5) }, 0.3, Enum.EasingStyle.Back)

	local head = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = dlg,
	})
	listLayout(head, 8, {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	local ic = makeIcon(head, o.Icon, 22, T.Text)
	if ic then
		ic.LayoutOrder = 1
	end
	label(head, tostring(o.Title or "Dialog"), 18, F.Bold, T.Text, {
		Size = UDim2.new(1, ic and -30 or 0, 0, 24),
		LayoutOrder = 2,
	})
	if o.Content then
		label(dlg, tostring(o.Content), 14, F.Regular, T.Text, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			TextTransparency = 0.35,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 2,
		})
	end

	local function close()
		tween(overlay, { BackgroundTransparency = 1 }, 0.15)
		tween(dlg, { Position = UDim2.fromScale(0.5, 0.55) }, 0.15)
		task.delay(0.15, function()
			overlay:Destroy()
		end)
	end

	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = dlg,
	})
	listLayout(row, 8, {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	})
	padding(row, 0, 6, 0, 0)
	for idx, b in ipairs(o.Buttons or { { Title = "OK" } }) do
		local primary = (b.Variant or (idx == #(o.Buttons or { 1 }) and "Primary" or "Secondary")) == "Primary"
		local btn = create("TextButton", {
			Size = UDim2.new(0, 0, 0, 34),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = primary and T.Text or T.Panel,
			BackgroundTransparency = primary and 0 or 0.9,
			AutoButtonColor = false,
			Text = tostring(b.Title or "OK"),
			TextColor3 = primary and T.Dialog or T.Text,
			Font = F.Bold,
			TextSize = 14,
			LayoutOrder = idx,
			Parent = row,
		})
		corner(btn, 17)
padding(btn, 18, 0, 18, 0)
		btn.MouseButton1Click:Connect(function()
			close()
			fire(b.Callback)
		end)
	end
	return { Close = close }
end

function Window:Tag(o)
	local T = self.T
	local color = o.Color or T.Button
	local tag = create("Frame", {
		Size = UDim2.new(0, 0, 0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = color,
		BackgroundTransparency = 0.2,
		Parent = self.TagHolder,
	})
	corner(tag, 11)
	padding(tag, 9, 0, 9, 0)
	local lbl = label(tag, tostring(o.Title or "Tag"), 12, F.Bold, T.Text, {
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
	})
	return {
		SetTitle = function(_, s)
			lbl.Text = s
		end,
		Destroy = function()
			tag:Destroy()
		end,
	}
end

---------------------------------------------------------------------
-- tabs
---------------------------------------------------------------------
function Window:Divider()
	self._order += 1
	create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = self.T.Outline,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		LayoutOrder = self._order,
		Parent = self.TabList,
	})
end

-- sidebar group title; tabs created through it simply follow in order
function Window:Section(o)
	if type(o) == "string" then
		o = { Title = o }
	end
	self._order += 1
	label(self.TabList, string.upper(tostring(o.Title)), 11, F.Bold, self.T.Text, {
		Size = UDim2.new(1, 0, 0, 22),
		TextTransparency = 0.55,
		LayoutOrder = self._order,
	})
	local win = self
	return {
		Tab = function(_, t)
			return win:Tab(t)
		end,
	}
end

function Window:Tab(o)
	if type(o) == "string" then
		o = { Title = o }
	end
	local T = self.T
	self._order += 1

	local tab = setmetatable({
		Window = self,
		T = T,
		Elements = {},
		Name = o.Title,
	}, Tab)

	local btn = create("TextButton", {
		Name = tostring(o.Title),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = self._order,
		Parent = self.TabList,
	})
	corner(btn, 20)
local bst = glassStroke(btn, 1)
	local textX = 12
	local ic = makeIcon(btn, o.Icon, 18, T.Icon)
	if ic then
		ic.AnchorPoint = Vector2.new(0, 0.5)
		ic.Position = UDim2.new(0, 12, 0.5, 0)
		textX = 38
	end
	local lbl = label(btn, tostring(o.Title), 14, F.Medium, T.Text, {
		Position = UDim2.fromOffset(textX, 0),
		Size = UDim2.new(1, -textX - 8, 1, 0),
		TextTransparency = 0.45,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local page = create("ScrollingFrame", {
		Name = tostring(o.Title),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Outline,
		ScrollBarImageTransparency = 0.8,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = self.Content,
	})
	listLayout(page, 8)
	padding(page, 14, 14, 16, 14)
	tab.Page, tab.Container, tab.Scroller = page, page, page

	function tab:_style(active)
		tween(btn, { BackgroundTransparency = active and 0.86 or 1 }, 0.2)
		tween(bst, { Transparency = active and 0.45 or 1 }, 0.2)
		tween(lbl, { TextTransparency = active and 0 or 0.45 }, 0.2)
		if ic then
			if ic:IsA("ImageLabel") then
				tween(ic, { ImageColor3 = active and T.Text or T.Icon }, 0.2)
			else
				tween(ic, { TextColor3 = active and T.Text or T.Icon }, 0.2)
			end
		end
	end

	btn.MouseButton1Click:Connect(function()
		tab:Select()
	end)
	btn.MouseEnter:Connect(function()
		if self.Current ~= tab then
			tween(btn, { BackgroundTransparency = 0.96 }, 0.15)
		end
	end)
	btn.MouseLeave:Connect(function()
		if self.Current ~= tab then
			tween(btn, { BackgroundTransparency = 1 }, 0.15)
		end
	end)

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then
		tab:Select()
	end
	return tab
end

function Tab:Select()
	local win = self.Window
	win:_closePopup()
	for _, t in ipairs(win.Tabs) do
		t.Page.Visible = (t == self)
		t:_style(t == self)
	end
	win.Current = self
	win:_applySearch()
end

function Window:SelectTab(which)
	local t = type(which) == "number" and self.Tabs[which] or which
	if t then
		t:Select()
	end
end

---------------------------------------------------------------------
-- element panel
---------------------------------------------------------------------
local function panel(self, o, rightW, interactive)
	local T = self.T
	local win = self.Window
	local prominent = o.Style == "Prominent"
	local function baseT()
		return prominent and 0.15 or panelT(win.Glass)
	end
	local f = create("Frame", {
		Name = tostring(o.Title or "Element"),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = prominent and T.Slider or T.Panel,
		BackgroundTransparency = baseT(),
		LayoutOrder = #self.Elements + 1,
		Parent = self.Container,
	})
	corner(f, 22)
	glassStroke(f, 0.55)
	sheen(f, 0.6)
	padding(f, 18, 14, 18, 14)
	listLayout(f, 10)
	if not prominent then
		table.insert(win._glassObjs, { f, "panel" })
	end

	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 30),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = f,
	})
	local left = create("Frame", {
		Name = "Left",
		Size = UDim2.new(1, rightW > 0 and -(rightW + 12) or 0, 0, 30),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = header,
	})
	listLayout(left, 2, { VerticalAlignment = Enum.VerticalAlignment.Center })

	if o.Icon then
		padding(left, 28, 0, 0, 0)
		local ic = makeIcon(header, o.Icon, 18, T.Icon)
		if ic then
			ic.AnchorPoint = Vector2.new(0, 0.5)
			ic.Position = UDim2.new(0, 0, 0, 15)
		end
	end

	local titleLbl = label(left, tostring(o.Title or ""), 15, F.Bold, T.Text, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		LayoutOrder = 1,
	})
	local descLbl
	if o.Desc and o.Desc ~= "" then
		descLbl = label(left, tostring(o.Desc), 13, F.Regular, T.Text, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			TextTransparency = 0.45,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 2,
		})
	end

	local right
	if rightW > 0 then
		right = create("Frame", {
			Name = "Right",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.new(0, rightW, 0, 30),
			BackgroundTransparency = 1,
			Parent = header,
		})
	end

	if interactive then
		f.MouseEnter:Connect(function()
	tween(f, { BackgroundTransparency = baseT() - 0.05 }, 0.15)
end)
f.MouseLeave:Connect(function()
	tween(f, { BackgroundTransparency = baseT() }, 0.15)
end)
	end

	table.insert(self.Elements, { Frame = f, Name = tostring(o.Title or "") .. " " .. tostring(o.Desc or "") })
	return f, header, right, titleLbl, descLbl
end

local function titleSetters(titleLbl, descLbl)
	return function(_, s)
		titleLbl.Text = s
	end, function(_, s)
		if descLbl then
			descLbl.Text = s
		end
	end
end

---------------------------------------------------------------------
-- elements
---------------------------------------------------------------------
function Container:Divider()
	local d = create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = self.T.Outline,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		LayoutOrder = #self.Elements + 1,
		Parent = self.Container,
	})
	table.insert(self.Elements, { Frame = d, Name = "" })
end

function Container:Space(px)
	local s = create("Frame", {
		Size = UDim2.new(1, 0, 0, px or 8),
		BackgroundTransparency = 1,
		LayoutOrder = #self.Elements + 1,
		Parent = self.Container,
	})
	table.insert(self.Elements, { Frame = s, Name = "" })
end

function Container:Paragraph(o)
	local f, header, _, titleLbl, descLbl = panel(self, o, 0, false)
	if o.Buttons and #o.Buttons > 0 then
		local T = self.T
		local row = create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Parent = f,
		})
		listLayout(row, 8, { FillDirection = Enum.FillDirection.Horizontal })
		for idx, b in ipairs(o.Buttons) do
			local btn = create("TextButton", {
				Size = UDim2.new(0, 0, 0, 32),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = T.Panel,
				BackgroundTransparency = 0.88,
				AutoButtonColor = false,
				Text = tostring(b.Title or "Button"),
				TextColor3 = T.Text,
				Font = F.Bold,
				TextSize = 13,
				LayoutOrder = idx,
				Parent = row,
			})
			corner(btn, 16)
padding(btn, 16, 0, 16, 0)
			btn.MouseButton1Click:Connect(function()
				fire(b.Callback)
			end)
		end
	end
	local st, sd = titleSetters(titleLbl, descLbl)
	return { SetTitle = st, SetDesc = sd }
end

function Container:Button(o)
	local T = self.T
	local prominent = o.Style == "Prominent" -- iOS-style filled glass button
	local f, header, right, titleLbl, descLbl = panel(self, o, 24, true)
	if prominent then
		titleLbl.TextColor3 = Color3.new(1, 1, 1)
		if descLbl then
			descLbl.TextColor3 = Color3.new(1, 1, 1)
		end
	end
	label(right, "›", 26, F.Bold, prominent and Color3.new(1, 1, 1) or T.Text, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTransparency = 0.5,
	})
	local sc = create("UIScale", { Parent = f })
	local b = hit(header)
	local function release()
		tween(sc, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
	end
	b.MouseButton1Down:Connect(function()
		tween(sc, { Scale = 0.97 }, 0.12)
	end)
	b.MouseButton1Up:Connect(release)
	b.MouseLeave:Connect(release)
	b.MouseButton1Click:Connect(function()
		fire(o.Callback)
	end)
	local st, sd = titleSetters(titleLbl, descLbl)
	return { SetTitle = st, SetDesc = sd }
end

function Container:Toggle(o)
	local T = self.T
	local check = o.Type == "Checkbox"
	local state = o.Value == true
	local f, header, right, titleLbl, descLbl = panel(self, o, check and 28 or 54, true)
	local OFF = Color3.fromRGB(120, 120, 128)
	local WHITE = Color3.new(1, 1, 1)
	local W, K = 52, 28
	local pressed = false

	local track = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = check and UDim2.fromOffset(26, 26) or UDim2.fromOffset(W, 32),
		BackgroundColor3 = state and (check and T.Checkbox or T.Toggle) or OFF,
		BackgroundTransparency = state and 0 or 0.55,
		Parent = right,
	})
	corner(track, check and 13 or 16)
	local knob, tick
	if check then
		tick = label(track, "✓", 16, F.Bold, WHITE, {
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTransparency = state and 0 or 1,
		})
	else
		knob = create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, state and (W - K - 2) or 2, 0.5, 0),
			Size = UDim2.fromOffset(K, K),
			BackgroundColor3 = WHITE,
			Parent = track,
		})
		corner(knob, K / 2)
		create("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.88, Thickness = 1, Parent = knob })
		create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(WHITE, Color3.fromRGB(228, 228, 234)),
			Parent = knob,
		})
	end

	local function paint()
		if check then
			tween(track, { BackgroundColor3 = state and T.Checkbox or OFF, BackgroundTransparency = state and 0 or 0.55 }, 0.2)
			tween(tick, { TextTransparency = state and 0 or 1 }, 0.2)
		else
			tween(track, { BackgroundColor3 = state and T.Toggle or OFF, BackgroundTransparency = state and 0 or 0.55 }, 0.25)
			local kw = pressed and 36 or K -- knob stretches while pressed, like iOS
			local x = state and (W - kw - 2) or 2
			tween(knob, { Size = UDim2.fromOffset(kw, K), Position = UDim2.new(0, x, 0.5, 0) }, 0.4, Enum.EasingStyle.Back)
		end
	end
	local function set(v, silent)
		state = v and true or false
		paint()
		flagSet(o, state)
		if not silent then
			fire(o.Callback, state)
		end
	end
	flagSet(o, state)
	flagReg(o, state, function(v)
		set(v)
	end)

	local h = hit(header)
	local function release()
		if pressed then
			pressed = false
			paint()
		end
	end
	h.MouseButton1Down:Connect(function()
		pressed = true
		paint()
	end)
	h.MouseButton1Up:Connect(release)
	h.MouseLeave:Connect(release)
	h.MouseButton1Click:Connect(function()
		set(not state)
	end)

	local st, sd = titleSetters(titleLbl, descLbl)
	return {
		Set = function(_, v)
			set(v)
		end,
		Get = function()
			return state
		end,
		SetTitle = st,
		SetDesc = sd,
	}
end

function Container:Slider(o)
	if o.Dynamic or o.Style == "Dynamic" then
		return self:DynamicSlider(o)
	end
	local T = self.T
	local win = self.Window
	local v = o.Value or {}
	local min, max = v.Min or 0, v.Max or 100
	local step = o.Step or 1
	local value = math.clamp(v.Default or min, min, max)
	local OFF = Color3.fromRGB(120, 120, 128)
	local WHITE = Color3.new(1, 1, 1)

	local f, header, right, titleLbl, descLbl = panel(self, o, 200, true)
	local box = create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(54, 30),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.88,
		Text = "",
		TextColor3 = T.Text,
		Font = F.Medium,
		TextSize = 13,
		ClearTextOnFocus = false,
		Parent = right,
	})
	corner(box, 15)
	glassStroke(box, 0.65)
	local track = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, -80, 0, 6),
		BackgroundColor3 = OFF,
		BackgroundTransparency = 0.55,
		Parent = right,
	})
	corner(track, 3)
	local fill = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = T.Slider,
		BorderSizePixel = 0,
		Parent = track,
	})
	corner(fill, 3)
	-- wide glass capsule handle, like iOS 26/27
	local thumb = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(30, 20),
		BackgroundColor3 = WHITE,
		Parent = fill,
	})
	corner(thumb, 10)
	create("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.85, Thickness = 1, Parent = thumb })
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(WHITE, Color3.fromRGB(228, 228, 234)),
		Parent = thumb,
	})

	local function set(n, silent)
		n = math.clamp(math.floor((n - min) / step + 0.5) * step + min, min, max)
		n = tonumber(string.format("%.6g", n))
		value = n
		local a = (max == min) and 0 or (n - min) / (max - min)
		tween(fill, { Size = UDim2.fromScale(a, 1) }, 0.08)
		box.Text = tostring(n) .. (o.Suffix and (" " .. o.Suffix) or "")
		flagSet(o, n)
		if not silent then
			fire(o.Callback, n)
		end
	end
	set(value, true)
	flagReg(o, value, function(n)
		set(n)
	end)

	box.FocusLost:Connect(function()
		local n = tonumber(string.match(box.Text, "-?%d+%.?%d*"))
		set(n or value)
	end)

	local area = create("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -16, 0.5, 0),
		Size = UDim2.new(1, -48, 0, 34),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 3,
		Parent = right,
	})
	local held = false
	area.InputBegan:Connect(function(i)
		if isPress(i) then
			held = true
			tween(thumb, { Size = UDim2.fromOffset(38, 22) }, 0.25, Enum.EasingStyle.Back)
		end
	end)
	win:_track(UserInputService.InputEnded:Connect(function(i)
		if held and isPress(i) then
			held = false
			tween(thumb, { Size = UDim2.fromOffset(30, 20) }, 0.35, Enum.EasingStyle.Back)
		end
	end))
	win:_drag(area, self.Scroller, function(p)
		local a = math.clamp((p.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		set(min + (max - min) * a)
	end)

	local st, sd = titleSetters(titleLbl, descLbl)
	return {
		Set = function(_, n)
			set(n)
		end,
		Get = function()
			return value
		end,
		SetTitle = st,
		SetDesc = sd,
	}
end

-- Dynamic slider: a springy, Control Center-style slider.
-- Rests as a thin track with a handle; when touched the track swells into a fat
-- glass bar, a value bubble pops up, the fill follows on a spring (with rubber-band
-- stretch past the ends) and the handle squashes/stretches with drag speed.
function Container:DynamicSlider(o)
	local RunService = game:GetService("RunService")
	local T = self.T
	local win = self.Window
	local v = o.Value or {}
	local min, max = v.Min or 0, v.Max or 100
	local step = o.Step or 1
	local value = math.clamp(v.Default or min, min, max)
	local OFF = Color3.fromRGB(120, 120, 128)
	local WHITE = Color3.new(1, 1, 1)

	local function toAlpha(n)
		return (max == min) and 0 or (n - min) / (max - min)
	end

	local f, header, right, titleLbl, descLbl = panel(self, o, 72, true)
	local valLbl = label(right, "", 15, F.Bold, T.Text, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = f,
	})
	local track = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0, 34),
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundColor3 = OFF,
		BackgroundTransparency = 0.55,
		Parent = row,
	})
	corner(track, 14)
	local fill = create("Frame", {
		Size = UDim2.fromScale(toAlpha(value), 1),
		BackgroundColor3 = T.Slider,
		BorderSizePixel = 0,
		Parent = track,
	})
	corner(fill, 14)
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(WHITE, Color3.fromRGB(205, 210, 225)),
		Parent = fill,
	})

	local thumb = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(30, 20),
		BackgroundColor3 = WHITE,
		Parent = fill,
	})
	corner(thumb, 10)
	local thumbStroke = create("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.85, Thickness = 1, Parent = thumb })

	-- value bubble
	local bubble = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(toAlpha(value), 0, 0, 2),
		Size = UDim2.fromOffset(54, 26),
		BackgroundColor3 = T.Dialog,
		BackgroundTransparency = 0.05,
		ZIndex = 5,
		Parent = row,
	})
	corner(bubble, 13)
	glassStroke(bubble, 0.5)
	local bubbleScale = create("UIScale", { Scale = 0, Parent = bubble })
	local bubbleLbl = label(bubble, "", 13, F.Bold, T.Text, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 6,
	})

	local function fmt(n)
		return tostring(n) .. (o.Suffix and (" " .. o.Suffix) or "")
	end

	-- spring state
	local alpha, vel, target = toAlpha(value), 0, toAlpha(value)
	local held = false

	local function set(n, silent)
		n = math.clamp(math.floor((n - min) / step + 0.5) * step + min, min, max)
		n = tonumber(string.format("%.6g", n))
		local changed = n ~= value
		value = n
		target = toAlpha(n)
		valLbl.Text = fmt(n)
		bubbleLbl.Text = fmt(n)
		flagSet(o, n)
		if changed and not silent then
			fire(o.Callback, n)
		end
	end
	valLbl.Text = fmt(value)
	bubbleLbl.Text = fmt(value)
	flagSet(o, value)
	flagReg(o, value, function(n)
		set(n)
	end)

	local function setHeld(state)
		held = state
		tween(track, { Size = UDim2.new(1, 0, 0, state and 30 or 12) }, 0.4, Enum.EasingStyle.Back)
		tween(thumb, { BackgroundTransparency = state and 1 or 0 }, 0.2)
		tween(thumbStroke, { Transparency = state and 1 or 0.85 }, 0.2)
		tween(bubbleScale, { Scale = state and 1 or 0 }, state and 0.4 or 0.2, state and Enum.EasingStyle.Back or Enum.EasingStyle.Quint)
		if not state then
			target = toAlpha(value) -- snap the rubber band back
		end
	end

	local area = create("TextButton", {
		Position = UDim2.fromOffset(0, 14),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 3,
		Parent = row,
	})
	area.InputBegan:Connect(function(i)
		if isPress(i) then
			setHeld(true)
		end
	end)
	win:_track(UserInputService.InputEnded:Connect(function(i)
		if held and isPress(i) then
			setHeld(false)
		end
	end))
	win:_drag(area, self.Scroller, function(p)
		local raw = (p.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		local clamped = math.clamp(raw, 0, 1)
		set(min + (max - min) * clamped)
		-- rubber band: dragging past the ends stretches the fill a little
		target = target + math.clamp((raw - clamped) * 0.15, -0.05, 0.05)
	end)

	-- spring integration + squash/stretch
	win:_track(RunService.RenderStepped:Connect(function(dt)
		if not win.Visible then
			return
		end
		dt = math.min(dt, 1 / 30)
		local force = (target - alpha) * 320 - vel * 26
		vel += force * dt
		alpha += vel * dt
		local a = math.max(alpha, 0)
		fill.Size = UDim2.new(a, 0, 1, 0)
		bubble.Position = UDim2.new(math.clamp(alpha, 0, 1), 0, 0, 2)
		if not held then
			local stretch = math.clamp(math.abs(vel) * 12, 0, 16)
			thumb.Size = UDim2.fromOffset(30 + stretch, 20 - stretch * 0.25)
		end
	end))

	local st, sd = titleSetters(titleLbl, descLbl)
	return {
		Set = function(_, n)
			set(n)
		end,
		Get = function()
			return value
		end,
		SetTitle = st,
		SetDesc = sd,
	}
end

function Container:Input(o)
	local T = self.T
	local area = o.Type == "Textarea"
	local f, header, _, titleLbl, descLbl = panel(self, o, 0, false)
	local field = create("TextBox", {
		Size = UDim2.new(1, 0, 0, area and 92 or 34),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.93,
		Text = o.Value or "",
		PlaceholderText = o.Placeholder or "",
		PlaceholderColor3 = T.Placeholder,
		TextColor3 = T.Text,
		Font = F.Medium,
		TextSize = 14,
		ClearTextOnFocus = false,
		MultiLine = area,
		TextWrapped = area,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = area and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		LayoutOrder = 2,
		Parent = f,
	})
	corner(field, area and 18 or 17)
	padding(field, 12, area and 8 or 0, 12, area and 8 or 0)
	local st = stroke(field, T.Outline, STROKE_T)
	field.Focused:Connect(function()
		tween(st, { Transparency = 0.65 }, 0.15)
	end)
	field.FocusLost:Connect(function()
		tween(st, { Transparency = STROKE_T }, 0.15)
		flagSet(o, field.Text)
		fire(o.Callback, field.Text)
	end)
	flagReg(o, field.Text, function(s)
		field.Text = tostring(s)
	end)
	local stt, sd = titleSetters(titleLbl, descLbl)
	return {
		Set = function(_, s)
			field.Text = tostring(s)
		end,
		Get = function()
			return field.Text
		end,
		SetTitle = stt,
		SetDesc = sd,
	}
end

function Container:Keybind(o)
	local T = self.T
	local key = o.Value or "F"
	local listening = false
	local f, header, right, titleLbl, descLbl = panel(self, o, 84, true)
	local pill = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(84, 28),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.9,
		Parent = right,
	})
	corner(pill, 15)
glassStroke(pill, 0.6)
local lbl = label(pill, key, 13, F.Bold, T.Text, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local function set(k)
		key = k
		lbl.Text = k
		flagSet(o, k)
	end
	flagSet(o, key)
	flagReg(o, key, set)

	hit(header).MouseButton1Click:Connect(function()
		listening = true
		lbl.Text = "..."
		tween(pill, { BackgroundTransparency = 0.8 }, 0.15)
	end)
	self.Window:_track(UserInputService.InputBegan:Connect(function(i, gp)
		if listening then
			if i.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				tween(pill, { BackgroundTransparency = 0.9 }, 0.15)
				if i.KeyCode == Enum.KeyCode.Escape then
					lbl.Text = key
				else
					set(i.KeyCode.Name)
					fire(o.OnChange, key)
				end
			end
		elseif not gp and i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name == key then
			fire(o.Callback, key)
		end
	end))

	local st, sd = titleSetters(titleLbl, descLbl)
	return {
		Set = function(_, k)
			set(k)
		end,
		Get = function()
			return key
		end,
		SetTitle = st,
		SetDesc = sd,
	}
end

function Container:Dropdown(o)
	local T = self.T
	local win = self.Window
	local multi = o.Multi == true
	local values = table.clone(o.Values or {})
	local selected = {}
	local init = o.Value
	if type(init) ~= "table" and init ~= nil then
		init = { init }
	end
	for _, x in ipairs(init or {}) do
		selected[x] = true
	end

	local f, header, right, titleLbl, descLbl = panel(self, o, 150, true)
	local pill = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(150, 30),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.9,
		Parent = right,
	})
	corner(pill, 16)
glassStroke(pill, 0.6)
local valLbl = label(pill, "", 13, F.Medium, T.Text, {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -30, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local chev = label(pill, "▾", 13, F.Bold, T.Icon, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 0),
		Size = UDim2.fromOffset(14, 30),
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local function result()
		if multi then
			local out = {}
			for _, x in ipairs(values) do
				if selected[x] then
					table.insert(out, x)
				end
			end
			return out
		end
		for _, x in ipairs(values) do
			if selected[x] then
				return x
			end
		end
		return nil
	end
	local function refreshText()
		local r = result()
		if multi then
			valLbl.Text = #r > 0 and table.concat(r, ", ") or "None"
		else
			valLbl.Text = r ~= nil and tostring(r) or "None"
		end
	end
	local function commit(silent)
		refreshText()
		local r = result()
		flagSet(o, r)
		if not silent then
			fire(o.Callback, r)
		end
	end
	refreshText()
	flagReg(o, result(), function(v)
		table.clear(selected)
		if type(v) == "table" then
			for _, x in ipairs(v) do
				selected[x] = true
			end
		elseif v ~= nil then
			selected[v] = true
		end
		commit()
	end)

	local function openMenu()
		local showSearch = #values > 7
		local rows = math.min(math.max(#values, 1), 6)
		local listH = rows * 40
		local h = listH + 12 + (showSearch and 40 or 0)
		local w = math.max(pill.AbsoluteSize.X / win.UIScale.Scale, 180)
		local pop = win:_popup(pill, w, h, "right")
		padding(pop, 6, 6, 6, 6)
		tween(chev, { Rotation = 180 }, 0.2)

		local y = 0
		local searchBox
		if showSearch then
			searchBox = create("TextBox", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = T.Panel,
				BackgroundTransparency = 0.93,
				Text = "",
				PlaceholderText = "Search",
				PlaceholderColor3 = T.Placeholder,
				TextColor3 = T.Text,
				Font = F.Medium,
				TextSize = 13,
				ClearTextOnFocus = false,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = pop,
			})
			corner(searchBox, 9)
			padding(searchBox, 10, 0, 10, 0)
			y = 40
		end
		local scroll = create("ScrollingFrame", {
			Position = UDim2.fromOffset(0, y),
			Size = UDim2.new(1, 0, 0, listH),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = T.Outline,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = pop,
		})
		listLayout(scroll, 4)

		local items = {}
		local function paint()
			for val, it in pairs(items) do
				local on = selected[val] == true
				tween(it.btn, { BackgroundTransparency = on and 0.9 or 1 }, 0.12)
				it.tick.TextTransparency = on and 0 or 1
			end
		end
		for idx, val in ipairs(values) do
			local btn = create("TextButton", {
				Size = UDim2.new(1, -4, 0, 36), BackgroundColor3 = T.Panel, BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = idx,
				Parent = scroll,
			})
			corner(btn, 15)
label(btn, tostring(val), 14, F.Medium, T.Text, {
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, -36, 1, 0),
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local tick = label(btn, "✓", 16, F.Bold, T.Slider, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.fromOffset(16, 36),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextTransparency = 1,
			})
			items[val] = { btn = btn, tick = tick }
			btn.MouseEnter:Connect(function()
				if not selected[val] then
					tween(btn, { BackgroundTransparency = 0.95 }, 0.1)
				end
			end)
			btn.MouseLeave:Connect(function()
				if not selected[val] then
					tween(btn, { BackgroundTransparency = 1 }, 0.1)
				end
			end)
			btn.MouseButton1Click:Connect(function()
				if multi then
					selected[val] = not selected[val] or nil
					paint()
					commit()
				else
					table.clear(selected)
					selected[val] = true
					commit()
					win:_closePopup()
				end
			end)
		end
		paint()
		if searchBox then
			searchBox:GetPropertyChangedSignal("Text"):Connect(function()
				local q = string.lower(searchBox.Text)
				for val, it in pairs(items) do
					it.btn.Visible = q == "" or string.find(string.lower(tostring(val)), q, 1, true) ~= nil
				end
			end)
		end
		table.insert(win._popStore, {
			Disconnect = function()
				if chev.Parent then
					tween(chev, { Rotation = 0 }, 0.2)
				end
			end,
		})
	end

	hit(header).MouseButton1Click:Connect(openMenu)

	local st, sd = titleSetters(titleLbl, descLbl)
	return {
		Set = function(_, v)
			table.clear(selected)
			if type(v) == "table" then
				for _, x in ipairs(v) do
					selected[x] = true
				end
			elseif v ~= nil then
				selected[v] = true
			end
			commit()
		end,
		Get = result,
		Refresh = function(_, newValues)
			values = table.clone(newValues)
			table.clear(selected)
			commit()
		end,
		SetTitle = st,
		SetDesc = sd,
	}
end

function Container:Colorpicker(o)
	local T = self.T
	local win = self.Window
	local color = o.Value or o.Default or Color3.fromRGB(0, 145, 255)
	local h, s, v = color:ToHSV()

	local f, header, right, titleLbl, descLbl = panel(self, o, 44, true)
	local swatch = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(44, 26),
		BackgroundColor3 = color,
		Parent = right,
	})
	corner(swatch, 13)
glassStroke(swatch, 0.35)

	local pickerSync -- set while popup open
	local function apply(silent)
		color = Color3.fromHSV(h, s, v)
		swatch.BackgroundColor3 = color
		flagSet(o, color)
		if pickerSync then
			pickerSync()
		end
		if not silent then
			fire(o.Callback, color)
		end
	end
	flagReg(o, color, function(c)
		h, s, v = c:ToHSV()
		apply()
	end)

	hit(header).MouseButton1Click:Connect(function()
		local W, SVH = 220, 130
		local pop = win:_popup(swatch, W, 12 + SVH + 10 + 14 + 10 + 32, "right")
		padding(pop, 6, 6, 6, 6)

		local sv = create("Frame", {
			Size = UDim2.new(1, 0, 0, SVH),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			Parent = pop,
		})
		corner(sv, 9)
		local white = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = sv })
		corner(white, 9)
		create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
		local black = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = sv })
		corner(black, 9)
		create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = black })
		local cursor = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(14, 14),
			BackgroundTransparency = 1,
			Parent = sv,
		})
		corner(cursor, 7)
		stroke(cursor, Color3.new(1, 1, 1), 0, 2)

		local hue = create("Frame", {
			Position = UDim2.fromOffset(0, SVH + 10),
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = pop,
		})
		corner(hue, 7)
		local seq = {}
		for i = 0, 6 do
			table.insert(seq, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
		end
		create("UIGradient", { Color = ColorSequence.new(seq), Parent = hue })
		local hcur = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(6, 18),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = hue,
		})
		corner(hcur, 3)
		stroke(hcur, Color3.new(0, 0, 0), 0.6, 1)

		local hexBox = create("TextBox", {
			Position = UDim2.fromOffset(0, SVH + 10 + 14 + 10),
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = T.Panel,
			BackgroundTransparency = 0.93,
			Text = "",
			PlaceholderText = "#RRGGBB",
			PlaceholderColor3 = T.Placeholder,
			TextColor3 = T.Text,
			Font = F.Medium,
			TextSize = 13,
			ClearTextOnFocus = false,
			Parent = pop,
		})
		corner(hexBox, 9)

		pickerSync = function()
			sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			cursor.Position = UDim2.fromScale(s, 1 - v)
			hcur.Position = UDim2.fromScale(h, 0.5)
			if not hexBox:IsFocused() then
				hexBox.Text = toHex(color)
			end
		end
		pickerSync()
		table.insert(win._popStore, {
			Disconnect = function()
				pickerSync = nil
			end,
		})

		win:_drag(sv, nil, function(p)
			s = math.clamp((p.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
			v = 1 - math.clamp((p.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
			apply()
		end, win._popStore)
		win:_drag(hue, nil, function(p)
			h = math.clamp((p.X - hue.AbsolutePosition.X) / math.max(hue.AbsoluteSize.X, 1), 0, 1)
			apply()
		end, win._popStore)
		hexBox.FocusLost:Connect(function()
			local ok, c = pcall(Color3.fromHex, hexBox.Text)
			if ok then
				h, s, v = c:ToHSV()
				apply()
			else
				hexBox.Text = toHex(color)
			end
		end)
	end)

	local st, sd = titleSetters(titleLbl, descLbl)
	return {
		Set = function(_, c)
			h, s, v = c:ToHSV()
			apply()
		end,
		Get = function()
			return color
		end,
		SetTitle = st,
		SetDesc = sd,
	}
end

function Container:Section(o)
	if type(o) == "string" then
		o = { Title = o }
	end
	local T = self.T
	local opened = o.Opened ~= false

	local wrap = create("Frame", {
		Name = tostring(o.Title or "Section"),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = #self.Elements + 1,
		Parent = self.Container,
	})
	listLayout(wrap, 8)

	local head = create("Frame", {
		Size = UDim2.new(1, 0, 0, o.Desc and 44 or 30),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = wrap,
	})
	label(head, tostring(o.Title or "Section"), 17, F.Bold, T.Text, {
		Position = UDim2.fromOffset(2, o.Desc and 2 or 0),
		Size = UDim2.new(1, -30, 0, o.Desc and 22 or 30),
	})
	if o.Desc then
		label(head, tostring(o.Desc), 13, F.Regular, T.Text, {
			Position = UDim2.fromOffset(2, 24),
			Size = UDim2.new(1, -30, 0, 16),
			TextTransparency = 0.45,
		})
	end
	local chev = label(head, "▾", 15, F.Bold, T.Icon, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 24, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		Rotation = opened and 0 or -90,
	})

	local body = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = opened,
		LayoutOrder = 2,
		Parent = wrap,
	})
	listLayout(body, 8)

	local sec = setmetatable({
		Window = self.Window,
		T = T,
		Container = body,
		Elements = {},
		Scroller = self.Scroller,
	}, Section)

	hit(head).MouseButton1Click:Connect(function()
		opened = not opened
		body.Visible = opened
		tween(chev, { Rotation = opened and 0 or -90 }, 0.2)
	end)

	table.insert(self.Elements, { Frame = wrap, Name = tostring(o.Title or "") .. " " .. tostring(o.Desc or ""), Children = sec.Elements })
	return sec
end

---------------------------------------------------------------------
-- config files (writefile / readfile when the executor has them,
-- otherwise an in-memory store that lasts until the script is closed)
---------------------------------------------------------------------
Lumen.ConfigFolder = "Lumen" -- change before creating the window if you want another folder
Lumen._mem = {}
Lumen._memAuto = nil

local fsCache
local function getFs()
	if fsCache == nil then
		local function pick(name)
			local ok, f = pcall(function()
				return getfenv()[name]
			end)
			return ok and type(f) == "function" and f or nil
		end
		local f = {
			write = pick("writefile"),
			read = pick("readfile"),
			isfile = pick("isfile"),
			isfolder = pick("isfolder"),
			mkdir = pick("makefolder"),
			list = pick("listfiles"),
			del = pick("delfile"),
		}
		fsCache = (f.write and f.read and f.isfile and f.isfolder and f.mkdir and f.list and f.del) and f or false
	end
	return fsCache or nil
end

local function cleanName(name)
	name = tostring(name or ""):gsub("[^%w _%-]", "")
	name = name:match("^%s*(.-)%s*$") or ""
	return name:sub(1, 40)
end

local function dir()
	return Lumen.ConfigFolder .. "/configs"
end

local function ensureDirs(f)
	pcall(function()
		if not f.isfolder(Lumen.ConfigFolder) then
			f.mkdir(Lumen.ConfigFolder)
		end
		if not f.isfolder(dir()) then
			f.mkdir(dir())
		end
	end)
end

function Lumen:ConfigStorage()
	return getFs() and "files" or "memory"
end

function Lumen:ListConfigs()
	local out = {}
	local f = getFs()
	if f then
		ensureDirs(f)
		local ok, files = pcall(f.list, dir())
		if ok and type(files) == "table" then
			for _, p in ipairs(files) do
				local n = tostring(p):match("([^/\\]+)%.json$")
				if n then
					table.insert(out, n)
				end
			end
		end
	else
		for n in pairs(self._mem) do
			table.insert(out, n)
		end
	end
	table.sort(out, function(a, b)
		return a:lower() < b:lower()
	end)
	return out
end

function Lumen:ConfigExists(name)
	name = cleanName(name)
	if name == "" then
		return false
	end
	local f = getFs()
	if f then
		local ok, r = pcall(f.isfile, dir() .. "/" .. name .. ".json")
		return ok and r == true
	end
	return self._mem[name] ~= nil
end

-- every function below returns ok, errorMessage
function Lumen:SaveConfigFile(name)
	name = cleanName(name)
	if name == "" then
		return false, "Enter a config name first"
	end
	local json = self:SaveConfig()
	local f = getFs()
	if f then
		ensureDirs(f)
		local ok, err = pcall(f.write, dir() .. "/" .. name .. ".json", json)
		if not ok then
			return false, tostring(err)
		end
	else
		self._mem[name] = json
	end
	return true
end

function Lumen:LoadConfigFile(name)
	name = cleanName(name)
	if name == "" then
		return false, "Pick a config first"
	end
	local json
	local f = getFs()
	if f then
		local ok, r = pcall(f.read, dir() .. "/" .. name .. ".json")
		if not ok then
			return false, "Could not read that config"
		end
		json = r
	else
		json = self._mem[name]
	end
	if not json then
		return false, "Config not found"
	end
	if not self:LoadConfig(json) then
		return false, "Config file is corrupt"
	end
	return true
end

function Lumen:DeleteConfigFile(name)
	name = cleanName(name)
	if name == "" then
		return false, "Pick a config first"
	end
	local f = getFs()
	if f then
		local ok, err = pcall(f.del, dir() .. "/" .. name .. ".json")
		if not ok then
			return false, tostring(err)
		end
	else
		self._mem[name] = nil
	end
	if self:GetAutoload() == name then
		self:SetAutoload(nil)
	end
	return true
end

function Lumen:GetAutoload()
	local f = getFs()
	if f then
		local path = self.ConfigFolder .. "/autoload.txt"
		local ok, exists = pcall(f.isfile, path)
		if ok and exists then
			local ok2, txt = pcall(f.read, path)
			if ok2 then
				txt = cleanName(txt)
				return txt ~= "" and txt or nil
			end
		end
		return nil
	end
	return self._memAuto
end

function Lumen:SetAutoload(name)
	name = name and cleanName(name) or nil
	if name == "" then
		name = nil
	end
	local f = getFs()
	if f then
		ensureDirs(f)
		pcall(f.write, self.ConfigFolder .. "/autoload.txt", name or "")
	else
		self._memAuto = name
	end
	return true
end

-- call once at the END of your script, after every element exists
function Lumen:LoadAutoload()
	local name = self:GetAutoload()
	if name and self:ConfigExists(name) then
		local ok = self:LoadConfigFile(name)
		return ok, name
	end
	return false
end

-- Tab/Section:ConfigManager() builds the whole config UI
function Container:ConfigManager(o)
	o = o or {}
	local win = self.Window
	local selected

	local function toast(title, content, icon)
		win:Notify({ Title = title, Content = content, Icon = icon, Duration = 3 })
	end

	if Lumen:ConfigStorage() == "memory" then
		self:Paragraph({
			Title = "Configs",
			Desc = "This executor has no file access, so configs last only until the script closes.",
		})
	end

	local nameBox = self:Input({
		Title = o.Title or "Config name",
		Placeholder = "e.g. legit, rage, default",
	})
	local list = self:Dropdown({
		Title = "Saved configs",
		Values = Lumen:ListConfigs(),
		Callback = function(v)
			selected = v
			if v then
				nameBox:Set(v)
			end
		end,
	})
	local status = self:Paragraph({
		Title = "Autoload",
		Desc = "None",
	})

	local function refresh()
		list:Refresh(Lumen:ListConfigs())
		selected = nil
		local a = Lumen:GetAutoload()
		status:SetDesc(a or "None")
	end
	refresh()

	local function target()
		local n = cleanName(nameBox:Get())
		if n == "" then
			n = selected and cleanName(selected) or ""
		end
		return n
	end

	local function doSave(n)
		local ok, err = Lumen:SaveConfigFile(n)
		if ok then
			toast("Config saved", n, "check")
			refresh()
			list:Set(n)
			selected = n
		else
			toast("Save failed", err, "info")
		end
	end

	self:Paragraph({
		Title = "Actions",
		Buttons = {
			{
				Title = "Save",
				Callback = function()
					local n = target()
					if n == "" then
						return toast("Save failed", "Enter a config name first", "info")
					end
					if Lumen:ConfigExists(n) then
						win:Dialog({
							Title = "Overwrite config?",
							Content = '"' .. n .. '" already exists and will be replaced.',
							Icon = "info",
							Buttons = {
								{ Title = "Cancel", Variant = "Secondary" },
								{
									Title = "Overwrite",
									Variant = "Primary",
									Callback = function()
										doSave(n)
									end,
								},
							},
						})
					else
						doSave(n)
					end
				end,
			},
			{
				Title = "Load",
				Callback = function()
					local n = target()
					local ok, err = Lumen:LoadConfigFile(n)
					if ok then
						toast("Config loaded", n, "check")
					else
						toast("Load failed", err, "info")
					end
				end,
			},
			{
				Title = "Delete",
				Callback = function()
					local n = target()
					if not Lumen:ConfigExists(n) then
						return toast("Delete failed", "Pick a saved config first", "info")
					end
					win:Dialog({
						Title = "Delete config?",
						Content = '"' .. n .. '" will be removed permanently.',
						Icon = "info",
						Buttons = {
							{ Title = "Cancel", Variant = "Secondary" },
							{
								Title = "Delete",
								Variant = "Primary",
								Callback = function()
									local ok, err = Lumen:DeleteConfigFile(n)
									if ok then
										toast("Config deleted", n, "check")
										nameBox:Set("")
										refresh()
									else
										toast("Delete failed", err, "info")
									end
								end,
							},
						},
					})
				end,
			},
			{
				Title = "Refresh",
				Callback = refresh,
			},
		},
	})

	self:Paragraph({
		Title = "Autoload",
		Desc = "Load a config automatically on launch (needs Lumen:LoadAutoload() at the end of your script).",
		Buttons = {
			{
				Title = "Set autoload",
				Callback = function()
					local n = target()
					if not Lumen:ConfigExists(n) then
						return toast("Autoload", "Pick a saved config first", "info")
					end
					Lumen:SetAutoload(n)
					status:SetDesc(n)
					toast("Autoload set", n, "check")
				end,
			},
			{
				Title = "Clear autoload",
				Callback = function()
					Lumen:SetAutoload(nil)
					status:SetDesc("None")
					toast("Autoload cleared", nil, "check")
				end,
			},
		},
	})

	return { Refresh = refresh }
end

return Lumen
end)()
