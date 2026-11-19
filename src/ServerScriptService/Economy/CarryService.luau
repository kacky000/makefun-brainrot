-- CarryService: buying a brainrot off the Prize Belt puts it on the player's head; they carry it
-- across the midway and it is delivered to a pedestal the moment they step into their own booth.
-- A Popcorn Wave or dying drops it. Also handles a rival player stealing from an unlocked booth.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.GameConfig)
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local BrainrotModels = require(script.Parent.Parent.World.BrainrotModels)

local CarryService = {}

CarryService.holdDelivery = false -- TourDirector sets this to stage a carrying shot
local services = nil
local lastFullWarning: { [Player]: number } = {}

-- Pays for the brainrot riding the belt and lifts it onto the buyer's head.
function CarryService.buyFromBelt(player: Player, beltItem)
	local state = services.PlayerState.get(player)
	beltItem = services.ConveyorSpawner.itemOnBelt(beltItem.model) -- only a prize still riding the belt can be bought
	if not state or not beltItem then
		return false
	end
	local entry = BrainrotCatalog.BY_ID[beltItem.id]
	if state.carrying then
		services.notify(player, "toast", { text = "HANDS FULL! Carry " .. BrainrotCatalog.BY_ID[state.carrying.id].name .. " to your booth first", tone = "bad", fx = "error" })
		return false
	end
	local price = BrainrotCatalog.priceOf(beltItem.id, beltItem.mutation, services.EventScheduler.priceScale())
	if not services.PlayerState.trySpend(player, price) then
		services.notify(player, "toast", { text = "NEED $" .. GameConfig.formatCash(price - state.cash) .. " MORE for " .. entry.name, tone = "bad", fx = "error" })
		return false
	end
	services.ConveyorSpawner.takeFromBelt(beltItem)
	CarryService.startCarrying(player, { id = beltItem.id, mutation = beltItem.mutation, model = beltItem.model })
	services.notify(player, "receipt", { line = 1, text = "BOUGHT " .. string.upper(entry.name) .. "  -$" .. GameConfig.formatCash(price), fx = "buy", rarity = entry.rarity })
	if services.PlayerState.markDiscovered(player, beltItem.id) then
		services.notify(player, "toast", { text = "NEW BRAINROT! " .. entry.name .. " added to your INDEX", tone = "gold", fx = "discover" })
	end
	return true
end

-- Welds the brainrot above the player's head. The model keeps its name card so everyone sees the catch.
function CarryService.startCarrying(player: Player, brainrot)
	local state = services.PlayerState.get(player)
	local character = player.Character
	local torso = character and character:FindFirstChild("HumanoidRootPart")
	if not state or not torso then
		if brainrot.model then
			brainrot.model:Destroy()
		end
		return
	end
	local model = brainrot.model or BrainrotModels.buildBrainrotModel(brainrot.id, brainrot.mutation)
	brainrot.model = model
	local root = model.PrimaryPart :: BasePart
	for _, child in root:GetChildren() do
		if child:IsA("ProximityPrompt") or child:IsA("WeldConstraint") then
			child:Destroy()
		end
	end
	BrainrotModels.attachNameCard(model, brainrot.id, brainrot.mutation, nil, GameConfig.rebirthMultiplier(state.rebirths))
	root.Massless = true
	model:PivotTo(torso.CFrame * CFrame.new(0, 3.1, 0))
	model.Parent = character
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = torso
	weld.Part1 = root
	weld.Parent = root
	root.Anchored = false
	state.carrying = brainrot
	services.PlayerState.publish(player)
end

-- The carried brainrot is lost (Popcorn Wave, death, rebirth).
function CarryService.dropCarried(player: Player, reason: string): boolean
	local state = services.PlayerState.get(player)
	local brainrot = state and state.carrying
	if not brainrot then
		return false
	end
	state.carrying = nil
	if brainrot.model then
		brainrot.model:Destroy()
	end
	services.PlayerState.publish(player)
	if reason == "wave" then
		services.notify(player, "toast", { text = "THE POPCORN WAVE SWEPT AWAY " .. string.upper(BrainrotCatalog.BY_ID[brainrot.id].name) .. "!", tone = "bad", fx = "stolen" })
	end
	return true
end

-- Stands the carried brainrot on a free pedestal of the player's booth.
function CarryService.deliverCarried(player: Player): boolean
	local state = services.PlayerState.get(player)
	local brainrot = state and state.carrying
	if not brainrot then
		return false
	end
	local entry = BrainrotCatalog.BY_ID[brainrot.id]
	local model = brainrot.model
	if model then
		model.Parent = workspace
	end
	local slot = services.BasePedestals.placeBrainrotOnPedestal(player, brainrot)
	if not slot then
		if model then
			model.Parent = player.Character
		end
		local now = os.clock()
		if now - (lastFullWarning[player] or 0) > 4 then
			lastFullWarning[player] = now
			services.notify(player, "toast", { text = "BOOTH FULL! Sell one or buy MORE PEDESTALS", tone = "bad", fx = "error" })
		end
		return false
	end
	state.carrying = nil
	services.PlayerState.publish(player)
	local income = BrainrotCatalog.incomePerSecond(brainrot.id, brainrot.mutation) * GameConfig.rebirthMultiplier(state.rebirths)
	services.notify(player, "receipt", { line = 2, text = "PLACED " .. string.upper(entry.name) .. "  +$" .. GameConfig.formatCash(income) .. "/s", fx = "place", rarity = entry.rarity })
	return true
end

-- A rival holds the prompt on a brainrot in someone else's booth: allowed only while the gate is unlocked.
function CarryService.stealFromPedestal(thief: Player, owner: Player, slot: number)
	local ownerState = services.PlayerState.get(owner)
	local thiefState = services.PlayerState.get(thief)
	if not ownerState or not thiefState or not ownerState.booth or thiefState.carrying then
		return
	end
	if services.GateLock.isLocked(ownerState.booth) then
		services.notify(thief, "toast", { text = "BLOCKED BY LOCK!", tone = "bad", fx = "blocked" })
		return
	end
	local brainrot = services.BasePedestals.removeFromPedestal(owner, slot)
	if not brainrot then
		return
	end
	local name = string.upper(BrainrotCatalog.BY_ID[brainrot.id].name)
	CarryService.startCarrying(thief, brainrot)
	services.PlayerState.markDiscovered(thief, brainrot.id)
	services.notify(thief, "toast", { text = "YOU STOLE " .. name .. "! RUN HOME!", tone = "gold", fx = "buy" })
	services.notify(owner, "toast", { text = string.upper(thief.DisplayName) .. " STOLE YOUR " .. name .. "! LOCK YOUR GATE!", tone = "bad", fx = "stolen" })
end

function CarryService.start(allServices)
	services = allServices
	local function watchCharacter(player: Player, character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			(humanoid :: Humanoid).Died:Connect(function()
				CarryService.dropCarried(player, "died")
			end)
		end
	end
	local function watchPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			watchCharacter(player, character)
		end)
		if player.Character then
			task.spawn(watchCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end
	task.spawn(function()
		while true do
			task.wait(0.15)
			if not CarryService.holdDelivery then
				for player, state in services.PlayerState.all() do
					local torso = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if state.carrying and state.booth and torso and GameConfig.isInsideBooth(state.booth, torso.Position) then
						CarryService.deliverCarried(player)
					end
				end
			end
		end
	end)
end

return CarryService
