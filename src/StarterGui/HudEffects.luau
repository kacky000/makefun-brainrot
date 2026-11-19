-- HudEffects: feedback. Sounds, floating money numbers, confetti, screen flash, camera punch and shake, the
-- Popcorn Wave knock-back, and the slow spin of the ferris wheel and the carousel.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local HudEffects = {}

-- Every sound ships with the Roblox client (rbxasset://sounds), so none depends on an uploaded asset.
local SOUNDS = {
	Buy = { "rbxasset://sounds/electronicpingshort.wav", 0.7, 1.2 },
	Place = { "rbxasset://sounds/button.wav", 0.9, 1.0 },
	Collect = { "rbxasset://sounds/snap.mp3", 0.8, 1.4 },
	Click = { "rbxasset://sounds/clickfast.wav", 0.6, 1.0 },
	Error = { "rbxasset://sounds/uuhhh.mp3", 0.5, 1.1 },
	Alarm = { "rbxasset://sounds/bass.wav", 0.9, 0.8 },
	Splat = { "rbxasset://sounds/splat.wav", 0.9, 1.0 },
	Lock = { "rbxasset://sounds/switch.wav", 0.9, 0.7 },
	Blocked = { "rbxasset://sounds/collide.wav", 0.9, 0.8 },
	Bonk = { "rbxasset://sounds/swordslash.wav", 0.8, 0.7 },
	Fanfare = { "rbxasset://sounds/victory.wav", 0.6, 1.0 },
}
local CONFETTI = { Color3.fromRGB(255, 80, 90), Color3.fromRGB(255, 222, 70), Color3.fromRGB(90, 220, 110), Color3.fromRGB(80, 170, 255), Color3.fromRGB(214, 120, 255), Color3.fromRGB(255, 150, 196) }
local sounds = {}
local shake = 0
local tourCamera = nil
local baseFov = 70
local rng = Random.new()

function HudEffects.play(name: string)
	local spec = SOUNDS[name]
	if not spec then
		return
	end
	local sound = sounds[name]
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = spec[1]
		sound.Volume = spec[2]
		sound.PlaybackSpeed = spec[3]
		sound.Parent = SoundService
		sounds[name] = sound
	end
	sound:Play()
end

-- popNumber: a money number that pops beside the wallet and floats up.
function HudEffects.popNumber(gui: ScreenGui, message: string, color: Color3)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.LuckiestGuy
	label.Text = message
	label.TextColor3 = color
	label.TextScaled = true
	label.TextStrokeTransparency = 0
	label.Size = UDim2.fromOffset(260, 44)
	label.Position = UDim2.fromOffset(330 + rng:NextInteger(-10, 30), 190 + rng:NextInteger(-12, 12))
	label.Rotation = rng:NextInteger(-8, 8)
	label.Parent = gui
	local rise = TweenService:Create(label, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = label.Position - UDim2.fromOffset(0, 70), TextTransparency = 1, TextStrokeTransparency = 1 })
	rise:Play()
	rise.Completed:Connect(function()
		label:Destroy()
	end)
end

function HudEffects.confetti(gui: ScreenGui, count: number)
	for i = 1, count do
		local bit = Instance.new("Frame")
		bit.BorderSizePixel = 0
		bit.BackgroundColor3 = CONFETTI[i % #CONFETTI + 1]
		bit.Size = UDim2.fromOffset(rng:NextInteger(8, 14), rng:NextInteger(14, 22))
		bit.Position = UDim2.new(rng:NextNumber(0.2, 0.8), 0, 0, -30)
		bit.Rotation = rng:NextInteger(0, 360)
		bit.ZIndex = 20
		bit.Parent = gui
		local fall = TweenService:Create(bit, TweenInfo.new(rng:NextNumber(1.2, 2.2), Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(bit.Position.X.Scale + rng:NextNumber(-0.15, 0.15), 0, 1, 40),
			Rotation = bit.Rotation + rng:NextInteger(-360, 360),
		})
		fall:Play()
		fall.Completed:Connect(function()
			bit:Destroy()
		end)
	end
end

function HudEffects.flash(gui: ScreenGui, color: Color3)
	local sheet = Instance.new("Frame")
	sheet.Size = UDim2.fromScale(3, 3)
	sheet.Position = UDim2.fromScale(-1, -1)
	sheet.BackgroundColor3 = color
	sheet.BackgroundTransparency = 0.2
	sheet.ZIndex = 30
	sheet.Parent = gui
	local fade = TweenService:Create(sheet, TweenInfo.new(0.7), { BackgroundTransparency = 1 })
	fade:Play()
	fade.Completed:Connect(function()
		sheet:Destroy()
	end)
end

function HudEffects.punchCamera(degrees: number)
	local camera = Workspace.CurrentCamera
	camera.FieldOfView = baseFov + degrees
	TweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { FieldOfView = baseFov }):Play()
end

function HudEffects.shakeCamera(seconds: number)
	shake = math.max(shake, seconds)
end

-- knockBack: the Popcorn Wave throws the player down the street. The client owns its character, so it throws itself.
function HudEffects.knockBack(player: Player)
	local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.AssemblyLinearVelocity = Vector3.new(-70, 55, rng:NextNumber(-10, 10))
	end
end

-- aimCamera: TourDirector's fixed shot. No position hands the camera back to the player.
function HudEffects.aimCamera(position: Vector3?, lookAt: Vector3?)
	local camera = Workspace.CurrentCamera
	if position and lookAt then
		tourCamera = CFrame.lookAt(position, lookAt)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = tourCamera
	else
		tourCamera = nil
		camera.CameraType = Enum.CameraType.Custom
	end
end

local wheels = nil
local function findWheels()
	local carnival = Workspace:FindFirstChild("Carnival")
	if not carnival then
		return nil
	end
	local found = {}
	local ferris = carnival:FindFirstChild("FerrisWheel")
	local carousel = carnival:FindFirstChild("Carousel")
	if ferris and ferris:FindFirstChild("Wheel") then
		table.insert(found, { model = ferris.Wheel, axis = Vector3.new(0, 0, 1), speed = 0.12 })
	end
	if carousel and carousel:FindFirstChild("Wheel") then
		table.insert(found, { model = carousel.Wheel, axis = Vector3.new(0, 1, 0), speed = 0.5 })
	end
	return found
end

function HudEffects.step(dt: number)
	local camera = Workspace.CurrentCamera
	if tourCamera then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = tourCamera
	elseif shake > 0 then
		shake -= dt
		camera.CFrame *= CFrame.new(rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.5, 0.5), 0)
	end
	wheels = wheels or findWheels()
	for _, wheel in wheels or {} do
		if wheel.model.PrimaryPart then
			local pivot = wheel.model:GetPivot()
			wheel.model:PivotTo(CFrame.new(pivot.Position) * CFrame.fromAxisAngle(wheel.axis, wheel.speed * dt) * pivot.Rotation)
		end
	end
end

return HudEffects
