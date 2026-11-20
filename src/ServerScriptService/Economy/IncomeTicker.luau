-- IncomeTicker: every second each player is paid the money a second of every brainrot on their pedestals,
-- times their rebirth multiplier and any running event.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local GameConfig = require(ReplicatedStorage.GameConfig)
local MutationRoller = require(ReplicatedStorage.MutationRoller)
local PlayerState = require(script.Parent.Parent.State.PlayerState)

local IncomeTicker = {}

local services

-- Add up a player's money a second from their pedestals (a brainrot a thief is running off with earns nothing).
function IncomeTicker.recomputeIncome(player: Player): number
	local state = PlayerState.get(player)
	if not state then
		return 0
	end
	local total = 0
	for _, item in state.placed do
		if not item.stolen then
			total += BrainrotCatalog.byId[item.id].income * MutationRoller.incomeMultiplier(item.mutation)
		end
	end
	total *= GameConfig.rebirthIncomeMultiplier(state.rebirths) * services.EventScheduler.incomeMultiplier()
	state.income = math.floor(total)
	PlayerState.syncToClient(player)
	return state.income
end

function IncomeTicker.init(shared)
	services = shared
end

function IncomeTicker.recomputeEveryone()
	for _, player in Players:GetPlayers() do
		IncomeTicker.recomputeIncome(player)
	end
end

function IncomeTicker.payIncomeEverySecond()
	while true do
		task.wait(1)
		for _, player in Players:GetPlayers() do
			local state = PlayerState.get(player)
			if state and state.income > 0 then
				PlayerState.addMoney(player, state.income)
			end
		end
	end
end

return IncomeTicker
