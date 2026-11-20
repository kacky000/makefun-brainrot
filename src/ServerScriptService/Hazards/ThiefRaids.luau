-- ThiefRaids: the stealing. A Sneaky Clown walks to a player's booth and goes for the best-earning brainrot.
-- A locked gate bounces him; otherwise he runs off with it, and the owner gets it back by catching and bonking him.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local GameConfig = require(ReplicatedStorage.GameConfig)
local MutationRoller = require(ReplicatedStorage.MutationRoller)
local PlayerState = require(script.Parent.Parent.State.PlayerState)

local ThiefRaids = {}

local services
local random = Random.new()
local thieves = {} -- Player -> thief
ThiefRaids.paused = false

local function clownPart(model: Model, shape: string?, size: Vector3, color: Color3, offset: CFrame, material: Enum.Material?)
	local part = Instance.new("Part")
	if shape == "Ball" then
		part.Shape = Enum.PartType.Ball
	elseif shape == "Cylinder" then
		part.Shape = Enum.PartType.Cylinder
	end
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CFrame = offset
	part.Parent = model
	return part
end

-- The Sneaky Clown: striped suit, white face, red nose, rainbow hair, big shoes and a loot sack. He faces -Z.
local function buildClown(): Model
	local model = Instance.new("Model")
	model.Name = "SneakyClown"
	local root = clownPart(model, nil, Vector3.new(2, 0.4, 2), Color3.new(1, 1, 1), CFrame.new(0, 0, 0))
	root.Transparency = 1
	root.Name = "Root"
	model.PrimaryPart = root
	local white = Color3.fromRGB(250, 250, 250)
	local red = Color3.fromRGB(235, 40, 60)
	local hair = { Color3.fromRGB(255, 90, 120), Color3.fromRGB(80, 200, 255), Color3.fromRGB(255, 220, 70), Color3.fromRGB(120, 230, 130), Color3.fromRGB(200, 130, 255) }
	for _, side in { -1, 1 } do
		clownPart(model, nil, Vector3.new(1.2, 2.4, 1.2), Color3.fromRGB(60, 60, 200), CFrame.new(side * 0.9, 1.6, 0))
		clownPart(model, nil, Vector3.new(1.8, 0.8, 3.2), red, CFrame.new(side * 0.9, 0.4, -0.7))
		clownPart(model, nil, Vector3.new(1, 2.6, 1), Color3.fromRGB(255, 220, 70), CFrame.new(side * 2.4, 4.6, -0.6) * CFrame.Angles(math.rad(-50), 0, 0))
		clownPart(model, "Ball", Vector3.new(1.3, 1.3, 1.3), white, CFrame.new(side * 2.4, 5.4, -1.9))
	end
	for stripe = 0, 3 do
		clownPart(model, nil, Vector3.new(4, 0.85, 2.4), (stripe % 2 == 0) and Color3.fromRGB(255, 220, 70) or Color3.fromRGB(200, 60, 220), CFrame.new(0, 3.2 + stripe * 0.85, 0))
	end
	for index, x in { -1, 0, 1 } do
		clownPart(model, "Ball", Vector3.new(0.7, 0.7, 0.7), hair[index], CFrame.new(0, 3.3 + (x + 1) * 1.1, -1.25))
	end
	clownPart(model, nil, Vector3.new(3.4, 0.5, 2.8), white, CFrame.new(0, 6.5, 0))
	clownPart(model, "Ball", Vector3.new(3.6, 3.6, 3.6), white, CFrame.new(0, 8.2, 0))
	clownPart(model, "Ball", Vector3.new(1.1, 1.1, 1.1), red, CFrame.new(0, 8.1, -1.9))
	for _, side in { -1, 1 } do
		clownPart(model, "Ball", Vector3.new(0.9, 0.9, 0.9), white, CFrame.new(side * 0.75, 8.8, -1.5))
		clownPart(model, "Ball", Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(20, 20, 30), CFrame.new(side * 0.7, 8.75, -1.9))
		clownPart(model, nil, Vector3.new(0.9, 0.2, 0.2), Color3.fromRGB(20, 20, 30), CFrame.new(side * 0.75, 9.5, -1.5) * CFrame.Angles(0, 0, math.rad(side * -25)))
		for index = 1, 3 do
			clownPart(model, "Ball", Vector3.new(2, 2, 2), hair[(index + (side > 0 and 2 or 0)) % #hair + 1], CFrame.new(side * (1.6 + index * 0.25), 8.2 + index * 0.75, 0.3))
		end
	end
	clownPart(model, nil, Vector3.new(2, 0.4, 0.3), red, CFrame.new(0, 7.35, -1.6))
	clownPart(model, "Cylinder", Vector3.new(0.3, 3.4, 3.4), Color3.fromRGB(30, 30, 40), CFrame.new(0, 10.1, 0) * CFrame.Angles(0, 0, math.rad(90)))
	clownPart(model, "Cylinder", Vector3.new(1.8, 2.2, 2.2), Color3.fromRGB(30, 30, 40), CFrame.new(0, 11, 0) * CFrame.Angles(0, 0, math.rad(90)))
	clownPart(model, "Ball", Vector3.new(3.4, 3.4, 3.4), Color3.fromRGB(150, 110, 70), CFrame.new(0.6, 4.8, 2.2))
	local sign = Instance.new("BillboardGui")
	sign.Name = "Sign"
	sign.Size = UDim2.fromScale(9.5, 2.5)
	sign.StudsOffset = Vector3.new(0, 14.2, 0)
	sign.MaxDistance = 140
	sign.LightInfluence = 0
	sign.Parent = root
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(40, 10, 20)
	card.BackgroundTransparency = 0.1
	card.Parent = sign
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = red
	stroke.Thickness = 3
	stroke.Parent = card
	for index, name in { "Title", "Status" } do
		local line = Instance.new("TextLabel")
		line.Name = name
		line.BackgroundTransparency = 1
		line.Size = UDim2.fromScale(0.94, 0.48)
		line.Position = UDim2.fromScale(0.03, (index - 1) * 0.5)
		line.Font = Enum.Font.FredokaOne
		line.TextScaled = true
		line.TextColor3 = (index == 1) and white or Color3.fromRGB(255, 220, 70)
		line.TextStrokeTransparency = 0.3
		line.Text = (index == 1) and "SNEAKY CLOWN - THIEF" or "COMING FOR YOUR BEST!"
		line.Parent = card
	end
	return model
end

local function setStatus(thief, text: string)
	thief.model.PrimaryPart.Sign.Frame.Status.Text = text
end

local function placeThief(thief, facing: Vector3)
	local hop = math.abs(math.sin(os.clock() * 10)) * 0.5
	local spot = thief.position + Vector3.new(0, hop, 0)
	thief.model:PivotTo(CFrame.lookAt(spot, spot + facing))
	if thief.loot then
		thief.loot.model:PivotTo(CFrame.lookAt(spot + Vector3.new(0, 12.4, 0), spot + Vector3.new(0, 12.4, 0) + facing))
	end
end

-- The owner catches the clown: he drops the loot back on its pedestal and pays a reward.
local function bonk(thief)
	local player = thief.player
	thief.alive = false
	local reward = 100
	if thief.loot then
		local state = PlayerState.get(player)
		local item = thief.loot
		local entry = BrainrotCatalog.byId[item.id]
		reward = math.max(reward, math.floor(entry.price * MutationRoller.priceMultiplier(item.mutation) * 0.2))
		item.stolen = nil
		thief.loot = nil
		if state and state.placed[thief.slot] == item then
			local spot = GameConfig.pedestalPoint(state.booth, thief.slot) + Vector3.new(0, GameConfig.PEDESTAL_TOP, 0)
			local _, dir = GameConfig.boothOrigin(state.booth)
			item.model:PivotTo(CFrame.lookAt(spot, spot + Vector3.new(0, 0, -dir)))
			services.IncomeTicker.recomputeIncome(player)
		end
	end
	PlayerState.addMoney(player, reward)
	services.notify(player, "bonk", { reward = reward })
end

-- Walk the clown to a spot. False when he was bonked (or removed) on the way.
local function walkTo(thief, target: Vector3, speed: number): boolean
	while thief.alive do
		local delta = Vector3.new(target.X - thief.position.X, 0, target.Z - thief.position.Z)
		local distance = delta.Magnitude
		if distance < 0.6 then
			return true
		end
		local deltaTime = task.wait()
		local facing = delta.Unit
		thief.position += facing * math.min(distance, speed * deltaTime)
		thief.facing = facing
		placeThief(thief, facing)
		local rootPart = thief.player.Character and thief.player.Character:FindFirstChild("HumanoidRootPart")
		if rootPart and thief.catchable and (rootPart.Position - thief.position).Magnitude < GameConfig.THIEF.bonkRange then
			bonk(thief)
		end
	end
	return false
end

local function removeThief(thief)
	thief.alive = false
	if thieves[thief.player] == thief then
		thieves[thief.player] = nil
	end
	thief.model:Destroy()
end

-- Send one Sneaky Clown at a player's booth. staySeconds holds him at a locked gate (the tour frames it);
-- fromSide picks the end of the street he comes from (-1 west, 1 east).
function ThiefRaids.sendThief(player: Player, staySeconds: number?, fromSide: number?)
	local state = PlayerState.get(player)
	if not state or state.booth == 0 then
		return nil
	end
	ThiefRaids.dismissThief(player)
	local side = fromSide or (random:NextNumber() > 0.5 and 1 or -1)
	local booth = state.booth
	local thief = { player = player, alive = true, catchable = false, model = buildClown(), position = GameConfig.boothPoint(booth, -13, side * 58, 0), facing = Vector3.new(-side, 0, 0) }
	thieves[player] = thief
	placeThief(thief, thief.facing)
	thief.model.Parent = Workspace
	services.notify(player, "thief", {})
	task.spawn(function()
		local specs = GameConfig.THIEF
		local street = GameConfig.boothPoint(booth, -13, side * 58, 0)
		if not walkTo(thief, GameConfig.boothPoint(booth, -7, 0, 0), specs.walkSpeed) then
			return removeThief(thief)
		end
		if services.GateLock.isLocked(player) then
			-- Bounced: he recoils from the lasers and slinks off empty-handed.
			setStatus(thief, "BLOCKED BY LOCK!")
			services.notify(player, "blocked", {})
			local _, dir = GameConfig.boothOrigin(booth)
			placeThief(thief, Vector3.new(-side * 0.7, 0, -dir))
			thief.model:PivotTo(thief.model:GetPivot() * CFrame.Angles(math.rad(-14), 0, 0))
			task.wait(staySeconds or 1.6)
			walkTo(thief, street, specs.fleeSpeed + 6)
			return removeThief(thief)
		end
		local slot = services.BasePedestals.mostValuableSlot(player)
		if not slot then
			setStatus(thief, "NOTHING TO STEAL...")
			task.wait(1.5)
			walkTo(thief, street, specs.walkSpeed)
			return removeThief(thief)
		end
		thief.catchable = true
		setStatus(thief, "STEALING! BONK HIM!")
		local pedestal = GameConfig.pedestalPoint(booth, slot)
		local carpet = Vector3.new(GameConfig.boothPoint(booth, 0, 0, 0).X, 0, pedestal.Z)
		if not (walkTo(thief, GameConfig.boothPoint(booth, 4, 0, 0), specs.walkSpeed) and walkTo(thief, carpet, specs.walkSpeed)) then
			return removeThief(thief)
		end
		local item = state.placed[slot]
		if item and not item.stolen then
			item.stolen = true
			thief.loot = item
			thief.slot = slot
			services.IncomeTicker.recomputeIncome(player)
			services.notify(player, "stealing", { name = BrainrotCatalog.byId[item.id].name })
			setStatus(thief, "GOT IT! CATCH ME!")
		end
		local escaped = walkTo(thief, GameConfig.boothPoint(booth, -7, 0, 0), specs.fleeSpeed) and walkTo(thief, GameConfig.boothPoint(booth, -13, side * 150, 0), specs.fleeSpeed)
		if escaped and thief.loot then
			local lost = thief.loot
			lost.model:Destroy()
			if state.placed[slot] == lost then
				state.placed[slot] = nil
			end
			services.IncomeTicker.recomputeIncome(player)
			services.notify(player, "stolen", { name = BrainrotCatalog.byId[lost.id].name })
		end
		removeThief(thief)
	end)
	return thief
end

function ThiefRaids.dismissThief(player: Player)
	local thief = thieves[player]
	if thief then
		if thief.loot then
			thief.loot.stolen = nil
			thief.loot = nil
		end
		removeThief(thief)
	end
end

function ThiefRaids.init(shared)
	services = shared
end

-- Raid each player on their own timer, once they own something worth stealing.
function ThiefRaids.runRaidLoop()
	local nextRaid = {}
	while true do
		task.wait(2)
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			nextRaid[player] = nextRaid[player] or (now + GameConfig.THIEF.firstAfter)
			if not ThiefRaids.paused and now >= nextRaid[player] and not thieves[player] then
				nextRaid[player] = now + random:NextNumber(GameConfig.THIEF.minGap, GameConfig.THIEF.maxGap)
				if services.BasePedestals.mostValuableSlot(player) then
					ThiefRaids.sendThief(player)
				end
			end
		end
	end
end

return ThiefRaids
