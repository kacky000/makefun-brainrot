--!strict
-- Pays every booth once a second: each pedestal's brainrot earns its income times its mutation, times the
-- owner's rebirth multiplier, times the running event; the client gets the per-pedestal amounts for "+$".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local MutationRoller = require(ReplicatedStorage:WaitForChild("MutationRoller"))

local IncomeTicker = {}

local services: { [string]: any } = {}
local Remotes: Folder

function IncomeTicker.incomePerSecond(profile: any): number
	return services.PlayerData.baseIncome(profile) * services.PlayerData.rebirthMultiplier(profile) * services.EventScheduler.incomeMultiplier()
end

function IncomeTicker.tickIncome()
	local eventMultiplier = services.EventScheduler.incomeMultiplier()
	for player, profile in services.PlayerData.all() do
		local multiplier = services.PlayerData.rebirthMultiplier(profile) * eventMultiplier
		local perSlot = {}
		local total = 0
		for slotIndex, slot in profile.slots do
			local def = BrainrotCatalog.get(slot.id)
			if def and slotIndex <= profile.pedestals then
				local amount = def.income * MutationRoller.multiplier(slot.mut) * multiplier
				perSlot[tostring(slotIndex)] = amount
				total += amount
			end
		end
		profile.incomePerSec = total
		services.PlayerData.addCash(player, total)
		if total > 0 then
			(Remotes :: any).IncomeTick:FireClient(player, perSlot, total)
		end
	end
end

function IncomeTicker.init(all: { [string]: any })
	services = all
	Remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function IncomeTicker.start()
	task.spawn(function()
		while true do
			task.wait(1)
			IncomeTicker.tickIncome()
		end
	end)
end

return IncomeTicker
