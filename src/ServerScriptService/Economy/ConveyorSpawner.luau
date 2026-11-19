-- ConveyorSpawner: the Prize Cannon fires a weighted-random brainrot (with a rolled mutation)
-- onto the Prize Belt every few seconds; the belt carries it east past the booths with a BUY
-- prompt until someone buys it or it drops into the Popcorn Machine.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.GameConfig)
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local MutationRoller = require(ReplicatedStorage.MutationRoller)
local BrainrotModels = require(script.Parent.Parent.World.BrainrotModels)

local ConveyorSpawner = {}

local BELT = GameConfig.BELT
local services = nil
local items = {} -- { model, id, mutation, x, facing }
local folder: Folder
local rng = Random.new()
local spawned = 0

local function roll(): number
	return rng:NextNumber()
end

local function beltCFrame(x: number, facing: number): CFrame
	local at = Vector3.new(x, BELT.top, BELT.z)
	return CFrame.lookAt(at, at + Vector3.new(0.25, 0, facing))
end

local function labelItem(item)
	local price = BrainrotCatalog.priceOf(item.id, item.mutation, services.EventScheduler.priceScale())
	BrainrotModels.attachNameCard(item.model, item.id, item.mutation, price)
	local prompt = (item.model.PrimaryPart :: BasePart):FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.ActionText = "Buy $" .. GameConfig.formatCash(price)
	end
end

-- Fires one brainrot onto the belt. `forcedId`/`forcedMutation` let events and the tour pick it.
function ConveyorSpawner.spawnOnBelt(forcedId: string?, forcedMutation: string?, atX: number?)
	spawned += 1
	local entry = if forcedId then BrainrotCatalog.BY_ID[forcedId] else BrainrotCatalog.pickForBelt(roll, services.EventScheduler.rarityLuck())
	local mutation = forcedMutation
	if mutation == nil then
		mutation = MutationRoller.rollMutation(roll, services.EventScheduler.mutationLuck())
	elseif mutation == "" then
		mutation = nil
	end
	local model = BrainrotModels.buildBrainrotModel(entry.id, mutation)
	local item = { model = model, id = entry.id, mutation = mutation, x = atX or BELT.x0, facing = if spawned % 2 == 0 then 1 else -1 }
	model:PivotTo(beltCFrame(item.x, item.facing))
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = entry.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 13
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player: Player)
		services.CarryService.buyFromBelt(player, item)
	end)
	labelItem(item)
	model.Parent = folder
	table.insert(items, item)
	return item
end

-- The buyer takes the model with them; the belt forgets it.
function ConveyorSpawner.takeFromBelt(item)
	local index = table.find(items, item)
	if index then
		table.remove(items, index)
	end
end

-- The Popcorn Wave wipes every prize east of `fromX` off the belt.
function ConveyorSpawner.sweepBelt(fromX: number)
	for index = #items, 1, -1 do
		local item = items[index]
		if item.x >= fromX then
			item.model:Destroy()
			table.remove(items, index)
		end
	end
end

-- After a wave: the cannon restocks the belt at once, ahead of whatever is already riding it.
function ConveyorSpawner.refillBelt()
	local step = BELT.speed * BELT.spawnEvery
	local first = BELT.x0 + 12
	for _, item in items do
		first = math.max(first, item.x + step)
	end
	for x = first, BELT.x1 - 20, step do
		ConveyorSpawner.spawnOnBelt(nil, nil, x)
	end
end

-- Prices change when Butter Storm starts or ends.
function ConveyorSpawner.repriceBelt()
	for _, item in items do
		labelItem(item)
	end
end

function ConveyorSpawner.beltItems()
	return items
end

-- The belt's own record for a model, or nil once it was bought, swept or dropped off the end.
function ConveyorSpawner.itemOnBelt(model: Model?)
	for _, item in items do
		if item.model == model then
			return item
		end
	end
	return nil
end

function ConveyorSpawner.start(allServices)
	services = allServices
	folder = Instance.new("Folder")
	folder.Name = "BeltBrainrots"
	folder.Parent = workspace
	ConveyorSpawner.refillBelt()
	local sinceSpawn = 0
	RunService.Heartbeat:Connect(function(dt: number)
		for index = #items, 1, -1 do
			local item = items[index]
			item.x += BELT.speed * dt
			if item.x > BELT.x1 then
				item.model:Destroy()
				table.remove(items, index)
			else
				(item.model.PrimaryPart :: BasePart).CFrame = beltCFrame(item.x, item.facing)
			end
		end
		sinceSpawn += dt
		if sinceSpawn >= BELT.spawnEvery * services.EventScheduler.spawnScale() then
			sinceSpawn = 0
			ConveyorSpawner.spawnOnBelt()
		end
	end)
end

return ConveyorSpawner
