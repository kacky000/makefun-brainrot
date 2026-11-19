--!strict
-- Rebirth: once cash reaches the rebirth price, the player trades their cash and brainrots for a permanent
-- +50% income multiplier and +25% luck on every roll. Pedestal and shoe upgrades are kept.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local RebirthService = {}

local services: { [string]: any } = {}
local Remotes: Folder

function RebirthService.canRebirth(profile: any): boolean
	return profile.cash >= services.PlayerData.rebirthCost(profile)
end

function RebirthService.rebirth(player: Player): boolean
	local profile = services.PlayerData.get(player)
	if not profile then
		return false
	end
	if not RebirthService.canRebirth(profile) then
		(Remotes :: any).Notify:FireClient(player, "Rebirth needs " .. GameConfig.money(services.PlayerData.rebirthCost(profile)), Color3.fromRGB(255, 120, 120))
		return false
	end
	if profile.carrying then
		services.CarryService.dropCarry(player, "Reborn!")
	end
	profile.rebirths += 1
	profile.cash = GameConfig.START_CASH
	table.clear(profile.slots)
	services.PlayerData.publish(player)
	services.BasePedestals.refreshPedestals(player)
	local multiplier = services.PlayerData.rebirthMultiplier(profile);
	(Remotes :: any).Celebrate:FireClient(player, "REBIRTH " .. profile.rebirths .. "!", string.format("x%.1f INCOME FOREVER", multiplier), Color3.fromRGB(200, 110, 255));
	(Remotes :: any).Sfx:FireClient(player, "rebirth")
	return true
end

function RebirthService.init(all: { [string]: any })
	services = all
	Remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

return RebirthService
