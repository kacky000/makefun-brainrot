-- ThiefRaids: the Sneaky Clown. Every so often he tiptoes to a player's booth for their best brainrot.
-- A LOCKED gate bounces him ("BLOCKED BY LOCK!"). An open one lets him grab it and run for the exit: touch him to
-- bonk him, get the brainrot back and earn a reward; let him escape and it is gone.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.GameConfig)
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local PlayerState = require(script.Parent.Parent.State.PlayerState)
local BrainrotModels = require(script.Parent.Parent.World.BrainrotModels)
local BasePedestals = require(script.Parent.Parent.Economy.BasePedestals)
local GateLock = require(script.Parent.GateLock)

local ThiefRaids = {}
local raiding = false
ThiefRaids.frozen = false -- TourDirector holds the clown still for a screenshot
ThiefRaids.clown = nil :: Model?

local function piece(m: Model, shape: Enum.PartType, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.Parent = m
	return p
end

local function buildSneakyClown(): Model
	local m = Instance.new("Model")
	m.Name = "SneakyClown"
	local white, red, black = Color3.fromRGB(250, 250, 250), Color3.fromRGB(235, 50, 60), Color3.fromRGB(30, 26, 36)
	local ball, block, tube = Enum.PartType.Ball, Enum.PartType.Block, Enum.PartType.Cylinder
	local up = CFrame.Angles(0, 0, math.pi / 2)
	for i = -1, 1, 2 do
		piece(m, block, Vector3.new(2.2, 0.8, 3.6), CFrame.new(i * 1.1, 0.4, -0.7), red)
		for j = 0, 3 do
			piece(m, tube, Vector3.new(0.6, 1, 1), CFrame.new(i * 1.1, 1.1 + j * 0.6, 0) * up, if j % 2 == 0 then black else white)
		end
		piece(m, tube, Vector3.new(2.6, 0.9, 0.9), CFrame.new(i * 2.9, 5.6, -0.6) * CFrame.Angles(0, 0, i * math.rad(30)), black)
		piece(m, ball, Vector3.new(1.4, 1.4, 1.4), CFrame.new(i * 4.0, 6.3, -0.8), white)
		piece(m, ball, Vector3.new(2.6, 2.6, 2.6), CFrame.new(i * 2.0, 10.2, 0.2), Color3.fromRGB(80, 220, 120))
		piece(m, ball, Vector3.new(1.3, 1.3, 1.3), CFrame.new(i * 0.75, 9.3, -1.55), white)
		piece(m, ball, Vector3.new(0.6, 0.6, 0.6), CFrame.new(i * 0.7, 9.25, -2.1), black)
	end
	piece(m, ball, Vector3.new(5, 5, 5), CFrame.new(0, 5.4, 0), black)
	for i = 0, 2 do
		piece(m, ball, Vector3.new(0.9, 0.9, 0.9), CFrame.new(0, 4.2 + i * 1.2, -2.3), Color3.fromRGB(255, 220, 70), Enum.Material.Neon)
	end
	piece(m, ball, Vector3.new(3.8, 3.8, 3.8), CFrame.new(0, 9.2, 0), white)
	piece(m, block, Vector3.new(3.9, 0.9, 1.2), CFrame.new(0, 9.35, -1.45), black) -- the burglar mask
	piece(m, ball, Vector3.new(1.3, 1.3, 1.3), CFrame.new(0, 8.7, -2.0), red, Enum.Material.Neon)
	piece(m, block, Vector3.new(1.8, 0.35, 0.3), CFrame.new(0, 7.9, -1.6), red)
	piece(m, tube, Vector3.new(0.3, 3.6, 3.6), CFrame.new(0, 11.2, 0) * up, black)
	piece(m, tube, Vector3.new(2, 2.2, 2.2), CFrame.new(0, 12.2, 0) * up, black)
	piece(m, ball, Vector3.new(3.4, 3.4, 3.4), CFrame.new(0, 5.2, 2.6), Color3.fromRGB(190, 150, 90)) -- the loot sack
	local root = piece(m, block, Vector3.new(5, 13, 4), CFrame.new(0, 6.5, 0), white)
	root.Name = "Root"
	root.Transparency = 1
	root.Anchored = true
	for _, part in m:GetChildren() do
		if part ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = part
			weld.Parent = part
		end
	end
	m.PrimaryPart = root
	local tag = Instance.new("BillboardGui")
	tag.Name = "Tag"
	tag.Size = UDim2.fromScale(18, 3.4)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 9.5, 0)
	tag.LightInfluence = 0
	tag.MaxDistance = 220
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.LuckiestGuy
	text.Text = "SNEAKY CLOWN"
	text.TextColor3 = Color3.fromRGB(255, 80, 90)
	text.TextScaled = true
	text.TextStrokeTransparency = 0
	text.Parent = tag
	tag.Parent = root
	return m
end

-- walkTo: glide the clown to a point with a tiptoe bob. Returns true when a player got close enough to bonk him.
local function walkTo(clown: Model, goal: Vector3, speed: number, loot: Model?): boolean
	local feet = clown:GetPivot().Position - Vector3.new(0, 6.5, 0)
	local t = 0
	while true do
		local dt = RunService.Heartbeat:Wait()
		if not ThiefRaids.frozen then
			t += dt
			local flat = Vector3.new(goal.X - feet.X, 0, goal.Z - feet.Z)
			if flat.Magnitude < 0.6 then
				return false
			end
			feet += flat.Unit * math.min(flat.Magnitude, speed * dt)
			local bob = math.abs(math.sin(t * 9)) * 0.9
			clown:PivotTo(CFrame.lookAt(feet + Vector3.new(0, 6.5 + bob, 0), feet + Vector3.new(0, 6.5 + bob, 0) + flat.Unit))
			if loot then
				loot:PivotTo(CFrame.new(feet + Vector3.new(0, 15.5 + bob, 0)) * CFrame.Angles(0, t * 3, 0))
			end
			for _, player in Players:GetPlayers() do
				local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if rootPart and (rootPart.Position - feet).Magnitude < GameConfig.THIEF.bonkRange then
					return true
				end
			end
		end
	end
end

local function say(clown: Model, text: string, color: Color3)
	local label = clown.PrimaryPart.Tag.Text
	label.Text = text
	label.TextColor3 = color
end

function ThiefRaids.sendThief(target: Player?): string -- Sneaky Clown raid: "blocked" | "bonked" | "escaped" | "none"
	if raiding then
		return "none"
	end
	local owner = target
	if not owner then
		local marks = {}
		for _, player in Players:GetPlayers() do
			if PlayerState.get(player) and BasePedestals.boothOf(player) and BasePedestals.countBrainrots(player) >= GameConfig.THIEF.minBrainrots then
				table.insert(marks, player)
			end
		end
		owner = marks[math.random(1, math.max(1, #marks))]
	end
	if not owner or not BasePedestals.boothOf(owner) then
		return "none"
	end
	raiding = true
	local T = GameConfig.THIEF
	local booth = BasePedestals.boothOf(owner)
	local laneZ = booth.spec.side * 9
	local clown = buildSneakyClown()
	ThiefRaids.clown = clown
	clown:PivotTo(CFrame.new(GameConfig.STREET.xMin + 14, 6.5, laneZ))
	clown.Parent = Workspace
	PlayerState.notify(owner, "ThiefWarning", {})
	Workspace:SetAttribute("ThiefTarget", owner.Name)

	local outcome = "escaped"
	local loot: Model? = nil
	local held, slot = nil, nil
	local function finish(result: string)
		outcome = result
	end

	local bonked = walkTo(clown, Vector3.new(booth.spec.x, 0, laneZ), T.speed)
	bonked = bonked or walkTo(clown, BasePedestals.gatePoint(owner, -5), T.speed)
	if bonked then
		finish("bonked")
	elseif GateLock.isLocked(owner) then
		say(clown, "BLOCKED BY LOCK!", Color3.fromRGB(255, 230, 80))
		PlayerState.notify(owner, "ThiefBlocked", {})
		local hold = 0
		while hold < 1.6 or ThiefRaids.frozen do
			hold += RunService.Heartbeat:Wait()
		end
		walkTo(clown, Vector3.new(GameConfig.STREET.xMin + 10, 0, laneZ), T.escapeSpeed)
		finish("blocked")
	else
		slot = BasePedestals.mostValuableSlot(owner)
		if slot and not walkTo(clown, BasePedestals.gatePoint(owner, 6), T.speed) then
			local spot = BasePedestals.pedestalPosition(owner, slot)
			local towardCarpet = Vector3.new(booth.spec.x + (spot.X - booth.spec.x) * 0.45, 0, spot.Z)
			if not walkTo(clown, towardCarpet, T.speed) then
				held = BasePedestals.removeBrainrot(owner, slot)
			end
		end
		if held then
			say(clown, "GOT YOUR " .. string.upper(BrainrotCatalog.byId[held.id].name) .. "!", Color3.fromRGB(255, 80, 90))
			loot = BrainrotModels.buildBrainrot(held.id, held.mutation)
			loot.Parent = Workspace
			PlayerState.notify(owner, "ThiefGrabbed", { name = BrainrotCatalog.byId[held.id].name })
			local caught = walkTo(clown, BasePedestals.gatePoint(owner, 4), T.escapeSpeed, loot)
			caught = caught or walkTo(clown, BasePedestals.gatePoint(owner, -6), T.escapeSpeed, loot)
			caught = caught or walkTo(clown, Vector3.new(GameConfig.STREET.xMax - 14, 0, laneZ), T.escapeSpeed, loot)
			finish(if caught then "bonked" else "escaped")
		else
			finish("bonked")
		end
	end

	if outcome == "bonked" then
		local reward = 25
		if held and PlayerState.get(owner) then
			local s = PlayerState.get(owner)
			s.slots[slot] = held
			BasePedestals.showSlot(owner, slot)
			PlayerState.mirror(owner)
			reward = math.floor(BrainrotCatalog.byId[held.id].price * T.bonkReward)
		end
		if PlayerState.get(owner) then
			PlayerState.addCash(owner, reward)
			PlayerState.notify(owner, "ThiefBonked", { reward = reward, name = held and BrainrotCatalog.byId[held.id].name })
		end
		say(clown, "BONK!", Color3.fromRGB(255, 230, 80))
		for i = 1, 20 do
			clown:PivotTo(clown:GetPivot() * CFrame.Angles(0, 0.9, 0) + Vector3.new(0, 0.5, 0))
			task.wait(0.03)
		end
	elseif outcome == "escaped" and held and PlayerState.get(owner) then
		PlayerState.notify(owner, "Stolen", { name = BrainrotCatalog.byId[held.id].name, by = "THE SNEAKY CLOWN" })
	end
	if loot then
		loot:Destroy()
	end
	clown:Destroy()
	ThiefRaids.clown = nil
	Workspace:SetAttribute("ThiefTarget", "")
	raiding = false
	return outcome
end

function ThiefRaids.start()
	Workspace:SetAttribute("ThiefTarget", "")
	task.spawn(function()
		task.wait(GameConfig.THIEF.first)
		while true do
			ThiefRaids.sendThief()
			task.wait(GameConfig.THIEF.every)
		end
	end)
end

return ThiefRaids
