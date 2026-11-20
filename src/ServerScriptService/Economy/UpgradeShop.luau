-- UpgradeShop: three upgrades bought with money: more pedestals, faster shoes, a longer gate lock.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.GameConfig)
local PlayerState = require(script.Parent.Parent.State.PlayerState)

local UpgradeShop = {}

local services

-- Buy the next level of an upgrade when the player can pay for it.
function UpgradeShop.buyUpgrade(player: Player, key: string): boolean
	local state = PlayerState.get(player)
	local spec = GameConfig.UPGRADES[key]
	if not (state and spec) then
		return false
	end
	local level = state.upgrades[key]
	if level >= spec.maxLevel then
		services.notify(player, "toast", { text = spec.title .. " IS MAXED", color = "red" })
		return false
	end
	local cost = GameConfig.upgradeCost(key, level)
	if not PlayerState.trySpend(player, cost) then
		services.notify(player, "toast", { text = "NEED " .. GameConfig.formatMoney(cost - state.money) .. " MORE", color = "red" })
		return false
	end
	state.upgrades[key] = level + 1
	if key == "pedestals" then
		services.BasePedestals.refreshPedestals(player)
	elseif key == "speed" then
		UpgradeShop.applyWalkSpeed(player)
	end
	PlayerState.syncToClient(player)
	services.notify(player, "upgraded", { title = spec.title, level = level + 1 })
	return true
end

function UpgradeShop.init(shared)
	services = shared
end

function UpgradeShop.applyWalkSpeed(player: Player)
	local state = PlayerState.get(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if state and humanoid then
		humanoid.WalkSpeed = GameConfig.walkSpeed(state.upgrades.speed)
	end
end

return UpgradeShop
