-- EventScheduler: timed carnival events for everyone: Golden Hour (x2 income), Rainbow Rain (x4 mutation odds),
-- Cannon Frenzy (x3 prizes on the belt) and Butter Storm (half-price prizes).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.GameConfig)

local EventScheduler = {}

local services
local current = nil
local token = 0
EventScheduler.paused = false

-- Start an event now for a number of seconds; it replaces any event already running.
function EventScheduler.startEvent(key: string, seconds: number?)
	local spec = GameConfig.EVENTS[key]
	if not spec then
		return false
	end
	token += 1
	local mine = token
	local duration = seconds or spec.seconds
	current = key
	Workspace:SetAttribute("EventKey", key)
	Workspace:SetAttribute("EventEnds", Workspace:GetServerTimeNow() + duration)
	services.IncomeTicker.recomputeEveryone()
	services.notifyAll("event", { key = key })
	task.delay(duration, function()
		if token == mine then
			EventScheduler.stopEvent()
		end
	end)
	return true
end

function EventScheduler.stopEvent()
	token += 1
	current = nil
	Workspace:SetAttribute("EventKey", "")
	services.IncomeTicker.recomputeEveryone()
end

function EventScheduler.init(shared)
	services = shared
	Workspace:SetAttribute("EventKey", "")
	Workspace:SetAttribute("EventEnds", 0)
end

function EventScheduler.incomeMultiplier(): number
	return current == "GoldenHour" and 2 or 1
end

function EventScheduler.mutationBoost(): number
	return current == "RainbowRain" and 4 or 1
end

function EventScheduler.spawnRate(): number
	return current == "CannonFrenzy" and 3 or 1
end

function EventScheduler.priceMultiplier(): number
	return current == "ButterStorm" and 0.5 or 1
end

-- Run one event after every gap, cycling through the four in a shuffled order.
function EventScheduler.runSchedule()
	local random = Random.new()
	local turn = random:NextInteger(1, #GameConfig.EVENT_ORDER)
	while true do
		task.wait(GameConfig.EVENT_GAP)
		if not EventScheduler.paused and not current then
			turn = turn % #GameConfig.EVENT_ORDER + 1
			EventScheduler.startEvent(GameConfig.EVENT_ORDER[turn])
		end
	end
end

return EventScheduler
