-- PopcornWave: the hazard to outrun. Every so often the Popcorn Machine blows and a wall of popcorn rolls down the
-- whole street. Anyone it catches on the street is knocked flying and drops the brainrot they carry; it also
-- sweeps the Prize Belt clean. Booths are safe, and players who stay clear get a dodge bonus.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.GameConfig)
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local PlayerState = require(script.Parent.Parent.State.PlayerState)
local CarryService = require(script.Parent.Parent.Economy.CarryService)
local ConveyorSpawner = require(script.Parent.Parent.Economy.ConveyorSpawner)
local IncomeTicker = require(script.Parent.Parent.Economy.IncomeTicker)

local PopcornWave = {}
local rolling = false
PopcornWave.frozenAt = nil :: number? -- TourDirector parks the wave at an x for a screenshot

local function buildWall(): Model
	local wall = Instance.new("Model")
	wall.Name = "PopcornWave"
	local width = GameConfig.STREET.halfWidth * 2 + 4
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Size = Vector3.new(7, 15, width)
	core.Color = Color3.fromRGB(255, 226, 120)
	core.Material = Enum.Material.Neon
	core.Transparency = 0.25
	core.Anchored = true
	core.CanCollide = false
	core.Parent = wall
	wall.PrimaryPart = core
	local rng = Random.new(11)
	for i = 1, 130 do
		local kernel = Instance.new("Part")
		kernel.Shape = Enum.PartType.Ball
		local d = rng:NextNumber(2.4, 5)
		kernel.Size = Vector3.new(d, d, d)
		local y = rng:NextNumber(-7, 9) ^ 1
		kernel.CFrame = CFrame.new(rng:NextNumber(-5, 4) - (y + 7) * 0.25, y, rng:NextNumber(-width / 2, width / 2))
		kernel.Color = if i % 4 == 0 then Color3.fromRGB(255, 214, 90) else Color3.fromRGB(255, 250, 232)
		kernel.Material = Enum.Material.SmoothPlastic
		kernel.Anchored = false
		kernel.CanCollide = false
		kernel.CanTouch = false
		kernel.CanQuery = false
		kernel.Massless = true
		kernel.Parent = wall
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = core
		weld.Part1 = kernel
		weld.Parent = kernel
	end
	local spray = Instance.new("ParticleEmitter")
	spray.Color = ColorSequence.new(Color3.fromRGB(255, 250, 225))
	spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0.4) })
	spray.Lifetime = NumberRange.new(0.8, 1.6)
	spray.Rate = 140
	spray.Speed = NumberRange.new(20, 40)
	spray.SpreadAngle = Vector2.new(70, 70)
	spray.Acceleration = Vector3.new(0, -50, 0)
	spray.EmissionDirection = Enum.NormalId.Top
	spray.Parent = core
	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromScale(34, 6)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 13, 0)
	tag.LightInfluence = 0
	tag.MaxDistance = 400
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.LuckiestGuy
	text.Text = "POPCORN WAVE!"
	text.TextColor3 = Color3.fromRGB(255, 236, 110)
	text.TextScaled = true
	text.TextStrokeTransparency = 0
	text.TextStrokeColor3 = Color3.fromRGB(150, 40, 20)
	text.Parent = tag
	tag.Parent = core
	return wall
end

local function hitPlayer(player: Player)
	local dropped = nil
	local s = PlayerState.get(player)
	if s and s.carrying then
		dropped = BrainrotCatalog.byId[s.carrying.id].name
		CarryService.dropCarried(player, "wave")
	end
	PlayerState.notify(player, "WaveHit", { dropped = dropped })
end

function PopcornWave.startPopcornWave(warning: number?) -- warn, then roll the popcorn wall down the street
	if rolling then
		return
	end
	rolling = true
	local W = GameConfig.WAVE
	local warn = warning or W.warning
	Workspace:SetAttribute("WaveState", "warning")
	Workspace:SetAttribute("WaveHitsAt", Workspace:GetServerTimeNow() + warn)
	PlayerState.notifyAll("WaveWarning", { seconds = warn })
	task.wait(warn)

	Workspace:SetAttribute("WaveState", "rolling")
	local wall = buildWall()
	local x = GameConfig.BELT.xEnd + 8
	wall:PivotTo(CFrame.new(x, 7.5, 0))
	wall.Parent = Workspace
	local wasHit = {}
	local half = GameConfig.STREET.halfWidth + 1.5
	while x > GameConfig.STREET.xMin - 12 do
		local dt = RunService.Heartbeat:Wait()
		if PopcornWave.frozenAt then
			x = PopcornWave.frozenAt
		else
			x -= W.speed * dt
		end
		wall:PivotTo(CFrame.new(x, 7.5 + math.sin(x * 0.3) * 0.6, 0))
		ConveyorSpawner.sweepBelt(x - 4, x + 4)
		for _, player in Players:GetPlayers() do
			local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if rootPart and not wasHit[player] and not PopcornWave.frozenAt then
				local p = rootPart.Position
				if math.abs(p.Z) < half and math.abs(p.X - x) < W.hitHalfDepth and p.Y < 17 then
					wasHit[player] = true
					hitPlayer(player)
				end
			end
		end
	end
	wall:Destroy()
	ConveyorSpawner.fillBelt()
	for _, player in Players:GetPlayers() do
		if not wasHit[player] and PlayerState.get(player) then
			local bonus = math.max(10, math.floor(IncomeTicker.incomePerSecond(player) * 5))
			PlayerState.addCash(player, bonus)
			PlayerState.notify(player, "WaveDodged", { bonus = bonus })
		end
	end
	Workspace:SetAttribute("WaveState", "idle")
	Workspace:SetAttribute("NextWaveAt", Workspace:GetServerTimeNow() + W.every)
	rolling = false
end

function PopcornWave.isRolling(): boolean
	return rolling
end

function PopcornWave.start()
	Workspace:SetAttribute("WaveState", "idle")
	Workspace:SetAttribute("NextWaveAt", Workspace:GetServerTimeNow() + GameConfig.WAVE.first)
	task.spawn(function()
		task.wait(GameConfig.WAVE.first)
		while true do
			PopcornWave.startPopcornWave()
			task.wait(GameConfig.WAVE.every)
		end
	end)
end

return PopcornWave
