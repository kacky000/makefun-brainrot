--!strict
-- Carnival events: every couple of minutes one of four events runs for a while and changes the rules
-- (income, mutation luck, the belt's speed and luck, the popcorn waves). Everyone sees its banner.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

export type CarnivalEvent = {
	name: string,
	desc: string,
	color: Color3,
	income: number,
	mutation: number,
	beltLuck: number,
	beltRate: number,
	waveFrequency: number,
	waveSpeed: number,
}

local EventScheduler = {}

EventScheduler.EVENTS = {
	{ name = "GOLDEN HOUR", desc = "ALL INCOME x2", color = Color3.fromRGB(255, 200, 40), income = 2, mutation = 1.5, beltLuck = 1, beltRate = 1, waveFrequency = 1, waveSpeed = 1 },
	{ name = "RAINBOW RAIN", desc = "MUTATIONS x5 ON THE BELT", color = Color3.fromRGB(255, 90, 200), income = 1, mutation = 5, beltLuck = 1, beltRate = 1, waveFrequency = 1, waveSpeed = 1 },
	{ name = "CANNON FRENZY", desc = "BELT x2 FASTER, RARER PRIZES", color = Color3.fromRGB(90, 200, 255), income = 1, mutation = 1, beltLuck = 2.5, beltRate = 2, waveFrequency = 1, waveSpeed = 1 },
	{ name = "BUTTER STORM", desc = "WAVES 2x OFTEN AND FASTER, INCOME x1.5", color = Color3.fromRGB(255, 150, 60), income = 1.5, mutation = 2, beltLuck = 1.5, beltRate = 1, waveFrequency = 2, waveSpeed = 1.4 },
} :: { CarnivalEvent }

local current: CarnivalEvent? = nil
local endsAt = 0
local tint: ColorCorrectionEffect

function EventScheduler.current(): CarnivalEvent?
	return current
end

function EventScheduler.incomeMultiplier(): number
	return if current then current.income else 1
end

function EventScheduler.mutationLuck(): number
	return if current then current.mutation else 1
end

function EventScheduler.beltLuck(): number
	return if current then current.beltLuck else 1
end

function EventScheduler.beltRate(): number
	return if current then current.beltRate else 1
end

function EventScheduler.waveFrequency(): number
	return if current then current.waveFrequency else 1
end

function EventScheduler.waveSpeed(): number
	return if current then current.waveSpeed else 1
end

local function publish()
	workspace:SetAttribute("EventName", if current then current.name else "")
	workspace:SetAttribute("EventDesc", if current then current.desc else "")
	workspace:SetAttribute("EventColor", if current then current.color else Color3.new(1, 1, 1))
	workspace:SetAttribute("EventEndsAt", endsAt)
end

function EventScheduler.startEvent(name: string, length: number?)
	for _, event in EventScheduler.EVENTS do
		if event.name == name then
			current = event
			endsAt = workspace:GetServerTimeNow() + (length or GameConfig.EVENT_LENGTH)
			tint.TintColor = Color3.new(1, 1, 1):Lerp(event.color, 0.18)
			publish()
			for _, player in Players:GetPlayers() do
				(ReplicatedStorage :: any).Remotes.Celebrate:FireClient(player, event.name .. "!", event.desc, event.color)
			end
			return
		end
	end
end

function EventScheduler.endEvent()
	current = nil
	endsAt = 0
	tint.TintColor = Color3.new(1, 1, 1)
	publish()
end

function EventScheduler.init(_services: { [string]: any })
	tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "EventTint"
	tint.Parent = Lighting
	publish()
end

function EventScheduler.start()
	task.spawn(function()
		local rng = Random.new()
		local nextEventAt = workspace:GetServerTimeNow() + GameConfig.EVENT_EVERY * 0.5
		while true do
			task.wait(0.5)
			local now = workspace:GetServerTimeNow()
			if current and now >= endsAt then
				EventScheduler.endEvent()
				nextEventAt = now + GameConfig.EVENT_EVERY
			elseif not current and now >= nextEventAt then
				local event = EventScheduler.EVENTS[rng:NextInteger(1, #EventScheduler.EVENTS)]
				EventScheduler.startEvent(event.name)
			end
		end
	end)
end

return EventScheduler
