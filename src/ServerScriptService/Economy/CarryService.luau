-- CarryService: buying a brainrot off the Prize Belt, carrying it over your head, and delivering it when you
-- step into your own booth. A popcorn wave makes you drop what you carry.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local GameConfig = require(ReplicatedStorage.GameConfig)
local MutationRoller = require(ReplicatedStorage.MutationRoller)
local PlayerState = require(script.Parent.Parent.State.PlayerState)
local BrainrotModels = require(script.Parent.Parent.World.BrainrotModels)

local CarryService = {}

local services
local deliveryHeld = false
local carriedFolder
local lastFullNotice = {}

local CARRY_SCALE = 0.78
local CARRY_HEIGHT = 3.6

-- Pay for a brainrot on the belt and lift it over the buyer's head. The server checks the money and the belt.
function CarryService.buyAndCarryFromBelt(player: Player, beltItem): (boolean, string?)
	local state = PlayerState.get(player)
	if not state or not beltItem.onBelt then
		return false, "gone"
	end
	if state.carrying then
		services.notify(player, "toast", { text = "HANDS FULL! Carry it to your booth first", color = "red" })
		return false, "carrying"
	end
	if not PlayerState.trySpend(player, beltItem.price) then
		services.notify(player, "toast", { text = "NEED " .. GameConfig.formatMoney(beltItem.price - state.money) .. " MORE", color = "red" })
		return false, "money"
	end
	services.ConveyorSpawner.takeFromBelt(beltItem)
	-- The belt's copy is retired and a fresh body is welded to the buyer: a part the belt was moving every
	-- frame keeps its belt position on the buyer's client when it is welded in the same step.
	beltItem.model:Destroy()
	services.notify(player, "bought", { name = beltItem.entry.name, price = beltItem.price, rarity = beltItem.entry.rarity, mutation = beltItem.mutation })
	-- A bought brainrot goes straight onto a pedestal in the buyer's booth and starts earning at once.
	-- Only a full booth (or the screenshot tour) leaves it in the buyer's hands to carry.
	if not deliveryHeld then
		local slot = services.BasePedestals.placeBrainrotOnPedestal(player, beltItem.entry.id, beltItem.mutation, nil)
		if slot then
			PlayerState.discover(player, beltItem.entry.id)
			return true
		end
		services.notify(player, "toast", { text = "BOOTH FULL! Buy MORE PEDESTALS or sell one (hold F)", color = "red" })
	end
	CarryService.carry(player, beltItem.entry.id, beltItem.mutation, nil)
	return true
end

function CarryService.init(shared)
	services = shared
	carriedFolder = Instance.new("Folder")
	carriedFolder.Name = "CarriedBrainrots"
	carriedFolder.Parent = Workspace
end

-- Weld a brainrot, shrunk, above the player's head.
function CarryService.carry(player: Player, id: string, mutation: string?, model: Model?)
	local state = PlayerState.get(player)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not (state and rootPart) then
		if model then
			model:Destroy()
		end
		return
	end
	local entry = BrainrotCatalog.byId[id]
	local body = model or BrainrotModels.buildBrainrot(entry, mutation, nil, false)
	local prompt = body.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt:Destroy()
	end
	body:ScaleTo((body:GetAttribute("FullScale") or 1) * CARRY_SCALE)
	BrainrotModels.attachLabel(body, entry, mutation, nil)
	body:PivotTo(rootPart.CFrame * CFrame.new(0, CARRY_HEIGHT, 0))
	body.PrimaryPart.Anchored = false
	body.PrimaryPart.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = rootPart
	weld.Part1 = body.PrimaryPart
	weld.Parent = body.PrimaryPart
	body.Parent = carriedFolder
	state.carrying = { id = id, mutation = mutation, model = body }
	PlayerState.discover(player, id)
	local income = entry.income * MutationRoller.incomeMultiplier(mutation) * GameConfig.rebirthIncomeMultiplier(state.rebirths)
	player:SetAttribute("Carrying", string.format("%s%s  +%s/s", mutation and (string.upper(mutation) .. " ") or "", entry.name, GameConfig.formatMoney(income)))
end

-- Lose what you carry (a popcorn wave hit, a respawn, a rebirth).
function CarryService.dropCarried(player: Player, reason: string?)
	local state = PlayerState.get(player)
	if not state or not state.carrying then
		return false
	end
	local name = BrainrotCatalog.byId[state.carrying.id].name
	state.carrying.model:Destroy()
	state.carrying = nil
	player:SetAttribute("Carrying", "")
	if reason then
		services.notify(player, "dropped", { name = name, reason = reason })
	end
	return true
end

-- Stop or resume delivery at the booth gate (the tour holds it so a carried brainrot stays in the shot).
function CarryService.holdDelivery(held: boolean)
	deliveryHeld = held
end

-- A carrier standing inside their own booth hands the brainrot to a pedestal.
function CarryService.deliverIfHome(player: Player)
	local state = PlayerState.get(player)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if deliveryHeld or not (state and state.carrying and rootPart and state.booth > 0) then
		return
	end
	if not GameConfig.isInsideBooth(state.booth, rootPart.Position) then
		return
	end
	local carried = state.carrying
	-- The weld comes off first: a pedestal anchors the brainrot, and an anchored weld would pin the player.
	local weld = carried.model.PrimaryPart:FindFirstChild("CarryWeld")
	if weld then
		weld.Enabled = false
	end
	local slot = services.BasePedestals.placeBrainrotOnPedestal(player, carried.id, carried.mutation, carried.model)
	if slot then
		if weld then
			weld:Destroy()
		end
		state.carrying = nil
		player:SetAttribute("Carrying", "")
		return
	end
	if weld then
		weld.Enabled = true
	end
	if (lastFullNotice[player] or 0) + 4 < os.clock() then
		lastFullNotice[player] = os.clock()
		services.notify(player, "toast", { text = "BOOTH FULL! Buy MORE PEDESTALS or sell one (hold F)", color = "red" })
	end
end

function CarryService.start()
	RunService.Heartbeat:Connect(function()
		for _, player in Players:GetPlayers() do
			CarryService.deliverIfHome(player)
		end
	end)
end

return CarryService
