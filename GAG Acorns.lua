-- // Hacker Style Acorn Auto-Tween GUI - LocalScript

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- ===== GUI SETUP =====
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "AcornTweenUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(200, 70)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
frame.BorderColor3 = Color3.fromRGB(0, 255, 0)
frame.BorderSizePixel = 2
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local uicorner = Instance.new("UICorner", frame)
uicorner.CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 28)
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
status.Position = UDim2.new(0, 10, 0, 36)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Code
status.Text = "STATUS: OFFLINE"
status.TextColor3 = Color3.fromRGB(0, 180, 0)
status.TextSize = 14
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local btn = Instance.new("TextButton")
btn.Size = UDim2.fromOffset(60, 30)
btn.Position = UDim2.new(1, -70, 0, 20)
btn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
btn.TextColor3 = Color3.fromRGB(0, 0, 0)
btn.Font = Enum.Font.Code
btn.TextSize = 14
btn.Text = "OFF"
btn.BorderSizePixel = 0
btn.Parent = frame

local btnCorner = Instance.new("UICorner", btn)
btnCorner.CornerRadius = UDim.new(0, 8)

-- glow pulse
local UIStroke = Instance.new("UIStroke", frame)
UIStroke.Thickness = 1.6
UIStroke.Color = Color3.fromRGB(0, 255, 0)
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Transparency = 0.2

-- ===== LOGIC =====
local running = false

local function tweenTo(targetPos)
	local distance = (targetPos - hrp.Position).Magnitude
	local duration = distance / 140
	local tween = TweenService:Create(
		hrp,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CFrame = CFrame.new(targetPos + Vector3.new(0, 4, 0))}
	)
	tween:Play()
	tween.Completed:Wait()
end

-- background pulse effect
task.spawn(function()
	while true do
		if running then
			UIStroke.Transparency = 0.05
			task.wait(0.3)
			UIStroke.Transparency = 0.4
			task.wait(0.3)
		else
			UIStroke.Transparency = 0.2
			task.wait(0.5)
		end
	end
end)

-- main loop
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

-- toggle
btn.MouseButton1Click:Connect(function()
	running = not running
	if running then
		btn.Text = "ON"
		btn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		status.Text = "STATUS: SCANNING..."
	else
		btn.Text = "OFF"
		btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		status.Text = "STATUS: OFFLINE"
	end
end)

-- rebind HRP if respawn
player.CharacterAdded:Connect(function(c)
	char = c
	hrp = c:WaitForChild("HumanoidRootPart")
end)
