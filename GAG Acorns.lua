-- // Hacker Style Acorn Auto-Tween GUI - LocalScript (Separate AFK Toggle)

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser  = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local char   = player.Character or player.CharacterAdded:Wait()
local hrp    = char:WaitForChild("HumanoidRootPart")

-- ===== GUI SETUP =====
local gui = Instance.new("ScreenGui")
gui.Name = "AcornTweenUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(240, 110)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
frame.BorderColor3 = Color3.fromRGB(0, 255, 0)
frame.BorderSizePixel = 2
frame.Active = true
frame.Draggable = true
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 26)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Code
title.Text = "ACORN AUTO-TWEEN"
title.TextColor3 = Color3.fromRGB(0, 255, 0)
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 18)
status.Position = UDim2.new(0, 10, 0, 34)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Code
status.Text = "STATUS: OFFLINE"
status.TextColor3 = Color3.fromRGB(0, 200, 0)
status.TextSize = 14
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

-- AFK status line
local afkStatus = Instance.new("TextLabel")
afkStatus.Size = UDim2.new(1, -20, 0, 18)
afkStatus.Position = UDim2.new(0, 10, 0, 52)
afkStatus.BackgroundTransparency = 1
afkStatus.Font = Enum.Font.Code
afkStatus.Text = "AFK: OFF"
afkStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
afkStatus.TextSize = 14
afkStatus.TextXAlignment = Enum.TextXAlignment.Left
afkStatus.Parent = frame

-- Buttons row
local btnRun = Instance.new("TextButton")
btnRun.Size = UDim2.fromOffset(90, 32)
btnRun.Position = UDim2.new(0, 10, 0, 72)
btnRun.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
btnRun.TextColor3 = Color3.fromRGB(0, 0, 0)
btnRun.Font = Enum.Font.Code
btnRun.TextSize = 14
btnRun.Text = "RUN: OFF"
btnRun.BorderSizePixel = 0
btnRun.Parent = frame
Instance.new("UICorner", btnRun).CornerRadius = UDim.new(0, 8)

local btnAFK = Instance.new("TextButton")
btnAFK.Size = UDim2.fromOffset(90, 32)
btnAFK.Position = UDim2.new(0, 120, 0, 72)
btnAFK.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
btnAFK.TextColor3 = Color3.fromRGB(0, 0, 0)
btnAFK.Font = Enum.Font.Code
btnAFK.TextSize = 14
btnAFK.Text = "AFK: OFF"
btnAFK.BorderSizePixel = 0
btnAFK.Parent = frame
Instance.new("UICorner", btnAFK).CornerRadius = UDim.new(0, 8)

-- Hacker glow pulse
local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.6
stroke.Color = Color3.fromRGB(0, 255, 0)
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Transparency = 0.2
stroke.Parent = frame

-- ===== STATE =====
local running = false        -- Acorn runner
local afkOn   = false        -- AFK keep-alive

-- ===== HELPERS =====
local function setBtnVisual(button: TextButton, isOn: boolean, label: string)
	if isOn then
		button.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		button.Text = label .. ": ON"
	else
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		button.Text = label .. ": OFF"
	end
end

local function refreshStatus()
	local main = running and "STATUS: ACTIVE" or "STATUS: OFFLINE"
	status.Text = main
	afkStatus.Text = "AFK: " .. (afkOn and "ON" or "OFF")
end

-- ===== ACORN TWEEN =====
local function tweenTo(targetPos: Vector3)
	local distance = (targetPos - hrp.Position).Magnitude
	local duration = distance / 140
	local tw = TweenService:Create(
		hrp,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CFrame = CFrame.new(targetPos + Vector3.new(0, 4, 0))}
	)
	tw:Play()
	tw.Completed:Wait()
end

task.spawn(function()
	while true do
		if running then
			local acornFolder = workspace:FindFirstChild("Acorn")
			if acornFolder then
				local acorn = acornFolder:FindFirstChild("Acorn")
				if acorn then
					local pos = acorn:IsA("Model") and (acorn.PrimaryPart and acorn.PrimaryPart.Position) or acorn.Position
					if pos then
						status.Text = "STATUS: LOCKED ON"
						tweenTo(pos)
					else
						status.Text = "STATUS: SCANNING..."
					end
				else
					status.Text = "STATUS: SCANNING..."
				end
			else
				status.Text = "STATUS: SEARCHING..."
			end
		end
		task.wait(1)
	end
end)

-- ===== ANTI-AFK (separate toggle) =====
local afkConn : RBXScriptConnection? = nil
local wiggleStop = false

local function startAFK()
	if afkConn then afkConn:Disconnect() end
	afkConn = player.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)

	wiggleStop = false
	task.spawn(function()
		while afkOn and not wiggleStop do
			task.wait(math.random(55, 75))
			pcall(function()
				if not hrp or not hrp.Parent then return end
				local orig = hrp.CFrame
				local offset = Vector3.new((math.random()-0.5)*0.6, 0, (math.random()-0.5)*0.6)
				local t1 = TweenService:Create(hrp, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = orig + offset})
				t1:Play(); t1.Completed:Wait()
				local t2 = TweenService:Create(hrp, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {CFrame = orig})
				t2:Play(); t2.Completed:Wait()
			end)
		end
	end)
end

local function stopAFK()
	if afkConn then afkConn:Disconnect(); afkConn = nil end
	wiggleStop = true
end

-- ===== UI ANIM =====
task.spawn(function()
	while true do
		if running or afkOn then
			stroke.Transparency = 0.05; task.wait(0.3)
			stroke.Transparency = 0.4;  task.wait(0.3)
		else
			stroke.Transparency = 0.2;  task.wait(0.5)
		end
	end
end)

-- ===== BUTTONS =====
btnRun.MouseButton1Click:Connect(function()
	running = not running
	setBtnVisual(btnRun, running, "RUN")
	refreshStatus()
end)

btnAFK.MouseButton1Click:Connect(function()
	afkOn = not afkOn
	setBtnVisual(btnAFK, afkOn, "AFK")
	if afkOn then startAFK() else stopAFK() end
	refreshStatus()
end)

-- ===== RESPAWN SAFETY =====
player.CharacterAdded:Connect(function(c)
	char = c
	hrp = c:WaitForChild("HumanoidRootPart")
	-- if AFK was on before respawn, keep it running
	if afkOn then
		stopAFK()
		startAFK()
	end
end)

-- init visuals
setBtnVisual(btnRun, false, "RUN")
setBtnVisual(btnAFK, false, "AFK")
refreshStatus()
