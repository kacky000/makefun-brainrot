--!strict
-- The Popcorn Wave: every minute or so the Popcorn Machine overflows and a buttery wall of popcorn rolls
-- down the whole Midway. Anyone it catches outside a booth is flung and drops what they carry, so a
-- player with a fresh catch has to dash home before it arrives.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Feedback = require(game:GetService("ServerScriptService"):WaitForChild("World"):WaitForChild("Feedback"))

local PopcornWave = {}

local services: { [string]: any } = {}
local Remotes: Folder
local wave: Model? = nil
local waveX = 0
local frozen = false
local hitThisWave: { [Player]: boolean } = {}
local restartCountdown = false

local START_X = 200
local END_X = -215
local HALF_WIDTH = GameConfig.STREET_HALF_WIDTH + GameConfig.PLOT_GAP - 1

local broadcast = Feedback.broadcast

-- A wall of popcorn: a creamy core, hundreds of kernels on its face and crest, butter drips and spray.
function PopcornWave.buildWaveModel(): Model
	local model = Instance.new("Model")
	model.Name = "PopcornWave"
	local height = GameConfig.WAVE_HEIGHT
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.Size = Vector3.new(16, height, HALF_WIDTH * 2)
	core.CFrame = CFrame.new(0, height / 2, 0)
	core.Color = Color3.fromRGB(255, 196, 60)
	core.Material = Enum.Material.SmoothPlastic
	core.Parent = model
	model.PrimaryPart = core

	local rng = Random.new(11)
	local function kernel(pos: Vector3, size: number, color: Color3, material: Enum.Material?)
		local k = Instance.new("Part")
		k.Name = "Kernel"
		k.Shape = Enum.PartType.Ball
		k.Size = Vector3.one * size
		k.CFrame = CFrame.new(pos)
		k.Color = color
		k.Material = material or Enum.Material.SmoothPlastic
		k.Anchored = false
		k.CanCollide = false
		k.CanQuery = false
		k.CanTouch = false
		k.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = core
		weld.Part1 = k
		weld.Parent = k
		k.Parent = model
	end
	-- Front face (toward -X, the way it rolls) and the crest.
	for _ = 1, 150 do
		local z = rng:NextNumber(-HALF_WIDTH, HALF_WIDTH)
		local y = rng:NextNumber(0.5, height)
		local white = rng:NextNumber() < 0.55
		kernel(Vector3.new(-8 + rng:NextNumber(-1.5, 1), math.max(y, 8), z), rng:NextNumber(3, 5.5), if white then Color3.fromRGB(255, 244, 200) else Color3.fromRGB(255, 176, 40))
	end
	for _ = 1, 110 do
		local z = rng:NextNumber(-HALF_WIDTH, HALF_WIDTH)
		kernel(Vector3.new(rng:NextNumber(-8, 8), height + rng:NextNumber(-1, 4), z), rng:NextNumber(4, 7), if rng:NextNumber() < 0.8 then Color3.fromRGB(255, 250, 230) else Color3.fromRGB(255, 200, 70))
	end
	-- A red-and-white striped bucket rim rolling along the bottom of the face.
	for i = 0, math.floor(HALF_WIDTH * 2 / 6) - 1 do
		local stripe = Instance.new("Part")
		stripe.Name = "BucketStripe"
		stripe.Size = Vector3.new(2, 7, 6)
		stripe.CFrame = CFrame.new(-9, 3.5, -HALF_WIDTH + 3 + i * 6)
		stripe.Color = if i % 2 == 0 then Color3.fromRGB(230, 30, 50) else Color3.fromRGB(255, 255, 255)
		stripe.Anchored = false
		stripe.CanCollide = false
		stripe.CanQuery = false
		stripe.Massless = true
		local w = Instance.new("WeldConstraint")
		w.Part0 = core
		w.Part1 = stripe
		w.Parent = stripe
		stripe.Parent = model
	end
	-- Butter drips glowing on the face.
	for _ = 1, 24 do
		local z = rng:NextNumber(-HALF_WIDTH, HALF_WIDTH)
		local drip = Instance.new("Part")
		drip.Name = "Butter"
		drip.Size = Vector3.new(0.6, rng:NextNumber(3, 8), 1.4)
		drip.CFrame = CFrame.new(-9.6, rng:NextNumber(4, height - 2), z)
		drip.Color = Color3.fromRGB(255, 205, 40)
		drip.Material = Enum.Material.Neon
		drip.Anchored = false
		drip.CanCollide = false
		drip.CanQuery = false
		drip.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = core
		weld.Part1 = drip
		weld.Parent = drip
		drip.Parent = model
	end
	local spray = Instance.new("ParticleEmitter")
	spray.Name = "KernelSpray"
	spray.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	spray.Color = ColorSequence.new(Color3.fromRGB(255, 250, 220), Color3.fromRGB(255, 210, 80))
	spray.Size = NumberSequence.new(1.6, 0.4)
	spray.Rate = 160
	spray.Lifetime = NumberRange.new(0.8, 1.6)
	spray.Speed = NumberRange.new(20, 34)
	spray.SpreadAngle = Vector2.new(40, 60)
	spray.Acceleration = Vector3.new(0, -40, 0)
	spray.EmissionDirection = Enum.NormalId.Left
	spray.Parent = core
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 120)
	light.Range = 40
	light.Brightness = 2
	light.Parent = core
	return model
end

local function isInsideAnyBooth(position: Vector3): boolean
	return math.abs(position.Z) > HALF_WIDTH + 0.5
end

function PopcornWave.hitPlayer(player: Player, rootPart: BasePart)
	if hitThisWave[player] then
		return
	end
	hitThisWave[player] = true
	if services.CarryService.isCarrying(player) then
		services.CarryService.dropCarry(player, "SWEPT BY THE POPCORN WAVE!")
	else
		(Remotes :: any).Notify:FireClient(player, "SWEPT BY THE POPCORN WAVE!", Color3.fromRGB(255, 200, 60))
	end
	local side = if rootPart.Position.Z >= 0 then 1 else -1
	rootPart.AssemblyLinearVelocity = Vector3.new(-70, 55, side * 25)
	local humanoid = rootPart.Parent and rootPart.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
	end
	(Remotes :: any).Sfx:FireClient(player, "wave")
end

local function sweepWave(dt: number)
	if not wave then
		return
	end
	if not frozen then
		waveX -= GameConfig.WAVE_SPEED * services.EventScheduler.waveSpeed() * dt
	end
	(wave :: Model):PivotTo(CFrame.new(waveX, 0, 0))
	workspace:SetAttribute("WaveX", waveX)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if rootPart then
			local p = rootPart.Position
			if math.abs(p.X - waveX) < 9 and p.Y < GameConfig.WAVE_HEIGHT + 4 and not isInsideAnyBooth(p) then
				PopcornWave.hitPlayer(player, rootPart)
			end
		end
	end
	if waveX < END_X and not frozen then
		(wave :: Model):Destroy()
		wave = nil
		workspace:SetAttribute("WaveActive", false)
	end
end

function PopcornWave.startPopcornWave(atX: number?, freeze: boolean?)
	if wave then
		wave:Destroy()
	end
	table.clear(hitThisWave)
	waveX = atX or START_X
	frozen = freeze == true
	wave = PopcornWave.buildWaveModel();
	(wave :: Model):PivotTo(CFrame.new(waveX, 0, 0));
	(wave :: Model).Parent = workspace
	workspace:SetAttribute("WaveActive", true)
	workspace:SetAttribute("WaveEta", 0)
	broadcast("POPCORN WAVE! GET OFF THE MIDWAY!", Color3.fromRGB(255, 90, 60))
end

-- Holds the wave where it is (for the tour's screenshots) or lets it roll again.
function PopcornWave.freezeAt(x: number?)
	if x then
		PopcornWave.startPopcornWave(x, true)
	else
		frozen = false
	end
end

-- Sweeps the current wave away and restarts the countdown (the tour's calm shots).
function PopcornWave.clearWave()
	if wave then
		wave:Destroy()
		wave = nil
	end
	frozen = false
	workspace:SetAttribute("WaveActive", false)
	restartCountdown = true
end

local function scheduleWaves()
	while true do
		local interval = GameConfig.WAVE_INTERVAL / services.EventScheduler.waveFrequency()
		local due = os.clock() + interval
		local warned = false
		restartCountdown = false
		while os.clock() < due and not restartCountdown do
			local left = due - os.clock()
			workspace:SetAttribute("WaveEta", left)
			workspace:SetAttribute("WaveInterval", interval)
			if not warned and left <= GameConfig.WAVE_WARNING then
				warned = true
				broadcast("The Popcorn Machine is rumbling... wave in " .. math.ceil(left) .. "s!", Color3.fromRGB(255, 220, 80))
			end
			task.wait(0.25)
		end
		if restartCountdown then
			continue
		end
		if not frozen then
			PopcornWave.startPopcornWave()
		end
		while wave ~= nil do
			task.wait(0.25)
		end
	end
end

function PopcornWave.init(all: { [string]: any })
	services = all
	Remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	workspace:SetAttribute("WaveActive", false)
	workspace:SetAttribute("WaveEta", GameConfig.WAVE_INTERVAL)
	workspace:SetAttribute("WaveInterval", GameConfig.WAVE_INTERVAL)
end

function PopcornWave.start()
	RunService.Heartbeat:Connect(sweepWave)
	task.spawn(scheduleWaves)
end

return PopcornWave
