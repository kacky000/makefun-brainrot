-- CarryService: buying a brainrot off the Prize Belt (or stealing one) puts it over the player's head; carrying it
-- through their own gate delivers it to a pedestal. A Popcorn Wave or dying drops it.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.GameConfig)
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local PlayerState = require(script.Parent.Parent.State.PlayerState)
local BrainrotModels = require(script.Parent.Parent.World.BrainrotModels)
local EventScheduler = require(script.Parent.Parent.Events.EventScheduler)
local BasePedestals = require(script.Parent.BasePedestals)
local GateLock = require(script.Parent.Parent.Hazards.GateLock)

local CarryService = {}
CarryService.deliveryPaused = false -- TourDirector holds deliveries while it stages a screenshot
local fullWarnedAt = {}

function CarryService.tryBuy(player, id, mutation, price) -- pay, carry it home
	local s = PlayerState.get(player)
	if not s then
		return false
	end
	if s.carrying then
		PlayerState.notify(player, "Toast", { text = "CARRY ONE AT A TIME - RUN IT HOME!", bad = true })
		return false
	end
	if not PlayerState.trySpend(player, price) then
		PlayerState.notify(player, "Toast", { text = "NEED " .. BrainrotCatalog.formatMoney(price - s.cash) .. " MORE", bad = true })
		return false
	end
	CarryService.giveCarry(player, id, mutation)
	PlayerState.notify(player, "Receipt", { line = "BOUGHT", name = BrainrotCatalog.byId[id].name, detail = "-" .. BrainrotCatalog.formatMoney(price), rarity = BrainrotCatalog.byId[id].rarity, mutation = mutation })
	return true
end

-- giveCarry: weld the brainrot over the character's head.
function CarryService.giveCarry(player: Player, id: string, mutation: string?)
	local s = PlayerState.get(player)
	CarryService.clearCarry(player)
	local model = BrainrotModels.buildBrainrot(id, mutation, math.min(1.25, BrainrotCatalog.rarityOf(id).scale))
	BrainrotModels.attachLabel(model, mutation, nil)
	s.carrying = { id = id, mutation = mutation, model = model }
	PlayerState.mirror(player)
	CarryService.applyWalkSpeed(player)
	task.spawn(function()
		local character = player.Character or player.CharacterAdded:Wait()
		if not player:HasAppearanceLoaded() then
			player.CharacterAppearanceLoaded:Wait()
		end
		local head = character:WaitForChild("Head", 5)
		if not head or s.carrying == nil or s.carrying.model ~= model then
			return
		end
		local root = model.PrimaryPart
		root.Anchored = false
		root.CFrame = head.CFrame * CFrame.new(0, 1.2 + model:GetAttribute("TopY") / 2, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = root
		weld.Parent = root
		model.Parent = character
	end)
end

function CarryService.clearCarry(player: Player)
	local s = PlayerState.get(player)
	if s and s.carrying then
		s.carrying.model:Destroy()
		s.carrying = nil
		PlayerState.mirror(player)
		CarryService.applyWalkSpeed(player)
	end
end

-- dropCarried: the carried brainrot is lost (a Popcorn Wave hit, a fall).
function CarryService.dropCarried(player: Player, reason: string): boolean
	local s = PlayerState.get(player)
	if not s or not s.carrying then
		return false
	end
	local name = BrainrotCatalog.byId[s.carrying.id].name
	CarryService.clearCarry(player)
	PlayerState.notify(player, "Dropped", { name = name, reason = reason })
	return true
end

function CarryService.deliverCarried(player: Player): boolean
	local s = PlayerState.get(player)
	local carried = s.carrying
	if not carried then
		return false
	end
	local slot = BasePedestals.placeBrainrot(player, carried.id, carried.mutation)
	if not slot then
		if (fullWarnedAt[player] or 0) + 4 < os.clock() then
			fullWarnedAt[player] = os.clock()
			PlayerState.notify(player, "Toast", { text = "BOOTH FULL! SELL ONE OR BUY PEDESTALS", bad = true })
		end
		return false
	end
	local isNew = PlayerState.markFound(player, carried.id)
	local entry = BrainrotCatalog.byId[carried.id]
	local income = BrainrotCatalog.incomePerSecond(carried.id, carried.mutation)
	CarryService.clearCarry(player)
	PlayerState.mirror(player)
	PlayerState.notify(player, "Receipt", { line = "PLACED", name = entry.name, detail = "+" .. BrainrotCatalog.formatMoney(income) .. "/s", rarity = entry.rarity, mutation = carried.mutation, isNew = isNew, slot = slot })
	return true
end

function CarryService.applyWalkSpeed(player: Player)
	local s = PlayerState.get(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if s and humanoid then
		local speed = GameConfig.BASE_WALK_SPEED + s.upgrades.Speed * GameConfig.UPGRADES.Speed.per + EventScheduler.speedBonus()
		humanoid.WalkSpeed = speed - (if s.carrying then GameConfig.CARRY_SPEED_PENALTY else 0)
	end
end

-- handlePedestalPrompt: the owner sells; anyone else steals, unless the gate is locked.
function CarryService.handlePedestalPrompt(who: Player, owner: Player, slot: number)
	if who == owner then
		BasePedestals.sellBrainrot(who, slot)
		return
	end
	if GateLock.isLocked(owner) then
		PlayerState.notify(who, "Toast", { text = "BLOCKED BY LOCK!", bad = true })
		return
	end
	local thief = PlayerState.get(who)
	if not thief or thief.carrying then
		return
	end
	local held = BasePedestals.removeBrainrot(owner, slot)
	if held then
		CarryService.giveCarry(who, held.id, held.mutation)
		PlayerState.notify(who, "Receipt", { line = "STOLE", name = BrainrotCatalog.byId[held.id].name, detail = "RUN!" })
		PlayerState.notify(owner, "Stolen", { name = BrainrotCatalog.byId[held.id].name, by = who.DisplayName })
	end
end

function CarryService.start()
	BasePedestals.onPedestalPrompt = CarryService.handlePedestalPrompt
	task.spawn(function()
		while true do
			task.wait(0.15)
			for _, player in Players:GetPlayers() do
				local s = PlayerState.get(player)
				local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if s and s.carrying and rootPart and not CarryService.deliveryPaused then
					if BasePedestals.isInsideBooth(player, rootPart.Position) then
						CarryService.deliverCarried(player)
					elseif rootPart.Position.Y < -20 then
						CarryService.dropCarried(player, "fell")
					end
				end
				CarryService.applyWalkSpeed(player)
			end
		end
	end)
end

return CarryService
