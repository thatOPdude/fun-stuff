--// ===== Player Hub — HACKER STYLE (glass + slider tabs, no blur, no requires) =====
-- Tabs: Controls | Movement | Fun/FX | UI Settings | Settings
-- Hacker vibe: neon green accent, monospace font, underline tab indicator, optional Matrix Rain overlay.

--== services / player ==--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam

local function refreshCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid  = character:WaitForChild("Humanoid")
	hrp       = character:WaitForChild("HumanoidRootPart")
end

--== state/helpers ==--
local conns = {}
local function bind(name, conn) if conns[name] then conns[name]:Disconnect() end; conns[name] = conn end
local function unbind(name) if conns[name] then conns[name]:Disconnect(); conns[name] = nil end end
local function safeNum(v, def) v = tonumber(v); return v or def end

--========================
--  FEATURES (gameplay)
--========================
-- Infinite Jump
local infJumpOn=false
local function setInfiniteJump(on)
	infJumpOn=on
	unbind("infjump")
	if on then
		bind("infjump", UserInputService.JumpRequest:Connect(function()
			if humanoid and humanoid.Parent then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				humanoid:ChangeState(Enum.HumanoidStateType.Seated)
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end))
	end
end

-- Noclip
local noclipOn=false
local function setNoclip(on)
	noclipOn=on
	unbind("noclip")
	if on then
		bind("noclip", RunService.Stepped:Connect(function()
			if not character or not character.Parent then return end
			for _,v in ipairs(character:GetDescendants()) do
				if v:IsA("BasePart") then v.CanCollide=false end
			end
		end))
	end
end

-- Fly
local flyOn=false
local flySpeed=60
local flyKeys={W=false,A=false,S=false,D=false,Up=false,Down=false}
local function flyDir()
	local cf=camera.CFrame
	local v=Vector3.zero
	if flyKeys.W then v+=cf.LookVector end
	if flyKeys.S then v-=cf.LookVector end
	if flyKeys.A then v-=cf.RightVector end
	if flyKeys.D then v+=cf.RightVector end
	if flyKeys.Up then v+=Vector3.new(0,1,0) end
	if flyKeys.Down then v-=Vector3.new(0,1,0) end
	if v.Magnitude>0 then v=v.Unit end
	return v
end
local function setFly(on)
	flyOn=on
	unbind("fly")
	if on then
		if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Physics) end
		if hrp then
			hrp.AssemblyLinearVelocity=Vector3.zero
			hrp.AssemblyAngularVelocity=Vector3.zero
		end
		bind("fly", RunService.RenderStepped:Connect(function(dt)
			if not hrp or not hrp.Parent then return end
			local v=flyDir()*flySpeed
			if v.Magnitude>0 then hrp.CFrame=hrp.CFrame+v*dt end
			hrp.AssemblyLinearVelocity=Vector3.zero
			hrp.AssemblyAngularVelocity=Vector3.zero
		end))
	else
		if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Running) end
	end
end
UserInputService.InputBegan:Connect(function(i,gp)
	if gp then return end
	local k=i.KeyCode
	if k==Enum.KeyCode.W then flyKeys.W=true end
	if k==Enum.KeyCode.A then flyKeys.A=true end
	if k==Enum.KeyCode.S then flyKeys.S=true end
	if k==Enum.KeyCode.D then flyKeys.D=true end
	if k==Enum.KeyCode.Space then flyKeys.Up=true end
	if k==Enum.KeyCode.LeftControl then flyKeys.Down=true end
end)
UserInputService.InputEnded:Connect(function(i,gp)
	if gp then return end
	local k=i.KeyCode
	if k==Enum.KeyCode.W then flyKeys.W=false end
	if k==Enum.KeyCode.A then flyKeys.A=false end
	if k==Enum.KeyCode.S then flyKeys.S=false end
	if k==Enum.KeyCode.D then flyKeys.D=false end
	if k==Enum.KeyCode.Space then flyKeys.Up=false end
	if k==Enum.KeyCode.LeftControl then flyKeys.Down=false end
end)

-- Gravity & Jump Power
humanoid.UseJumpPower=true
local function setGravity(g) workspace.Gravity=math.clamp(safeNum(g,workspace.Gravity),0,500) end
local function setJumpPower(p) humanoid.JumpPower=math.clamp(safeNum(p,humanoid.JumpPower),0,300) end

-- Walk on Water
local walkOnWaterOn=false
local rayParams=RaycastParams.new()
rayParams.FilterType=Enum.RaycastFilterType.Exclude
local function setWalkOnWater(on)
	walkOnWaterOn=on
	unbind("waterwalk")
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, not on)
	if on then
		bind("waterwalk", RunService.Heartbeat:Connect(function()
			if not hrp then return end
			rayParams.FilterDescendantsInstances={character}
			local ray=workspace:Raycast(hrp.Position, Vector3.new(0,-10,0), rayParams)
			if ray and ray.Material==Enum.Material.Water then
				local y=ray.Position.Y+2.8
				if hrp.Position.Y<y then
					hrp.Velocity=Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z)
					hrp.CFrame=CFrame.new(hrp.Position.X,y,hrp.Position.Z)
				end
			end
		end))
	else
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,true)
	end
end

-- Fun / FX
local function quickReset() if humanoid then humanoid.Health=0 end end
local function explodeMe()
	if not hrp then return end
	local e=Instance.new("Explosion"); e.Position=hrp.Position; e.BlastPressure=0; e.BlastRadius=6; e.Parent=workspace
	task.delay(0.05,function() if humanoid then humanoid.Health=0 end end)
end
local ragdollOn=false
local function setRagdoll(on)
	ragdollOn=on
	if on then humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll); humanoid.PlatformStand=true
	else humanoid.PlatformStand=false; humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
end
local fxOn=false
local jumpPE, landPE
local function makeJumpFX()
	if jumpPE and landPE then return end
	jumpPE=Instance.new("ParticleEmitter")
	jumpPE.Rate=0; jumpPE.Speed=NumberRange.new(6,12); jumpPE.SpreadAngle=Vector2.new(360,360)
	jumpPE.Lifetime=NumberRange.new(0.4,0.7)
	jumpPE.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.6),NumberSequenceKeypoint.new(1,0)})
	jumpPE.Parent=hrp
	landPE=jumpPE:Clone(); landPE.Parent=hrp
end
local function burst(pe,n) if pe then pe:Emit(n or 20) end end
local function setLowGravFX(on)
	fxOn=on; makeJumpFX(); unbind("fxJump"); unbind("fxLand")
	if on then
		bind("fxJump", humanoid.StateChanged:Connect(function(_,new)
			if new==Enum.HumanoidStateType.Jumping then burst(jumpPE,25) end
		end))
		bind("fxLand", humanoid.StateChanged:Connect(function(_,new)
			if new==Enum.HumanoidStateType.Landed then burst(landPE,35) end
		end))
	end
end

--========================
--  UI (Hacker glass)
--========================
local gui=Instance.new("ScreenGui")
gui.Name="PlayerHub_UI"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.Parent=player:WaitForChild("PlayerGui")

-- THEME (defaults are hacker green)
local Theme={
	AccentHue=0.33, AccentSat=0.95, AccentVal=0.95, -- neon green
	PanelAlpha=0.18, RowAlpha=0.12, StrokeAlpha=0.25,
	Corner=12, Scale=1.0,
	Font = Enum.Font.Code
}
local function AccentColor() return Color3.fromHSV(Theme.AccentHue,Theme.AccentSat,Theme.AccentVal) end

-- main window
local uiScale=Instance.new("UIScale")
uiScale.Scale=Theme.Scale

local main=Instance.new("Frame")
main.Size=UDim2.fromOffset(560, 410)
main.Position=UDim2.new(0.5,-280,0.5,-205)
main.BackgroundColor3=Color3.fromRGB(8,12,10)
main.BackgroundTransparency=1-Theme.PanelAlpha
main.Parent=gui
uiScale.Parent=main

local corner=Instance.new("UICorner",main); corner.CornerRadius=UDim.new(0,Theme.Corner)
local stroke=Instance.new("UIStroke",main); stroke.Thickness=1.2; stroke.Color=AccentColor(); stroke.Transparency=Theme.StrokeAlpha

-- titlebar (draggable)
local title=Instance.new("Frame",main)
title.Size=UDim2.new(1,0,0,36)
title.BackgroundColor3=Color3.fromRGB(10,16,12)
title.BackgroundTransparency=1-Theme.PanelAlpha
local tcorner=Instance.new("UICorner",title); tcorner.CornerRadius=UDim.new(0,Theme.Corner)

local titleLabel=Instance.new("TextLabel",title)
titleLabel.BackgroundTransparency=1
titleLabel.Text="> PLAYER HUB _"
titleLabel.Font=Theme.Font
titleLabel.TextSize=18
titleLabel.TextColor3=AccentColor()
titleLabel.Position=UDim2.fromOffset(12, 5)
titleLabel.Size=UDim2.fromOffset(400, 26)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- drag
do
	local dragging, dragStart, startPos
	title.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 then
			dragging=true; dragStart=input.Position; startPos=main.Position
			input.Changed:Connect(function()
				if input.UserInputState==Enum.UserInputState.End then dragging=false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
			local d=input.Position-dragStart
			main.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
		end
	end)
end

-- ===== Segmented Slider Tabs (underline indicator) =====
local tabBar=Instance.new("Frame",main)
tabBar.Position=UDim2.fromOffset(12,44)
tabBar.Size=UDim2.fromOffset(536,34)
tabBar.BackgroundColor3=Color3.fromRGB(12,18,14)
tabBar.BackgroundTransparency=1-Theme.RowAlpha
local tabCorner=Instance.new("UICorner",tabBar); tabCorner.CornerRadius=UDim.new(0, math.max(8,Theme.Corner-6))
local tabStroke=Instance.new("UIStroke",tabBar); tabStroke.Color=AccentColor(); tabStroke.Transparency=Theme.StrokeAlpha

local underline=Instance.new("Frame",tabBar)
underline.BackgroundColor3=AccentColor()
underline.Size=UDim2.fromOffset(0,3)
underline.Position=UDim2.fromOffset(0, tabBar.Size.Y.Offset - 3)
underline.AnchorPoint = Vector2.new(0,1)

local tabLabels={"Controls","Movement","Fun/FX","UI Settings","Settings"}
local NUM_TABS=#tabLabels
local currentIndex=1
local segButtons={}

for i=1,NUM_TABS do
	local seg=Instance.new("TextButton")
	seg.BackgroundTransparency=1
	seg.Text=tabLabels[i]
	seg.Font=Theme.Font
	seg.TextSize=14
	seg.TextColor3=Color3.fromRGB(190,255,200)
	seg.Parent=tabBar
	segButtons[i]=seg
end

local function layoutTabs()
	local w = tabBar.AbsoluteSize.X/NUM_TABS
	for i,b in ipairs(segButtons) do
		b.Size=UDim2.fromOffset(w,34)
		b.Position=UDim2.fromOffset((i-1)*w,0)
	end
	underline.Size = UDim2.fromOffset(w,3)
	underline.Position = UDim2.new(0, (currentIndex-1)*w, 1, 0)
end
tabBar:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutTabs)
task.defer(layoutTabs)

-- drag/click to select
local draggingTabs=false
local function setTabFromX(x)
	local rel=x - tabBar.AbsolutePosition.X
	local w=tabBar.AbsoluteSize.X
	local t=math.clamp(rel/w,0,0.9999)
	local idx=math.floor(t*NUM_TABS)+1
	if idx~=currentIndex then
		currentIndex=idx
		layoutTabs()
		if currentIndex==1 then _G.buildControls()
		elseif currentIndex==2 then _G.buildMovement()
		elseif currentIndex==3 then _G.buildFunFX()
		elseif currentIndex==4 then _G.buildUISettings()
		else _G.buildSettings()
		end
	end
end
tabBar.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 then draggingTabs=true; setTabFromX(input.Position.X) end
end)
UserInputService.InputChanged:Connect(function(input)
	if draggingTabs and input.UserInputType==Enum.UserInputType.MouseMovement then setTabFromX(input.Position.X) end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 then draggingTabs=false end
end)
for _,b in ipairs(segButtons) do b.MouseButton1Click:Connect(function() setTabFromX(b.AbsolutePosition.X+1) end) end

-- ===== Content =====
local content=Instance.new("Frame",main)
content.Position=UDim2.fromOffset(12, 86)
content.Size=UDim2.fromOffset(536, 312)
content.BackgroundColor3=Color3.fromRGB(10,14,12)
content.BackgroundTransparency=1-Theme.PanelAlpha
local cc=Instance.new("UICorner",content); cc.CornerRadius=UDim.new(0,Theme.Corner-4)
local cs=Instance.new("UIStroke",content); cs.Thickness=1; cs.Color=AccentColor(); cs.Transparency=Theme.StrokeAlpha

local list=Instance.new("ScrollingFrame",content)
list.AutomaticCanvasSize=Enum.AutomaticSize.Y
list.CanvasSize=UDim2.new(0,0,0,0)
list.ScrollBarThickness=6
list.BorderSizePixel=0
list.BackgroundTransparency=1
list.Size=UDim2.new(1,-12,1,-12)
list.Position=UDim2.fromOffset(6,6)
local layout=Instance.new("UIListLayout",list)
layout.Padding=UDim.new(0,8)

-- reusable UI parts
local function styleRow(row)
	row.BackgroundColor3=Color3.fromRGB(12,18,14)
	row.BackgroundTransparency=1-Theme.RowAlpha
	local s=row:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke",row)
	s.Color=AccentColor(); s.Transparency=Theme.StrokeAlpha; s.Thickness=1
	local c=row:FindFirstChildOfClass("UICorner") or Instance.new("UICorner",row)
	c.CornerRadius=UDim.new(0, math.max(8,Theme.Corner-6))
end
local function restyleAll()
	main.BackgroundTransparency=1-Theme.PanelAlpha
	title.BackgroundTransparency=1-Theme.PanelAlpha
	content.BackgroundTransparency=1-Theme.PanelAlpha
	corner.CornerRadius=UDim.new(0,Theme.Corner)
	tcorner.CornerRadius=UDim.new(0,Theme.Corner)
	cc.CornerRadius=UDim.new(0,Theme.Corner-4)
	stroke.Color=AccentColor(); stroke.Transparency=Theme.StrokeAlpha
	cs.Color=AccentColor(); cs.Transparency=Theme.StrokeAlpha
	tabBar.BackgroundTransparency=1-Theme.RowAlpha
	tabStroke.Color=AccentColor(); tabStroke.Transparency=Theme.StrokeAlpha
	underline.BackgroundColor3=AccentColor()
	uiScale.Scale=Theme.Scale
	titleLabel.Font = Theme.Font
	for _,child in ipairs(list:GetChildren()) do if child:IsA("Frame") and child~=layout then styleRow(child) end end
	layoutTabs()
end
local function clearContent()
	for _,c in ipairs(list:GetChildren()) do
		if c:IsA("GuiObject") and c~=layout then c:Destroy() end
	end
end
local function makeRow(h)
	local row=Instance.new("Frame")
	row.Size=UDim2.new(1,-12,0,h or 44)
	row.Parent=list
	styleRow(row)
	return row
end
local function label(parent,text)
	local lbl=Instance.new("TextLabel",parent)
	lbl.BackgroundTransparency=1
	lbl.Font=Theme.Font
	lbl.Text=text
	lbl.TextXAlignment=Enum.TextXAlignment.Left
	lbl.TextSize=14
	lbl.TextColor3=Color3.fromRGB(170,255,170)
	lbl.Position=UDim2.fromOffset(12, 10)
	lbl.Size=UDim2.new(1,-24,1,-20)
	return lbl
end
local function addToggle(text,default,cb)
	local row=makeRow()
	label(row,text)
	local btn=Instance.new("TextButton",row)
	btn.Text=""; btn.AutoButtonColor=false
	btn.Size=UDim2.fromOffset(46,22)
	btn.Position=UDim2.new(1,-58,0.5,-11)
	btn.BackgroundColor3=Color3.fromRGB(40,60,40); btn.BackgroundTransparency=0.3
	local bc=Instance.new("UICorner",btn); bc.CornerRadius=UDim.new(1,0)
	local knob=Instance.new("Frame",btn)
	knob.Size=UDim2.fromOffset(18,18); knob.Position=UDim2.fromOffset(2,2)
	knob.BackgroundColor3=Color3.fromRGB(170,255,170)
	local kc=Instance.new("UICorner",knob); kc.CornerRadius=UDim.new(1,0)
	local on=false
	local function paint()
		if on then
			btn.BackgroundColor3=AccentColor(); btn.BackgroundTransparency=0
			knob:TweenPosition(UDim2.fromOffset(26,2),"Out","Quad",0.12,true)
			knob.BackgroundColor3=Color3.fromRGB(10,20,10)
		else
			btn.BackgroundColor3=Color3.fromRGB(40,60,40); btn.BackgroundTransparency=0.3
			knob:TweenPosition(UDim2.fromOffset(2,2),"Out","Quad",0.12,true)
			knob.BackgroundColor3=Color3.fromRGB(170,255,170)
		end
	end
	btn.MouseButton1Click:Connect(function() on=not on; paint(); cb(on) end)
	on=default or false; paint()
	return function(v) on=v; paint(); cb(on) end
end
local function addButton(text,cb)
	local row=makeRow(); label(row,text)
	local b=Instance.new("TextButton",row)
	b.Text="EXEC"; b.Font=Theme.Font; b.TextSize=14; b.TextColor3=Color3.fromRGB(10,20,10)
	b.Size=UDim2.fromOffset(70,26); b.Position=UDim2.new(1,-86,0.5,-13)
	b.BackgroundColor3=AccentColor(); b.BackgroundTransparency=0
	local bc=Instance.new("UICorner",b); bc.CornerRadius=UDim.new(0, math.max(8,Theme.Corner-8))
	b.MouseButton1Click:Connect(cb)
	return b
end
local function addSlider(text,min,max,def,onChange,decimal)
	local row=makeRow(56)
	local fmt=function(v) return decimal and string.format("%.2f",v) or tostring(math.floor(v)) end
	local lbl=label(row, text.."  ("..fmt(def)..")")
	local bar=Instance.new("Frame",row)
	bar.Position=UDim2.new(0,12,1,-20); bar.Size=UDim2.new(1,-24,0,8)
	bar.BackgroundColor3=Color3.fromRGB(20,30,20); bar.BackgroundTransparency=0.1
	local bc=Instance.new("UICorner",bar); bc.CornerRadius=UDim.new(1,0)
	local fill=Instance.new("Frame",bar); fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=AccentColor()
	local fc=Instance.new("UICorner",fill); fc.CornerRadius=UDim.new(1,0)
	local value=def; local dragging=false
	local function setVal(v)
		value=math.clamp(v,min,max)
		local t=(value-min)/(max-min)
		fill.Size=UDim2.new(t,0,1,0)
		lbl.Text=text.."  ("..fmt(value)..")"
		onChange(value)
	end
	bar.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 then
			dragging=true
			local rel=(input.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X
			setVal(min+math.clamp(rel,0,1)*(max-min))
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
			local rel=(input.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X
			setVal(min+math.clamp(rel,0,1)*(max-min))
		end
	end)
	setVal(def)
	return { set=setVal, _recolor=function() fill.BackgroundColor3=AccentColor() end }
end

-- ===== Matrix Rain overlay =====
local matrixOn=false
local matrixGui
local glyphs=("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ#$%&*/+<>[]{}()\\|")
local columns=40
local function randGlyph()
	return string.sub(glyphs, math.random(1,#glyphs), math.random(1,#glyphs))
end
local function setMatrix(on)
	matrixOn=on
	if matrixGui then matrixGui:Destroy(); matrixGui=nil end
	if not on then return end
	matrixGui=Instance.new("ScreenGui")
	matrixGui.Name="MatrixRain"
	matrixGui.IgnoreGuiInset=true
	matrixGui.ResetOnSpawn=false
	matrixGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
	matrixGui.Parent=gui

	local vs=workspace.CurrentCamera.ViewportSize
	for i=1,columns do
		local lbl=Instance.new("TextLabel")
		lbl.BackgroundTransparency=1
		lbl.Font=Theme.Font
		lbl.TextColor3=Color3.fromRGB(120,255,120)
		lbl.TextSize=14
		lbl.Text=randGlyph()
		lbl.Position=UDim2.new(i/columns, -8, math.random(), -200)
		lbl.Size=UDim2.fromOffset(16, 2000)
		lbl.TextYAlignment = Enum.TextYAlignment.Top
		lbl.ZIndex = 0
		lbl.Parent=matrixGui

		bind("matrix_"..i, RunService.Heartbeat:Connect(function(dt)
			if not lbl or not lbl.Parent then return end
			local p = lbl.Position
			local ny = p.Y.Scale + dt * (0.08 + (i%7)*0.01)
			if ny > 1 then ny = -0.1 end
			lbl.Position = UDim2.new(p.X.Scale, p.X.Offset, ny, p.Y.Offset)
			-- randomize text
			if math.random() < 0.15 then lbl.Text = randGlyph() end
		end))
	end
end

-- ===== Tab builders (exposed for slider) =====
_G.buildControls=function()
	clearContent()
	addSlider("WalkSpeed",4,200,humanoid.WalkSpeed,function(v) humanoid.WalkSpeed=math.floor(v) end)
	addSlider("Camera FOV",40,120,camera.FieldOfView,function(v) camera.FieldOfView=math.floor(v) end)
	addToggle("Infinite Jump",false,function(s) setInfiniteJump(s) end)
	addToggle("Noclip",false,function(s) setNoclip(s) end)
	restyleAll()
end
_G.buildMovement=function()
	clearContent()
	addToggle("Fly",false,function(s) setFly(s) end)
	addSlider("Fly Speed",10,200,flySpeed,function(v) flySpeed=math.floor(v) end)
	addSlider("Jump Power",0,300,humanoid.JumpPower,function(v) setJumpPower(v) end)
	addSlider("Gravity",0,500,workspace.Gravity,function(v) setGravity(v) end)
	addToggle("Walk on Water",false,function(s) setWalkOnWater(s) end)
	restyleAll()
end
_G.buildFunFX=function()
	clearContent()
	addToggle("Ragdoll",false,function(s) setRagdoll(s) end)
	addButton("Explode Me",function() explodeMe() end)
	addButton("Quick Reset",function() quickReset() end)
	addToggle("Low-Gravity Jump FX",false,function(s) setLowGravFX(s) end)
	restyleAll()
end

-- quick preset to force hacker vibe back anytime
local function applyHackerPreset()
	Theme.AccentHue,Theme.AccentSat,Theme.AccentVal = 0.33,0.95,0.95
	Theme.PanelAlpha,Theme.RowAlpha,Theme.StrokeAlpha = 0.18,0.12,0.25
	Theme.Corner,Theme.Scale,Theme.Font = 12,1.0,Enum.Font.Code
	restyleAll()
end

_G.buildUISettings=function()
	clearContent()
	addButton("Hacker Mode Preset", function() applyHackerPreset() end)

	addSlider("Panel Transparency",0,1,Theme.PanelAlpha,function(v) Theme.PanelAlpha=v; restyleAll() end,true)
	addSlider("Row Transparency",0,1,Theme.RowAlpha,function(v) Theme.RowAlpha=v; restyleAll() end,true)
	addSlider("Stroke Opacity",0,1,(1-Theme.StrokeAlpha),function(v) Theme.StrokeAlpha=1-v; restyleAll() end,true)
	addSlider("Corner Radius (px)",4,30,Theme.Corner,function(v) Theme.Corner=math.floor(v); restyleAll() end)
	addSlider("Accent Hue (0-360)",0,360,math.floor(Theme.AccentHue*360),function(v) Theme.AccentHue=v/360; restyleAll() end)
	addSlider("Accent Saturation",0,1,Theme.AccentSat,function(v) Theme.AccentSat=v; restyleAll() end,true)
	addSlider("Accent Value",0,1,Theme.AccentVal,function(v) Theme.AccentVal=v; restyleAll() end,true)
	addSlider("UI Scale",0.6,1.4,Theme.Scale,function(v) Theme.Scale=tonumber(string.format('%.2f',v)); restyleAll() end,true)

	addToggle("Matrix Rain Overlay", false, function(s) setMatrix(s) end)
	restyleAll()
end
_G.buildSettings=function()
	clearContent()
	addButton("Destroy GUI",function()
		setInfiniteJump(false); setNoclip(false); setFly(false); setWalkOnWater(false); setRagdoll(false); setLowGravFX(false); setMatrix(false)
		for k,c in pairs(conns) do if c then c:Disconnect() end conns[k]=nil end
		if matrixGui then matrixGui:Destroy() end
		if jumpPE then jumpPE:Destroy() end
		if landPE then landPE:Destroy() end
		gui:Destroy()
	end)
	restyleAll()
end

-- helpers used above
function clearContent()
	for _,c in ipairs(list:GetChildren()) do
		if c:IsA("GuiObject") and c~=layout then c:Destroy() end
	end
end

-- initial
_G.buildControls()
restyleAll()
layoutTabs()
applyHackerPreset() -- start in hacker mode

-- respawn safety
player.CharacterAdded:Connect(function()
	refreshCharacter()
	if infJumpOn then setInfiniteJump(true) end
	if noclipOn then setNoclip(true) end
	if flyOn then setFly(true) end
	if walkOnWaterOn then setWalkOnWater(true) end
	if ragdollOn then setRagdoll(true) end
	if fxOn then setLowGravFX(true) end
end)
