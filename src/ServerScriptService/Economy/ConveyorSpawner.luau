-- ConveyorSpawner: the Prize Cannon fires brainrots onto the Prize Belt, which carries them down the street.
-- Each one has a rolled rarity, a rolled mutation, a price and a Buy prompt.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local GameConfig = require(ReplicatedStorage.GameConfig)
local MutationRoller = require(ReplicatedStorage.MutationRoller)
local PlayerState = require(script.Parent.Parent.State.PlayerState)
local BrainrotModels = require(script.Parent.Parent.World.BrainrotModels)

local ConveyorSpawner = {}

local services
local beltFolder
local random = Random.new()
ConveyorSpawner.items = {}
ConveyorSpawner.paused = false -- the tour stops the cannon so it can lay out the belt itself

-- Fire one brainrot onto the belt at x (the cannon's end when x is nil). entry and mutation are rolled when not given.
function ConveyorSpawner.spawnOnBelt(entry, mutation: string?, x: number?)
	local luck, poorest = 1, math.huge
	for _, player in Players:GetPlayers() do
		local state = PlayerState.get(player)
		if state then
			luck = math.max(luck, GameConfig.rebirthLuck(state.rebirths))
			poorest = math.min(poorest, state.money)
		end
	end
	local rolledEntry = entry
	if not rolledEntry and poorest < 2500 and random:NextNumber() < 0.25 then
		-- While someone is still starting out, one prize in four is one they can pay for.
		rolledEntry = BrainrotCatalog.rollAffordable(poorest, random)
	end
	rolledEntry = rolledEntry or BrainrotCatalog.rollBrainrot(luck, random)
	local rolledMutation = mutation
	if not entry and not mutation then
		rolledMutation = MutationRoller.rollMutation(luck * services.EventScheduler.mutationBoost(), random)
	end
	local price = math.floor(rolledEntry.price * MutationRoller.priceMultiplier(rolledMutation) * services.EventScheduler.priceMultiplier())
	local model = BrainrotModels.buildBrainrot(rolledEntry, rolledMutation, price)
	-- Prizes ride facing back up the belt, turned a little to one side of the street or the other.
	local turn = (#ConveyorSpawner.items % 2 == 0) and -0.55 or 0.55
	local item = { entry = rolledEntry, mutation = rolledMutation, price = price, model = model, x = x or GameConfig.BELT.startX, onBelt = true, facing = Vector3.new(-1, 0, turn) }
	model:PivotTo(CFrame.lookAt(Vector3.new(item.x, GameConfig.BELT.topY, 0), Vector3.new(item.x, GameConfig.BELT.topY, 0) + item.facing))
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy " .. GameConfig.formatMoney(price)
	prompt.ObjectText = rolledEntry.name
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 13
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		services.CarryService.buyAndCarryFromBelt(player, item)
	end)
	model.Parent = beltFolder
	table.insert(ConveyorSpawner.items, item)
	return item
end

function ConveyorSpawner.init(shared)
	services = shared
	beltFolder = Instance.new("Folder")
	beltFolder.Name = "BeltBrainrots"
	beltFolder.Parent = Workspace
end

-- A bought brainrot leaves the belt's list; its model goes with the buyer.
function ConveyorSpawner.takeFromBelt(item)
	item.onBelt = false
	local index = table.find(ConveyorSpawner.items, item)
	if index then
		table.remove(ConveyorSpawner.items, index)
	end
end

function ConveyorSpawner.clearBelt()
	for _, item in ConveyorSpawner.items do
		item.onBelt = false
		item.model:Destroy()
	end
	table.clear(ConveyorSpawner.items)
end

-- Move every brainrot along the belt; the ones that reach the Popcorn Machine fall in and are gone.
function ConveyorSpawner.stepBelt(deltaTime: number)
	local belt = GameConfig.BELT
	if ConveyorSpawner.paused then
		return
	end
	for index = #ConveyorSpawner.items, 1, -1 do
		local item = ConveyorSpawner.items[index]
		item.x += belt.speed * deltaTime
		if item.x > belt.endX then
			item.onBelt = false
			item.model:Destroy()
			table.remove(ConveyorSpawner.items, index)
		else
			local bob = math.abs(math.sin(item.x * 0.6)) * 0.25
			local spot = Vector3.new(item.x, belt.topY + bob, 0)
			item.model:PivotTo(CFrame.lookAt(spot, spot + item.facing))
		end
	end
end

function ConveyorSpawner.start()
	local belt = GameConfig.BELT
	-- Stock the belt along its whole length, so the first player finds prizes already rolling.
	local gap = belt.speed * belt.spawnEvery
	for x = belt.startX + gap, belt.endX - 10, gap do
		ConveyorSpawner.spawnOnBelt(nil, nil, x)
	end
	RunService.Heartbeat:Connect(ConveyorSpawner.stepBelt)
	task.spawn(function()
		while true do
			task.wait(belt.spawnEvery / services.EventScheduler.spawnRate())
			if not ConveyorSpawner.paused and #ConveyorSpawner.items < belt.maxItems then
				ConveyorSpawner.spawnOnBelt()
				services.notifyAll("cannon", {})
			end
		end
	end)
end

return ConveyorSpawner
