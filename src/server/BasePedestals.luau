--!strict
-- Player booths: hands each player a booth, spawns them in it, shows each owned brainrot standing on its
-- pedestal (with Sell for the owner and Steal for everyone else), and places or takes brainrots.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BrainrotModels = require(ReplicatedStorage:WaitForChild("BrainrotModels"))
local MutationRoller = require(ReplicatedStorage:WaitForChild("MutationRoller"))

local BasePedestals = {}

local services: { [string]: any } = {}
local Remotes: Folder
local owners: { [number]: Player } = {}
local shown: { [Player]: { [number]: Model } } = {}

local function notify(player: Player, text: string, color: Color3?)
	(Remotes :: any).Notify:FireClient(player, text, color or Color3.fromRGB(255, 255, 255))
end

local function sfx(player: Player, name: string)
	(Remotes :: any).Sfx:FireClient(player, name)
end

function BasePedestals.plotOf(player: Player): any
	local profile = services.PlayerData.get(player)
	if not profile or profile.plotIndex == 0 then
		return nil
	end
	return services.CarnivalWorld.plots[profile.plotIndex]
end

function BasePedestals.ownerOfPlot(index: number): Player?
	return owners[index]
end

-- True when a world position stands inside this booth's walls.
function BasePedestals.isInsidePlot(plot: any, position: Vector3): boolean
	local localPos = plot.gate:PointToObjectSpace(position)
	return math.abs(localPos.X) < GameConfig.PLOT_WIDTH / 2 and -localPos.Z > 1 and -localPos.Z < GameConfig.PLOT_DEPTH
end

-- The top of a pedestal, facing into the booth toward its owner (who spawns at the back).
function BasePedestals.pedestalCFrame(plot: any, slot: number): CFrame
	local base: BasePart = plot.pedestals[slot]
	local top = base.Position + Vector3.new(0, base.Size.X / 2, 0)
	return CFrame.lookAt(top, top + plot.inward)
end

local function sellValue(slot: { id: string, mut: string? }): number
	local def = BrainrotCatalog.get(slot.id)
	if not def then
		return 0
	end
	return math.floor(def.price * MutationRoller.multiplier(slot.mut) * GameConfig.SELL_REFUND)
end

local function addPrompts(owner: Player, slotIndex: number, model: Model, slot: { id: string, mut: string? })
	local root = model.PrimaryPart :: BasePart
	model:SetAttribute("OwnerUserId", owner.UserId)
	model:SetAttribute("Slot", slotIndex)

	local sell = Instance.new("ProximityPrompt")
	sell.Name = "SellPrompt"
	sell.ActionText = "Sell +" .. GameConfig.money(sellValue(slot))
	sell.ObjectText = model.Name
	sell.KeyboardKeyCode = Enum.KeyCode.F
	sell.HoldDuration = 0.6
	sell.MaxActivationDistance = 9
	sell.RequiresLineOfSight = false
	sell.Parent = root
	sell.Triggered:Connect(function(who)
		if who == owner then
			BasePedestals.sellFromPedestal(owner, slotIndex)
		end
	end)

	local steal = Instance.new("ProximityPrompt")
	steal.Name = "StealPrompt"
	steal.ActionText = "Steal!"
	steal.ObjectText = model.Name
	steal.KeyboardKeyCode = Enum.KeyCode.E
	steal.HoldDuration = 1.2
	steal.MaxActivationDistance = 9
	steal.RequiresLineOfSight = false
	steal.Parent = root
	steal.Triggered:Connect(function(who)
		if who ~= owner then
			BasePedestals.stealFromPedestal(who, owner, slotIndex)
		end
	end)
end

local function clearShown(player: Player, slotIndex: number)
	local models = shown[player]
	if models and models[slotIndex] then
		models[slotIndex]:Destroy()
		models[slotIndex] = nil
	end
end

local function styleLockedPedestals(player: Player, plot: any, profile: any)
	for slotIndex, base in plot.pedestals do
		local owned = slotIndex <= profile.pedestals
		base.Transparency = if owned then 0 else 0.55
		base.Color = if owned then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(120, 110, 140)
		local old = base:FindFirstChild("LockedTag")
		if old then
			old:Destroy()
		end
		if slotIndex == profile.pedestals + 1 then
			local tag = Instance.new("BillboardGui")
			tag.Name = "LockedTag"
			tag.Size = UDim2.fromScale(8, 2.2)
			tag.StudsOffset = Vector3.new(0, 3, 0)
			tag.MaxDistance = 120
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.TextColor3 = Color3.fromRGB(255, 225, 80)
			label.TextStrokeTransparency = 0
			label.Text = "LOCKED PEDESTAL\nUPGRADE " .. GameConfig.money(services.PlayerData.nextPedestalCost(profile))
			label.Parent = tag
			tag.Parent = base
		end
	end
	local _ = player
end

-- Shows one slot exactly as the profile says (a model, or nothing).
function BasePedestals.refreshSlot(player: Player, slotIndex: number, dropIn: boolean?)
	local plot = BasePedestals.plotOf(player)
	local profile = services.PlayerData.get(player)
	if not plot or not profile then
		return
	end
	clearShown(player, slotIndex)
	local slot = profile.slots[slotIndex]
	if not slot then
		return
	end
	local def = BrainrotCatalog.get(slot.id)
	if not def then
		return
	end
	local model = BrainrotModels.build(def, slot.mut)
	local target = BasePedestals.pedestalCFrame(plot, slotIndex)
	model:PivotTo(if dropIn then target * CFrame.new(0, 12, 0) else target)
	model.Parent = plot.folder
	addPrompts(player, slotIndex, model, slot)
	shown[player] = shown[player] or {}
	shown[player][slotIndex] = model
	if dropIn then
		local root = model.PrimaryPart :: BasePart
		TweenService:Create(root, TweenInfo.new(0.55, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { CFrame = target }):Play()
		local burst = Instance.new("ParticleEmitter")
		burst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		burst.Color = ColorSequence.new(BrainrotCatalog.rarity(def.rarity).color)
		burst.Speed = NumberRange.new(10, 18)
		burst.SpreadAngle = Vector2.new(180, 180)
		burst.Lifetime = NumberRange.new(0.5, 0.9)
		burst.Size = NumberSequence.new(0.8)
		burst.LightEmission = 1
		burst.Rate = 0
		burst.Parent = plot.pedestals[slotIndex]
		task.delay(0.5, function()
			burst:Emit(40)
		end)
		task.delay(2, function()
			burst:Destroy()
		end)
	end
end

function BasePedestals.refreshPedestals(player: Player)
	local plot = BasePedestals.plotOf(player)
	local profile = services.PlayerData.get(player)
	if not plot or not profile then
		return
	end
	for slotIndex = 1, GameConfig.MAX_PEDESTALS do
		BasePedestals.refreshSlot(player, slotIndex)
	end
	styleLockedPedestals(player, plot, profile)
end

-- Puts a brainrot on the first free pedestal; returns the slot, or nil when the booth is full.
function BasePedestals.placeOnPedestal(player: Player, id: string, mut: string?): number?
	local profile = services.PlayerData.get(player)
	if not profile then
		return nil
	end
	local slotIndex = services.PlayerData.firstFreePedestal(profile)
	if not slotIndex then
		return nil
	end
	services.PlayerData.setSlot(player, slotIndex, { id = id, mut = mut })
	BasePedestals.refreshSlot(player, slotIndex, true)
	sfx(player, "place")
	return slotIndex
end

function BasePedestals.takeFromPedestal(player: Player, slotIndex: number): { id: string, mut: string? }?
	local profile = services.PlayerData.get(player)
	if not profile then
		return nil
	end
	local slot = profile.slots[slotIndex]
	if not slot then
		return nil
	end
	services.PlayerData.setSlot(player, slotIndex, nil)
	clearShown(player, slotIndex)
	return slot
end

function BasePedestals.sellFromPedestal(player: Player, slotIndex: number)
	local slot = BasePedestals.takeFromPedestal(player, slotIndex)
	if not slot then
		return
	end
	local value = sellValue(slot)
	services.PlayerData.addCash(player, value)
	notify(player, "Sold for " .. GameConfig.money(value), Color3.fromRGB(120, 255, 140))
	sfx(player, "collect")
end

function BasePedestals.stealFromPedestal(thief: Player, victim: Player, slotIndex: number)
	local thiefProfile = services.PlayerData.get(thief)
	if not thiefProfile or thiefProfile.carrying then
		notify(thief, "Your hands are full!")
		return
	end
	if services.GateLock.isLocked(victim) then
		notify(thief, "That booth's gate is LOCKED!", Color3.fromRGB(255, 80, 100))
		sfx(thief, "blocked")
		return
	end
	local slot = BasePedestals.takeFromPedestal(victim, slotIndex)
	if not slot then
		return
	end
	services.CarryService.startCarry(thief, { id = slot.id, mut = slot.mut, fromUserId = victim.UserId, fromSlot = slotIndex, source = "steal" })
	local def = BrainrotCatalog.get(slot.id)
	local name = if def then def.name else "a brainrot"
	notify(victim, thief.DisplayName .. " is stealing your " .. name .. "! Stop them!", Color3.fromRGB(255, 80, 100))
	sfx(victim, "stolen")
	notify(thief, "You grabbed " .. name .. "! Run it home!", Color3.fromRGB(255, 225, 80))
end

local function moveIntoBooth(player: Player, character: Model)
	local plot = BasePedestals.plotOf(player)
	if not plot then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end
	task.wait(0.1)
	character:PivotTo(plot.spawn)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local profile = services.PlayerData.get(player)
	if humanoid and profile then
		humanoid.WalkSpeed = GameConfig.SPEED_LEVELS[profile.speedLevel]
	end
end

function BasePedestals.assignPlot(player: Player, profile: any)
	local chosen: number? = nil
	for index = 1, #services.CarnivalWorld.plots do
		if owners[index] == nil then
			chosen = index
			break
		end
	end
	if not chosen then
		warn("[BasePedestals] no free booth for " .. player.Name)
		return
	end
	owners[chosen] = player
	profile.plotIndex = chosen
	services.PlayerData.publish(player)
	local plot = services.CarnivalWorld.plots[chosen]
	plot.folder:SetAttribute("OwnerUserId", player.UserId)
	plot.lockButton:SetAttribute("OwnerUserId", player.UserId)
	plot.sign.Text = string.upper(player.DisplayName) .. "'S BOOTH"
	BasePedestals.refreshPedestals(player)
	player.CharacterAdded:Connect(function(character)
		moveIntoBooth(player, character)
	end)
	if player.Character then
		task.spawn(moveIntoBooth, player, player.Character)
	end
end

function BasePedestals.releasePlot(player: Player)
	for index, owner in owners do
		if owner == player then
			owners[index] = nil
			local plot = services.CarnivalWorld.plots[index]
			plot.folder:SetAttribute("OwnerUserId", nil)
			plot.lockButton:SetAttribute("OwnerUserId", nil)
			plot.sign.Text = "EMPTY BOOTH"
			plot.laser.Transparency = 1
		end
	end
	local models = shown[player]
	if models then
		for _, model in models do
			model:Destroy()
		end
	end
	shown[player] = nil
end

-- Updates each booth's sign with its owner's income every second.
local function refreshSigns()
	for index, owner in owners do
		local profile = services.PlayerData.get(owner)
		local plot = services.CarnivalWorld.plots[index]
		if profile and plot and plot.signSub then
			local used = services.PlayerData.usedPedestals(profile)
			plot.signSub.Text = string.format("+%s  ·  %d/%d pedestals", GameConfig.perSecond(profile.incomePerSec), used, profile.pedestals)
		end
	end
end

function BasePedestals.init(all: { [string]: any })
	services = all
	Remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function BasePedestals.start()
	services.PlayerData.onProfileReady(BasePedestals.assignPlot)
	services.PlayerData.onLeave(BasePedestals.releasePlot)
	task.spawn(function()
		while true do
			task.wait(1)
			refreshSigns()
		end
	end)
	local _ = Players
end

return BasePedestals
