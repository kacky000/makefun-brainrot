--!strict
-- Clown thief raids: every so often a Sneaky Clown sneaks off the Midway toward a booth, grabs a brainrot
-- from an unlocked booth and runs for the street. A locked gate bounces it; any player who touches it bonks
-- it and the brainrot hops back onto its pedestal; if it reaches the end of the Midway the brainrot is gone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local BrainrotModels = require(ReplicatedStorage:WaitForChild("BrainrotModels"))

type Raid = {
	model: Model,
	victim: Player,
	loot: { id: string, mut: string? }?,
	lootModel: Model?,
	bonked: boolean,
}

local ThiefRaids = {}

local services: { [string]: any } = {}
local Remotes: Folder
local raids: { Raid } = {}
local rng = Random.new()

local function notify(player: Player, text: string, color: Color3?)
	(Remotes :: any).Notify:FireClient(player, text, color or Color3.fromRGB(255, 255, 255))
end

-- A Sneaky Clown: striped onesie, white face, red nose, burglar mask, green hair and a loot sack.
function ThiefRaids.buildThief(): Model
	local model = Instance.new("Model")
	model.Name = "SneakyClown"
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2, 0.2, 2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.Parent = model
	model.PrimaryPart = root
	local function piece(shape: Enum.PartType, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?)
		local p = Instance.new("Part")
		p.Shape = shape
		p.Size = size
		p.CFrame = root.CFrame * offset
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = false
		p.CanCollide = false
		p.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = p
		weld.Parent = p
		p.Parent = model
	end
	local purple = Color3.fromRGB(120, 50, 170)
	local yellow = Color3.fromRGB(255, 220, 60)
	piece(Enum.PartType.Block, Vector3.new(0.8, 2.2, 0.8), CFrame.new(-0.6, 1.1, 0), purple)
	piece(Enum.PartType.Block, Vector3.new(0.8, 2.2, 0.8), CFrame.new(0.6, 1.1, 0), yellow)
	piece(Enum.PartType.Block, Vector3.new(1.2, 0.6, 1.6), CFrame.new(-0.6, 0.3, -0.4), Color3.fromRGB(255, 60, 60))
	piece(Enum.PartType.Block, Vector3.new(1.2, 0.6, 1.6), CFrame.new(0.6, 0.3, -0.4), Color3.fromRGB(255, 60, 60))
	piece(Enum.PartType.Block, Vector3.new(2.4, 2.4, 1.4), CFrame.new(0, 3.4, 0), purple)
	piece(Enum.PartType.Block, Vector3.new(2.45, 0.5, 1.45), CFrame.new(0, 3.0, 0), yellow)
	piece(Enum.PartType.Block, Vector3.new(2.45, 0.5, 1.45), CFrame.new(0, 3.9, 0), yellow)
	piece(Enum.PartType.Ball, Vector3.one * 2.4, CFrame.new(0, 5.6, 0), Color3.fromRGB(250, 250, 250))
	piece(Enum.PartType.Block, Vector3.new(2.3, 0.55, 0.4), CFrame.new(0, 5.9, -1.0), Color3.fromRGB(20, 20, 25))
	piece(Enum.PartType.Ball, Vector3.one * 0.7, CFrame.new(0, 5.4, -1.25), Color3.fromRGB(255, 30, 40))
	piece(Enum.PartType.Ball, Vector3.one * 1.2, CFrame.new(-1.1, 6.4, 0.1), Color3.fromRGB(60, 220, 90))
	piece(Enum.PartType.Ball, Vector3.one * 1.2, CFrame.new(1.1, 6.4, 0.1), Color3.fromRGB(60, 220, 90))
	piece(Enum.PartType.Ball, Vector3.one * 2.0, CFrame.new(0, 4.0, 1.3), Color3.fromRGB(170, 130, 80))
	piece(Enum.PartType.Block, Vector3.new(1.8, 0.25, 0.2), CFrame.new(0, 4.9, -1.1), Color3.fromRGB(200, 30, 60))

	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromScale(8, 2)
	tag.StudsOffset = Vector3.new(0, 8.2, 0)
	tag.MaxDistance = 160
	tag.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = "SNEAKY CLOWN · THIEF!"
	label.TextColor3 = Color3.fromRGB(255, 70, 90)
	label.TextStrokeTransparency = 0
	label.Parent = tag
	tag.Parent = root
	return model
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Pops the clown in a puff of confetti; any loot hops back home.
function ThiefRaids.bonkThief(raid: Raid, bonker: Player?)
	if raid.bonked then
		return
	end
	raid.bonked = true
	local root = raid.model.PrimaryPart :: BasePart
	local puff = Instance.new("ParticleEmitter")
	puff.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	puff.Rate = 0
	puff.Speed = NumberRange.new(14, 24)
	puff.SpreadAngle = Vector2.new(180, 180)
	puff.Color = ColorSequence.new(Color3.fromRGB(255, 90, 200), Color3.fromRGB(255, 230, 80))
	puff.Size = NumberSequence.new(1)
	puff.Parent = root
	puff:Emit(60)
	if raid.loot then
		local def = BrainrotCatalog.get(raid.loot.id)
		if services.BasePedestals.placeOnPedestal(raid.victim, raid.loot.id, raid.loot.mut) and def then
			notify(raid.victim, "BONK! " .. def.name .. " is back on its pedestal!", Color3.fromRGB(120, 255, 140))
		end
		raid.loot = nil
	end
	if bonker then
		local tip = 50 + math.floor((services.PlayerData.get(bonker) or { incomePerSec = 0 }).incomePerSec * 5)
		services.PlayerData.addCash(bonker, tip)
		notify(bonker, "BONK! Clown caught: +" .. GameConfig.money(tip) .. " reward", Color3.fromRGB(255, 225, 80));
		(Remotes :: any).Sfx:FireClient(bonker, "bonk")
	end
	task.delay(0.4, function()
		raid.model:Destroy()
	end)
end

-- Walks the clown to a point; false if it was bonked on the way.
local function walkTo(raid: Raid, target: Vector3, speed: number): boolean
	local root = raid.model.PrimaryPart :: BasePart
	while not raid.bonked and raid.model.Parent do
		local dt = RunService.Heartbeat:Wait()
		local pos = root.Position
		local flat = Vector3.new(target.X, pos.Y, target.Z)
		local delta = flat - pos
		if delta.Magnitude < 0.6 then
			return true
		end
		local step = math.min(delta.Magnitude, speed * dt)
		local nextPos = pos + delta.Unit * step
		local hop = math.abs(math.sin(os.clock() * 12)) * 0.5
		raid.model:PivotTo(CFrame.lookAt(Vector3.new(nextPos.X, hop, nextPos.Z), Vector3.new(flat.X, hop, flat.Z)))
		for _, player in Players:GetPlayers() do
			local r = rootOf(player)
			if r and (r.Position - root.Position).Magnitude < 6 then
				ThiefRaids.bonkThief(raid, player)
				return false
			end
		end
	end
	return false
end

function ThiefRaids.startRaid(victim: Player, forcedSlot: number?): Raid?
	local profile = services.PlayerData.get(victim)
	local plot = services.BasePedestals.plotOf(victim)
	if not profile or not plot then
		return nil
	end
	local model = ThiefRaids.buildThief()
	local entryX = if plot.gate.Position.X > 0 then 190 else -190
	model:PivotTo(CFrame.new(entryX, 0, 0))
	model.Parent = workspace
	local raid: Raid = { model = model, victim = victim, loot = nil, lootModel = nil, bonked = false }
	table.insert(raids, raid)
	notify(victim, "A SNEAKY CLOWN is heading for your booth! LOCK the gate or bonk it!", Color3.fromRGB(255, 80, 100));
	(Remotes :: any).Sfx:FireClient(victim, "alarm")

	task.spawn(function()
		local outside = plot.gate.Position - plot.inward * 6
		if not walkTo(raid, Vector3.new(outside.X, 0, 0), GameConfig.THIEF_WALK_SPEED) then
			return
		end
		if not walkTo(raid, outside, GameConfig.THIEF_WALK_SPEED) then
			return
		end
		if services.GateLock.isLocked(victim) then
			notify(victim, "Your LOCK stopped the Sneaky Clown!", Color3.fromRGB(120, 255, 140))
			walkTo(raid, Vector3.new(entryX, 0, 0), GameConfig.THIEF_RUN_SPEED)
			if not raid.bonked then
				model:Destroy()
			end
			return
		end
		-- Pick the most valuable pedestal (or the forced one) and sneak to it.
		local bestSlot: number? = forcedSlot
		if not bestSlot then
			local bestIncome = -1
			for slotIndex, slot in profile.slots do
				local def = BrainrotCatalog.get(slot.id)
				if def and def.income > bestIncome then
					bestIncome = def.income
					bestSlot = slotIndex
				end
			end
		end
		if not bestSlot then
			walkTo(raid, Vector3.new(entryX, 0, 0), GameConfig.THIEF_RUN_SPEED)
			model:Destroy()
			return
		end
		local target = services.BasePedestals.pedestalCFrame(plot, bestSlot).Position
		if not walkTo(raid, target - plot.inward * 3, GameConfig.THIEF_WALK_SPEED) then
			return
		end
		local loot = services.BasePedestals.takeFromPedestal(victim, bestSlot)
		if not loot then
			walkTo(raid, Vector3.new(entryX, 0, 0), GameConfig.THIEF_RUN_SPEED)
			model:Destroy()
			return
		end
		raid.loot = loot
		local def = BrainrotCatalog.get(loot.id)
		if def then
			local lootModel = BrainrotModels.build(def, loot.mut)
			local lootRoot = lootModel.PrimaryPart :: BasePart
			lootRoot.Anchored = false
			lootModel:PivotTo((model.PrimaryPart :: BasePart).CFrame * CFrame.new(0, 7.2, 0))
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = model.PrimaryPart
			weld.Part1 = lootRoot
			weld.Parent = lootRoot
			lootModel.Parent = model
			raid.lootModel = lootModel
			notify(victim, "The clown grabbed your " .. def.name .. "! CATCH IT!", Color3.fromRGB(255, 60, 80));
			(Remotes :: any).Sfx:FireClient(victim, "stolen")
		end
		if not walkTo(raid, outside, GameConfig.THIEF_RUN_SPEED) then
			return
		end
		if not walkTo(raid, Vector3.new(outside.X, 0, 0), GameConfig.THIEF_RUN_SPEED) then
			return
		end
		if not walkTo(raid, Vector3.new(entryX + (if entryX > 0 then 20 else -20), 0, 0), GameConfig.THIEF_RUN_SPEED) then
			return
		end
		if raid.loot and def then
			notify(victim, "The clown escaped with your " .. def.name .. "... lock your gate next time!", Color3.fromRGB(255, 120, 80))
		end
		raid.loot = nil
		model:Destroy()
	end)
	return raid
end

function ThiefRaids.activeRaids(): { Raid }
	return raids
end

function ThiefRaids.init(all: { [string]: any })
	services = all
	Remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function ThiefRaids.start()
	task.spawn(function()
		while true do
			task.wait(GameConfig.RAID_EVERY + rng:NextNumber(-10, 10))
			for index = #raids, 1, -1 do
				if not raids[index].model.Parent then
					table.remove(raids, index)
				end
			end
			local candidates = {}
			for player, profile in services.PlayerData.all() do
				if services.PlayerData.usedPedestals(profile) >= 2 then
					table.insert(candidates, player)
				end
			end
			if #candidates > 0 then
				ThiefRaids.startRaid(candidates[rng:NextInteger(1, #candidates)])
			end
		end
	end)
end

return ThiefRaids
