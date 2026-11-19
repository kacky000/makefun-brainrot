-- ThiefRaids: Sneaky Clown NPC thieves. Every so often one walks up the midway to a player's
-- booth. A locked gate bounces him ("BLOCKED BY LOCK!"). An open gate lets him grab the booth's
-- best brainrot and run for the exit; the owner bonks him by touching him to save it for a reward.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.GameConfig)
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)

local ThiefRaids = {}

local THIEF = GameConfig.THIEF
local services = nil
local raids = {} -- [Player] = raid
local nextRaidAt: { [Player]: number } = {}

-- Sends one Sneaky Clown at the player's booth. `linger` (seconds) holds a blocked clown at the gate.
function ThiefRaids.sendThief(player: Player, linger: number?)
	local state = services.PlayerState.get(player)
	if not state or not state.booth or raids[player] then
		return nil
	end
	local boothIndex = state.booth
	local origin, dir = GameConfig.boothOrigin(boothIndex)
	local side = if math.random() < 0.5 then -1 else 1
	local laneZ = dir * (GameConfig.STREET.halfWidth - 6)
	local exit = Vector3.new(math.clamp(origin.X + side * 75, -140, 140), 0.3, laneZ)
	local gateFront = GameConfig.boothPoint(boothIndex, 0, -7, 0.3)
	local raid = { owner = player, clown = ThiefRaids.buildSneakyClown(), position = exit, done = false, loot = nil, slot = nil }
	raids[player] = raid
	raid.clown.Parent = workspace
	services.notify(player, "toast", { text = "SNEAKY CLOWN SPOTTED! LOCK YOUR GATE!", tone = "bad", fx = "alarm" })

	task.spawn(function()
		local function finish()
			raid.done = true
			raids[player] = nil
			if raid.clown then
				raid.clown:Destroy()
			end
		end
		if not ThiefRaids.walkClown(raid, gateFront, THIEF.walkSpeed) then
			return finish()
		end
		if services.GateLock.isLocked(boothIndex) then
			ThiefRaids.setClownSign(raid, "BLOCKED BY LOCK!", Color3.fromRGB(255, 70, 80))
			services.notify(player, "toast", { text = "BLOCKED BY LOCK! The clown bounced off your lasers", tone = "good", fx = "blocked" })
			local untilTime = os.clock() + (linger or 1.6)
			while os.clock() < untilTime and not raid.done do
				local bounce = math.abs(math.sin(os.clock() * 9)) * 2.4
				local at = gateFront + Vector3.new(0, bounce, -dir * bounce)
				raid.clown:PivotTo(CFrame.lookAt(at, at + Vector3.new(0.3, 0, -dir))) -- recoiling, facing the street
				RunService.Heartbeat:Wait()
			end
			ThiefRaids.walkClown(raid, exit, THIEF.walkSpeed * 1.5)
			return finish()
		end
		local slot, brainrot = services.BasePedestals.mostValuableSlot(player)
		if not slot then
			ThiefRaids.walkClown(raid, exit, THIEF.walkSpeed)
			return finish()
		end
		local target = GameConfig.pedestalPosition(boothIndex, slot)
		local across = GameConfig.BOOTH.columnX[(slot - 1) % 4 + 1]
		local aisle = GameConfig.boothPoint(boothIndex, 0, (target.Z - origin.Z) * dir, 0.6)
		local reach = target + Vector3.new(if across > 0 then -4 else 4, 0.6, 0)
		for _, waypoint in { GameConfig.boothPoint(boothIndex, 0, 4, 0.6), aisle, reach } do
			if not ThiefRaids.walkClown(raid, waypoint, THIEF.walkSpeed) then
				return finish()
			end
		end
		local loot = services.BasePedestals.removeFromPedestal(player, slot)
		if loot then
			raid.loot, raid.slot = loot, slot
			local lootRoot = loot.model.PrimaryPart :: BasePart
			loot.model:PivotTo((raid.clown.PrimaryPart :: BasePart).CFrame * CFrame.new(0, 7.4, 0))
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = raid.clown.PrimaryPart
			weld.Part1 = lootRoot
			weld.Parent = lootRoot
			lootRoot.Anchored = false
			ThiefRaids.setClownSign(raid, "GOT IT! HEHEHE", Color3.fromRGB(255, 226, 90))
			services.notify(player, "toast", { text = "THIEF GRABBED " .. string.upper(BrainrotCatalog.BY_ID[loot.id].name) .. "! BONK HIM!", tone = "bad", fx = "stolen" })
		end
		for _, waypoint in { aisle, GameConfig.boothPoint(boothIndex, 0, 4, 0.6), gateFront, exit } do
			if raid.loot and services.GateLock.isLocked(boothIndex) and GameConfig.isInsideBooth(boothIndex, raid.position) then
				ThiefRaids.bonkThief(raid, "TRAPPED BY YOUR LOCK!")
				return finish()
			end
			if not ThiefRaids.walkClown(raid, waypoint, THIEF.fleeSpeed) then
				return finish()
			end
		end
		if raid.loot then
			local name = string.upper(BrainrotCatalog.BY_ID[raid.loot.id].name)
			raid.loot.model:Destroy()
			raid.loot = nil
			state.stolen += 1
			services.notify(player, "toast", { text = "STOLEN! The clown got away with " .. name, tone = "bad", fx = "stolen" })
		end
		finish()
	end)
	return raid
end

-- The owner caught the clown: the brainrot goes back on its pedestal and the owner is paid a reward.
function ThiefRaids.bonkThief(raid, headline: string?)
	if raid.done then
		return
	end
	raid.done = true
	local player = raid.owner
	local reward = 50
	local saved = ""
	if raid.loot then
		local loot = raid.loot
		raid.loot = nil
		reward = math.max(50, math.floor(BrainrotCatalog.priceOf(loot.id, loot.mutation) * THIEF.bonkRewardShare))
		saved = " SAVED " .. string.upper(BrainrotCatalog.BY_ID[loot.id].name)
		if not services.BasePedestals.placeBrainrotOnPedestal(player, loot, raid.slot) then
			services.BasePedestals.placeBrainrotOnPedestal(player, loot)
		end
	end
	local state = services.PlayerState.get(player)
	if state then
		state.bonks += 1
	end
	services.PlayerState.addCash(player, reward)
	services.notify(player, "toast", { text = (headline or "BONK!") .. saved .. "  +$" .. GameConfig.formatCash(reward), tone = "gold", fx = "bonk" })
end

-- Hops the clown toward `target`. Returns false when the raid ended on the way (he was bonked).
function ThiefRaids.walkClown(raid, target: Vector3, speed: number): boolean
	while true do
		local dt = RunService.Heartbeat:Wait()
		if raid.done then
			return false
		end
		local delta = (target - raid.position) * Vector3.new(1, 0, 1)
		local distance = delta.Magnitude
		if distance < 0.6 then
			return true
		end
		local heading = delta.Unit
		raid.position += heading * math.min(distance, speed * dt)
		local hop = math.abs(math.sin(os.clock() * 11)) * 0.9
		local at = Vector3.new(raid.position.X, 0.3 + hop, raid.position.Z)
		raid.clown:PivotTo(CFrame.lookAt(at, at + heading))
		local torso = raid.owner.Character and raid.owner.Character:FindFirstChild("HumanoidRootPart")
		if torso and (torso.Position - at).Magnitude < THIEF.bonkRange then
			ThiefRaids.bonkThief(raid)
			return false
		end
	end
end

function ThiefRaids.setClownSign(raid, text: string, color: Color3)
	local label = raid.clown:FindFirstChild("Shout", true)
	if label then
		label.Text = text
		label.TextColor3 = color
	end
end

-- The Sneaky Clown: striped body, bandit mask, red nose, green hair, huge shoes and a loot sack.
function ThiefRaids.buildSneakyClown(): Model
	local model = Instance.new("Model")
	model.Name = "SneakyClown"
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.Parent = model
	model.PrimaryPart = root
	local function add(shape: Enum.PartType, size: Vector3, at: CFrame, color: Color3, material: Enum.Material?)
		local part = Instance.new("Part")
		part.Shape = shape
		part.Size = size
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		part.CanCollide = false
		part.Massless = true
		part.CFrame = at
		local weld = Instance.new("Weld")
		weld.Part0 = root
		weld.Part1 = part
		weld.C0 = at
		weld.Parent = part
		part.Parent = model
		return part
	end
	local ballShape, block, cylinder = Enum.PartType.Ball, Enum.PartType.Block, Enum.PartType.Cylinder
	local upright = CFrame.Angles(0, 0, math.pi / 2)
	add(ballShape, Vector3.new(4.2, 4.2, 4.2), CFrame.new(0, 2.9, 0), Color3.fromRGB(130, 60, 200))
	for stripe = -1, 1 do
		add(cylinder, Vector3.new(0.5, 4.0 - math.abs(stripe) * 0.7, 4.0 - math.abs(stripe) * 0.7), CFrame.new(0, 2.9 + stripe * 1.1, 0) * upright, Color3.fromRGB(60, 220, 200))
	end
	add(ballShape, Vector3.new(3, 3, 3), CFrame.new(0, 5.9, 0), Color3.fromRGB(255, 250, 245))
	add(block, Vector3.new(3.1, 0.8, 0.5), CFrame.new(0, 6.2, -1.2), Color3.fromRGB(25, 22, 30))
	for _, side in { -1, 1 } do
		add(ballShape, Vector3.new(0.5, 0.5, 0.5), CFrame.new(side * 0.6, 6.2, -1.45), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
		for tuft = 0, 2 do
			add(ballShape, Vector3.new(1.5, 1.5, 1.5), CFrame.new(side * (1.5 + tuft * 0.3), 6.2 + tuft * 0.8, 0.2), Color3.fromRGB(70, 220, 90))
		end
		add(ballShape, Vector3.new(1.6, 1.6, 1.6), CFrame.new(side * 1.2, 0.5, -1.2), Color3.fromRGB(230, 40, 50))
		add(block, Vector3.new(1.5, 1.0, 2.6), CFrame.new(side * 1.2, 0.5, -0.4), Color3.fromRGB(230, 40, 50))
		add(cylinder, Vector3.new(2.2, 0.5, 0.5), CFrame.new(side * 2.5, 3.6, -0.4) * CFrame.Angles(0, 0, side * 0.9), Color3.fromRGB(25, 22, 30))
		add(ballShape, Vector3.new(1.1, 1.1, 1.1), CFrame.new(side * 3.2, 4.5, -0.5), Color3.fromRGB(255, 255, 255))
	end
	add(ballShape, Vector3.new(0.9, 0.9, 0.9), CFrame.new(0, 5.7, -1.6), Color3.fromRGB(255, 30, 50), Enum.Material.Neon)
	add(block, Vector3.new(1.4, 0.3, 0.3), CFrame.new(0, 5.0, -1.3), Color3.fromRGB(200, 30, 50))
	add(cylinder, Vector3.new(1.6, 1.8, 1.8), CFrame.new(0.3, 7.9, 0) * upright * CFrame.Angles(0.2, 0, 0), Color3.fromRGB(25, 22, 30))
	add(cylinder, Vector3.new(0.2, 3.0, 3.0), CFrame.new(0.2, 7.2, 0) * upright, Color3.fromRGB(25, 22, 30))
	add(ballShape, Vector3.new(3, 3, 3), CFrame.new(0, 3.6, 2.4), Color3.fromRGB(190, 150, 90), Enum.Material.Fabric)

	local card = Instance.new("BillboardGui")
	card.Name = "ClownSign"
	card.Size = UDim2.fromScale(13, 3.4)
	card.StudsOffsetWorldSpace = Vector3.new(0, 11.5, 0)
	card.MaxDistance = 160
	card.LightInfluence = 0
	card.AlwaysOnTop = true
	local plate = Instance.new("Frame")
	plate.Size = UDim2.fromScale(1, 1)
	plate.BackgroundColor3 = Color3.fromRGB(22, 18, 34)
	plate.BackgroundTransparency = 0.1
	plate.Parent = card
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = plate
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 60, 80)
	stroke.Thickness = 3
	stroke.Parent = plate
	local name = Instance.new("TextLabel")
	name.Size = UDim2.fromScale(1, 0.42)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.Text = "SNEAKY CLOWN - THIEF"
	name.TextColor3 = Color3.fromRGB(255, 255, 255)
	name.Parent = plate
	local shout = Instance.new("TextLabel")
	shout.Name = "Shout"
	shout.Size = UDim2.fromScale(1, 0.58)
	shout.Position = UDim2.fromScale(0, 0.42)
	shout.BackgroundTransparency = 1
	shout.Font = Enum.Font.FredokaOne
	shout.TextScaled = true
	shout.Text = "COMING FOR YOUR BEST!"
	shout.TextColor3 = Color3.fromRGB(255, 120, 130)
	shout.Parent = plate
	card.Parent = root
	return model
end

function ThiefRaids.activeRaid(player: Player)
	return raids[player]
end

function ThiefRaids.start(allServices)
	services = allServices
	task.spawn(function()
		while true do
			task.wait(3)
			local now = os.clock()
			for player, state in services.PlayerState.all() do
				nextRaidAt[player] = nextRaidAt[player] or now + THIEF.firstAfter
				if now >= nextRaidAt[player] and next(state.pedestals) ~= nil and not ThiefRaids.paused then
					nextRaidAt[player] = now + THIEF.every + math.random(-8, 12)
					ThiefRaids.sendThief(player)
				end
			end
		end
	end)
end

return ThiefRaids
