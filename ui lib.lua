--[[
R1CKOMGG UI Library (Rayfield-like)
Single-file drop-in. API mirrors the example you sent.

Usage:
local Rayfield = loadstring(game:HttpGet("<RAW_URL_TO_THIS_FILE>"))()

Rayfield:Notify("Hello","Loaded", 0)

Notes:
- Config saving uses exploit FS (isfile, writefile, readfile); gracefully no-ops if not present.
- All UI is created client-side (LocalScript).
- Minimal styling with green/black "hacker" vibe.
]]

local Rayfield = {}
Rayfield.__index = Rayfield

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer:WaitForChild("PlayerGui")

-- FS helpers (executor)
local HAS_FS = typeof(isfile) == "function" and typeof(writefile) == "function" and typeof(readfile) == "function"

-- Theme
local THEME = {
	bg = Color3.fromRGB(10, 12, 12),
	panel = Color3.fromRGB(16, 20, 20),
	accent = Color3.fromRGB(30, 200, 110),
	accent2 = Color3.fromRGB(80, 255, 180),
	text = Color3.fromRGB(235, 255, 245),
	muted = Color3.fromRGB(150, 175, 165)
}

-- Utility
local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = parent
	return c
end

local function stroke(parent, c, t)
	local s = Instance.new("UIStroke")
	s.Color = c or THEME.accent
	s.Thickness = t or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function padding(parent, p)
	local ui = Instance.new("UIPadding")
	ui.PaddingTop = UDim.new(0, p)
	ui.PaddingBottom = UDim.new(0, p)
	ui.PaddingLeft = UDim.new(0, p)
	ui.PaddingRight = UDim.new(0, p)
	ui.Parent = parent
	return ui
end

local function tween(o, info, props)
	return TweenService:Create(o, info, props)
end

local function mkButton(text)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = THEME.panel
	b.AutoButtonColor = true
	b.Text = text or "Button"
	b.Font = Enum.Font.GothamMedium
	b.TextColor3 = THEME.text
	b.TextSize = 14
	b.Size = UDim2.new(1, 0, 0, 32)
	corner(b, 8)
	stroke(b, THEME.accent, 1)
	return b
end

local function mkLabel(text, size, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.Text = text or "Label"
	l.TextColor3 = THEME.text
	l.TextSize = size or 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Size = UDim2.new(1, 0, 0, size and (size+6) or 20)
	return l
end

local function makeToggle()
	local holder = Instance.new("Frame")
	holder.BackgroundColor3 = THEME.panel
	holder.Size = UDim2.new(1, 0, 0, 36)
	corner(holder, 8)
	stroke(holder, THEME.accent, 1)
	padding(holder, 8)

	local text = mkLabel("Toggle", 14, true)
	text.Parent = holder

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(1, 0.5)
	knob.Position = UDim2.new(1, -8, 0.5, 0)
	knob.Size = UDim2.new(0, 48, 0, 20)
	knob.BackgroundColor3 = Color3.fromRGB(35, 40, 40)
	corner(knob, 10)
	stroke(knob, THEME.accent, 1)
	knob.Parent = holder

	local bubble = Instance.new("Frame")
	bubble.Size = UDim2.new(0, 16, 0, 16)
	bubble.Position = UDim2.new(0, 2, 0.5, -8)
	bubble.BackgroundColor3 = THEME.accent
	corner(bubble, 8)
	bubble.Parent = knob

	return holder, text, knob, bubble
end

local function makeSlider()
	local holder = Instance.new("Frame")
	holder.BackgroundColor3 = THEME.panel
	holder.Size = UDim2.new(1, 0, 0, 52)
	corner(holder, 8)
	stroke(holder, THEME.accent, 1)
	padding(holder, 8)

	local title = mkLabel("Slider", 14, true)
	title.Parent = holder

	local valueLbl = mkLabel("0", 12, false)
	valueLbl.TextColor3 = THEME.muted
	valueLbl.AnchorPoint = Vector2.new(1, 0)
	valueLbl.Position = UDim2.new(1, -8, 0, 8)
	valueLbl.Parent = holder

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -16, 0, 6)
	bar.Position = UDim2.new(0, 8, 1, -16)
	bar.BackgroundColor3 = Color3.fromRGB(35,40,40)
	corner(bar, 3)
	bar.Parent = holder

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = THEME.accent
	corner(fill, 3)
	fill.Parent = bar

	return holder, title, valueLbl, bar, fill
end

local function makeInput()
	local holder = Instance.new("Frame")
	holder.BackgroundColor3 = THEME.panel
	holder.Size = UDim2.new(1, 0, 0, 40)
	corner(holder, 8)
	stroke(holder, THEME.accent, 1)
	padding(holder, 8)

	local box = Instance.new("TextBox")
	box.BackgroundTransparency = 1
	box.ClearTextOnFocus = false
	box.Text = ""
	box.PlaceholderText = "Input"
	box.TextColor3 = THEME.text
	box.PlaceholderColor3 = THEME.muted
	box.Font = Enum.Font.Gotham
	box.TextSize = 14
	box.Size = UDim2.new(1, 0, 1, 0)
	box.Parent = holder

	return holder, box
end

local function makeKeybind()
	local holder = Instance.new("Frame")
	holder.BackgroundColor3 = THEME.panel
	holder.Size = UDim2.new(1, 0, 0, 36)
	corner(holder, 8)
	stroke(holder, THEME.accent, 1)
	padding(holder, 8)

	local left = mkLabel("Keybind", 14, true)
	left.Parent = holder

	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(1,0.5)
	btn.Position = UDim2.new(1,-8,0.5,0)
	btn.Size = UDim2.new(0, 100, 0, 22)
	btn.Text = "Not Set"
	btn.TextSize = 13
	btn.Font = Enum.Font.Gotham
	btn.TextColor3 = THEME.text
	btn.BackgroundColor3 = Color3.fromRGB(35,40,40)
	corner(btn, 6)
	stroke(btn, THEME.accent, 1)
	btn.Parent = holder

	return holder, left, btn
end

local function makeDropdown()
	local holder = Instance.new("Frame")
	holder.BackgroundColor3 = THEME.panel
	holder.Size = UDim2.new(1, 0, 0, 38)
	corner(holder, 8)
	stroke(holder, THEME.accent, 1)
	padding(holder, 8)

	local title = mkLabel("Dropdown", 14, true)
	title.Parent = holder

	local openBtn = Instance.new("TextButton")
	openBtn.AnchorPoint = Vector2.new(1,0.5)
	openBtn.Position = UDim2.new(1,-8,0.5,0)
	openBtn.Size = UDim2.new(0, 130, 0, 22)
	openBtn.Text = "Select"
	openBtn.TextSize = 13
	openBtn.Font = Enum.Font.Gotham
	openBtn.TextColor3 = THEME.text
	openBtn.BackgroundColor3 = Color3.fromRGB(35,40,40)
	corner(openBtn, 6)
	stroke(openBtn, THEME.accent, 1)
	openBtn.Parent = holder

	local listFrame = Instance.new("Frame")
	listFrame.Name = "List"
	listFrame.Visible = false
	listFrame.BackgroundColor3 = THEME.panel
	listFrame.Size = UDim2.new(1, 0, 0, 0)
	corner(listFrame, 8)
	stroke(listFrame, THEME.accent, 1)
	listFrame.Parent = holder

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = listFrame

	return holder, title, openBtn, listFrame
end

-- Config Manager
local Config = {}
Config.__index = Config

function Config.new(opts)
	local cfg = setmetatable({}, Config)
	cfg.enabled = opts.Enabled
	cfg.folder = opts.FolderName or "Rayfield"
	cfg.file = opts.FileName or "config"
	cfg.path = cfg.folder .. "/" .. cfg.file .. ".json"
	if cfg.enabled and HAS_FS then
		if not isfolder or not isfolder(cfg.folder) then pcall(function() if makefolder then makefolder(cfg.folder) end end) end
	end
	cfg.data = {}
	return cfg
end

function Config:load()
	if not (self.enabled and HAS_FS) then return {} end
	local ok, result = pcall(function()
		if isfile(self.path) then
			local raw = readfile(self.path)
			return HttpService:JSONDecode(raw)
		end
		return {}
	end)
	self.data = ok and (result or {}) or {}
	return self.data
end

function Config:save()
	if not (self.enabled and HAS_FS) then return end
	local ok, enc = pcall(function() return HttpService:JSONEncode(self.data) end)
	if ok and enc then pcall(function() writefile(self.path, enc) end) end
end

-- Window/Tab objects
local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

-- Element prototypes will be simple tables with .Set methods

-- Notifications
local function createNotifier(rootGui)
	local holder = Instance.new("Frame")
	holder.Name = "Notifier"
	holder.AnchorPoint = Vector2.new(1,1)
	holder.Position = UDim2.new(1, -16, 1, -16)
	holder.Size = UDim2.new(0, 300, 1, -32)
	holder.BackgroundTransparency = 1
	holder.Parent = rootGui

	local layout = Instance.new("UIListLayout")
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Padding = UDim.new(0, 8)
	layout.Parent = holder

	return function(title, content)
		local panel = Instance.new("Frame")
		panel.BackgroundColor3 = THEME.panel
		panel.Size = UDim2.new(1, 0, 0, 70)
		panel.AnchorPoint = Vector2.new(1,1)
		corner(panel, 10)
		stroke(panel, THEME.accent, 1)
		padding(panel, 10)
		panel.Parent = holder

		local t = mkLabel(title or "Notification", 16, true)
		t.Parent = panel
		local d = mkLabel(content or "", 13, false)
		d.Position = UDim2.new(0, 0, 0, 28)
		d.TextColor3 = THEME.muted
		d.Parent = panel

		panel.BackgroundTransparency = 1
		panel.Visible = true
		tween(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()

		task.delay(3, function()
			local tw = tween(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
			tw.Completed:Connect(function()
				panel:Destroy()
			end)
			tw:Play()
		end)
	end
end

-- CreateWindow
function Rayfield:CreateWindow(opts)
	opts = opts or {}
	local name = opts.Name or "UI Window"
	local loadingTitle = opts.LoadingTitle or "Loading"
	local loadingSubtitle = opts.LoadingSubtitle or ""
	local cfg = Config.new(opts.ConfigurationSaving or {Enabled=false})
	local keySystem = opts.KeySystem
	local keySettings = opts.KeySettings or {}

	-- Root GUI
	local gui = Instance.new("ScreenGui")
	gui.Name = "R1_UI"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = PlayerGui

	-- Draggable window
	local win = Instance.new("Frame")
	win.Name = "Window"
	win.BackgroundColor3 = THEME.bg
	win.Size = UDim2.new(0, 640, 0, 420)
	win.Position = UDim2.new(0.5, -320, 0.5, -210)
	win.Active = true
	win.Draggable = true
	corner(win, 12)
	stroke(win, THEME.accent, 1)
	padding(win, 8)
	win.Parent = gui

	-- Title bar
	local top = Instance.new("Frame")
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(1, -16, 0, 30)
	top.Position = UDim2.new(0, 8, 0, 8)
	top.Parent = win

	local title = mkLabel(name, 18, true)
	title.Size = UDim2.new(1, -120, 1, 0)
	title.Parent = top

	local close = mkButton("Destroy")
	close.Size = UDim2.new(0, 90, 1, 0)
	close.Position = UDim2.new(1, -90, 0, 0)
	close.Parent = top

	-- Tabs bar
	local tabsBar = Instance.new("Frame")
	tabsBar.BackgroundTransparency = 1
	tabsBar.Size = UDim2.new(0, 160, 1, -54)
	tabsBar.Position = UDim2.new(0, 8, 0, 46)
	tabsBar.Parent = win

	local tabList = Instance.new("UIListLayout")
	tabList.Padding = UDim.new(0, 8)
	tabList.SortOrder = Enum.SortOrder.LayoutOrder
	tabList.Parent = tabsBar

	-- Content area
	local content = Instance.new("Frame")
	content.BackgroundColor3 = THEME.panel
	content.Size = UDim2.new(1, -184, 1, -62)
	content.Position = UDim2.new(0, 176, 0, 54)
	corner(content, 10)
	stroke(content, THEME.accent, 1)
	padding(content, 10)
	content.Parent = win

	-- Scrolling container for active tab
	local tabContainer = Instance.new("ScrollingFrame")
	tabContainer.Size = UDim2.new(1, -8, 1, -8)
	tabContainer.Position = UDim2.new(0, 4, 0, 4)
	tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabContainer.ScrollBarThickness = 4
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = content
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.Parent = tabContainer
	tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabContainer.CanvasSize = UDim2.new(0,0,0, tabLayout.AbsoluteContentSize.Y + 16)
	end)

	-- Notifier
	local pushNotify = createNotifier(gui)

	-- Close behavior
	close.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)

	-- Optional key system (simple)
	if keySystem then
		local wall = Instance.new("TextBox")
		wall.Size = UDim2.new(1, -16, 0, 36)
		wall.Position = UDim2.new(0, 8, 0, 300)
		wall.PlaceholderText = "Enter Key"
		wall.Text = ""
		wall.TextColor3 = THEME.text
		wall.PlaceholderColor3 = THEME.muted
		wall.Font = Enum.Font.Gotham
		wall.TextSize = 14
		wall.BackgroundColor3 = THEME.panel
		corner(wall, 8); stroke(wall, THEME.accent, 1)
		wall.Parent = win
		local allowed = false
		wall.FocusLost:Connect(function(enter)
			if enter and (wall.Text == (keySettings.Key or "")) then
				allowed = true
				wall:Destroy()
				pushNotify("Access Granted", keySettings.Subtitle or "", 0)
			else
				pushNotify("Bad Key", "Try again", 0)
			end
		end)
		-- Block content until allowed
		content.Visible = false
		tabsBar.Visible = false
		RunService.RenderStepped:Wait()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			if allowed then
				content.Visible = true; tabsBar.Visible = true
				conn:Disconnect()
			end
		end)
	end

	-- Window object
	local windowObj = setmetatable({
		_gui = gui,
		_root = win,
		_tabsBar = tabsBar,
		_tabContainer = tabContainer,
		_tabLayout = tabLayout,
		_tabs = {},
		_activeTab = nil,
		_config = cfg,
		_notify = pushNotify,
	}, Window)

	-- Public API on Rayfield
	local rf = setmetatable({
		_ = windowObj
	}, {__index = function(_, k) return Rayfield[k] end})

	return rf
end

-- Rayfield methods on the instance proxy (rf)
function Rayfield:CreateTab(title, imageId)
	local W = rawget(self, "_")
	local button = mkButton(title or "Tab")
	button.Parent = W._tabsBar

	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 0, 0)
	container.Visible = false
	container.Parent = W._tabContainer

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.Parent = container

	local tab = setmetatable({
		_title = title or "Tab",
		_button = button,
		_container = container,
		_layout = layout,
		_win = W,
	}, Tab)

	W._tabs[#W._tabs+1] = tab

	local function select()
		if W._activeTab then W._activeTab._container.Visible = false end
		W._activeTab = tab
		container.Visible = true
	end
	button.MouseButton1Click:Connect(select)
	if not W._activeTab then select() end

	return tab
end

function Rayfield:Notify(title, content, imageId)
	local W = rawget(self, "_")
	W._notify(title, content)
end

function Rayfield:Destroy()
	local W = rawget(self, "_")
	if W and W._gui then W._gui:Destroy() end
end

function Rayfield:LoadConfiguration()
	local W = rawget(self, "_")
	return W._config:load()
end

-- ===== Tab instance methods =====
function Tab:CreateSection(text)
	local l = mkLabel(text or "Section", 16, true)
	l.TextColor3 = THEME.accent2
	l.Parent = self._container
	return {
		Set = function(_, t)
			l.Text = t
		end
	}
end

function Tab:CreateLabel(text)
	local holder = Instance.new("Frame")
	holder.BackgroundColor3 = THEME.panel
	holder.Size = UDim2.new(1, 0, 0, 30)
	corner(holder, 8)
	stroke(holder, THEME.accent, 1)
	padding(holder, 8)
	holder.Parent = self._container

	local l = mkLabel(text or "Label", 14, false)
	l.Parent = holder

	return {
		Set = function(_, t) l.Text = t end
	}
end

function Tab:CreateParagraph(opts)
	opts = opts or {}
	local holder = Instance.new("Frame")
	holder.BackgroundColor3 = THEME.panel
	holder.Size = UDim2.new(1, 0, 0, 90)
	corner(holder, 8)
	stroke(holder, THEME.accent, 1)
	padding(holder, 10)
	holder.Parent = self._container

	local title = mkLabel(opts.Title or "Title", 15, true)
	title.Parent = holder
	local body = mkLabel(opts.Content or "", 13, false)
	body.Position = UDim2.new(0, 0, 0, 28)
	body.TextWrapped = true
	body.Size = UDim2.new(1, -6, 1, -30)
	body.Parent = holder

	return {
		Set = function(_, o)
			title.Text = o.Title or title.Text
			body.Text = o.Content or body.Text
		end
	}
end

function Tab:CreateButton(opts)
	opts = opts or {}
	local b = mkButton(opts.Name or "Button")
	b.Parent = self._container
	b.MouseButton1Click:Connect(function()
		pcall(function() (opts.Callback or function() end)() end)
	end)
	return {
		Set = function(_, t) b.Text = t end
	}
end

function Tab:CreateToggle(opts)
	opts = opts or {}
	local holder, text, knob, bubble = makeToggle()
	holder.Parent = self._container
	text.Text = opts.Name or "Toggle"

	local value = opts.CurrentValue or false
	local flag = opts.Flag
	local cfg = self._win._config
	local function setVisual(v)
		value = v
		local goalX = v and (knob.AbsoluteSize.X - 18) or 2
		TweenService:Create(bubble, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, goalX, 0.5, -8)}):Play()
		bubble.BackgroundColor3 = v and THEME.accent2 or THEME.accent
	end

	local data = cfg:load()
	if flag and data[flag] ~= nil then value = data[flag] end
	setVisual(value)

	holder.InputBegan:Connect(function(ip)
		if ip.UserInputType == Enum.UserInputType.MouseButton1 then
			setVisual(not value)
			if flag then data[flag] = value; cfg.data = data; cfg:save() end
			pcall(function() (opts.Callback or function() end)(value) end)
		end
	end)

	return {
		Set = function(_, v)
			setVisual(v)
			if flag then data[flag] = v; cfg.data = data; cfg:save() end
		end
	}
end

function Tab:CreateSlider(opts)
	opts = opts or {}
	local holder, title, valueLbl, bar, fill = makeSlider()
	holder.Parent = self._container
	title.Text = (opts.Name or "Slider") .. (opts.Suffix and (" ["..opts.Suffix.."]") or "")

	local range = opts.Range or {0,100}
	local min, max = range[1], range[2]
	local inc = opts.Increment or 1
	local flag = opts.Flag
	local cfg = self._win._config
	local data = cfg:load()

	local value = opts.CurrentValue or min
	if flag and data[flag] then value = data[flag] end

	local function apply(v)
		v = math.clamp(v, min, max)
		v = math.round(v / inc) * inc
		value = v
		valueLbl.Text = tostring(v)
		local alpha = (v - min) / (max - min)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
	end
	apply(value)

	local dragging = false
	bar.InputBegan:Connect(function(ip)
		if ip.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end)
	UserInputService.InputEnded:Connect(function(ip)
		if ip.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(ip)
		if dragging and ip.UserInputType == Enum.UserInputType.MouseMovement then
			local rel = (ip.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
			apply(min + rel * (max - min))
			if flag then data[flag] = value; cfg.data = data; cfg:save() end
			pcall(function() (opts.Callback or function() end)(value) end)
		end
	end)

	return {
		Set = function(_, v)
			apply(v)
			if flag then data[flag] = v; cfg.data = data; cfg:save() end
		end
	}
end

function Tab:CreateInput(opts)
	opts = opts or {}
	local holder, box = makeInput()
	holder.Parent = self._container
	box.PlaceholderText = opts.PlaceholderText or "Input"

	box.FocusLost:Connect(function()
		pcall(function() (opts.Callback or function() end)(box.Text) end)
		if opts.RemoveTextAfterFocusLost then box.Text = "" end
	end)

	return {
		Set = function(_, t) box.Text = t end
	}
end

function Tab:CreateKeybind(opts)
	opts = opts or {}
	local holder, left, btn = makeKeybind()
	holder.Parent = self._container
	left.Text = opts.Name or "Keybind"

	local flag = opts.Flag
	local cfg = self._win._config
	local data = cfg:load()

	local current = opts.CurrentKeybind or "None"
	if flag and data[flag] then current = data[flag] end
	btn.Text = tostring(current)
	local holding = false

	local capturing = false
	btn.MouseButton1Click:Connect(function()
		capturing = true
		btn.Text = "Press..."
	end)

	UserInputService.InputBegan:Connect(function(ip, gp)
		if capturing and not gp and ip.KeyCode ~= Enum.KeyCode.Unknown then
			current = ip.KeyCode.Name
			btn.Text = current
			capturing = false
			if flag then data[flag] = current; cfg.data = data; cfg:save() end
		end
		if not capturing and tostring(ip.KeyCode.Name) == tostring(current) then
			if opts.HoldToInteract then holding = true end
			pcall(function() (opts.Callback or function() end)(opts.HoldToInteract and holding or true) end)
		end
	end)
	UserInputService.InputEnded:Connect(function(ip)
		if tostring(ip.KeyCode.Name) == tostring(current) and opts.HoldToInteract then
			holding = false
			pcall(function() (opts.Callback or function() end)(false) end)
		end
	end)

	return {
		Set = function(_, key)
			current = key
			btn.Text = key
			if flag then data[flag] = key; cfg.data = data; cfg:save() end
		end
	}
end

function Tab:CreateDropdown(opts)
	opts = opts or {}
	local holder, title, openBtn, listFrame = makeDropdown()
	holder.Parent = self._container
	title.Text = opts.Name or "Dropdown"

	local options = opts.Options or {}
	local current = opts.CurrentOption or (options[1] or "")
	local flag = opts.Flag
	local cfg = self._win._config
	local data = cfg:load()
	if flag and data[flag] then current = data[flag] end
	openBtn.Text = tostring(current)

	local function setOption(opt)
		current = opt
		openBtn.Text = tostring(opt)
		if flag then data[flag] = opt; cfg.data = data; cfg:save() end
		pcall(function() (opts.Callback or function() end)(opt) end)
	end

	local function rebuild()
		listFrame:ClearAllChildren()
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0,6)
		layout.Parent = listFrame
		for _,opt in ipairs(options) do
			local b = mkButton(tostring(opt))
			b.Size = UDim2.new(1, -6, 0, 26)
			b.Parent = listFrame
			b.MouseButton1Click:Connect(function()
				setOption(opt)
				listFrame.Visible = false
				holder.Size = UDim2.new(1, 0, 0, 38)
			end)
		end
		listFrame.Size = UDim2.new(1, 0, 0, math.min(26 * #options + 12, 150))
	end
	rebuild()

	openBtn.MouseButton1Click:Connect(function()
		listFrame.Visible = not listFrame.Visible
		if listFrame.Visible then
			holder.Size = UDim2.new(1, 0, 0, 38 + listFrame.Size.Y.Offset + 8)
		else
			holder.Size = UDim2.new(1, 0, 0, 38)
		end
	end)

	return {
		Set = function(_, opt)
			setOption(opt)
		end,
		Refresh = function(_, newOptions)
			options = newOptions or options
			rebuild()
		end
	}
end

-- convenience alias to update CanvasSize when items added
local function hookCanvas(win)
	-- already handled by layout size change in CreateWindow
end

-- expose
return setmetatable({}, Rayfield)
