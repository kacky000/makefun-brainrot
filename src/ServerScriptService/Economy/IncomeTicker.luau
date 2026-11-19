-- IncomeTicker: every second each placed brainrot pays its money a second into its owner's booth stash;
-- stepping on the booth's collect pad moves the stash into cash.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local PlayerState = require(script.Parent.Parent.State.PlayerState)
local EventScheduler = require(script.Parent.Parent.Events.EventScheduler)
local RebirthService = require(script.Parent.RebirthService)

local IncomeTicker = {}

function IncomeTicker.incomePerSecond(player: Player): number -- sum of pedestals x mutation x rebirth x event
	local s = PlayerState.get(player)
	if not s then
		return 0
	end
	local total = 0
	for _, held in s.slots do
		total += BrainrotCatalog.incomePerSecond(held.id, held.mutation)
	end
	return total * RebirthService.incomeMultiplier(s.rebirths) * EventScheduler.incomeMultiplier()
end

function IncomeTicker.payTick(player: Player)
	local s = PlayerState.get(player)
	if not s then
		return
	end
	local income = IncomeTicker.incomePerSecond(player)
	s.stash += income
	player:SetAttribute("Income", income)
	player:SetAttribute("Stash", math.floor(s.stash))
end

function IncomeTicker.collectStash(player: Player): number
	local s = PlayerState.get(player)
	if not s or s.stash < 1 then
		return 0
	end
	local amount = math.floor(s.stash)
	s.stash -= amount
	PlayerState.addCash(player, amount)
	player:SetAttribute("Stash", math.floor(s.stash))
	PlayerState.notify(player, "Collected", { amount = amount })
	return amount
end

function IncomeTicker.start()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				IncomeTicker.payTick(player)
			end
		end
	end)
end

return IncomeTicker
