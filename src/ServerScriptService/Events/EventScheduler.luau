-- EventScheduler: runs one timed carnival event at a time (Golden Hour, Rainbow Rain, Cannon Frenzy, Butter Storm)
-- and answers what the running event multiplies: money, mutation luck, cannon rate, rare shots, prices, speed.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.GameConfig)
local PlayerState = require(script.Parent.Parent.State.PlayerState)

local EventScheduler = {}
local current = nil
local endsAt = 0
local lastIndex = 0

function EventScheduler.startEvent(eventId: string, seconds: number?): boolean -- GoldenHour | RainbowRain | CannonFrenzy | ButterStorm
	for index, event in GameConfig.EVENTS do
		if event.id == eventId then
			current = event
			lastIndex = index
			endsAt = Workspace:GetServerTimeNow() + (seconds or event.seconds)
			Workspace:SetAttribute("EventId", event.id)
			Workspace:SetAttribute("EventBanner", event.banner)
			Workspace:SetAttribute("EventColor", event.color)
			Workspace:SetAttribute("EventEnds", endsAt)
			PlayerState.notifyAll("EventStarted", { banner = event.banner, color = event.color })
			return true
		end
	end
	return false
end

function EventScheduler.endEvent()
	current = nil
	Workspace:SetAttribute("EventId", "")
	Workspace:SetAttribute("EventBanner", "")
end

function EventScheduler.currentEvent()
	return current
end

function EventScheduler.incomeMultiplier(): number
	return if current and current.income then current.income else 1
end

function EventScheduler.luckMultiplier(): number
	return if current and current.luck then current.luck else 1
end

function EventScheduler.spawnFactor(): number
	return if current and current.spawn then current.spawn else 1
end

function EventScheduler.rareBoost(): number
	return if current and current.rare then current.rare else 1
end

function EventScheduler.priceFactor(): number
	return if current and current.price then current.price else 1
end

function EventScheduler.speedBonus(): number
	return if current and current.speed then current.speed else 0
end

function EventScheduler.start()
	EventScheduler.endEvent()
	Workspace:SetAttribute("NextEventAt", Workspace:GetServerTimeNow() + GameConfig.EVENT_FIRST)
	task.spawn(function()
		task.wait(GameConfig.EVENT_FIRST)
		while true do
			if not current then
				EventScheduler.startEvent(GameConfig.EVENTS[lastIndex % #GameConfig.EVENTS + 1].id)
			end
			while current and Workspace:GetServerTimeNow() < endsAt do
				task.wait(0.5)
			end
			EventScheduler.endEvent()
			Workspace:SetAttribute("NextEventAt", Workspace:GetServerTimeNow() + GameConfig.EVENT_EVERY)
			task.wait(GameConfig.EVENT_EVERY)
		end
	end)
end

return EventScheduler
