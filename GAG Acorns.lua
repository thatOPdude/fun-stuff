-- // Simple Acorn Tween Toggle - LocalScript

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- UI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "AcornTweenUI"
gui.ResetOnSpawn = false

local btn = Instance.new("TextButton", gui)
btn.Size = UDim2.fromOffset(150, 50)
btn.Position = UDim2.new(0, 20, 0, 20)
btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.Text = "Auto: OFF"
btn.BorderSizePixel = 0
btn.Active = true
btn.Draggable = true

local running = false

-- tween helper
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
						tweenTo(pos)
					end
				end
			end
		end
		task.wait(1) -- check every second (works fine for 2-min spawns)
	end
end)

-- toggle
btn.MouseButton1Click:Connect(function()
	running = not running
	btn.Text = running and "Auto: ON" or "Auto: OFF"
	btn.BackgroundColor3 = running and Color3.fromRGB(45, 170, 95) or Color3.fromRGB(60, 60, 60)
end)

-- rebind HRP if respawn
player.CharacterAdded:Connect(function(c)
	char = c
	hrp = c:WaitForChild("HumanoidRootPart")
end)
