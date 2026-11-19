-- RebirthService: trade all cash and every brainrot for a permanent +50% income multiplier and
-- +25% mutation luck per rebirth. Upgrades and the INDEX are kept. The cost grows x6 each time.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.GameConfig)

local RebirthService = {}

local services = nil

-- Rebirths the player if they can pay the current rebirth cost.
function RebirthService.tryRebirth(player: Player): boolean
	local state = services.PlayerState.get(player)
	if not state then
		return false
	end
	local cost = GameConfig.rebirthCost(state.rebirths)
	if state.cash < cost then
		services.notify(player, "toast", { text = "REBIRTH NEEDS $" .. GameConfig.formatCash(cost) .. " (" .. math.floor(state.cash / cost * 100) .. "% there)", tone = "bad", fx = "error" })
		return false
	end
	services.CarryService.dropCarried(player, "rebirth")
	services.BasePedestals.clearPedestals(player)
	state.cash = GameConfig.START_CASH
	state.rebirths += 1
	services.BasePedestals.refreshBooth(player)
	services.IncomeTicker.refreshIncome(player)
	services.notify(player, "toast", { text = "REBIRTH " .. state.rebirths .. "! INCOME x" .. GameConfig.rebirthMultiplier(state.rebirths) .. " FOREVER", tone = "gold", fx = "rebirth" })
	return true
end

-- Mutation luck from rebirths; the Prize Cannon uses the luckiest player's value.
function RebirthService.mutationLuck(player: Player): number
	local state = services.PlayerState.get(player)
	return 1 + GameConfig.REBIRTH.luckPer * (if state then state.rebirths else 0)
end

function RebirthService.start(allServices)
	services = allServices
end

return RebirthService
