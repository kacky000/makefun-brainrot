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

-- Brings the running game to one of the three screenshot scenes: "cover", "raid" or "panels".
function TourDirector.showcase(scene: string)
	local player = Players:GetPlayers()[1]
	if not player then
		return "no player"
	end
	local state = call("PlayerState", "get", player)
	local carry = services and services.CarryService
	local thieves = services and services.ThiefRaids
	if thieves then
		thieves.paused = true
	end
	TourDirector.stageRichBooth(player)
	if scene == "cover" then
		if carry then
			carry.holdDelivery = true
		end
		call("EventScheduler", "startEvent", "GoldenHour", 600)
		call("GateLock", "lockGate", player)
		call("CarryService", "dropCarried", player, "tour")
		call("CarryService", "startCarrying", player, { id = "popcornado", mutation = "Gold" })
		call("PlayerState", "markDiscovered", player, "popcornado")
		services.notify(player, "receipt", { line = 1, text = "BOUGHT POPCORNADO SUPREMO  -$1.6B", fx = "buy", rarity = "Secret" })
		services.notify(player, "receipt", { line = 2, text = "PLACED KING KERNELCORN  +$" .. GameConfig.formatCash(BrainrotCatalog.incomePerSecond("kernelcorn", "Gold") * 4) .. "/s", fx = "place", rarity = "Mythic" })
		task.spawn(call, "PopcornWave", "startPopcornWave")
	elseif scene == "raid" then
		if carry then
			carry.holdDelivery = false
		end
		call("GateLock", "unlockGate", player)
		state.lockReadyAt = 0
		call("GateLock", "lockGate", player)
		call("ThiefRaids", "sendThief", player, 600)
	elseif scene == "panels" then
		services.notify(player, "panel", { open = { "Index", "Rebirth" } })
	end
	return "staged " .. scene
end

function TourDirector.start(allServices)
	services = allServices
end

return TourDirector
