-- BasePedestals: the player's base. Gives each player one of the six booths, stands bought
-- brainrots on its pedestals (where they earn money a second), sells them back, hands them to a
-- thief or a stealing rival, and dresses unclaimed booths as NPC show booths.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.GameConfig)
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local BrainrotModels = require(script.Parent.Parent.World.BrainrotModels)

local BasePedestals = {}

local PEDESTAL_TOP = 1.6
local CLAIM_ORDER = { 2, 5, 1, 3, 4, 6 }
local SHOW_OWNERS = { "MADAME ZUCCHINI", "BARKER BOB", "UNCLE FUNNEL", "THE GREAT GOUDA", "NONNA NITRO", "CAPTAIN CORNDOG" }
local SHOW_CAST = { "duckuccino", "slushi", "carousello", "nacho", "teacuppo", "strongmanno", "balloono", "hotdoggo", "ferriswheelio", "lollipoppa" }

local booths = {} -- [boothIndex] = { model, owner, show = { Model } }
local services = nil

local function boothFolder(): Instance
	return workspace:WaitForChild("Carnival")
end

local function setSign(boothIndex: number, text: string)
	local sign = booths[boothIndex].model:FindFirstChild("Sign")
	if sign then
		for _, face in sign:GetChildren() do
			local title = face:FindFirstChild("Title")
			if title then
				title.Text = text
			end
		end
	end
end

-- Where a brainrot stands on a pedestal: on top, turned to the carpet aisle and a little to the gate.
local function pedestalCFrame(boothIndex: number, slot: number): CFrame
	local at = GameConfig.pedestalPosition(boothIndex, slot) + Vector3.new(0, PEDESTAL_TOP, 0)
	local _, dir = GameConfig.boothOrigin(boothIndex)
	local across = GameConfig.BOOTH.columnX[(slot - 1) % 4 + 1]
	local toward = Vector3.new(if across > 0 then -1 else 1, 0, -dir * 0.9)
	return CFrame.lookAt(at, at + toward)
end

-- Stands a brainrot on the player's first free pedestal. Returns the slot, or nil when the booth is full.
function BasePedestals.placeBrainrotOnPedestal(player: Player, brainrot, wantedSlot: number?): number?
	local state = services.PlayerState.get(player)
	if not state or not state.booth then
		return nil
	end
	local capacity = services.PlayerState.pedestalCapacity(player)
	local slot = wantedSlot
	if not slot then
		for candidate = 1, capacity do
			if not state.pedestals[candidate] then
				slot = candidate
				break
			end
		end
	end
	if not slot or slot > capacity then
		return nil
	end
	local model = brainrot.model or BrainrotModels.buildBrainrotModel(brainrot.id, brainrot.mutation)
	brainrot.model = model
	local root = model.PrimaryPart :: BasePart
	for _, joint in root:GetChildren() do
		if joint:IsA("WeldConstraint") or joint:IsA("ProximityPrompt") then
			joint:Destroy()
		end
	end
	root.Anchored = true
	model:PivotTo(pedestalCFrame(state.booth, slot))
	model.Parent = booths[state.booth].model
	BrainrotModels.attachNameCard(model, brainrot.id, brainrot.mutation, nil, GameConfig.rebirthMultiplier(state.rebirths))

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = BrainrotCatalog.BY_ID[brainrot.id].name
	prompt.ActionText = "Sell (yours) / Steal"
	prompt.HoldDuration = 1.2
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(who: Player)
		if who == player then
			BasePedestals.sellFromPedestal(player, slot)
		else
			services.CarryService.stealFromPedestal(who, player, slot)
		end
	end)

	state.pedestals[slot] = brainrot
	services.IncomeTicker.refreshIncome(player)
	return slot
end

-- Takes a brainrot off a pedestal (sold, stolen or rebirthed away). The caller owns the model after.
function BasePedestals.removeFromPedestal(player: Player, slot: number)
	local state = services.PlayerState.get(player)
	local brainrot = state and state.pedestals[slot]
	if not brainrot then
		return nil
	end
	state.pedestals[slot] = nil
	local root = brainrot.model and brainrot.model.PrimaryPart
	if root then
		for _, child in root:GetChildren() do
			if child:IsA("ProximityPrompt") then
				child:Destroy()
			end
		end
	end
	services.IncomeTicker.refreshIncome(player)
	return brainrot
end

function BasePedestals.sellFromPedestal(player: Player, slot: number)
	local brainrot = BasePedestals.removeFromPedestal(player, slot)
	if not brainrot then
		return
	end
	local refund = math.floor(BrainrotCatalog.priceOf(brainrot.id, brainrot.mutation) * GameConfig.SELL_BACK)
	if brainrot.model then
		brainrot.model:Destroy()
	end
	services.PlayerState.addCash(player, refund)
	services.notify(player, "toast", { text = "SOLD " .. BrainrotCatalog.BY_ID[brainrot.id].name .. "  +$" .. GameConfig.formatCash(refund), tone = "gold", fx = "sell" })
end

-- The pedestal holding the player's best earner: what a thief goes for.
function BasePedestals.mostValuableSlot(player: Player): (number?, any)
	local state = services.PlayerState.get(player)
	local bestSlot, bestBrainrot, bestIncome = nil, nil, -1
	if state then
		for slot, brainrot in state.pedestals do
			local income = BrainrotCatalog.incomePerSecond(brainrot.id, brainrot.mutation)
			if income > bestIncome then
				bestSlot, bestBrainrot, bestIncome = slot, brainrot, income
			end
		end
	end
	return bestSlot, bestBrainrot
end

function BasePedestals.clearPedestals(player: Player)
	local state = services.PlayerState.get(player)
	if not state then
		return
	end
	for slot, brainrot in state.pedestals do
		if brainrot.model then
			brainrot.model:Destroy()
		end
		state.pedestals[slot] = nil
	end
	services.IncomeTicker.refreshIncome(player)
end

-- Greys out the pedestals the player has not unlocked yet and relabels every name card's income.
function BasePedestals.refreshBooth(player: Player)
	local state = services.PlayerState.get(player)
	if not state or not state.booth then
		return
	end
	local capacity = services.PlayerState.pedestalCapacity(player)
	local model = booths[state.booth].model
	for slot = 1, GameConfig.MAX_PEDESTALS do
		local pedestal = model:FindFirstChild(string.format("Pedestal%02d", slot))
		if pedestal then
			local open = slot <= capacity
			pedestal.Color = if open then Color3.fromRGB(255, 252, 245) else Color3.fromRGB(90, 84, 104)
			pedestal.Material = if open then Enum.Material.SmoothPlastic else Enum.Material.DiamondPlate
			local tag = pedestal:FindFirstChild("LockedTag")
			if open and tag then
				tag:Destroy()
			elseif not open and not tag then
				local card = Instance.new("BillboardGui")
				card.Name = "LockedTag"
				card.Size = UDim2.fromScale(5, 1.6)
				card.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
				card.MaxDistance = 60
				card.LightInfluence = 0
				local label = Instance.new("TextLabel")
				label.Size = UDim2.fromScale(1, 1)
				label.BackgroundTransparency = 1
				label.Font = Enum.Font.FredokaOne
				label.TextScaled = true
				label.Text = "LOCKED - UPGRADE"
				label.TextColor3 = Color3.fromRGB(255, 226, 110)
				label.TextStrokeTransparency = 0
				label.Parent = card
				card.Parent = pedestal
			end
		end
	end
	for _, brainrot in state.pedestals do
		if brainrot.model then
			BrainrotModels.attachNameCard(brainrot.model, brainrot.id, brainrot.mutation, nil, GameConfig.rebirthMultiplier(state.rebirths))
		end
	end
end

-- Rebuilds the models of a returning player's saved brainrots.
function BasePedestals.restorePedestals(player: Player)
	local state = services.PlayerState.get(player)
	if not state then
		return
	end
	local saved = state.pedestals
	state.pedestals = {}
	for slot, brainrot in saved do
		BasePedestals.placeBrainrotOnPedestal(player, { id = brainrot.id, mutation = brainrot.mutation }, slot)
	end
	BasePedestals.refreshBooth(player)
end

-- An unclaimed booth is run by an NPC showman so the midway never looks empty.
local function dressShowBooth(boothIndex: number)
	local booth = booths[boothIndex]
	setSign(boothIndex, SHOW_OWNERS[boothIndex])
	for spot = 1, 6 do
		local id = SHOW_CAST[(boothIndex * 3 + spot * 7) % #SHOW_CAST + 1]
		local mutation = if (boothIndex + spot) % 4 == 0 then GameConfig.MUTATIONS[(boothIndex + spot) % 3 + 1].key else nil
		local model = BrainrotModels.buildBrainrotModel(id, mutation)
		model:PivotTo(pedestalCFrame(boothIndex, spot))
		model.Parent = booth.model
		BrainrotModels.attachNameCard(model, id, mutation)
		table.insert(booth.show, model)
	end
end

local function clearShowBooth(boothIndex: number)
	for _, model in booths[boothIndex].show do
		model:Destroy()
	end
	table.clear(booths[boothIndex].show)
end

local function sendToBooth(player: Player, character: Model)
	local state = services.PlayerState.get(player)
	if state and state.booth then
		task.wait(0.1)
		local _, dir = GameConfig.boothOrigin(state.booth)
		local at = GameConfig.boothPoint(state.booth, 0, 7, 4)
		character:PivotTo(CFrame.lookAt(at, at + Vector3.new(0, 0, -dir)))
	end
end

-- Gives the player a free booth: their base, spawn point and gate.
function BasePedestals.claimBooth(player: Player): number?
	local state = services.PlayerState.get(player)
	if not state then
		return nil
	end
	for _, boothIndex in CLAIM_ORDER do
		local booth = booths[boothIndex]
		if booth and not booth.owner then
			booth.owner = player
			state.booth = boothIndex
			clearShowBooth(boothIndex)
			setSign(boothIndex, string.upper(player.DisplayName) .. "'S BOOTH")
			player.RespawnLocation = booth.model:FindFirstChild("Spawn") :: SpawnLocation
			player.CharacterAdded:Connect(function(character)
				sendToBooth(player, character)
			end)
			if player.Character then
				task.spawn(sendToBooth, player, player.Character)
			end
			BasePedestals.refreshBooth(player)
			return boothIndex
		end
	end
	return nil
end

function BasePedestals.releaseBooth(player: Player)
	local state = services.PlayerState.get(player)
	if not state or not state.booth then
		return
	end
	local boothIndex = state.booth
	for _, brainrot in state.pedestals do
		if brainrot.model then
			brainrot.model:Destroy()
		end
	end
	booths[boothIndex].owner = nil
	dressShowBooth(boothIndex)
end

function BasePedestals.ownerOfBooth(boothIndex: number): Player?
	return booths[boothIndex] and booths[boothIndex].owner
end

function BasePedestals.boothModel(boothIndex: number): Model
	return booths[boothIndex].model
end

function BasePedestals.start(allServices)
	services = allServices
	local carnival = boothFolder()
	for boothIndex = 1, GameConfig.BOOTH_COUNT do
		booths[boothIndex] = { model = carnival:WaitForChild("Booth" .. boothIndex), owner = nil, show = {} }
		dressShowBooth(boothIndex)
	end
	for _, player in Players:GetPlayers() do
		if services.PlayerState.get(player) and not services.PlayerState.get(player).booth then
			BasePedestals.claimBooth(player)
		end
	end
end

return BasePedestals
