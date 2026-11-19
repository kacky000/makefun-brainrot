-- TourDirector: stages the game's showcase scenes for screenshots and for TOUR.json, using only
-- the live services: fills the first player's booth, sets cash and rebirths, starts an event,
-- rolls a Popcorn Wave, sends a Sneaky Clown at a locked gate, opens the INDEX and REBIRTH panels.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage.GameConfig)
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)

local TourDirector = {}

local services = nil

local SHOW_BOOTH = {
	{ "kernelcorn", "Gold" }, { "ringmaster", nil }, { "gelato", "Rainbow" }, { "elephanto", nil },
	{ "ferriswheelio", "Neon" }, { "tigre", nil }, { "clownfisho", "Buttered" }, { "cannonballo", nil },
	{ "fortuna", "Galaxy" }, { "strongmanno", nil }, { "carousello", "Gold" }, { "tendone", nil },
}

local function call(serviceName: string, functionName: string, ...)
	if services then
		return services[serviceName][functionName](...)
	end
	return (ServerStorage:WaitForChild("ServiceCall") :: BindableFunction):Invoke(serviceName, functionName, ...)
end

-- A rich mid-game booth for the first player: cash, a rebirth, upgrades and twelve rare brainrots.
function TourDirector.stageRichBooth(player: Player)
	local state = call("PlayerState", "get", player)
	if not state then
		return
	end
	call("BasePedestals", "clearPedestals", player)
	state.cash = 2470000
	state.rebirths = 2
	state.upgrades.Pedestals = 4
	state.upgrades.Speed = 3
	state.upgrades.LockTime = 2
	call("BasePedestals", "refreshBooth", player)
	for _, pick in SHOW_BOOTH do
		call("BasePedestals", "placeBrainrotOnPedestal", player, { id = pick[1], mutation = pick[2] })
		state.discovered[pick[1]] = true
	end
	for order, entry in BrainrotCatalog.LIST do
		if order <= 22 then
			state.discovered[entry.id] = true
		end
	end
	call("IncomeTicker", "refreshIncome", player)
end

-- Buys `id` off the belt for the player with the game's own purchase, so the receipt is real.
local function buyOffBelt(player: Player, id: string, mutation: string, x: number)
	local prize = call("ConveyorSpawner", "spawnOnBelt", id, mutation, x)
	call("PlayerState", "addCash", player, BrainrotCatalog.priceOf(id, mutation, call("EventScheduler", "priceScale")))
	call("CarryService", "buyFromBelt", player, prize)
end

-- Brings the running game to one of the three screenshot scenes: "cover", "belt" or "panels".
--   cover : the player runs a fresh Secret home under a held Popcorn Wave while a Sneaky Clown
--           bounces off the locked gate of a full booth
--   belt  : the same run seen from the Prize Belt: priced brainrots riding into the wave
--   panels: the INDEX and REBIRTH panels over that booth
function TourDirector.showcase(scene: string)
	if not services then
		-- Required from outside the running game (TOUR.json, the command bar): hand over to the live copy.
		return (ServerStorage:WaitForChild("ServiceCall") :: BindableFunction):Invoke("TourDirector", "showcase", scene)
	end
	local player = Players:GetPlayers()[1]
	if not player then
		return "no player"
	end
	local state = services.PlayerState.get(player)
	local booth = state.booth
	local _, dir = GameConfig.boothOrigin(booth)
	services.ThiefRaids.paused = true
	services.CarryService.holdDelivery = true
	TourDirector.stageRichBooth(player)
	state.discovered.trofeo = true
	services.notify(player, "panel", { open = if scene == "panels" then { "Index", "Rebirth" } else {} })
	services.CarryService.dropCarried(player, "tour")
	task.spawn(services.PopcornWave.startPopcornWave, GameConfig.boothPoint(booth, 40, 0, 0).X, 600)
	if scene == "cover" then
		services.EventScheduler.startEvent("GoldenHour", 600)
		services.GateLock.unlockGate(player)
		state.lockReadyAt = 0
		services.GateLock.lockGate(player)
		local street = GameConfig.boothPoint(booth, 8, -12, 3.5)
		if player.Character then
			player.Character:PivotTo(CFrame.lookAt(street, street + Vector3.new(-1, 0, -0.45 * dir)))
		end
		-- A real placement and a real purchase, so both receipts on screen are the game's own.
		services.CarryService.startCarrying(player, { id = "trofeo", mutation = "Gold" })
		services.CarryService.deliverCarried(player)
		buyOffBelt(player, "popcornado", "Rainbow", street.X)
		services.ThiefRaids.sendThief(player, 600, -1)
		services.notify(player, "camera", { from = GameConfig.boothPoint(booth, -12, -19, 11), to = GameConfig.boothPoint(booth, 8, 14, 5) })
	elseif scene == "belt" then
		local raid = services.ThiefRaids.activeRaid(player)
		if raid then
			services.ThiefRaids.bonkThief(raid)
		end
		local beside = GameConfig.boothPoint(booth, 6, -15, 3.5)
		if player.Character then
			player.Character:PivotTo(CFrame.lookAt(beside, beside + Vector3.new(-0.6, 0, dir)))
		end
		buyOffBelt(player, "kernelcorn", "Gold", beside.X)
		services.ConveyorSpawner.spawnOnBelt("gelato", "Neon", beside.X - 9)
		services.ConveyorSpawner.spawnOnBelt("fortuna", "", beside.X - 23)
		services.notify(player, "camera", { from = GameConfig.boothPoint(booth, -12, -2, 11), to = GameConfig.boothPoint(booth, 14, -25, 3) })
	end
	return "staged " .. scene
end

function TourDirector.start(allServices)
	services = allServices
end

return TourDirector
