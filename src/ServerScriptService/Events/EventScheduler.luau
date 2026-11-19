-- EventScheduler: runs one carnival event at a time on a timer and answers what it changes:
-- Golden Hour (income x2), Rainbow Rain (mutation luck x5), Cannon Frenzy (faster belt, rarer
-- prizes) and Butter Storm (all prizes 50% off). The HUD shows the banner and countdown.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.GameConfig)

local EventScheduler = {}

local services = nil
local active = nil -- the running event's config, or nil
local nextIndex = 1

-- Starts a carnival event now; it ends itself after `seconds` (default from GameConfig).
function EventScheduler.startEvent(eventKey: string, seconds: number?)
	local event = GameConfig.EVENTS[eventKey]
	if not event then
		return
	end
	active = event
	local endsAt = workspace:GetServerTimeNow() + (seconds or GameConfig.EVENT_TIMING.lasts)
	workspace:SetAttribute("EventKey", eventKey)
	workspace:SetAttribute("EventEndsAt", endsAt)
	local grade = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if grade then
		TweenService:Create(grade, TweenInfo.new(1.5), { TintColor = event.color:Lerp(Color3.new(1, 1, 1), 0.72) }):Play()
	end
	services.ConveyorSpawner.repriceBelt()
	services.IncomeTicker.refreshEveryone()
	services.notifyAll("toast", { text = event.banner, tone = "gold", fx = "event" })
	task.delay(seconds or GameConfig.EVENT_TIMING.lasts, function()
		if workspace:GetAttribute("EventEndsAt") == endsAt then
			EventScheduler.endEvent()
		end
	end)
end

function EventScheduler.endEvent()
	active = nil
	workspace:SetAttribute("EventKey", "")
	local grade = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if grade then
		TweenService:Create(grade, TweenInfo.new(1.5), { TintColor = Color3.fromRGB(255, 246, 240) }):Play()
	end
	services.ConveyorSpawner.repriceBelt()
	services.IncomeTicker.refreshEveryone()
end

function EventScheduler.incomeScale(): number
	return (active and active.income) or 1
end

function EventScheduler.priceScale(): number
	return (active and active.price) or 1
end

function EventScheduler.spawnScale(): number
	return (active and active.spawn) or 1
end

function EventScheduler.rarityLuck(): number
	return (active and active.rarityLuck) or 1
end

-- Event luck times the best rebirth luck among the players on the midway.
function EventScheduler.mutationLuck(): number
	local best = 1
	for player in services.PlayerState.all() do
		best = math.max(best, services.RebirthService.mutationLuck(player))
	end
	return best * ((active and active.luck) or 1)
end

function EventScheduler.start(allServices)
	services = allServices
	workspace:SetAttribute("EventKey", "")
	workspace:SetAttribute("EventEndsAt", 0)
	task.spawn(function()
		task.wait(GameConfig.EVENT_TIMING.firstAfter)
		while true do
			if workspace:GetAttribute("EventKey") == "" then
				EventScheduler.startEvent(GameConfig.EVENT_ORDER[nextIndex])
				nextIndex = nextIndex % #GameConfig.EVENT_ORDER + 1
			end
			task.wait(GameConfig.EVENT_TIMING.every)
		end
	end)
end

return EventScheduler
