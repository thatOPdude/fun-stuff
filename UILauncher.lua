-- =======================================================================
--   🎃 JACK-O'-LANTERN PUMPKIN UI LAUNCHER 🎃
-- =======================================================================
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local localPlayer      = Players.LocalPlayer

local parentGui = (typeof(gethui) == "function" and gethui()) 
	or CoreGui:FindFirstChild("RobloxGui") 
	or localPlayer:WaitForChild("PlayerGui")

-- Clean up any prior launcher instance
if parentGui:FindFirstChild("PumpkinUILauncher") then
	parentGui:FindFirstChild("PumpkinUILauncher"):Destroy()
end

local LauncherGui = Instance.new("ScreenGui")
LauncherGui.Name = "PumpkinUILauncher"
LauncherGui.ResetOnSpawn = false
LauncherGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
LauncherGui.Parent = parentGui

-- =======================================================================
--   INTRO ANIMATION: PUMPKIN SPLASH
-- =======================================================================
local SplashContainer = Instance.new("Frame")
SplashContainer.Name = "SplashContainer"
SplashContainer.AnchorPoint = Vector2.new(0.5, 0.5)
SplashContainer.Position = UDim2.new(0.5, 0, 0.45, 0)
SplashContainer.Size = UDim2.new(0, 200, 0, 200)
SplashContainer.BackgroundTransparency = 1
SplashContainer.Parent = LauncherGui

local SplashPumpkin = Instance.new("TextLabel")
SplashPumpkin.Name = "SplashPumpkin"
SplashPumpkin.Text = "🎃"
SplashPumpkin.TextSize = 0
SplashPumpkin.AnchorPoint = Vector2.new(0.5, 0.5)
SplashPumpkin.Position = UDim2.new(0.5, 0, 0.45, 0)
SplashPumpkin.Size = UDim2.new(0, 100, 0, 100)
SplashPumpkin.BackgroundTransparency = 1
SplashPumpkin.Parent = SplashContainer

local SplashTitle = Instance.new("TextLabel")
SplashTitle.Name = "SplashTitle"
SplashTitle.Text = "JACK-O'-LANTERN LAUNCHER"
SplashTitle.Font = Enum.Font.GothamBold
SplashTitle.TextSize = 13
SplashTitle.TextColor3 = Color3.fromRGB(255, 180, 40)
SplashTitle.TextTransparency = 1
SplashTitle.AnchorPoint = Vector2.new(0.5, 0.5)
SplashTitle.Position = UDim2.new(0.5, 0, 0.85, 0)
SplashTitle.Size = UDim2.new(1, 0, 0, 20)
SplashTitle.BackgroundTransparency = 1
SplashTitle.Parent = SplashContainer

-- =======================================================================
--   MAIN WINDOW SETUP (PUMPKIN BODY)
-- =======================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "PumpkinWindow"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.45, 0)
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(175, 68, 12)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.Parent = LauncherGui

local WindowCorner = Instance.new("UICorner", MainFrame)
WindowCorner.CornerRadius = UDim.new(0, 14)

-- Rich Pumpkin Skin Gradient
local PumpkinGradient = Instance.new("UIGradient", MainFrame)
PumpkinGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(195, 78, 14)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(150, 55, 8)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(105, 36, 4))
})
PumpkinGradient.Rotation = 90

-- Fiery Carved Border Stroke (Warm Amber & Gold)
local WindowStroke = Instance.new("UIStroke", MainFrame)
WindowStroke.Thickness = 2
WindowStroke.Color = Color3.fromRGB(255, 190, 40)

local StrokeGradient = Instance.new("UIGradient", WindowStroke)
StrokeGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 110, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 205, 50)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 110, 0))
})
StrokeGradient.Rotation = 45

-- Top Bar (Charred Carved Rind)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.BackgroundColor3 = Color3.fromRGB(42, 16, 4)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner", TopBar)
TopBarCorner.CornerRadius = UDim.new(0, 14)

local TopBarHider = Instance.new("Frame")
TopBarHider.Size = UDim2.new(1, 0, 0, 10)
TopBarHider.Position = UDim2.new(0, 0, 1, -10)
TopBarHider.BackgroundColor3 = Color3.fromRGB(42, 16, 4)
TopBarHider.BorderSizePixel = 0
TopBarHider.Parent = TopBar

-- Title
local Title = Instance.new("TextLabel")
Title.Text = "🎃 UI LAUNCHER"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextColor3 = Color3.fromRGB(255, 205, 75)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Position = UDim2.new(0, 14, 0, 0)
Title.Size = UDim2.new(1, -60, 1, 0)
Title.BackgroundTransparency = 1
Title.Parent = TopBar

-- Clean Close Button (X)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(140, 25, 15)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.fromRGB(255, 235, 235)
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner", CloseBtn)
CloseCorner.CornerRadius = UDim.new(0, 6)

CloseBtn.MouseEnter:Connect(function()
	TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(205, 35, 25)}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
	TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(140, 25, 15)}):Play()
end)

CloseBtn.MouseButton1Click:Connect(function()
	local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0)
	})
	closeTween:Play()
	closeTween.Completed:Connect(function()
		LauncherGui:Destroy()
	end)
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

-- Content Frame
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -24, 1, -56)
Content.Position = UDim2.new(0, 12, 0, 48)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout", Content)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 10)

-- Helper: Carved Dark Slots inside the Pumpkin Body
local function createCarvedButton(icon, title, desc, accentColor, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 60)
	btn.BackgroundColor3 = Color3.fromRGB(26, 11, 4)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.Parent = Content

	local bCorner = Instance.new("UICorner", btn)
	bCorner.CornerRadius = UDim.new(0, 8)

	-- Glowing Carved Edge
	local bStroke = Instance.new("UIStroke", btn)
	bStroke.Color = Color3.fromRGB(75, 32, 10)
	bStroke.Thickness = 1.2

	-- Accent Glow Stripe
	local stripe = Instance.new("Frame")
	stripe.Size = UDim2.new(0, 4, 1, -14)
	stripe.Position = UDim2.new(0, 8, 0, 7)
	stripe.BackgroundColor3 = accentColor
	stripe.BorderSizePixel = 0
	stripe.Parent = btn

	local sCorner = Instance.new("UICorner", stripe)
	sCorner.CornerRadius = UDim.new(1, 0)

	-- Icon
	local iconLbl = Instance.new("TextLabel")
	iconLbl.Text = icon
	iconLbl.TextSize = 18
	iconLbl.Position = UDim2.new(0, 20, 0, 12)
	iconLbl.Size = UDim2.new(0, 22, 0, 22)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Parent = btn

	-- Title
	local lblTitle = Instance.new("TextLabel")
	lblTitle.Text = title
	lblTitle.Font = Enum.Font.GothamBold
	lblTitle.TextSize = 13
	lblTitle.TextColor3 = Color3.fromRGB(255, 245, 225)
	lblTitle.TextXAlignment = Enum.TextXAlignment.Left
	lblTitle.Position = UDim2.new(0, 48, 0, 12)
	lblTitle.Size = UDim2.new(1, -56, 0, 16)
	lblTitle.BackgroundTransparency = 1
	lblTitle.Parent = btn

	-- Subtitle
	local lblSub = Instance.new("TextLabel")
	lblSub.Text = desc
	lblSub.Font = Enum.Font.Gotham
	lblSub.TextSize = 11
	lblSub.TextColor3 = Color3.fromRGB(215, 175, 145)
	lblSub.TextXAlignment = Enum.TextXAlignment.Left
	lblSub.Position = UDim2.new(0, 48, 0, 32)
	lblSub.Size = UDim2.new(1, -56, 0, 14)
	lblSub.BackgroundTransparency = 1
	lblSub.Parent = btn

	-- Hover Glow
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(42, 18, 6)}):Play()
		TweenService:Create(bStroke, TweenInfo.new(0.2), {Color = accentColor, Thickness = 1.6}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(26, 11, 4)}):Play()
		TweenService:Create(bStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(75, 32, 10), Thickness = 1.2}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		local flash = TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
			BackgroundColor3 = accentColor
		})
		flash:Play()
		callback()
	end)

	return btn
end

-- =======================================================================
--   BUTTON REGISTRATIONS
-- =======================================================================

-- 1. Storage Hunters (Golden Candlelight Glow)
createCarvedButton(
	"🎃",
	"Storage Hunters Hub", 
	"Auto-Tot (4m Cooldown), TPs, Insta-Repair & Garages", 
	Color3.fromRGB(255, 190, 30), 
	function()
		task.spawn(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/thatOPdude/fun-stuff/refs/heads/main/Storage%20Hunters%20Script%20(OPHUB)"))()
		end)
	end
)

-- 2. Remote & Interaction Spy (Clean Ghost White Glow)
createCarvedButton(
	"👻",
	"Remote & Interaction Spy", 
	"Captures Remotes, Prompt holds, & filters 'Finds' spam", 
	Color3.fromRGB(245, 245, 250), 
	function()
		task.spawn(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/thatOPdude/fun-stuff/refs/heads/main/Remote%20Spy.lua"))()
		end)
	end
)

-- 3. Dex Explorer (Toxic Slime Green Glow)
createCarvedButton(
	"🧪",
	"Dex Explorer", 
	"Dark Dex Premium: Browse workspace hierarchy & data", 
	Color3.fromRGB(100, 255, 90), 
	function()
		task.spawn(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/XIMMYzwsss/Dex-Premium/refs/heads/main/DexPremium.lua"))()
		end)
	end
)

-- =======================================================================
--   PLAY OPENING INTRO ANIMATION (SLOWER & CINEMATIC)
-- =======================================================================
task.spawn(function()
	-- 1. Pumpkin bounces in smoothly over 0.85s
	TweenService:Create(SplashPumpkin, TweenInfo.new(0.85, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 70
	}):Play()

	task.wait(0.35)

	-- 2. Subtitle gently fades in over 0.65s
	TweenService:Create(SplashTitle, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0
	}):Play()

	-- 3. Hold on-screen so users can clearly see it (~1.4s)
	task.wait(1.4)

	-- 4. Smooth shrink & fade out
	local fadeOut = TweenService:Create(SplashPumpkin, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		TextSize = 0
	})
	TweenService:Create(SplashTitle, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 1
	}):Play()

	fadeOut:Play()
	fadeOut.Completed:Wait()
	SplashContainer:Destroy()

	-- 5. Main pumpkin UI blooms open smoothly over 0.6s
	MainFrame.Visible = true
	TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 360, 0, 280)
	}):Play()
end)
