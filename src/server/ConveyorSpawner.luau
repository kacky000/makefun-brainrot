--!strict
-- The Prize Belt: the Prize Cannon fires a fresh brainrot onto the belt every few seconds (rarity and
-- mutation rolled with event luck), the belt carries the row past every booth, and a player buys one with
-- its prompt and carries it home.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BrainrotModels = require(ReplicatedStorage:WaitForChild("BrainrotModels"))
local MutationRoller = require(ReplicatedStorage:WaitForChild("MutationRoller"))

type BeltItem = { model: Model, id: string, mut: string?, price: number, x: number }

local ConveyorSpawner = {}

local services: { [string]: any } = {}
local Remotes: Folder
local belt: { BeltItem } = {}
local beltFolder: Folder
local rng = Random.new()
local BELT_TOP = 1.0

local function notify(player: Player, text: string, color: Color3?)
	(Remotes :: any).Notify:FireClient(player, text, color or Color3.fromRGB(255, 255, 255))
end

local function placeOnBelt(item: BeltItem)
	local bob = math.abs(math.sin(item.x * 0.5)) * 0.4
	local pos = Vector3.new(item.x, BELT_TOP + bob, 0)
	item.model:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(0, 0, -1)))
end

function ConveyorSpawner.buyFromBelt(player: Player, item: BeltItem)
	if table.find(belt, item) == nil then
		return
	end
	if services.CarryService.isCarrying(player) then
		notify(player, "Hands full! Take your brainrot home first.", Color3.fromRGB(255, 200, 80))
		return
	end
	if not services.PlayerData.trySpend(player, item.price) then
		notify(player, "Need " .. GameConfig.money(item.price) .. " for that one!", Color3.fromRGB(255, 100, 100));
		(Remotes :: any).Sfx:FireClient(player, "blocked")
		return
	end
	table.remove(belt, table.find(belt, item) :: number)
	item.model:Destroy()
	services.CarryService.startCarry(player, { id = item.id, mut = item.mut, source = "belt" })
	local def = BrainrotCatalog.get(item.id)
	if def then
		local mutation = MutationRoller.get(item.mut)
		local fullName = (if mutation then mutation.tag .. " " else "") .. def.name
		notify(player, "Bought " .. def.name .. "! Carry it to your booth!", BrainrotCatalog.rarity(def.rarity).color);
		(Remotes :: any).Receipt:FireClient(player, "BOUGHT " .. string.upper(fullName), "-" .. GameConfig.money(item.price) .. "  ·  now carry it home!", BrainrotCatalog.rarity(def.rarity).color)
	end;
	(Remotes :: any).Sfx:FireClient(player, "buy")
end

function ConveyorSpawner.spawnOnBelt(x: number?, forcedId: string?, forcedMut: string?): BeltItem
	local luck = services.EventScheduler.beltLuck()
	local def = if forcedId then BrainrotCatalog.get(forcedId) else nil
	if not def then
		def = BrainrotCatalog.rollBrainrot(luck, rng, 1, false)
	end
	local mut = forcedMut
	if mut == nil and not forcedId then
		mut = MutationRoller.rollMutation(services.EventScheduler.mutationLuck(), rng)
	end
	local brainrot = def :: BrainrotCatalog.Brainrot
	local price = math.floor(brainrot.price * MutationRoller.multiplier(mut))
	local model = BrainrotModels.build(brainrot, mut, { priceLine = "BUY " .. GameConfig.money(price) })
	local item: BeltItem = { model = model, id = brainrot.id, mut = mut, price = price, x = x or GameConfig.BELT_START_X }
	placeOnBelt(item)
	model.Parent = beltFolder

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy " .. GameConfig.money(price)
	prompt.ObjectText = brainrot.name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		ConveyorSpawner.buyFromBelt(player, item)
	end)

	table.insert(belt, item)
	if BrainrotCatalog.rarity(brainrot.rarity).order >= 5 then
		for _, player in game:GetService("Players"):GetPlayers() do
			notify(player, "The Prize Cannon fired a " .. string.upper(brainrot.rarity) .. ": " .. brainrot.name .. "!", BrainrotCatalog.rarity(brainrot.rarity).color)
		end
	end
	return item
end

-- Moves every brainrot along the belt; the ones that reach the end fall off and are gone.
local function stepBelt(dt: number)
	local speed = GameConfig.BELT_SPEED
	for index = #belt, 1, -1 do
		local item = belt[index]
		item.x += speed * dt
		if item.x > GameConfig.BELT_END_X then
			item.model:Destroy()
			table.remove(belt, index)
		else
			placeOnBelt(item)
		end
	end
end

function ConveyorSpawner.items(): { BeltItem }
	return belt
end

function ConveyorSpawner.clearBelt()
	for _, item in belt do
		item.model:Destroy()
	end
	table.clear(belt)
end

function ConveyorSpawner.init(all: { [string]: any })
	services = all
	Remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	beltFolder = Instance.new("Folder")
	beltFolder.Name = "PrizeBelt"
	beltFolder.Parent = workspace
end

function ConveyorSpawner.start()
	-- Fill the belt at once so the first look already shows a parade of prices.
	local gap = GameConfig.BELT_SPEED * GameConfig.BELT_SPAWN_EVERY
	local x = GameConfig.BELT_END_X - 8
	while x > GameConfig.BELT_START_X do
		ConveyorSpawner.spawnOnBelt(x)
		x -= gap
	end
	RunService.Heartbeat:Connect(stepBelt)
	task.spawn(function()
		while true do
			task.wait(GameConfig.BELT_SPAWN_EVERY / services.EventScheduler.beltRate())
			if #belt < GameConfig.BELT_MAX then
				ConveyorSpawner.spawnOnBelt()
			end
		end
	end)
end

return ConveyorSpawner
