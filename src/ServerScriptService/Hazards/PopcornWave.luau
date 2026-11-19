-- PopcornWave: the hazard to outrun. Every 75s the Popcorn Machine overflows and a wall of
-- popcorn rolls west down the whole midway. Anyone it catches on the street is flung and drops
-- the brainrot they carry; the belt is wiped. Booths are safe, so players dash home.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.GameConfig)

local PopcornWave = {}

local WAVE = GameConfig.WAVE
local services = nil
local wall: Model? = nil
local rolling = false
local holdLeft = 0

local function buildWall(): Model
	local model = Instance.new("Model")
	model.Name = "PopcornWave"
	local rng = Random.new(7)
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Size = Vector3.new(10, WAVE.height, GameConfig.STREET.halfWidth * 2)
	core.Color = Color3.fromRGB(255, 236, 170)
	core.Material = Enum.Material.SmoothPlastic
	core.Anchored = true
	core.CanCollide = false
	core.CFrame = CFrame.new(0, WAVE.height / 2, 0)
	core.Parent = model
	model.PrimaryPart = core
	for _ = 1, 110 do
		local kernel = Instance.new("Part")
		kernel.Name = "Kernel"
		kernel.Shape = Enum.PartType.Ball
		local size = rng:NextNumber(4, 8)
		kernel.Size = Vector3.new(size, size, size)
		local shade = rng:NextNumber()
		kernel.Color = if shade < 0.25 then Color3.fromRGB(255, 208, 70) elseif shade < 0.4 then Color3.fromRGB(255, 240, 190) else Color3.fromRGB(255, 252, 232)
		kernel.Material = Enum.Material.SmoothPlastic
		kernel.Anchored = true
		kernel.CanCollide = false
		kernel.CFrame = CFrame.new(rng:NextNumber(-9, 4), rng:NextNumber(1, WAVE.height + 3), rng:NextNumber(-GameConfig.STREET.halfWidth, GameConfig.STREET.halfWidth))
		kernel.Parent = model
	end
	local butter = Instance.new("PointLight")
	butter.Color = Color3.fromRGB(255, 214, 110)
	butter.Range = 40
	butter.Brightness = 2
	butter.Parent = core
	return model
end

local function catchPlayers(wallX: number, caught: { [Player]: boolean })
	for player in services.PlayerState.all() do
		local character = player.Character
		local torso = character and character:FindFirstChild("HumanoidRootPart")
		if torso and not caught[player] and GameConfig.isOnStreet(torso.Position) and math.abs(torso.Position.X - wallX) < 7 and torso.Position.Y < WAVE.height then
			caught[player] = true
			local lost = services.CarryService.dropCarried(player, "wave")
			torso.AssemblyLinearVelocity = Vector3.new(-WAVE.knock, 55, if torso.Position.Z >= 0 then 45 else -45)
			if not lost then
				services.notify(player, "toast", { text = "POPCORNED! Get off the midway when the wave rolls", tone = "bad", fx = "wave" })
			end
		end
	end
end

-- Rolls one Popcorn Wave from the machine to the cannon. Yields until it has passed.
-- TourDirector passes holdAtX/holdSeconds to pause the wall mid-street for a screenshot.
function PopcornWave.startPopcornWave(holdAtX: number?, holdSeconds: number?)
	if rolling then
		return
	end
	rolling = true
	wall = wall or buildWall()
	local model = wall :: Model
	local x = GameConfig.BELT.x1 + 6
	local finish = -GameConfig.STREET.halfLength - 12
	workspace:SetAttribute("WaveActive", true)
	services.notifyAll("toast", { text = "POPCORN WAVE! GET OFF THE MIDWAY!", tone = "bad", fx = "wave" })
	model:PivotTo(CFrame.new(x, WAVE.height / 2, 0))
	model.Parent = workspace
	local caught = {}
	local crumbs = 0
	holdLeft = holdSeconds or 0
	while x > finish and holdLeft >= 0 do
		local dt = RunService.Heartbeat:Wait()
		if holdAtX and x <= holdAtX and holdLeft > 0 then
			holdLeft -= dt
			if holdLeft <= 0 then
				holdAtX = nil
				holdLeft = 0
			end
		else
			x -= WAVE.speed * dt
		end
		model:PivotTo(CFrame.new(x, WAVE.height / 2, 0) * CFrame.Angles(0, 0, math.sin(x * 0.2) * 0.05))
		services.ConveyorSpawner.sweepBelt(x - 4)
		catchPlayers(x, caught)
		crumbs += dt
		if crumbs > 0.12 then
			crumbs = 0
			local crumb = Instance.new("Part")
			crumb.Shape = Enum.PartType.Ball
			crumb.Size = Vector3.new(1.6, 1.6, 1.6)
			crumb.Color = Color3.fromRGB(255, 248, 220)
			crumb.CanCollide = true
			crumb.CFrame = CFrame.new(x + 6, 4, math.random(-18, 18))
			crumb.Parent = workspace
			Debris:AddItem(crumb, 5)
		end
	end
	model.Parent = nil
	rolling = false
	workspace:SetAttribute("WaveActive", false)
	workspace:SetAttribute("WaveAt", workspace:GetServerTimeNow() + WAVE.interval)
	services.ConveyorSpawner.refillBelt()
end

-- Clears a wave that TourDirector is holding on the street, so the next scene starts clean.
function PopcornWave.clearHeldWave()
	if rolling and holdLeft > 0 then
		holdLeft = -1
	end
end

function PopcornWave.isRolling(): boolean
	return rolling
end

function PopcornWave.start(allServices)
	services = allServices
	workspace:SetAttribute("WaveActive", false)
	workspace:SetAttribute("WaveAt", workspace:GetServerTimeNow() + WAVE.interval)
	task.spawn(function()
		while true do
			local waitFor = (workspace:GetAttribute("WaveAt") :: number) - workspace:GetServerTimeNow()
			if waitFor > 0 or rolling or PopcornWave.paused then
				task.wait(math.clamp(waitFor, 0.25, 1))
			else
				PopcornWave.startPopcornWave()
			end
		end
	end)
end

return PopcornWave
