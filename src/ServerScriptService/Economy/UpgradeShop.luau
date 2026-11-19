-- UpgradeShop: three upgrades bought with cash: more pedestals, faster running, a longer gate lock.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.GameConfig)
local PlayerState = require(script.Parent.Parent.State.PlayerState)

local UpgradeShop = {}
UpgradeShop.onUpgrade = nil :: ((Player, string) -> ())?

function UpgradeShop.buyUpgrade(player: Player, key: string): boolean -- Pedestals | Speed | Lock
	local s = PlayerState.get(player)
	local config = GameConfig.UPGRADES[key]
	if not s or not config then
		return false
	end
	local level = s.upgrades[key]
	if level >= config.max then
		PlayerState.notify(player, "Toast", { text = config.label .. " IS MAXED", bad = true })
		return false
	end
	local cost = UpgradeShop.costOf(key, level)
	if not PlayerState.trySpend(player, cost) then
		PlayerState.notify(player, "Toast", { text = "NOT ENOUGH CASH", bad = true })
		return false
	end
	s.upgrades[key] = level + 1
	PlayerState.mirror(player)
	if UpgradeShop.onUpgrade then
		UpgradeShop.onUpgrade(player, key)
	end
	PlayerState.notify(player, "Upgraded", { key = key, level = level + 1, label = config.label })
	return true
end

function UpgradeShop.costOf(key: string, level: number): number
	local config = GameConfig.UPGRADES[key]
	return math.floor(config.base * config.growth ^ level)
end

return UpgradeShop
