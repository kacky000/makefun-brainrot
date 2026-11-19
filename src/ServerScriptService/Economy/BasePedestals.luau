-- BasePedestals: each player's booth is their base. Brainrots are placed on its pedestals, where they earn;
-- a pedestal's prompt sells (owner) or steals (anyone else, when the gate is unlocked); the pad collects the stash.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.GameConfig)
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local PlayerState = require(script.Parent.Parent.State.PlayerState)
local BrainrotModels = require(script.Parent.Parent.World.BrainrotModels)
local IncomeTicker = require(script.Parent.IncomeTicker)
local RebirthService = require(script.Parent.RebirthService)
local UpgradeShop = require(script.Parent.UpgradeShop)

local BasePedestals = {}
BasePedestals.onPedestalPrompt = nil :: ((Player, Player, number) -> ())? -- CarryService decides sell or steal

local booths = {} -- [index] = { model, spec, owner, tops = {[slot] = Part}, models = {[slot] = Model} }
local LOCKED_COLOR = Color3.fromRGB(120, 120, 135)
local OPEN_COLOR = Color3.fromRGB(255, 205, 60)

function BasePedestals.placeBrainrot(player, id, mutation) -- on a pedestal, earns $/s
	local s = PlayerState.get(player)
	local booth = booths[s.booth]
	if not booth then
		return nil
	end
	for slot = 1, PlayerState.capacity(player) do
		if not s.slots[slot] then
			s.slots[slot] = { id = id, mutation = mutation }
			BasePedestals.showSlot(player, slot)
			PlayerState.mirror(player)
			player:SetAttribute("Income", IncomeTicker.incomePerSecond(player))
			return slot
		end
	end
	return nil
end

function BasePedestals.removeBrainrot(owner: Player, slot: number)
	local s = PlayerState.get(owner)
	local held = s and s.slots[slot]
	if not held then
		return nil
	end
	s.slots[slot] = nil
	local booth = booths[s.booth]
	if booth and booth.models[slot] then
		booth.models[slot]:Destroy()
		booth.models[slot] = nil
	end
	PlayerState.mirror(owner)
	owner:SetAttribute("Income", IncomeTicker.incomePerSecond(owner))
	return held
end

function BasePedestals.sellBrainrot(player: Player, slot: number): number
	local held = BasePedestals.removeBrainrot(player, slot)
	if not held then
		return 0
	end
	local refund = math.floor(BrainrotCatalog.byId[held.id].price * GameConfig.SELL_SHARE)
	PlayerState.addCash(player, refund)
	PlayerState.notify(player, "Receipt", { line = "SOLD", name = BrainrotCatalog.byId[held.id].name, detail = "+" .. BrainrotCatalog.formatMoney(refund) })
	return refund
end

-- mostValuableSlot: what a thief goes for.
function BasePedestals.mostValuableSlot(owner: Player): number?
	local s = PlayerState.get(owner)
	local best, bestIncome = nil, -1
	for slot, held in s.slots do
		local income = BrainrotCatalog.incomePerSecond(held.id, held.mutation)
		if income > bestIncome then
			best, bestIncome = slot, income
		end
	end
	return best
end

function BasePedestals.countBrainrots(owner: Player): number
	local n = 0
	for _ in PlayerState.get(owner).slots do
		n += 1
	end
	return n
end

function BasePedestals.pedestalPosition(owner: Player, slot: number): Vector3
	local booth = booths[PlayerState.get(owner).booth]
	return booth.tops[slot].Position + Vector3.new(0, 0.3, 0)
end

function BasePedestals.boothOf(player: Player)
	local s = PlayerState.get(player)
	return s and booths[s.booth]
end

function BasePedestals.boothModels(owner: Player)
	return booths[PlayerState.get(owner).booth].models
end

-- isInsideBooth: is this position past the gate line, between the booth's walls?
function BasePedestals.isInsideBooth(player: Player, position: Vector3): boolean
	local booth = BasePedestals.boothOf(player)
	if not booth then
		return false
	end
	local depthIn = (position.Z - booth.gateZ) * booth.spec.side
	return math.abs(position.X - booth.spec.x) < GameConfig.BOOTH.halfWidth and depthIn > 1.5 and depthIn < GameConfig.BOOTH.depth
end

-- gatePoint: a point lz studs inside (or, negative, outside) the gate, on the carpet line.
function BasePedestals.gatePoint(player: Player, lz: number): Vector3
	local booth = BasePedestals.boothOf(player)
	return Vector3.new(booth.spec.x, 0.5, booth.gateZ + booth.spec.side * lz)
end

function BasePedestals.showSlot(player: Player, slot: number)
	local s = PlayerState.get(player)
	local booth = booths[s.booth]
	local held = s.slots[slot]
	if booth.models[slot] then
		booth.models[slot]:Destroy()
		booth.models[slot] = nil
	end
	if not held then
		return
	end
	local top = booth.tops[slot]
	local model = BrainrotModels.buildBrainrot(held.id, held.mutation)
	local feet = top.Position + Vector3.new(0, 0.3 + model:GetAttribute("TopY") / 2, 0)
	local lookDir = Vector3.new(top:GetAttribute("FaceX"), 0, booth.spec.side * 1.1)
	model:PivotTo(CFrame.lookAt(feet, feet + lookDir))
	BrainrotModels.attachLabel(model, held.mutation, nil)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Sell / Steal"
	prompt.ObjectText = BrainrotCatalog.byId[held.id].name
	prompt.HoldDuration = 0.8
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(who)
		local owner = booth.owner
		if owner and BasePedestals.onPedestalPrompt then
			BasePedestals.onPedestalPrompt(who, owner, slot)
		end
	end)
	model.Parent = booth.model
	booth.models[slot] = model
end

-- refreshBooth: redraw every pedestal: open ones gold, the ones an upgrade has not bought yet grey.
function BasePedestals.refreshBooth(player: Player)
	local booth = BasePedestals.boothOf(player)
	if not booth then
		return
	end
	local capacity = PlayerState.capacity(player)
	for slot, top in booth.tops do
		top.Color = if slot <= capacity then OPEN_COLOR else LOCKED_COLOR
		top.Material = if slot <= capacity then Enum.Material.SmoothPlastic else Enum.Material.Slate
		BasePedestals.showSlot(player, slot)
	end
	player:SetAttribute("Income", IncomeTicker.incomePerSecond(player))
end

function BasePedestals.claimBooth(player: Player): number
	local s = PlayerState.get(player)
	for index, booth in booths do
		if not booth.owner then
			booth.owner = player
			s.booth = index
			booth.ownerText.Text = string.upper(player.DisplayName) .. "'S BOOTH"
			BasePedestals.refreshBooth(player)
			PlayerState.mirror(player)
			return index
		end
	end
	return 0
end

function BasePedestals.releaseBooth(player: Player)
	for _, booth in booths do
		if booth.owner == player then
			booth.owner = nil
			booth.ownerText.Text = "OPEN BOOTH"
			for slot, model in booth.models do
				model:Destroy()
				booth.models[slot] = nil
			end
			for _, top in booth.tops do
				top.Color = OPEN_COLOR
			end
		end
	end
end

function BasePedestals.start()
	local folder = Workspace:WaitForChild("Carnival"):WaitForChild("Booths")
	for index, spec in GameConfig.BOOTHS do
		local model = folder:WaitForChild("Booth" .. index)
		local booth = { model = model, spec = spec, owner = nil, tops = {}, models = {}, gateZ = model:GetAttribute("GateZ") }
		for _, top in model.Pedestals:GetChildren() do
			local slot = top:GetAttribute("Slot")
			if slot then
				booth.tops[slot] = top
			end
		end
		booth.ownerText = model.Gate.Beam:FindFirstChild("OwnerText", true)
		booth.pad = model.CollectPad
		booth.pad.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player and player == booth.owner then
				IncomeTicker.collectStash(player)
			end
		end)
		booths[index] = booth
	end
	RebirthService.onRebirth = BasePedestals.refreshBooth
	UpgradeShop.onUpgrade = function(player, key)
		if key == "Pedestals" then
			BasePedestals.refreshBooth(player)
		end
	end
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, booth in booths do
				local s = booth.owner and PlayerState.get(booth.owner)
				booth.pad.PadGui.Text.Text = if s then "COLLECT " .. BrainrotCatalog.formatMoney(s.stash) else "COLLECT $0"
			end
		end
	end)
end

return BasePedestals
