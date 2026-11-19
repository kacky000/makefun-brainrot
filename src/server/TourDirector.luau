--!strict
-- Stages the game's showcase moments for screenshots and for reviewers (TOUR.json calls showcase):
--   "cover" - a full booth, Golden Hour, the player dashing home with a Secret while the wave closes in
--   "base"  - a booth of twenty rare brainrots earning, during Rainbow Rain, a clown raid on the way
--   "heist" - a Sneaky Clown escaping a booth with a stolen Legendary
--   "locked" - a locked gate bouncing a clown while a fresh Mythic is placed
--   "index" - the Brainrot Index book open with most of the cast discovered
-- Everything it shows is the game's own systems, called with chosen values.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local TourDirector = {}

local services: { [string]: any } = {}

local LINEUP = {
	{ "grandprize", "Gold" },
	{ "kernelking", nil },
	{ "coasterraptor", "Neon" },
	{ "saturnsundae", nil },
	{ "discodino", "Rainbow" },
	{ "lavalampo", nil },
	{ "fortunetoad", "Galaxy" },
	{ "lollilobster", nil },
	{ "ringrhino", "Buttered" },
	{ "goldfish", nil },
	{ "sushi", "Gold" },
	{ "bumperbulldog", nil },
	{ "popcornelius", "Neon" },
	{ "ferrisfrog", nil },
	{ "toiletronaut", "Rainbow" },
	{ "cactus", nil },
	{ "hotdogcopter", "Gold" },
	{ "clownfishino", nil },
	{ "teacuppa", "Buttered" },
	{ "wafflewalrus", nil },
}

local function firstPlayer(): Player?
	return Players:GetPlayers()[1]
end

local function fillBooth(player: Player, count: number)
	local profile = services.PlayerData.get(player)
	if not profile then
		return
	end
	profile.pedestals = GameConfig.MAX_PEDESTALS
	table.clear(profile.slots)
	for index = 1, math.min(count, #LINEUP) do
		local entry = LINEUP[index]
		profile.slots[index] = { id = entry[1], mut = entry[2] }
		profile.discovered[entry[1]] = true
	end
	services.PlayerData.publish(player)
	services.BasePedestals.refreshPedestals(player)
end

local function discover(player: Player, count: number)
	local profile = services.PlayerData.get(player)
	if not profile then
		return
	end
	for index, def in BrainrotCatalog.list do
		if index <= count then
			profile.discovered[def.id] = true
		end
	end
	services.PlayerData.publish(player)
end

local function placeCharacter(player: Player, cframe: CFrame)
	local character = player.Character
	if character then
		character:PivotTo(cframe)
	end
end

function TourDirector.showcase(scene: string)
	if not services.PlayerData then
		-- Required from another context (a tour harness): hand the call to the live game.
		local call = game:GetService("ServerStorage"):FindFirstChild("ServiceCall") :: BindableFunction?
		if call then
			call:Invoke("TourDirector", "showcase", scene)
		end
		return
	end
	local player = firstPlayer()
	if not player then
		return
	end
	local profile = services.PlayerData.get(player)
	local plot = services.BasePedestals.plotOf(player)
	if not profile or not plot then
		return
	end
	profile.rebirths = 2
	-- Screenshots are public: the booth shows no account name while touring, and toasts stay hidden.
	plot.sign.Text = "YOUR BOOTH"
	player:SetAttribute("Showcase", true)
	if scene == "cover" then
		-- The loop in one frame: King Kernelcorn bought off the belt and just placed on a pedestal near the
		-- camera (receipts BOUGHT then PLACED), while the player already carries the next prize home.
		fillBooth(player, 20)
		for slot = 1, 8 do
			profile.slots[slot] = nil
		end
		profile.slots[11] = nil
		services.BasePedestals.refreshPedestals(player)
		discover(player, 29)
		services.EventScheduler.startEvent("GOLDEN HOUR", 120)
		services.PopcornWave.freezeAt(nil)
		if profile.carrying then
			services.CarryService.dropCarry(player, "", true)
		end
		profile.cash = 171_400_000
		local gate = plot.gate.Position
		local item = services.ConveyorSpawner.spawnOnBelt(gate.X + 10, "kernelking", "Rainbow")
		services.ConveyorSpawner.buyFromBelt(player, item)
		task.wait(0.3)
		services.CarryService.dropCarry(player, "", true)
		services.BasePedestals.placeOnPedestal(player, "kernelking", "Rainbow", 11)
		services.CarryService.startCarry(player, { id = "saturnsundae", mut = nil, source = "belt" })
		-- Walking up the aisle toward the back of the booth, the next prize held high.
		local aisle = plot.gate * CFrame.new(-2, 3, -38)
		placeCharacter(player, aisle * CFrame.Angles(0, math.rad(190), 0))
		profile.lockUntil = 0
	elseif scene == "base" then
		fillBooth(player, 20)
		discover(player, 31)
		profile.cash = 132_000_000
		services.EventScheduler.startEvent("RAINBOW RAIN", 120)
		services.PopcornWave.freezeAt(nil)
		local inside = plot.gate * CFrame.new(0, 3, -6)
		placeCharacter(player, inside * CFrame.Angles(0, math.rad(180), 0))
		services.ThiefRaids.startRaid(player)
	elseif scene == "midway" then
		fillBooth(player, 14)
		discover(player, 24)
		profile.cash = 1_850_000
		profile.rebirths = 1
		services.EventScheduler.startEvent("CANNON FRENZY", 120)
		if profile.carrying then
			services.CarryService.dropCarry(player, "", true)
		end
		services.CarryService.startCarry(player, { id = "ringrhino", mut = "Gold", source = "belt" })
		local spot = Vector3.new(-30, 3, plot.inward.Z * 9)
		placeCharacter(player, CFrame.lookAt(spot, spot + Vector3.new(-1, 0, 0.2 * plot.inward.Z)))
		services.PopcornWave.freezeAt(30)
		services.ThiefRaids.startRaid(player)
	elseif scene == "heist" then
		-- A clown sneaks out of the booth with a Legendary while the player is across the Midway.
		fillBooth(player, 16)
		profile.slots[1] = { id = "toiletronaut", mut = "Gold" }
		services.BasePedestals.refreshPedestals(player)
		profile.cash = 4_200_000
		profile.lockUntil = 0
		profile.lockCooldownUntil = 0
		services.EventScheduler.startEvent("BUTTER STORM", 120)
		if profile.carrying then
			services.CarryService.dropCarry(player, "", true)
		end
		placeCharacter(player, CFrame.new(plot.gate.Position.X + 60, 3, -plot.inward.Z * 60))
		services.PopcornWave.freezeAt(plot.gate.Position.X + 52)
		local raid = services.ThiefRaids.startRaid(player, 1)
		if raid then
			raid.holdAt = plot.gate.Position - plot.inward * 14
		end
	elseif scene == "locked" then
		-- The gate is locked; a clown bounces off the laser while a fresh Mythic lands on a pedestal.
		fillBooth(player, 19)
		discover(player, 30)
		profile.cash = 9_800_000
		if profile.carrying then
			services.CarryService.dropCarry(player, "", true)
		end
		services.EventScheduler.startEvent("RAINBOW RAIN", 120)
		services.PopcornWave.freezeAt(plot.gate.Position.X - 34)
		profile.lockUntil = 0
		profile.lockCooldownUntil = 0
		services.GateLock.lockGate(player)
		profile.lockUntil = workspace:GetServerTimeNow() + 38
		local inside = plot.gate * CFrame.new(-6, 3, -8)
		placeCharacter(player, inside * CFrame.Angles(0, math.rad(200), 0))
		services.BasePedestals.placeOnPedestal(player, "fortunetoad", "Neon")
		local raid = services.ThiefRaids.startRaid(player)
		if raid then
			raid.holdWhenBlocked = true
			local deadline = os.clock() + 40
			while os.clock() < deadline and not raid.paused and raid.model.Parent do
				task.wait(0.1)
			end
		end
	elseif scene == "index" then
		discover(player, 31)
		player:SetAttribute("OpenPanel", "Index")
	elseif scene == "raid" then
		fillBooth(player, 12)
		services.ThiefRaids.startRaid(player)
	end
	services.PlayerData.publish(player)
end

function TourDirector.init(all: { [string]: any })
	services = all
end

return TourDirector
