--!strict
-- Carrying: a bought, caught or stolen brainrot rides on the player's head until they walk it into their
-- own booth (where it is placed on a pedestal) or drop it (popcorn wave, fainting). A stolen one that is
-- dropped goes back to its owner.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BrainrotModels = require(game:GetService("ServerScriptService"):WaitForChild("World"):WaitForChild("BrainrotModels"))
local Feedback = require(game:GetService("ServerScriptService"):WaitForChild("World"):WaitForChild("Feedback"))

local CarryService = {}

local services: { [string]: any } = {}
local Remotes: Folder
local carried: { [Player]: Model } = {}
local attaching: { [Player]: boolean } = {}

local notify = Feedback.notify

function CarryService.isCarrying(player: Player): boolean
	local profile = services.PlayerData.get(player)
	return profile ~= nil and profile.carrying ~= nil
end

local function attachModel(player: Player, model: Model)
	attaching[player] = true
	local character = player.Character
	if not character then
		attaching[player] = nil
		return
	end
	if not player:HasAppearanceLoaded() then
		local deadline = os.clock() + 4
		while not player:HasAppearanceLoaded() and os.clock() < deadline do
			task.wait(0.1)
		end
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart or not model.PrimaryPart or carried[player] ~= model then
		attaching[player] = nil
		return
	end
	local root = model.PrimaryPart :: BasePart
	root.Anchored = false
	root.Massless = true
	-- Held high over the head, facing the way the carrier runs.
	model:PivotTo(rootPart.CFrame * CFrame.new(0, 3.4, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rootPart
	weld.Part1 = root
	weld.Parent = root
	model.Parent = character
	attaching[player] = nil
end

-- Starts carrying; false when the hands are already full.
function CarryService.startCarry(player: Player, carry: { id: string, mut: string?, fromUserId: number?, fromSlot: number?, source: string }): boolean
	local profile = services.PlayerData.get(player)
	if not profile or profile.carrying then
		return false
	end
	local def = BrainrotCatalog.get(carry.id)
	if not def then
		return false
	end
	services.PlayerData.setCarrying(player, carry)
	local model = BrainrotModels.build(def, carry.mut, { scale = 1.8 })
	model.Name = "Carried"
	carried[player] = model
	task.spawn(attachModel, player, model)
	return true
end

local function clearModel(player: Player)
	local model = carried[player]
	if model then
		model:Destroy()
	end
	carried[player] = nil
end

-- Drops what the player carries. A stolen brainrot runs back to its owner; anything else is lost.
function CarryService.dropCarry(player: Player, reason: string, silent: boolean?)
	local profile = services.PlayerData.get(player)
	if not profile or not profile.carrying then
		return
	end
	local carry = profile.carrying
	services.PlayerData.setCarrying(player, nil)
	clearModel(player)
	local def = BrainrotCatalog.get(carry.id)
	local name = if def then def.name else "your brainrot"
	if carry.fromUserId then
		local owner = Players:GetPlayerByUserId(carry.fromUserId)
		if owner and services.BasePedestals.placeOnPedestal(owner, carry.id, carry.mut) then
			notify(owner, name .. " escaped the thief and came home!", Color3.fromRGB(120, 255, 140))
		end
	end
	if not silent then
		notify(player, reason .. " You dropped " .. name .. "!", Color3.fromRGB(255, 120, 80))
	end
end

function CarryService.deliverCarry(player: Player): boolean
	local profile = services.PlayerData.get(player)
	if not profile or not profile.carrying then
		return false
	end
	local carry = profile.carrying
	local slot = services.BasePedestals.placeOnPedestal(player, carry.id, carry.mut)
	if not slot then
		return false
	end
	services.PlayerData.setCarrying(player, nil)
	clearModel(player)
	local def = BrainrotCatalog.get(carry.id)
	if def then
		local rarity = BrainrotCatalog.rarity(def.rarity)
		notify(player, def.name .. " is earning on pedestal " .. slot .. "!", rarity.color)
		if rarity.order >= 5 then
			(Remotes :: any).Celebrate:FireClient(player, string.upper(def.rarity) .. "!", def.name, rarity.color)
		end
	end
	return true
end

-- Delivers carried brainrots the moment their carrier steps into their own booth.
local function watchDeliveries()
	local warnedFull: { [Player]: number } = {}
	while true do
		task.wait(0.2)
		for player, profile in services.PlayerData.all() do
			-- (A tour showcase holds the carry pose for its screenshot instead of delivering.)
			if profile.carrying and not player:GetAttribute("Showcase") then
				local character = player.Character
				local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local plot = services.BasePedestals.plotOf(player)
				if rootPart and plot and services.BasePedestals.isInsidePlot(plot, rootPart.Position) then
					if not CarryService.deliverCarry(player) and (warnedFull[player] or 0) < os.clock() then
						warnedFull[player] = os.clock() + 4
						notify(player, "Booth full! Sell one (F) or buy a pedestal in UPGRADES.", Color3.fromRGB(255, 200, 80))
					end
				end
				if profile.carrying and not attaching[player] and (not carried[player] or not carried[player].Parent) then
					-- The character respawned or the model was lost: re-attach.
					local def = BrainrotCatalog.get(profile.carrying.id)
					if def and character then
						local model = BrainrotModels.build(def, profile.carrying.mut, { scale = 1.8 })
						model.Name = "Carried"
						carried[player] = model
						task.spawn(attachModel, player, model)
					end
				end
			end
		end
	end
end

function CarryService.init(all: { [string]: any })
	services = all
	Remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function CarryService.start()
	local function hookCharacter(player: Player, character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if humanoid then
			humanoid.Died:Connect(function()
				CarryService.dropCarry(player, "You fainted!")
			end)
		end
	end
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			hookCharacter(player, character)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function(character)
			hookCharacter(player, character)
		end)
		if player.Character then
			task.spawn(hookCharacter, player, player.Character)
		end
	end
	services.PlayerData.onLeave(function(player)
		local profile = services.PlayerData.get(player)
		if profile and profile.carrying then
			CarryService.dropCarry(player, "Left the carnival.")
		end
		clearModel(player)
	end)
	task.spawn(watchDeliveries)
end

return CarryService
