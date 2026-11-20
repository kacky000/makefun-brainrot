-- RebirthService: trade your money and every brainrot for a permanent income multiplier and better cannon luck.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.GameConfig)
local PlayerState = require(script.Parent.Parent.State.PlayerState)

local RebirthService = {}

local services

-- Rebirth when the player can pay: pedestals and wallet reset, upgrades and the index stay, income x(1 + 0.5 each).
function RebirthService.tryRebirth(player: Player): boolean
	local state = PlayerState.get(player)
	if not state then
		return false
	end
	local cost = GameConfig.rebirthCost(state.rebirths)
	if state.money < cost then
		services.notify(player, "toast", { text = "REBIRTH NEEDS " .. GameConfig.formatMoney(cost), color = "red" })
		return false
	end
	services.CarryService.dropCarried(player)
	services.BasePedestals.clearBooth(player)
	state.rebirths += 1
	state.money = GameConfig.START_MONEY * (1 + state.rebirths)
	services.IncomeTicker.recomputeIncome(player)
	services.notify(player, "rebirth", { rebirths = state.rebirths, multiplier = GameConfig.rebirthIncomeMultiplier(state.rebirths) })
	return true
end

function RebirthService.init(shared)
	services = shared
end

return RebirthService
