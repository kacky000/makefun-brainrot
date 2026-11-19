-- ConveyorSpawner: the Prize Cannon fires a brainrot onto the Prize Belt every few seconds: a rarity-weighted pick
-- with a rolled mutation, riding east with a BUY prompt until someone buys it or it reaches the Popcorn Machine.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.GameConfig)
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local MutationRoller = require(ReplicatedStorage.MutationRoller)
local PlayerState = require(script.Parent.Parent.State.PlayerState)
local BrainrotModels = require(script.Parent.Parent.World.BrainrotModels)
local EventScheduler = require(script.Parent.Parent.Events.EventScheduler)
local RebirthService = require(script.Parent.RebirthService)
local CarryService = require(script.Parent.CarryService)

local ConveyorSpawner = {}
local rng = Random.new()
local items = {} -- { model, x, spin, id, mutation, price }
local beltFolder: Folder

function ConveyorSpawner.spawnOnBelt(id: string?, mutation: string?, atX: number?) -- cannon shot: rarity pick + mutation roll
	local best = 0
	for _, s in PlayerState.all() do
		best = math.max(best, s.rebirths)
	end
	local entry = if id then BrainrotCatalog.byId[id] else BrainrotCatalog.pickForCannon(rng, EventScheduler.rareBoost() * RebirthService.luckMultiplier(best))
	local rolled = mutation
	if not id and not mutation then
		rolled = MutationRoller.rollMutation(EventScheduler.luckMultiplier() * RebirthService.luckMultiplier(best))
	end
	local price = math.floor(entry.price * MutationRoller.incomeMultiplier(rolled) ^ 0.8 * EventScheduler.priceFactor())
	local model = BrainrotModels.buildBrainrot(entry.id, rolled)
	BrainrotModels.attachLabel(model, rolled, "BUY " .. BrainrotCatalog.formatMoney(price))
	local item = { model = model, x = atX or GameConfig.BELT.xStart, spin = rng:NextNumber(0, 6), id = entry.id, mutation = rolled, price = price }
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy " .. BrainrotCatalog.formatMoney(price)
	prompt.ObjectText = entry.name
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = GameConfig.BELT.buyRange
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		if item.sold then
			return
		end
		if CarryService.tryBuy(player, item.id, item.mutation, item.price) then
			item.sold = true
			ConveyorSpawner.removeItem(item)
		end
	end)
	model:PivotTo(CFrame.new(item.x, GameConfig.BELT.y + model:GetAttribute("TopY") / 2, 0))
	model.Parent = beltFolder
	table.insert(items, item)
	if entry.rarity >= 5 then
		PlayerState.notifyAll("RareOnBelt", { name = entry.name, rarity = entry.rarity })
	end
	return item
end

function ConveyorSpawner.removeItem(item)
	local at = table.find(items, item)
	if at then
		table.remove(items, at)
	end
	item.model:Destroy()
end

-- sweepBelt: a Popcorn Wave knocks every brainrot between two x positions off the belt.
function ConveyorSpawner.sweepBelt(xLow: number, xHigh: number)
	for i = #items, 1, -1 do
		local item = items[i]
		if item.x >= xLow and item.x <= xHigh then
			ConveyorSpawner.removeItem(item)
		end
	end
end

function ConveyorSpawner.clearBelt()
	ConveyorSpawner.sweepBelt(-math.huge, math.huge)
end

function ConveyorSpawner.itemCount(): number
	return #items
end

local function moveBelt(dt: number)
	for i = #items, 1, -1 do
		local item = items[i]
		item.x += GameConfig.BELT.speed * dt
		item.spin += dt * 0.7
		if item.x > GameConfig.BELT.xEnd then
			ConveyorSpawner.removeItem(item)
		else
			item.model:PivotTo(CFrame.new(item.x, GameConfig.BELT.y + item.model:GetAttribute("TopY") / 2, 0) * CFrame.Angles(0, item.spin, 0))
		end
	end
end

-- fillBelt: a full belt at once, so a new player (or everyone after a Popcorn Wave) has something to buy.
function ConveyorSpawner.fillBelt()
	local B = GameConfig.BELT
	ConveyorSpawner.clearBelt()
	local shot = 0
	for x = B.xStart, B.xEnd - 10, B.speed * B.spawnEvery do
		shot += 1
		ConveyorSpawner.spawnOnBelt(if shot % 4 == 1 then BrainrotCatalog.list[rng:NextInteger(1, 3)].id else nil, nil, x)
	end
end

function ConveyorSpawner.start()
	beltFolder = Instance.new("Folder")
	beltFolder.Name = "BeltBrainrots"
	beltFolder.Parent = Workspace
	ConveyorSpawner.fillBelt()
	RunService.Heartbeat:Connect(moveBelt)
	local B = GameConfig.BELT
	local shot = 0
	task.spawn(function()
		while true do
			task.wait(B.spawnEvery * EventScheduler.spawnFactor())
			shot += 1
			-- Every fourth shot is one of the three cheapest, so a broke player always has a way back in.
			ConveyorSpawner.spawnOnBelt(if shot % 4 == 0 then BrainrotCatalog.list[rng:NextInteger(1, 3)].id else nil)
		end
	end)
end

return ConveyorSpawner
