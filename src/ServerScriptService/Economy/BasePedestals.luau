-- BasePedestals: a player's booth. Assigns the booth, puts carried brainrots on its pedestals, sells them,
-- and shows which pedestals are still locked behind the MORE PEDESTALS upgrade.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local GameConfig = require(ReplicatedStorage.GameConfig)
local MutationRoller = require(ReplicatedStorage.MutationRoller)
local PlayerState = require(script.Parent.Parent.State.PlayerState)
local BrainrotModels = require(script.Parent.Parent.World.BrainrotModels)

local BasePedestals = {}

local services
local boothOwners = {} -- booth number -> Player

local function incomeOf(item): number
	return BrainrotCatalog.byId[item.id].income * MutationRoller.incomeMultiplier(item.mutation)
end

-- Put a brainrot on the player's first free pedestal. A full booth swaps out its weakest earner for a better one.
function BasePedestals.placeBrainrotOnPedestal(player: Player, id: string, mutation: string?, model: Model?, wantedSlot: number?): number?
	local state = PlayerState.get(player)
	if not state or state.booth == 0 then
		return nil
	end
	local entry = BrainrotCatalog.byId[id]
	local count = GameConfig.pedestalCount(state.upgrades.pedestals)
	local slot = wantedSlot
	if not slot then
		for candidate = 1, count do
			if not state.placed[candidate] then
				slot = candidate
				break
			end
		end
	end
	if not slot then
		local weakest, weakestIncome = nil, entry.income * MutationRoller.incomeMultiplier(mutation)
		for candidate, item in state.placed do
			if not item.stolen and incomeOf(item) < weakestIncome then
				weakest, weakestIncome = candidate, incomeOf(item)
			end
		end
		if not weakest then
			return nil
		end
		BasePedestals.sellFromPedestal(player, weakest)
		slot = weakest
	end
	local body = model or BrainrotModels.buildBrainrot(entry, mutation, nil, false)
	local spot = GameConfig.pedestalPoint(state.booth, slot) + Vector3.new(0, GameConfig.PEDESTAL_TOP, 0)
	local _, dir = GameConfig.boothOrigin(state.booth)
	body.PrimaryPart.Anchored = true
	body:ScaleTo(body:GetAttribute("FullScale") or 1)
	body:PivotTo(CFrame.lookAt(spot, spot + Vector3.new(0, 0, -dir)))
	BrainrotModels.attachLabel(body, entry, mutation, nil)
	body.Parent = BasePedestals.boothFolder(state.booth)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SellPrompt"
	prompt.ActionText = "Sell " .. GameConfig.formatMoney(entry.price * MutationRoller.priceMultiplier(mutation) * GameConfig.SELL_REFUND)
	prompt.ObjectText = entry.name
	prompt.HoldDuration = 1.2
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.Parent = body.PrimaryPart
	prompt.Triggered:Connect(function(who)
		if who == player then
			BasePedestals.sellFromPedestal(player, slot)
		end
	end)
	state.placed[slot] = { id = id, mutation = mutation, model = body }
	PlayerState.discover(player, id)
	services.IncomeTicker.recomputeIncome(player)
	services.notify(player, "placed", { name = entry.name, income = incomeOf(state.placed[slot]) * GameConfig.rebirthIncomeMultiplier(state.rebirths), rarity = entry.rarity, mutation = mutation })
	return slot
end

function BasePedestals.init(shared)
	services = shared
end

function BasePedestals.boothFolder(booth: number): Instance
	return Workspace.Carnival.Booths["Booth" .. booth]
end

function BasePedestals.ownerOf(booth: number): Player?
	return boothOwners[booth]
end

-- Dim the pedestals a player has not bought yet and light the ones they own.
function BasePedestals.refreshPedestals(player: Player)
	local state = PlayerState.get(player)
	if not state or state.booth == 0 then
		return
	end
	local count = GameConfig.pedestalCount(state.upgrades.pedestals)
	for slot = 1, GameConfig.BOOTH.maxPedestals do
		local pedestal = BasePedestals.boothFolder(state.booth).Pedestals["Pedestal" .. slot]
		local owned = slot <= count
		pedestal.Top.Color = owned and Color3.fromRGB(255, 205, 60) or Color3.fromRGB(70, 60, 92)
		pedestal.Glow.Transparency = owned and 0 or 1
		pedestal.Drum.Transparency = owned and 0 or 0.45
	end
end

-- Give a joining player the first free booth, restore their saved brainrots and stand them at its gate.
function BasePedestals.assignBooth(player: Player): number
	local state = PlayerState.get(player)
	for booth = 1, #GameConfig.BOOTHS do
		if not boothOwners[booth] then
			boothOwners[booth] = player
			state.booth = booth
			break
		end
	end
	if state.booth == 0 then
		return 0
	end
	local sign = BasePedestals.boothFolder(state.booth).Sign
	for _, gui in sign:GetChildren() do
		if gui:IsA("SurfaceGui") then
			gui.Title.Text = "BOOTH " .. state.booth .. " - OPEN"
		end
	end
	for _, saved in state.saved or {} do
		if BrainrotCatalog.byId[saved.id] and saved.slot <= GameConfig.pedestalCount(state.upgrades.pedestals) then
			BasePedestals.placeBrainrotOnPedestal(player, saved.id, saved.mutation, nil, saved.slot)
		end
	end
	state.saved = nil
	BasePedestals.refreshPedestals(player)
	PlayerState.syncToClient(player)
	return state.booth
end

function BasePedestals.sellFromPedestal(player: Player, slot: number)
	local state = PlayerState.get(player)
	local item = state and state.placed[slot]
	if not item or item.stolen then
		return
	end
	local entry = BrainrotCatalog.byId[item.id]
	local refund = math.floor(entry.price * MutationRoller.priceMultiplier(item.mutation) * GameConfig.SELL_REFUND)
	item.model:Destroy()
	state.placed[slot] = nil
	PlayerState.addMoney(player, refund)
	services.IncomeTicker.recomputeIncome(player)
	services.notify(player, "sold", { name = entry.name, refund = refund })
end

-- The pedestal a thief wants: the one earning the most.
function BasePedestals.mostValuableSlot(player: Player): number?
	local state = PlayerState.get(player)
	local best, bestIncome = nil, 0
	for slot, item in state and state.placed or {} do
		if not item.stolen and incomeOf(item) > bestIncome then
			best, bestIncome = slot, incomeOf(item)
		end
	end
	return best
end

-- Empty every pedestal (a rebirth, or the player leaving).
function BasePedestals.clearBooth(player: Player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	for slot, item in state.placed do
		if item.model then
			item.model:Destroy()
		end
		state.placed[slot] = nil
	end
	services.IncomeTicker.recomputeIncome(player)
end

function BasePedestals.releaseBooth(player: Player)
	local state = PlayerState.get(player)
	if not state or state.booth == 0 then
		return
	end
	for _, item in state.placed do
		if item.model then
			item.model:Destroy()
		end
	end
	local sign = BasePedestals.boothFolder(state.booth).Sign
	for _, gui in sign:GetChildren() do
		if gui:IsA("SurfaceGui") then
			gui.Title.Text = "BOOTH " .. state.booth
		end
	end
	boothOwners[state.booth] = nil
end

return BasePedestals
