-- IncomeTicker: every second each player is paid the money a second of every brainrot standing
-- on their pedestals, times their rebirth multiplier, times any running event (Golden Hour x2).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.GameConfig)
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)

local IncomeTicker = {}

local services = nil

-- Money a second for one player right now.
function IncomeTicker.incomePerSecond(player: Player): number
	local state = services.PlayerState.get(player)
	if not state then
		return 0
	end
	local total = 0
	for _, brainrot in state.pedestals do
		total += BrainrotCatalog.incomePerSecond(brainrot.id, brainrot.mutation)
	end
	return math.floor(total * GameConfig.rebirthMultiplier(state.rebirths) * services.EventScheduler.incomeScale())
end

-- Recomputes and republishes a player's rate after a pedestal, rebirth or event change.
function IncomeTicker.refreshIncome(player: Player)
	local state = services.PlayerState.get(player)
	if state then
		state.income = IncomeTicker.incomePerSecond(player)
		services.PlayerState.publish(player)
	end
end

function IncomeTicker.refreshEveryone()
	for player in services.PlayerState.all() do
		IncomeTicker.refreshIncome(player)
	end
end

-- One tick of pay for everyone.
function IncomeTicker.payEveryone()
	for player, state in services.PlayerState.all() do
		if state.income > 0 then
			services.PlayerState.addCash(player, state.income)
		end
	end
end

function IncomeTicker.start(allServices)
	services = allServices
	task.spawn(function()
		while true do
			task.wait(1)
			IncomeTicker.payEveryone()
		end
	end)
end

return IncomeTicker
