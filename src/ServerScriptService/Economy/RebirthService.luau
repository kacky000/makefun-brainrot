-- RebirthService: trade all cash and every brainrot on the pedestals for a permanent money and luck multiplier.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.GameConfig)
local PlayerState = require(script.Parent.Parent.State.PlayerState)

local RebirthService = {}
RebirthService.onRebirth = nil :: ((Player) -> ())? -- BasePedestals clears the booth here

function RebirthService.tryRebirth(player: Player): boolean -- resets cash + pedestals, +50% $/s and +20% luck each
	local s = PlayerState.get(player)
	if not s then
		return false
	end
	local cost = RebirthService.costOf(s.rebirths)
	if s.cash < cost then
		PlayerState.notify(player, "Toast", { text = "REBIRTH NEEDS " .. cost .. " CASH", bad = true })
		return false
	end
	s.rebirths += 1
	s.cash = GameConfig.START_CASH
	s.stash = 0
	s.slots = {}
	if RebirthService.onRebirth then
		RebirthService.onRebirth(player)
	end
	PlayerState.mirror(player)
	PlayerState.notify(player, "Rebirthed", { rebirths = s.rebirths, multiplier = RebirthService.incomeMultiplier(s.rebirths) })
	return true
end

function RebirthService.costOf(rebirths: number): number
	return GameConfig.REBIRTH.base * GameConfig.REBIRTH.growth ^ rebirths
end

function RebirthService.incomeMultiplier(rebirths: number): number
	return 1 + rebirths * GameConfig.REBIRTH.incomeBonus
end

function RebirthService.luckMultiplier(rebirths: number): number
	return 1 + rebirths * GameConfig.REBIRTH.luckBonus
end

return RebirthService
