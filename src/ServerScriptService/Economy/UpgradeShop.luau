-- UpgradeShop: three cash upgrades that survive rebirth: MORE PEDESTALS (8 -> 20),
-- ROLLER SKATES (walk speed) and LONGER LOCK (gate lock time).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.GameConfig)

local UpgradeShop = {}

local services = nil

-- Buys the next level of one upgrade if the player can afford it.
function UpgradeShop.tryBuyUpgrade(player: Player, key: string): boolean
	local state = services.PlayerState.get(player)
	local upgrade = GameConfig.UPGRADES[key]
	if not state or not upgrade then
		return false
	end
	local level = state.upgrades[key]
	local cost = upgrade.costs[level + 1]
	if not cost then
		services.notify(player, "toast", { text = upgrade.title .. " IS MAXED", tone = "info", fx = "error" })
		return false
	end
	if not services.PlayerState.trySpend(player, cost) then
		services.notify(player, "toast", { text = "NEED $" .. GameConfig.formatCash(cost - state.cash) .. " MORE for " .. upgrade.title, tone = "bad", fx = "error" })
		return false
	end
	state.upgrades[key] = level + 1
	if key == "Pedestals" then
		services.BasePedestals.refreshBooth(player)
	elseif key == "Speed" then
		UpgradeShop.applyWalkSpeed(player)
	end
	services.PlayerState.publish(player)
	services.notify(player, "toast", { text = upgrade.title .. " LEVEL " .. (level + 1) .. "! " .. upgrade.blurb, tone = "gold", fx = "upgrade" })
	return true
end

function UpgradeShop.applyWalkSpeed(player: Player)
	local state = services.PlayerState.get(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if state and humanoid then
		humanoid.WalkSpeed = GameConfig.upgradeValue("Speed", state.upgrades.Speed)
	end
end

function UpgradeShop.start(allServices)
	services = allServices
	local function watchPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid", 10)
			UpgradeShop.applyWalkSpeed(player)
		end)
		UpgradeShop.applyWalkSpeed(player)
	end
	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end
end

return UpgradeShop
