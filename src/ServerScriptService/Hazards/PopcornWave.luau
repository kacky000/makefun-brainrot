-- PopcornWave: the hazard to outrun. Every so often the Popcorn Machine overflows and a wall of popcorn rolls
-- down the whole street. Anyone it catches is thrown and drops the brainrot they carry; booths are safe.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.GameConfig)

local PopcornWave = {}

local services
local random = Random.new(7)
local active = nil
PopcornWave.paused = false

local function buildWaveModel(): Model
	local model = Instance.new("Model")
	model.Name = "PopcornWave"
	local width = GameConfig.STREET.halfWidth * 2
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Anchored = true
	core.CanCollide = false
	core.Size = Vector3.new(10, 15, width)
	core.CFrame = CFrame.new(0, 7.5, 0)
	core.Color = Color3.fromRGB(255, 214, 90)
	core.Material = Enum.Material.SmoothPlastic
	core.Parent = model
	model.PrimaryPart = core
	-- The front of the wave leans west: big kernels piled in rows, cream and butter-yellow.
	for row = 0, 5 do
		for column = 0, 10 do
			local kernel = Instance.new("Part")
			kernel.Name = "Kernel"
			kernel.Shape = Enum.PartType.Ball
			kernel.Anchored = true
			kernel.CanCollide = false
			kernel.CastShadow = false
			local size = random:NextNumber(4.2, 6.4)
			kernel.Size = Vector3.new(size, size, size)
			kernel.Color = (random:NextNumber() > 0.4) and Color3.fromRGB(255, 249, 228) or Color3.fromRGB(255, 205, 80)
			kernel.Material = Enum.Material.SmoothPlastic
			kernel.CFrame = CFrame.new(-6 - row * 0.4 + random:NextNumber(-2.5, 1.5) - (5 - row) * 1.4, 2 + row * 2.9 + random:NextNumber(-0.8, 0.8), -width / 2 + 2 + column * (width - 4) / 10 + random:NextNumber(-1, 1))
			kernel.Parent = model
		end
	end
	local spray = Instance.new("ParticleEmitter")
	spray.Texture = "rbxasset://textures/particles/smoke_main.dds"
	spray.Color = ColorSequence.new(Color3.fromRGB(255, 244, 200))
	spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 7) })
	spray.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	spray.Lifetime = NumberRange.new(1, 1.8)
	spray.Rate = 40
	spray.Speed = NumberRange.new(8, 16)
	spray.SpreadAngle = Vector2.new(60, 60)
	spray.EmissionDirection = Enum.NormalId.Top
	spray.Parent = core
	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromScale(34, 5)
	sign.StudsOffset = Vector3.new(-6, 13, 0)
	sign.MaxDistance = 260
	sign.LightInfluence = 0
	sign.Parent = core
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.FredokaOne
	text.Text = "POPCORN WAVE!"
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(255, 240, 120)
	text.TextStrokeColor3 = Color3.fromRGB(150, 40, 20)
	text.TextStrokeTransparency = 0
	text.Parent = sign
	return model
end

-- Throw every player the wave front has reached, and make them drop what they carry.
local function sweepPlayers(wave)
	for _, player in Players:GetPlayers() do
		local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if rootPart and not wave.hit[player] then
			local position = rootPart.Position
			local onStreet = math.abs(position.Z) < GameConfig.STREET.halfWidth + 1 and position.Y < 20
			if onStreet and math.abs(position.X - (wave.x - 6)) < GameConfig.WAVE.hitRange then
				wave.hit[player] = true
				local dropped = services.CarryService.dropCarried(player, "wave")
				rootPart.AssemblyLinearVelocity = Vector3.new(-70, 55, (position.Z >= 0 and 1 or -1) * 45)
				services.notify(player, "waveHit", { dropped = dropped })
			end
		end
	end
end

-- Send one wave down the street from startX (the Popcorn Machine's end when nil).
-- holdSeconds keeps it standing at startX first, so the tour can frame it.
function PopcornWave.startPopcornWave(startX: number?, holdSeconds: number?)
	PopcornWave.stopWave()
	local wave = { x = startX or GameConfig.STREET.maxX - 12, hold = holdSeconds or 0, hit = {}, model = buildWaveModel() }
	wave.model:PivotTo(CFrame.new(wave.x, 7.5, 0))
	wave.model.Parent = Workspace
	active = wave
	Workspace:SetAttribute("WaveActive", true)
	services.notifyAll("waveStart", {})
	wave.step = RunService.Heartbeat:Connect(function(deltaTime)
		if wave.hold > 0 then
			wave.hold -= deltaTime
		else
			wave.x -= GameConfig.WAVE.speed * deltaTime
		end
		wave.model:PivotTo(CFrame.new(wave.x, 7.5 + math.sin(os.clock() * 6) * 0.5, 0))
		sweepPlayers(wave)
		if wave.x < GameConfig.STREET.minX - 10 then
			PopcornWave.stopWave()
		end
	end)
	return wave
end

function PopcornWave.stopWave()
	if active then
		active.step:Disconnect()
		active.model:Destroy()
		active = nil
		Workspace:SetAttribute("WaveActive", false)
	end
end

function PopcornWave.init(shared)
	services = shared
	Workspace:SetAttribute("WaveActive", false)
	Workspace:SetAttribute("WaveAt", 0)
end

-- A wave every GameConfig.WAVE.every seconds; clients count down to WaveAt and warn before it.
function PopcornWave.runWaveLoop()
	while true do
		Workspace:SetAttribute("WaveAt", Workspace:GetServerTimeNow() + GameConfig.WAVE.every)
		task.wait(GameConfig.WAVE.every)
		if not PopcornWave.paused then
			PopcornWave.startPopcornWave()
			while active do
				task.wait(0.5)
			end
		end
	end
end

return PopcornWave
