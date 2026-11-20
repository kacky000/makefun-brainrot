-- HudEffects: feedback for the HUD: sounds, toasts, the screen flash, confetti bursts, number pops and camera shake.
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local HudEffects = {}

local screen: ScreenGui

-- Every sound is one of Roblox's built-in files, so nothing needs uploading.
local SOUNDS = {
	buy = { "rbxasset://sounds/electronicpingshort.wav", 0.7 },
	place = { "rbxasset://sounds/Kerplunk.wav", 0.8 },
	sell = { "rbxasset://sounds/clickfast.wav", 0.7 },
	stolen = { "rbxasset://sounds/uuhhh.mp3", 0.8 },
	blocked = { "rbxasset://sounds/hit.wav", 0.8 },
	bonk = { "rbxasset://sounds/splat.wav", 0.8 },
	rebirth = { "rbxasset://sounds/victory.wav", 0.8 },
	event = { "rbxasset://sounds/flashbulb.wav", 0.7 },
	wave = { "rbxasset://sounds/Rocket shot.wav", 0.6 },
	lock = { "rbxasset://sounds/switch.wav", 0.9 },
	error = { "rbxasset://sounds/button.wav", 0.6 },
	cannon = { "rbxasset://sounds/paintball.wav", 0.15 },
	alarm = { "rbxasset://sounds/snap.mp3", 0.8 },
}
local soundCache = {}

-- Play one of the HUD's named sounds.
function HudEffects.playSound(name: string)
	local spec = SOUNDS[name]
	if not spec then
		return
	end
	local sound = soundCache[name]
	if not sound then
		sound = Instance.new("Sound")
		sound.SoundId = spec[1]
		sound.Volume = spec[2]
		sound.Parent = SoundService
		soundCache[name] = sound
	end
	sound:Play()
end

function HudEffects.init(gui: ScreenGui)
	screen = gui
end

local TOAST_COLORS = {
	red = Color3.fromRGB(235, 50, 70),
	green = Color3.fromRGB(50, 190, 100),
	gold = Color3.fromRGB(255, 190, 40),
	purple = Color3.fromRGB(160, 90, 255),
}

-- A message that drops in under the top bands and fades out.
function HudEffects.toast(text: string, color: string?, seconds: number?)
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.fromScale(0.5, 0.2)
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(0.44, 0.055)
	label.BackgroundColor3 = TOAST_COLORS[color or "gold"] or TOAST_COLORS.gold
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.TextStrokeTransparency = 0.5
	label.ZIndex = 20
	label.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = label
	TweenService:Create(label, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0.5, 0.228) }):Play()
	task.delay(seconds or 2.6, function()
		local fade = TweenService:Create(label, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1, TextStrokeTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		label:Destroy()
	end)
end

-- Flash the whole screen one colour for a moment (a wave hit, a rebirth).
function HudEffects.flash(color: Color3)
	local cover = Instance.new("Frame")
	cover.Size = UDim2.fromScale(1, 1)
	cover.BackgroundColor3 = color
	cover.BackgroundTransparency = 0.35
	cover.BorderSizePixel = 0
	cover.ZIndex = 30
	cover.Parent = screen
	TweenService:Create(cover, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
	Debris:AddItem(cover, 0.7)
end

-- A burst of confetti falling down the screen.
function HudEffects.confetti(count: number?)
	local random = Random.new()
	for _ = 1, count or 60 do
		local piece = Instance.new("Frame")
		piece.Size = UDim2.fromOffset(random:NextInteger(8, 16), random:NextInteger(8, 16))
		piece.Position = UDim2.fromScale(random:NextNumber(), -0.05)
		piece.BackgroundColor3 = Color3.fromHSV(random:NextNumber(), 0.75, 1)
		piece.BorderSizePixel = 0
		piece.Rotation = random:NextNumber(0, 360)
		piece.ZIndex = 25
		piece.Parent = screen
		local fall = TweenInfo.new(random:NextNumber(1.2, 2.4), Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(piece, fall, { Position = UDim2.fromScale(piece.Position.X.Scale + random:NextNumber(-0.1, 0.1), 1.05), Rotation = piece.Rotation + 360 }):Play()
		Debris:AddItem(piece, 2.5)
	end
end

-- A number that pops up from a spot on the HUD and floats away ("+$120").
function HudEffects.popNumber(text: string, position: UDim2, color: Color3)
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Position = position
	label.Size = UDim2.fromScale(0.16, 0.04)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextStrokeTransparency = 0.3
	label.ZIndex = 15
	label.Parent = screen
	TweenService:Create(label, TweenInfo.new(0.9), { Position = position - UDim2.fromScale(0, 0.05), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(label, 1)
end

-- Grow a HUD element for a beat, then settle it back.
function HudEffects.bounce(element: GuiObject)
	local scale = element:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = element
	scale.Scale = 1.18
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

-- Shake the camera for a moment (hit by the popcorn wave).
function HudEffects.shakeCamera(seconds: number, strength: number)
	local random = Random.new()
	local finish = os.clock() + seconds
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		if os.clock() > finish or not camera then
			connection:Disconnect()
			return
		end
		camera.CFrame *= CFrame.new(random:NextNumber(-strength, strength), random:NextNumber(-strength, strength), 0)
	end)
end

return HudEffects
