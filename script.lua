local SILENT_TEXT = Drawing.new("Text")
SILENT_TEXT.Text = Kaias.settings.Enabled and "Silent Aim: ON" or "Silent Aim: OFF"
SILENT_TEXT.Color = Kaias.settings.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
SILENT_TEXT.Size = 32
SILENT_TEXT.Outline = true
SILENT_TEXT.Visible = false

function UpdateText()
	if Text.Enabled then
		SILENT_TEXT.Text = Kaias.settings.Enabled and "Silent Aim: ON" or "Silent Aim: OFF"
		SILENT_TEXT.Color = Kaias.settings.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
		SILENT_TEXT.Visible = Text.Enabled or true
		SILENT_TEXT.Size = Text.Size or 32
		SILENT_TEXT.Position = Text.Position:lower() == "bottomright" and Vector2.new(1765, 975) or Text.Position:lower() == "bottomleft" and Vector2.new(15, 975) or Text.Position:lower() == "topright" and Vector2.new(1765, 10) or Text.Position:lower() == "topleft" and Vector2.new(15, 10) or Vector2.new(15, 10)
	end
end

local Circle = Drawing.new("Circle")
local Result
local Toggled = false
local Target

function updateFOV()
	Circle.Visible = getgenv().Kaias.visualElements.FOV.visible
	Circle.Radius = getgenv().Kaias.visualElements.FOV.radius
	Circle.Color = getgenv().Kaias.visualElements.FOV.color
	Circle.Thickness = getgenv().Kaias.visualElements.FOV.thickness
	Circle.Filled = getgenv().Kaias.visualElements.FOV.filled
end


local function isKnockedOrGrabbed(player)
	return game.PlaceId ~= 2788229376 and true or player.Character:WaitForChild("BodyEffects")["K.O"].Value == false and player.Character:FindFirstChild("GRABBING_CONSTRAINT") == nil
end

local partNames = {
	"Head",
	"UpperTorso",
	"RightUpperArm",
	"RightLowerArm",
	"RightUpperArm",
	"HumanoidRootPart"
}

function getClosestPart(Target)
	local closestpart
	local closdist = Circle.Radius * 1.4
	for i, partName in next, partNames do
		local ting = Target and Target:FindFirstChild(partName) or nil
		closestpart = ting and (function()
			local pos = ting.Position
			local them, vis = workspace.CurrentCamera:WorldToScreenPoint(pos)
			local mousepos = game.Players.LocalPlayer:GetMouse()
			local magnitude = (Vector2.new(them.X, them.Y) - Vector2.new(mousepos.X, mousepos.Y)).magnitude
			return vis and magnitude < closdist and (function()
				closdist = magnitude
				return ting
			end)() or closestpart
		end)() or closestpart
	end
	return closestpart
end

function wallCheck(targetPosition, ignoreList)
	local camera = workspace.CurrentCamera
	local cameraPosition = camera.CFrame.p
	local cameraDirection = (targetPosition - cameraPosition).Unit
	local cameraRay = Ray.new(cameraPosition, cameraDirection * 1000)
	local ignoreDescendants = ignoreList or {}
	ignoreDescendants[# ignoreDescendants + 1] = game.Players.LocalPlayer.Character
	local hitPart, hitPosition, hitNormal = workspace:FindPartOnRayWithIgnoreList(cameraRay, ignoreDescendants)
	return hitPart == nil and true or (hitPosition - cameraPosition).Magnitude >= (targetPosition - cameraPosition).Magnitude
end

local function getClosestPlayer()
	local Mouse = game.Players.LocalPlayer:GetMouse()
	local mousePos = Mouse.hit.p
	local closestPlayer = nil
	local closestDistance = Circle.Radius * 1.4
	for _, player in pairs(game.Players:GetPlayers()) do
		local playerRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if player ~= game.Players.LocalPlayer and playerRootPart then
			local Vector, OnScreen = workspace.CurrentCamera:WorldToViewportPoint(playerRootPart.Position)
			local distance = (playerRootPart.Position - mousePos).magnitude
			if distance < closestDistance and isKnockedOrGrabbed(player) and OnScreen and wallCheck(player.Character:FindFirstChild("UpperTorso").Position, {
				game.Players.LocalPlayer,
				player.Character
			}) then
				closestPlayer = player
				closestDistance = distance
			end
		end
	end
	return closestPlayer
end

game:GetService("UserInputService").InputBegan:Connect(function(keybind, processed)
	if keybind.KeyCode.Name == Kaias.settings.ToggleKey and processed == false then
		Kaias.settings.Enabled = not Kaias.settings.Enabled
	end
	if keybind.KeyCode.Name == Kaias.settings.Keybind and processed == false then
		Toggled = not Toggled
		if not Kaias.settings.instaLock then
			Target = Toggled and getClosestPlayer() or nil
		end
	end
end)

function WSHPCheck()
	return Target.Character.Humanoid.Health > 56 and 22 or 16
end

function isAnti()
	return Target.Character.HumanoidRootPart.Velocity.Magnitude > 50 and Target.Character.Humanoid.MoveDirection * WSHPCheck() * Kaias.settings.Prediction or Target.Character.HumanoidRootPart.Velocity * Kaias.settings.Prediction
end

function camLock()
	local Main = CFrame.new(workspace.CurrentCamera.CFrame.p, Result.Position + isAnti() + Vector3.new(math.random(- Kaias.settings.TracingShakeValueX, Kaias.settings.TracingShakeValueX), math.random(- Kaias.settings.TracingShakeValueY, Kaias.settings.TracingShakeValueY), - Kaias.settings.TracingShakeValueZ, Kaias.settings.TracingShakeValueZ))
	workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(Main, Kaias.settings.TraceInterpolationFactor, Kaias.settings.EasingStyle, Kaias.settings.EasingDirection)
end

function AntiCurve()
	if getgenv().Kaias.settings.AntiCurve then
		for _, v in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
			if v:IsA("Script") and v.Name ~= "Health" and v.Name ~= "Sound" and v:FindFirstChild("LocalScript") then
				v:Destroy()
			end
		end
		game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
			repeat
				wait()
			until game.Players.LocalPlayer.Character
			char.ChildAdded:Connect(function(child)
				if child:IsA("Script") then
					wait()
					if child:FindFirstChild("LocalScript") then
						child.LocalScript:FireServer()
					end
				end
			end)
		end)
		local characterCf = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
		local target = Target.Character.HumanoidRootPart
		game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.lookAt(game.Players.LocalPlayer.Character.PrimaryPart.Position, Vector3.new(target.Position.X, game.Players.LocalPlayer.Character.PrimaryPart.Position.Y, target.Position.Z)))
		game.RunService.RenderStepped:Wait()
		game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(characterCf)
	end
end

game.RunService.Heartbeat:Connect(function()
	Target = Kaias.settings.instaLock and getClosestPlayer() or Target
	local vector2Pos = game:GetService("UserInputService"):GetMouseLocation()
	Result = Target and (Target.Character.Humanoid.FloorMaterial == Enum.Material.Air and Target.Character.HumanoidRootPart or getClosestPart(Target.Character)) or nil
	Circle.Position = getgenv().Kaias.visualElements.FOV.Stick and Target and getgenv().Kaias.settings.Enabled and Vector2.new(workspace.CurrentCamera:worldToViewportPoint(Target.Character.HumanoidRootPart.Position).X, workspace.CurrentCamera:worldToViewportPoint(Target.Character.HumanoidRootPart.Position).Y) or Vector2.new(vector2Pos.X, vector2Pos.Y)
	if Target and Kaias.settings.Enabled and Result then
		if Kaias.settings.Trace then
			camLock()
		end
	end
	AntiCurve()
	updateFOV()
	UpdateText()
end)

local __index
__index = hookmetamethod(game, "__index", function (Object, Property)
	return Object:IsA("Mouse") and Property == "Hit" and Result and Kaias.settings.Enabled and Target and Result.CFrame + isAnti() or __index(Object, Property)
end)
