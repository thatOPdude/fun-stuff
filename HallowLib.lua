-- =======================================================================
--   🎃 HALLOW-LIB (hallow) - PUMPKIN UI LIBRARY
--   Theme: Carved Jack-O'-Lantern / Amber Glow / Charred Rind
-- =======================================================================

local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local SoundService     = game:GetService("SoundService")
local localPlayer      = Players.LocalPlayer

-- GUI Container
local parentGui = (typeof(gethui) == "function" and gethui()) 
	or CoreGui:FindFirstChild("RobloxGui") 
	or localPlayer:WaitForChild("PlayerGui")

if parentGui:FindFirstChild("HallowLib_Main") then
	parentGui:FindFirstChild("HallowLib_Main"):Destroy()
end

local Hallow = {
	Sounds = {
		Click  = "rbxassetid://6895079853",
		Hover  = "rbxassetid://6895079853", -- Crisp high-pitch tick
		Toggle = "rbxassetid://6895079853",
		Notify = "rbxassetid://4590662766", -- Bright chime
	}
}

-- Loud & Clear Sound Player Helper
local function playSound(soundId, pitch, volume)
	pcall(function()
		local s = Instance.new("Sound")
		s.SoundId = soundId
		s.Pitch = pitch or 1
		s.Volume = volume or 0.9 -- Louder baseline volume
		s.Parent = SoundService
		s:Play()
		s.Ended:Connect(function()
			s:Destroy()
		end)
	end)
end

-- Hover sound helper with micro-debounce (prevents buzzing when moving fast)
local lastHoverTick = 0
local function playHoverSound(pitch, volume)
	local now = tick()
	if now - lastHoverTick > 0.04 then
		lastHoverTick = now
		playSound(Hallow.Sounds.Hover, pitch or 1.65, volume or 0.7)
	end
end

-- =======================================================================
--   NOTIFICATION SYSTEM
-- =======================================================================
local NotifyHolder
local function initNotifyHolder(gui)
	if not NotifyHolder then
		NotifyHolder = Instance.new("Frame")
		NotifyHolder.Name = "NotifyHolder"
		NotifyHolder.AnchorPoint = Vector2.new(1, 1)
		NotifyHolder.Position = UDim2.new(1, -20, 1, -20)
		NotifyHolder.Size = UDim2.new(0, 300, 1, -40)
		NotifyHolder.BackgroundTransparency = 1
		NotifyHolder.Parent = gui

		local layout = Instance.new("UIListLayout", NotifyHolder)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		layout.Padding = UDim.new(0, 10)
	end
end

function Hallow:Notify(config)
	local title = config.Title or "🎃 Notification"
	local text = config.Content or ""
	local duration = config.Duration or 3.5

	playSound(Hallow.Sounds.Notify, 1, 0.95)

	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(1, 0, 0, 76)
	toast.BackgroundColor3 = Color3.fromRGB(24, 10, 4)
	toast.BorderSizePixel = 0
	toast.BackgroundTransparency = 1
	toast.ClipsDescendants = true
	toast.Parent = NotifyHolder

	local corner = Instance.new("UICorner", toast)
	corner.CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", toast)
	stroke.Color = Color3.fromRGB(255, 140, 20)
	stroke.Thickness = 1.2
	stroke.Transparency = 1

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 4, 1, 0)
	bar.Position = UDim2.new(0, 0, 0, 0)
	bar.BackgroundColor3 = Color3.fromRGB(255, 175, 40)
	bar.BorderSizePixel = 0
	bar.Parent = toast

	local tLbl = Instance.new("TextLabel")
	tLbl.Text = title
	tLbl.Font = Enum.Font.GothamBold
	tLbl.TextSize = 14
	tLbl.TextColor3 = Color3.fromRGB(255, 200, 70)
	tLbl.TextXAlignment = Enum.TextXAlignment.Left
	tLbl.Position = UDim2.new(0, 16, 0, 10)
	tLbl.Size = UDim2.new(1, -26, 0, 18)
	tLbl.BackgroundTransparency = 1
	tLbl.TextTransparency = 1
	tLbl.Parent = toast

	local dLbl = Instance.new("TextLabel")
	dLbl.Text = text
	dLbl.Font = Enum.Font.Gotham
	dLbl.TextSize = 12
	dLbl.TextColor3 = Color3.fromRGB(220, 185, 160)
	dLbl.TextXAlignment = Enum.TextXAlignment.Left
	dLbl.TextWrapped = true
	dLbl.Position = UDim2.new(0, 16, 0, 30)
	dLbl.Size = UDim2.new(1, -26, 0, 36)
	dLbl.BackgroundTransparency = 1
	dLbl.TextTransparency = 1
	dLbl.Parent = toast

	TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
	TweenService:Create(stroke, TweenInfo.new(0.35), {Transparency = 0}):Play()
	TweenService:Create(tLbl, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
	TweenService:Create(dLbl, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

	local progress = Instance.new("Frame")
	progress.Size = UDim2.new(1, -4, 0, 2)
	progress.Position = UDim2.new(0, 4, 1, -2)
	progress.BackgroundColor3 = Color3.fromRGB(255, 130, 20)
	progress.BorderSizePixel = 0
	progress.Parent = toast

	TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()

	task.delay(duration, function()
		local outTween = TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0)
		})
		TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
		TweenService:Create(tLbl, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
		TweenService:Create(dLbl, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
		outTween:Play()
		outTween.Completed:Connect(function()
			toast:Destroy()
		end)
	end)
end

-- =======================================================================
--   WINDOW CREATOR
-- =======================================================================
function Hallow:CreateWindow(settings)
	settings = settings or {}
	local winTitle = settings.Title or "HALLOW"

	local defaultSize = UDim2.new(0, 680, 0, 450)

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "HallowLib_Main"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = parentGui

	initNotifyHolder(ScreenGui)

	-- Splash Intro
	local SplashContainer = Instance.new("Frame")
	SplashContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	SplashContainer.Position = UDim2.new(0.5, 0, 0.45, 0)
	SplashContainer.Size = UDim2.new(0, 260, 0, 200)
	SplashContainer.BackgroundTransparency = 1
	SplashContainer.Parent = ScreenGui

	local SplashPumpkin = Instance.new("TextLabel")
	SplashPumpkin.Text = "🎃"
	SplashPumpkin.TextSize = 0
	SplashPumpkin.AnchorPoint = Vector2.new(0.5, 0.5)
	SplashPumpkin.Position = UDim2.new(0.5, 0, 0.42, 0)
	SplashPumpkin.Size = UDim2.new(0, 100, 0, 100)
	SplashPumpkin.BackgroundTransparency = 1
	SplashPumpkin.Parent = SplashContainer

	local SplashTitle = Instance.new("TextLabel")
	SplashTitle.Text = string.upper(winTitle)
	SplashTitle.Font = Enum.Font.GothamBold
	SplashTitle.TextSize = 18
	SplashTitle.TextColor3 = Color3.fromRGB(255, 185, 45)
	SplashTitle.TextTransparency = 1
	SplashTitle.AnchorPoint = Vector2.new(0.5, 0.5)
	SplashTitle.Position = UDim2.new(0.5, 0, 0.86, 0)
	SplashTitle.Size = UDim2.new(1, 0, 0, 24)
	SplashTitle.BackgroundTransparency = 1
	SplashTitle.Parent = SplashContainer

	-- Main Window Frame
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.Position = UDim2.new(0.5, 0, 0.45, 0)
	MainFrame.Size = UDim2.new(0, 0, 0, 0)
	MainFrame.BackgroundColor3 = Color3.fromRGB(20, 9, 3)
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	MainFrame.Visible = false
	MainFrame.Parent = ScreenGui

	local MainCorner = Instance.new("UICorner", MainFrame)
	MainCorner.CornerRadius = UDim.new(0, 12)

	local MainStroke = Instance.new("UIStroke", MainFrame)
	MainStroke.Thickness = 2
	MainStroke.Color = Color3.fromRGB(255, 150, 30)

	local StrokeGradient = Instance.new("UIGradient", MainStroke)
	StrokeGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 100, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 210, 60)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 100, 0))
	})
	StrokeGradient.Rotation = 45

	local PumpkinGradient = Instance.new("UIGradient", MainFrame)
	PumpkinGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(36, 15, 6)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(20, 9, 3)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(12, 5, 2))
	})
	PumpkinGradient.Rotation = 90

	-- Top Bar
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0, 46)
	TopBar.BackgroundColor3 = Color3.fromRGB(32, 12, 4)
	TopBar.BorderSizePixel = 0
	TopBar.Parent = MainFrame

	local TopCorner = Instance.new("UICorner", TopBar)
	TopCorner.CornerRadius = UDim.new(0, 12)

	local TopHider = Instance.new("Frame")
	TopHider.Size = UDim2.new(1, 0, 0, 10)
	TopHider.Position = UDim2.new(0, 0, 1, -10)
	TopHider.BackgroundColor3 = Color3.fromRGB(32, 12, 4)
	TopHider.BorderSizePixel = 0
	TopHider.Parent = TopBar

	local LogoTitle = Instance.new("TextLabel")
	LogoTitle.Text = "🎃 " .. string.upper(winTitle)
	LogoTitle.Font = Enum.Font.GothamBold
	LogoTitle.TextSize = 16
	LogoTitle.TextColor3 = Color3.fromRGB(255, 205, 80)
	LogoTitle.TextXAlignment = Enum.TextXAlignment.Center
	LogoTitle.AnchorPoint = Vector2.new(0.5, 0.5)
	LogoTitle.Position = UDim2.new(0.5, 0, 0.5, 0)
	LogoTitle.Size = UDim2.new(0, 320, 1, 0)
	LogoTitle.BackgroundTransparency = 1
	LogoTitle.Parent = TopBar

	-- Close & Minimize
	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Size = UDim2.new(0, 28, 0, 28)
	CloseBtn.Position = UDim2.new(1, -36, 0, 9)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(130, 25, 15)
	CloseBtn.Text = "X"
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextSize = 12
	CloseBtn.TextColor3 = Color3.fromRGB(255, 230, 230)
	CloseBtn.BorderSizePixel = 0
	CloseBtn.AutoButtonColor = false
	CloseBtn.Parent = TopBar

	local CloseCorner = Instance.new("UICorner", CloseBtn)
	CloseCorner.CornerRadius = UDim.new(0, 6)

	local MinBtn = Instance.new("TextButton")
	MinBtn.Size = UDim2.new(0, 28, 0, 28)
	MinBtn.Position = UDim2.new(1, -70, 0, 9)
	MinBtn.BackgroundColor3 = Color3.fromRGB(48, 20, 8)
	MinBtn.Text = "-"
	MinBtn.Font = Enum.Font.GothamBold
	MinBtn.TextSize = 14
	MinBtn.TextColor3 = Color3.fromRGB(255, 205, 80)
	MinBtn.BorderSizePixel = 0
	MinBtn.AutoButtonColor = false
	MinBtn.Parent = TopBar

	local MinCorner = Instance.new("UICorner", MinBtn)
	MinCorner.CornerRadius = UDim.new(0, 6)

	-- Floating Pumpkin Re-open Button
	local ReopenBtn = Instance.new("TextButton")
	ReopenBtn.Name = "HallowPumpkinReopen"
	ReopenBtn.AnchorPoint = Vector2.new(0.5, 0)
	ReopenBtn.Position = UDim2.new(0.5, 0, 0, -70)
	ReopenBtn.Size = UDim2.new(0, 52, 0, 52)
	ReopenBtn.BackgroundTransparency = 1
	ReopenBtn.BorderSizePixel = 0
	ReopenBtn.AutoButtonColor = false
	ReopenBtn.Text = "🎃"
	ReopenBtn.TextSize = 36
	ReopenBtn.Visible = false
	ReopenBtn.Parent = ScreenGui

	ReopenBtn.MouseEnter:Connect(function()
		playHoverSound(1.5, 0.75)
		TweenService:Create(ReopenBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextSize = 42}):Play()
	end)
	ReopenBtn.MouseLeave:Connect(function()
		TweenService:Create(ReopenBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextSize = 36}):Play()
	end)

	local function showWindow()
		playSound(Hallow.Sounds.Click, 1.0, 0.95)
		local hideTween = TweenService:Create(ReopenBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0, -70)
		})
		hideTween:Play()
		hideTween.Completed:Connect(function()
			ReopenBtn.Visible = false
		end)

		MainFrame.Visible = true
		TweenService:Create(MainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = defaultSize
		}):Play()
	end

	local function hideWindow()
		playSound(Hallow.Sounds.Click, 0.85, 0.9)
		local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		})
		closeTween:Play()
		closeTween.Completed:Connect(function()
			MainFrame.Visible = false
			ReopenBtn.Visible = true
			TweenService:Create(ReopenBtn, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0, 14)
			}):Play()
		end)
	end

	CloseBtn.MouseButton1Click:Connect(hideWindow)
	ReopenBtn.MouseButton1Click:Connect(showWindow)

	local minimized = false
	MinBtn.MouseButton1Click:Connect(function()
		playSound(Hallow.Sounds.Click, 1.15, 0.9)
		minimized = not minimized
		if minimized then
			TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 680, 0, 46)
			}):Play()
		else
			TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = defaultSize
			}):Play()
		end
	end)

	CloseBtn.MouseEnter:Connect(function()
		playHoverSound(1.5, 0.6)
		TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(190, 35, 25)}):Play()
	end)
	CloseBtn.MouseLeave:Connect(function()
		TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(130, 25, 15)}):Play()
	end)
	MinBtn.MouseEnter:Connect(function()
		playHoverSound(1.5, 0.6)
		TweenService:Create(MinBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(68, 28, 10)}):Play()
	end)
	MinBtn.MouseLeave:Connect(function()
		TweenService:Create(MinBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(48, 20, 8)}):Play()
	end)

	-- Window Dragging
	local dragging, dragInput, dragStart, startPos
	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	TopBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	-- Body & Sidebar
	local Body = Instance.new("Frame")
	Body.Name = "Body"
	Body.Size = UDim2.new(1, 0, 1, -46)
	Body.Position = UDim2.new(0, 0, 0, 46)
	Body.BackgroundTransparency = 1
	Body.Parent = MainFrame

	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.Size = UDim2.new(0, 168, 1, 0)
	Sidebar.BackgroundTransparency = 1
	Sidebar.BorderSizePixel = 0
	Sidebar.Parent = Body

	local SideLine = Instance.new("Frame")
	SideLine.Size = UDim2.new(0, 1, 1, -14)
	SideLine.Position = UDim2.new(1, -1, 0, 6)
	SideLine.BackgroundColor3 = Color3.fromRGB(55, 24, 8)
	SideLine.BorderSizePixel = 0
	SideLine.Parent = Sidebar

	local TabScroll = Instance.new("ScrollingFrame")
	TabScroll.Size = UDim2.new(1, -14, 1, -16)
	TabScroll.Position = UDim2.new(0, 8, 0, 8)
	TabScroll.BackgroundTransparency = 1
	TabScroll.BorderSizePixel = 0
	TabScroll.ScrollBarThickness = 0
	TabScroll.Parent = Sidebar

	local TabLayout = Instance.new("UIListLayout", TabScroll)
	TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabLayout.Padding = UDim.new(0, 6)

	local PagesFolder = Instance.new("Folder", Body)
	PagesFolder.Name = "Pages"

	-- Intro Sequence
	task.spawn(function()
		TweenService:Create(SplashPumpkin, TweenInfo.new(0.85, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 75}):Play()
		task.wait(0.35)
		TweenService:Create(SplashTitle, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
		task.wait(1.5)
		local fadeOut = TweenService:Create(SplashPumpkin, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {TextSize = 0})
		TweenService:Create(SplashTitle, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
		fadeOut:Play()
		fadeOut.Completed:Wait()
		SplashContainer:Destroy()

		MainFrame.Visible = true
		TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = defaultSize
		}):Play()
	end)

	-- Tab Management
	local WindowHandler = { CurrentTab = nil }
	local TabList = {}

	function WindowHandler:Destroy()
		playSound(Hallow.Sounds.Click, 0.8, 0.9)
		ScreenGui:Destroy()
	end

	function WindowHandler:CreateTab(tabName, icon)
		icon = icon or "🎃"
		local TabBtn = Instance.new("TextButton")
		TabBtn.Name = tabName .. "_Btn"
		TabBtn.Size = UDim2.new(1, 0, 0, 42)
		TabBtn.BackgroundColor3 = Color3.fromRGB(60, 25, 9)
		TabBtn.BackgroundTransparency = 0.999
		TabBtn.BorderSizePixel = 0
		TabBtn.AutoButtonColor = false
		TabBtn.Text = ""
		TabBtn.Parent = TabScroll

		local TabCorner = Instance.new("UICorner", TabBtn)
		TabCorner.CornerRadius = UDim.new(0, 8)

		local TabStroke = Instance.new("UIStroke", TabBtn)
		TabStroke.Thickness = 1.3
		TabStroke.Color = Color3.fromRGB(220, 110, 20)
		TabStroke.Transparency = 1

		local TabIndicator = Instance.new("Frame")
		TabIndicator.Size = UDim2.new(0, 3, 0, 0)
		TabIndicator.Position = UDim2.new(0, 3, 0.5, 0)
		TabIndicator.AnchorPoint = Vector2.new(0, 0.5)
		TabIndicator.BackgroundColor3 = Color3.fromRGB(255, 170, 35)
		TabIndicator.BorderSizePixel = 0
		TabIndicator.BackgroundTransparency = 1
		TabIndicator.Parent = TabBtn

		local TabIndCorner = Instance.new("UICorner", TabIndicator)
		TabIndCorner.CornerRadius = UDim.new(1, 0)

		local TabIcon = Instance.new("TextLabel")
		TabIcon.Text = icon
		TabIcon.TextSize = 17
		TabIcon.Position = UDim2.new(0, 12, 0, 0)
		TabIcon.Size = UDim2.new(0, 24, 1, 0)
		TabIcon.BackgroundTransparency = 1
		TabIcon.Parent = TabBtn

		local TabTitle = Instance.new("TextLabel")
		TabTitle.Text = tabName
		TabTitle.Font = Enum.Font.GothamSemibold
		TabTitle.TextSize = 14
		TabTitle.TextColor3 = Color3.fromRGB(180, 135, 110)
		TabTitle.TextXAlignment = Enum.TextXAlignment.Left
		TabTitle.Position = UDim2.new(0, 42, 0, 0)
		TabTitle.Size = UDim2.new(1, -46, 1, 0)
		TabTitle.BackgroundTransparency = 1
		TabTitle.Parent = TabBtn

		local Page = Instance.new("ScrollingFrame")
		Page.Name = tabName .. "_Page"
		Page.Size = UDim2.new(1, -188, 1, -16)
		Page.Position = UDim2.new(0, 178, 0, 8)
		Page.BackgroundTransparency = 1
		Page.BorderSizePixel = 0
		Page.ScrollBarThickness = 3
		Page.ScrollBarImageColor3 = Color3.fromRGB(255, 140, 20)
		Page.Visible = false
		Page.Parent = PagesFolder

		local PageLayout = Instance.new("UIListLayout", Page)
		PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PageLayout.Padding = UDim.new(0, 10)

		PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 12)
		end)

		local tabInfo = {
			Name = tabName,
			Button = TabBtn,
			Stroke = TabStroke,
			Title = TabTitle,
			Indicator = TabIndicator,
			Page = Page
		}
		table.insert(TabList, tabInfo)

		local function activateTab()
			WindowHandler.CurrentTab = tabName
			for _, tab in ipairs(TabList) do
				if tab.Name == tabName then
					tab.Page.Visible = true
					TweenService:Create(tab.Button, TweenInfo.new(0.2), {
						BackgroundColor3 = Color3.fromRGB(72, 28, 9),
						BackgroundTransparency = 0
					}):Play()
					TweenService:Create(tab.Stroke, TweenInfo.new(0.2), {
						Color = Color3.fromRGB(255, 150, 30),
						Transparency = 0
					}):Play()
					TweenService:Create(tab.Title, TweenInfo.new(0.2), {
						TextColor3 = Color3.fromRGB(255, 220, 90)
					}):Play()
					TweenService:Create(tab.Indicator, TweenInfo.new(0.2), {
						Size = UDim2.new(0, 4, 0, 24),
						BackgroundTransparency = 0
					}):Play()
				else
					tab.Page.Visible = false
					TweenService:Create(tab.Button, TweenInfo.new(0.2), {
						BackgroundTransparency = 0.999
					}):Play()
					TweenService:Create(tab.Stroke, TweenInfo.new(0.2), {
						Transparency = 1
					}):Play()
					TweenService:Create(tab.Title, TweenInfo.new(0.2), {
						TextColor3 = Color3.fromRGB(180, 135, 110)
					}):Play()
					TweenService:Create(tab.Indicator, TweenInfo.new(0.2), {
						Size = UDim2.new(0, 3, 0, 0),
						BackgroundTransparency = 1
					}):Play()
				end
			end
			playSound(Hallow.Sounds.Click, 1.15, 0.9)
		end

		TabBtn.MouseButton1Click:Connect(activateTab)

		TabBtn.MouseEnter:Connect(function()
			if WindowHandler.CurrentTab ~= tabName then
				playHoverSound(1.65, 0.75)
				TweenService:Create(TabStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(220, 110, 20), Transparency = 0}):Play()
				TweenService:Create(TabBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(60, 25, 9), BackgroundTransparency = 0.15}):Play()
				TweenService:Create(TabTitle, TweenInfo.new(0.18), {TextColor3 = Color3.fromRGB(255, 240, 210)}):Play()
				TweenService:Create(TabIndicator, TweenInfo.new(0.18), {Size = UDim2.new(0, 3, 0, 14), BackgroundTransparency = 0}):Play()
			end
		end)

		TabBtn.MouseLeave:Connect(function()
			if WindowHandler.CurrentTab ~= tabName then
				TweenService:Create(TabStroke, TweenInfo.new(0.18), {Transparency = 1}):Play()
				TweenService:Create(TabBtn, TweenInfo.new(0.18), {BackgroundTransparency = 0.999}):Play()
				TweenService:Create(TabTitle, TweenInfo.new(0.18), {TextColor3 = Color3.fromRGB(180, 135, 110)}):Play()
				TweenService:Create(TabIndicator, TweenInfo.new(0.18), {Size = UDim2.new(0, 3, 0, 0), BackgroundTransparency = 1}):Play()
			end
		end)

		if not WindowHandler.CurrentTab then
			activateTab()
		end

		local TabElements = {}

		local function createCard(height)
			local Card = Instance.new("Frame")
			Card.Size = UDim2.new(1, -10, 0, height or 50)
			Card.BackgroundColor3 = Color3.fromRGB(26, 11, 4)
			Card.BorderSizePixel = 0
			Card.Parent = Page

			local cCorner = Instance.new("UICorner", Card)
			cCorner.CornerRadius = UDim.new(0, 8)

			local cStroke = Instance.new("UIStroke", Card)
			cStroke.Thickness = 1.2
			cStroke.Color = Color3.fromRGB(65, 27, 8)

			Card.MouseEnter:Connect(function()
				playHoverSound(1.7, 0.65)
				TweenService:Create(cStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(210, 100, 20)}):Play()
			end)
			Card.MouseLeave:Connect(function()
				TweenService:Create(cStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(65, 27, 8)}):Play()
			end)

			return Card, cStroke
		end

		function TabElements:CreateSection(secName)
			local sec = Instance.new("Frame")
			sec.Size = UDim2.new(1, -10, 0, 30)
			sec.BackgroundTransparency = 1
			sec.Parent = Page

			local sLbl = Instance.new("TextLabel")
			sLbl.Text = string.upper(secName)
			sLbl.Font = Enum.Font.GothamBold
			sLbl.TextSize = 13
			sLbl.TextColor3 = Color3.fromRGB(255, 155, 40)
			sLbl.TextXAlignment = Enum.TextXAlignment.Left
			sLbl.Position = UDim2.new(0, 4, 0, 6)
			sLbl.Size = UDim2.new(1, 0, 0, 20)
			sLbl.BackgroundTransparency = 1
			sLbl.Parent = sec
		end

		function TabElements:CreateButton(opts)
			opts = opts or {}
			local name = opts.Name or "Button"
			local desc = opts.Description or ""
			local callback = opts.Callback or function() end

			local hasDesc = (desc ~= "")
			local h = hasDesc and 60 or 48
			local Card = createCard(h)

			local ClickArea = Instance.new("TextButton")
			ClickArea.Size = UDim2.new(1, 0, 1, 0)
			ClickArea.BackgroundTransparency = 1
			ClickArea.Text = ""
			ClickArea.Parent = Card

			local t = Instance.new("TextLabel")
			t.Text = name
			t.Font = Enum.Font.GothamSemibold
			t.TextSize = 14
			t.TextColor3 = Color3.fromRGB(255, 235, 215)
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Position = UDim2.new(0, 14, 0, hasDesc and 8 or 14)
			t.Size = UDim2.new(1, -60, 0, 18)
			t.BackgroundTransparency = 1
			t.Parent = Card

			if hasDesc then
				local d = Instance.new("TextLabel")
				d.Text = desc
				d.Font = Enum.Font.Gotham
				d.TextSize = 12
				d.TextColor3 = Color3.fromRGB(180, 140, 115)
				d.TextXAlignment = Enum.TextXAlignment.Left
				d.Position = UDim2.new(0, 14, 0, 30)
				d.Size = UDim2.new(1, -60, 0, 18)
				d.BackgroundTransparency = 1
				d.Parent = Card
			end

			local arrow = Instance.new("TextLabel")
			arrow.Text = "🎃"
			arrow.TextSize = 18
			arrow.Position = UDim2.new(1, -36, 0.5, -11)
			arrow.Size = UDim2.new(0, 22, 0, 22)
			arrow.BackgroundTransparency = 1
			arrow.Parent = Card

			ClickArea.MouseEnter:Connect(function()
				playHoverSound(1.7, 0.7)
			end)

			ClickArea.MouseButton1Click:Connect(function()
				playSound(Hallow.Sounds.Click, 1.0, 0.95)
				local flash = TweenService:Create(Card, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
					BackgroundColor3 = Color3.fromRGB(65, 28, 9)
				})
				flash:Play()
				task.spawn(callback)
			end)
		end

		function TabElements:CreateToggle(opts)
			opts = opts or {}
			local name = opts.Name or "Toggle"
			local desc = opts.Description or ""
			local state = opts.Default or false
			local callback = opts.Callback or function() end

			local hasDesc = (desc ~= "")
			local h = hasDesc and 60 or 48
			local Card = createCard(h)

			local t = Instance.new("TextLabel")
			t.Text = name
			t.Font = Enum.Font.GothamSemibold
			t.TextSize = 14
			t.TextColor3 = Color3.fromRGB(255, 235, 215)
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Position = UDim2.new(0, 14, 0, hasDesc and 8 or 14)
			t.Size = UDim2.new(1, -80, 0, 18)
			t.BackgroundTransparency = 1
			t.Parent = Card

			if hasDesc then
				local d = Instance.new("TextLabel")
				d.Text = desc
				d.Font = Enum.Font.Gotham
				d.TextSize = 12
				d.TextColor3 = Color3.fromRGB(180, 140, 115)
				d.TextXAlignment = Enum.TextXAlignment.Left
				d.Position = UDim2.new(0, 14, 0, 30)
				d.Size = UDim2.new(1, -80, 0, 18)
				d.BackgroundTransparency = 1
				d.Parent = Card
			end

			local Switch = Instance.new("TextButton")
			Switch.Size = UDim2.new(0, 48, 0, 24)
			Switch.Position = UDim2.new(1, -62, 0.5, -12)
			Switch.BackgroundColor3 = state and Color3.fromRGB(220, 110, 15) or Color3.fromRGB(45, 18, 6)
			Switch.BorderSizePixel = 0
			Switch.Text = ""
			Switch.AutoButtonColor = false
			Switch.Parent = Card

			local swCorner = Instance.new("UICorner", Switch)
			swCorner.CornerRadius = UDim.new(1, 0)

			local Thumb = Instance.new("Frame")
			Thumb.Size = UDim2.new(0, 18, 0, 18)
			Thumb.Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
			Thumb.BackgroundColor3 = Color3.fromRGB(255, 245, 230)
			Thumb.BorderSizePixel = 0
			Thumb.Parent = Switch

			local thCorner = Instance.new("UICorner", Thumb)
			thCorner.CornerRadius = UDim.new(1, 0)

			Switch.MouseEnter:Connect(function()
				playHoverSound(1.65, 0.7)
			end)

			local function toggle()
				state = not state
				playSound(Hallow.Sounds.Toggle, state and 1.3 or 0.85, 0.95)

				local targetColor = state and Color3.fromRGB(220, 110, 15) or Color3.fromRGB(45, 18, 6)
				local targetPos   = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)

				TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
				TweenService:Create(Thumb, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = targetPos}):Play()

				task.spawn(callback, state)
			end

			Switch.MouseButton1Click:Connect(toggle)
		end

		-- ===============================================================
		--   SLIDER (DECIMAL INTERVAL 0.1 WITH LOUD AUDIO)
		-- ===============================================================
		function TabElements:CreateSlider(opts)
			opts = opts or {}
			local name = opts.Name or "Slider"
			local min = tonumber(opts.Min) or 0
			local max = tonumber(opts.Max) or 100
			local step = tonumber(opts.Increment or opts.Step) or 0.1
			local def = tonumber(opts.Default) or min
			def = math.clamp(def, min, max)
			local callback = opts.Callback or function() end

			local decimals = 0
			if step < 1 then
				local s = tostring(step)
				local dot = s:find("%.")
				decimals = dot and (#s - dot) or 1
			else
				decimals = 0
			end

			local function formatVal(v)
				if decimals > 0 then
					return string.format("%." .. decimals .. "f", v)
				else
					return tostring(math.floor(v + 0.5))
				end
			end

			local Card = createCard(66)

			local t = Instance.new("TextLabel")
			t.Text = name
			t.Font = Enum.Font.GothamSemibold
			t.TextSize = 14
			t.TextColor3 = Color3.fromRGB(255, 235, 215)
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Position = UDim2.new(0, 14, 0, 10)
			t.Size = UDim2.new(1, -80, 0, 18)
			t.BackgroundTransparency = 1
			t.Parent = Card

			local valLbl = Instance.new("TextLabel")
			valLbl.Text = formatVal(def)
			valLbl.Font = Enum.Font.GothamBold
			valLbl.TextSize = 14
			valLbl.TextColor3 = Color3.fromRGB(255, 185, 40)
			valLbl.TextXAlignment = Enum.TextXAlignment.Right
			valLbl.Position = UDim2.new(1, -68, 0, 10)
			valLbl.Size = UDim2.new(0, 54, 0, 18)
			valLbl.BackgroundTransparency = 1
			valLbl.Parent = Card

			local Track = Instance.new("TextButton")
			Track.Size = UDim2.new(1, -28, 0, 7)
			Track.Position = UDim2.new(0, 14, 0, 44)
			Track.BackgroundColor3 = Color3.fromRGB(45, 18, 6)
			Track.BorderSizePixel = 0
			Track.Text = ""
			Track.AutoButtonColor = false
			Track.Parent = Card

			local trkCorner = Instance.new("UICorner", Track)
			trkCorner.CornerRadius = UDim.new(1, 0)

			local Fill = Instance.new("Frame")
			local startPercent = math.clamp((def - min) / math.max(0.0001, (max - min)), 0, 1)
			Fill.Size = UDim2.new(startPercent, 0, 1, 0)
			Fill.BackgroundColor3 = Color3.fromRGB(255, 140, 20)
			Fill.BorderSizePixel = 0
			Fill.Parent = Track

			local fCorner = Instance.new("UICorner", Fill)
			fCorner.CornerRadius = UDim.new(1, 0)

			Track.MouseEnter:Connect(function()
				playHoverSound(1.7, 0.65)
			end)

			local sliding = false
			local function updateFromInput(input)
				local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
				local rawVal = min + ((max - min) * pos)
				local steppedVal = math.floor((rawVal / step) + 0.5) * step
				local clampedVal = math.clamp(steppedVal, min, max)

				local strVal = formatVal(clampedVal)
				valLbl.Text = strVal

				local visualPos = math.clamp((clampedVal - min) / math.max(0.0001, (max - min)), 0, 1)
				TweenService:Create(Fill, TweenInfo.new(0.04), {Size = UDim2.new(visualPos, 0, 1, 0)}):Play()
				task.spawn(callback, tonumber(strVal) or clampedVal)
			end

			Track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true
					playSound(Hallow.Sounds.Click, 1.4, 0.85)
					updateFromInput(input)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = false
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					updateFromInput(input)
				end
			end)
		end

		function TabElements:CreateDropdown(opts)
			opts = opts or {}
			local name = opts.Name or "Dropdown"
			local items = opts.Options or {}
			local selected = opts.Default or (items[1] or "Select...")
			local callback = opts.Callback or function() end

			local expanded = false
			local itemHeight = 32
			local collapsedHeight = 48

			local Card, stroke = createCard(collapsedHeight)
			Card.ClipsDescendants = true

			local HeaderBtn = Instance.new("TextButton")
			HeaderBtn.Size = UDim2.new(1, 0, 0, collapsedHeight)
			HeaderBtn.BackgroundTransparency = 1
			HeaderBtn.Text = ""
			HeaderBtn.Parent = Card

			local t = Instance.new("TextLabel")
			t.Text = name
			t.Font = Enum.Font.GothamSemibold
			t.TextSize = 14
			t.TextColor3 = Color3.fromRGB(255, 235, 215)
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Position = UDim2.new(0, 14, 0, 15)
			t.Size = UDim2.new(0.5, 0, 0, 18)
			t.BackgroundTransparency = 1
			t.Parent = Card

			local curLbl = Instance.new("TextLabel")
			curLbl.Text = tostring(selected)
			curLbl.Font = Enum.Font.Gotham
			curLbl.TextSize = 13
			curLbl.TextColor3 = Color3.fromRGB(255, 180, 50)
			curLbl.TextXAlignment = Enum.TextXAlignment.Right
			curLbl.Position = UDim2.new(1, -75, 0, 15)
			curLbl.Size = UDim2.new(0, 44, 0, 18)
			curLbl.BackgroundTransparency = 1
			curLbl.Parent = Card

			local Arrow = Instance.new("TextLabel")
			Arrow.Text = "▼"
			Arrow.Font = Enum.Font.GothamBold
			Arrow.TextSize = 11
			Arrow.TextColor3 = Color3.fromRGB(200, 140, 100)
			Arrow.Position = UDim2.new(1, -26, 0, 15)
			Arrow.Size = UDim2.new(0, 16, 0, 18)
			Arrow.BackgroundTransparency = 1
			Arrow.Parent = Card

			HeaderBtn.MouseEnter:Connect(function()
				playHoverSound(1.65, 0.7)
			end)

			local ListHolder = Instance.new("Frame")
			ListHolder.Size = UDim2.new(1, -16, 0, #items * itemHeight)
			ListHolder.Position = UDim2.new(0, 8, 0, collapsedHeight)
			ListHolder.BackgroundTransparency = 1
			ListHolder.Parent = Card

			local lLayout = Instance.new("UIListLayout", ListHolder)
			lLayout.Padding = UDim.new(0, 3)

			for _, item in ipairs(items) do
				local itmBtn = Instance.new("TextButton")
				itmBtn.Size = UDim2.new(1, 0, 0, itemHeight)
				itmBtn.BackgroundColor3 = Color3.fromRGB(36, 14, 5)
				itmBtn.BorderSizePixel = 0
				itmBtn.Font = Enum.Font.Gotham
				itmBtn.TextSize = 13
				itmBtn.TextColor3 = Color3.fromRGB(220, 185, 165)
				itmBtn.Text = "   " .. tostring(item)
				itmBtn.TextXAlignment = Enum.TextXAlignment.Left
				itmBtn.AutoButtonColor = false
				itmBtn.Parent = ListHolder

				local itmCorner = Instance.new("UICorner", itmBtn)
				itmCorner.CornerRadius = UDim.new(0, 5)

				itmBtn.MouseEnter:Connect(function()
					playHoverSound(1.85, 0.6)
				end)

				itmBtn.MouseButton1Click:Connect(function()
					selected = item
					curLbl.Text = tostring(item)
					playSound(Hallow.Sounds.Click, 1.2, 0.9)
					expanded = false
					TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = 0}):Play()
					TweenService:Create(Card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, -10, 0, collapsedHeight)
					}):Play()
					task.spawn(callback, selected)
				end)
			end

			HeaderBtn.MouseButton1Click:Connect(function()
				expanded = not expanded
				playSound(Hallow.Sounds.Click, 1.0, 0.9)
				local targetH = expanded and (collapsedHeight + (#items * itemHeight) + 10) or collapsedHeight
				TweenService:Create(Arrow, TweenInfo.new(0.25), {Rotation = expanded and 180 or 0}):Play()
				TweenService:Create(Card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, -10, 0, targetH)
				}):Play()
			end)
		end

		function TabElements:CreateInput(opts)
			opts = opts or {}
			local name = opts.Name or "Input"
			local placeholder = opts.Placeholder or "Type here..."
			local callback = opts.Callback or function() end

			local Card = createCard(50)

			local t = Instance.new("TextLabel")
			t.Text = name
			t.Font = Enum.Font.GothamSemibold
			t.TextSize = 14
			t.TextColor3 = Color3.fromRGB(255, 235, 215)
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Position = UDim2.new(0, 14, 0, 16)
			t.Size = UDim2.new(0.45, 0, 0, 18)
			t.BackgroundTransparency = 1
			t.Parent = Card

			local Box = Instance.new("TextBox")
			Box.Size = UDim2.new(0, 150, 0, 30)
			Box.Position = UDim2.new(1, -164, 0.5, -15)
			Box.BackgroundColor3 = Color3.fromRGB(42, 17, 6)
			Box.BorderSizePixel = 0
			Box.Font = Enum.Font.Gotham
			Box.TextSize = 13
			Box.TextColor3 = Color3.fromRGB(255, 220, 140)
			Box.PlaceholderText = placeholder
			Box.PlaceholderColor3 = Color3.fromRGB(150, 100, 75)
			Box.Text = ""
			Box.Parent = Card

			local bCorner = Instance.new("UICorner", Box)
			bCorner.CornerRadius = UDim.new(0, 6)

			Box.Focused:Connect(function()
				playHoverSound(1.5, 0.7)
			end)

			Box.FocusLost:Connect(function(enterPressed)
				playSound(Hallow.Sounds.Click, 1.1, 0.9)
				task.spawn(callback, Box.Text, enterPressed)
			end)
		end

		function TabElements:CreateKeybind(opts)
			opts = opts or {}
			local name = opts.Name or "Keybind"
			local currentKey = opts.Default or Enum.KeyCode.E
			local callback = opts.Callback or function() end

			local Card = createCard(48)

			local t = Instance.new("TextLabel")
			t.Text = name
			t.Font = Enum.Font.GothamSemibold
			t.TextSize = 14
			t.TextColor3 = Color3.fromRGB(255, 235, 215)
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Position = UDim2.new(0, 14, 0, 15)
			t.Size = UDim2.new(0.6, 0, 0, 18)
			t.BackgroundTransparency = 1
			t.Parent = Card

			local KeyBtn = Instance.new("TextButton")
			KeyBtn.Size = UDim2.new(0, 75, 0, 28)
			KeyBtn.Position = UDim2.new(1, -89, 0.5, -14)
			KeyBtn.BackgroundColor3 = Color3.fromRGB(42, 17, 6)
			KeyBtn.BorderSizePixel = 0
			KeyBtn.Font = Enum.Font.GothamBold
			KeyBtn.TextSize = 13
			KeyBtn.TextColor3 = Color3.fromRGB(255, 185, 45)
			KeyBtn.Text = currentKey.Name
			KeyBtn.Parent = Card

			local kCorner = Instance.new("UICorner", KeyBtn)
			kCorner.CornerRadius = UDim.new(0, 6)

			KeyBtn.MouseEnter:Connect(function()
				playHoverSound(1.7, 0.65)
			end)

			local listening = false
			KeyBtn.MouseButton1Click:Connect(function()
				listening = true
				KeyBtn.Text = "..."
				playSound(Hallow.Sounds.Click, 1.25, 0.9)
			end)

			UserInputService.InputBegan:Connect(function(input, gpe)
				if listening and input.UserInputType == Enum.UserInputType.Keyboard then
					listening = false
					currentKey = input.KeyCode
					KeyBtn.Text = currentKey.Name
					playSound(Hallow.Sounds.Click, 0.95, 0.95)
				elseif not gpe and input.KeyCode == currentKey then
					task.spawn(callback, currentKey)
				end
			end)
		end

		function TabElements:CreateParagraph(opts)
			opts = opts or {}
			local title = opts.Title or "Information"
			local content = opts.Content or ""

			local Card = createCard(72)

			local t = Instance.new("TextLabel")
			t.Text = title
			t.Font = Enum.Font.GothamBold
			t.TextSize = 14
			t.TextColor3 = Color3.fromRGB(255, 185, 50)
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Position = UDim2.new(0, 14, 0, 10)
			t.Size = UDim2.new(1, -28, 0, 18)
			t.BackgroundTransparency = 1
			t.Parent = Card

			local c = Instance.new("TextLabel")
			c.Text = content
			c.Font = Enum.Font.Gotham
			c.TextSize = 12
			c.TextColor3 = Color3.fromRGB(205, 175, 150)
			c.TextXAlignment = Enum.TextXAlignment.Left
			c.TextWrapped = true
			c.Position = UDim2.new(0, 14, 0, 32)
			c.Size = UDim2.new(1, -28, 0, 32)
			c.BackgroundTransparency = 1
			c.Parent = Card
		end

		return TabElements
	end

	return WindowHandler
end

return Hallow
