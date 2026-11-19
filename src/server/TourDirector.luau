--!strict
-- Stages the game's showcase moments for screenshots and for reviewers (TOUR.json calls showcase):
--   "cover" - a full booth, Golden Hour, the player dashing home with a Secret while the wave closes in
--   "base"  - a booth of twenty rare brainrots earning, during Rainbow Rain, a clown raid on the way
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
	-- Screenshots are public: the booth shows no account name while touring.
	plot.sign.Text = "YOUR BOOTH"
	if scene == "cover" then
		fillBooth(player, 20)
		discover(player, 29)
		profile.cash = 48_600_000
		services.EventScheduler.startEvent("GOLDEN HOUR", 120)
		local gate = plot.gate.Position
		local street = gate - plot.inward * 7 + Vector3.new(4, 3, 0)
		placeCharacter(player, CFrame.lookAt(street, street + plot.inward + Vector3.new(-0.3, 0, 0)))
		if not profile.carrying then
			services.CarryService.startCarry(player, { id = "kernelking", mut = "Rainbow", source = "belt" })
		end
		services.PopcornWave.freezeAt(gate.X + 40)
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
