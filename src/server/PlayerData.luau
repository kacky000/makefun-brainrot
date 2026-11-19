--!strict
-- The one place player state lives: cash, rebirths, upgrades, what stands on each pedestal, what the
-- player carries and which brainrots they have discovered. Every change goes through these functions,
-- which then publish the numbers to the player's attributes for the HUD. Saves to a DataStore when one
-- is reachable and plays on without saving when it is not (an unpublished Studio file).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local MutationRoller = require(ReplicatedStorage:WaitForChild("MutationRoller"))

export type Slot = { id: string, mut: string? }
export type Carry = { id: string, mut: string?, fromUserId: number?, fromSlot: number?, source: string }
export type Profile = {
	cash: number,
	earned: number,
	rebirths: number,
	pedestals: number,
	speedLevel: number,
	lockLevel: number,
	slots: { [number]: Slot },
	discovered: { [string]: boolean },
	lockUntil: number,
	lockCooldownUntil: number,
	carrying: Carry?,
	incomePerSec: number,
	plotIndex: number,
	loaded: boolean,
}

local PlayerData = {}

local services: { [string]: any } = {}
local profiles: { [Player]: Profile } = {}
local readyCallbacks: { (Player, Profile) -> () } = {}
local leaveCallbacks: { (Player) -> () } = {}
local store: DataStore? = nil

local function newProfile(): Profile
	return {
		cash = GameConfig.START_CASH,
		earned = 0,
		rebirths = 0,
		pedestals = GameConfig.BASE_PEDESTALS,
		speedLevel = 1,
		lockLevel = 1,
		slots = {},
		discovered = {},
		lockUntil = 0,
		lockCooldownUntil = 0,
		carrying = nil,
		incomePerSec = 0,
		plotIndex = 0,
		loaded = false,
	}
end

function PlayerData.init(all: { [string]: any })
	services = all
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(GameConfig.DATASTORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[PlayerData] no DataStore here, playing without saves: " .. tostring(result))
	end
end

local function serialize(profile: Profile)
	local slots = {}
	for index, slot in profile.slots do
		slots[tostring(index)] = { slot.id, slot.mut or "" }
	end
	local discovered = {}
	for id in profile.discovered do
		table.insert(discovered, id)
	end
	return {
		v = 1,
		cash = profile.cash,
		earned = profile.earned,
		rebirths = profile.rebirths,
		pedestals = profile.pedestals,
		speedLevel = profile.speedLevel,
		lockLevel = profile.lockLevel,
		slots = slots,
		discovered = discovered,
	}
end

local function deserialize(data: any, profile: Profile)
	if type(data) ~= "table" then
		return
	end
	profile.cash = tonumber(data.cash) or profile.cash
	profile.earned = tonumber(data.earned) or 0
	profile.rebirths = tonumber(data.rebirths) or 0
	profile.pedestals = math.clamp(tonumber(data.pedestals) or GameConfig.BASE_PEDESTALS, GameConfig.BASE_PEDESTALS, GameConfig.MAX_PEDESTALS)
	profile.speedLevel = math.clamp(tonumber(data.speedLevel) or 1, 1, #GameConfig.SPEED_LEVELS)
	profile.lockLevel = math.clamp(tonumber(data.lockLevel) or 1, 1, #GameConfig.LOCK_LEVELS)
	if type(data.slots) == "table" then
		for key, value in data.slots do
			local index = tonumber(key)
			if index and type(value) == "table" and BrainrotCatalog.get(value[1]) then
				profile.slots[index] = { id = value[1], mut = if value[2] == "" then nil else value[2] }
			end
		end
	end
	if type(data.discovered) == "table" then
		for _, id in data.discovered do
			if BrainrotCatalog.get(id) then
				profile.discovered[id] = true
			end
		end
	end
end

function PlayerData.loadProfile(player: Player): Profile
	local profile = newProfile()
	if store then
		local ok, data = pcall(function()
			return (store :: DataStore):GetAsync("p_" .. player.UserId)
		end)
		if ok then
			deserialize(data, profile)
		else
			warn("[PlayerData] load failed, fresh profile: " .. tostring(data))
		end
	end
	profile.loaded = true
	return profile
end

function PlayerData.saveProfile(player: Player)
	local profile = profiles[player]
	if not (store and profile and profile.loaded) then
		return
	end
	local payload = serialize(profile)
	local ok, err = pcall(function()
		(store :: DataStore):SetAsync("p_" .. player.UserId, payload)
	end)
	if not ok then
		warn("[PlayerData] save failed: " .. tostring(err))
	end
end

function PlayerData.get(player: Player): Profile?
	return profiles[player]
end

function PlayerData.all(): { [Player]: Profile }
	return profiles
end

function PlayerData.onProfileReady(callback: (Player, Profile) -> ())
	table.insert(readyCallbacks, callback)
	for player, profile in profiles do
		task.spawn(callback, player, profile)
	end
end

function PlayerData.onLeave(callback: (Player) -> ())
	table.insert(leaveCallbacks, callback)
end

-- Income multiplier from rebirths alone (events multiply on top, in IncomeTicker).
function PlayerData.rebirthMultiplier(profile: Profile): number
	return 1 + profile.rebirths * GameConfig.REBIRTH_INCOME_BONUS
end

function PlayerData.luck(profile: Profile): number
	return 1 + profile.rebirths * GameConfig.REBIRTH_LUCK_BONUS
end

function PlayerData.baseIncome(profile: Profile): number
	local total = 0
	for _, slot in profile.slots do
		local def = BrainrotCatalog.get(slot.id)
		if def then
			total += def.income * MutationRoller.multiplier(slot.mut)
		end
	end
	return total
end

function PlayerData.usedPedestals(profile: Profile): number
	local used = 0
	for index in profile.slots do
		if index <= profile.pedestals then
			used += 1
		end
	end
	return used
end

function PlayerData.firstFreePedestal(profile: Profile): number?
	for index = 1, profile.pedestals do
		if profile.slots[index] == nil then
			return index
		end
	end
	return nil
end

function PlayerData.addCash(player: Player, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.cash += amount
	if amount > 0 then
		profile.earned += amount
	end
	PlayerData.publish(player)
end

function PlayerData.trySpend(player: Player, amount: number): boolean
	local profile = profiles[player]
	if not profile or profile.cash < amount then
		return false
	end
	profile.cash -= amount
	PlayerData.publish(player)
	return true
end

function PlayerData.setSlot(player: Player, index: number, slot: Slot?)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.slots[index] = slot
	if slot then
		PlayerData.markDiscovered(player, slot.id)
	end
	PlayerData.publish(player)
end

function PlayerData.setCarrying(player: Player, carry: Carry?)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.carrying = carry
	if carry then
		PlayerData.markDiscovered(player, carry.id)
	end
	PlayerData.publish(player)
end

-- Returns true the first time this player meets this brainrot (a new Index entry).
function PlayerData.markDiscovered(player: Player, id: string): boolean
	local profile = profiles[player]
	if not profile or profile.discovered[id] then
		return false
	end
	profile.discovered[id] = true
	local def = BrainrotCatalog.get(id)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if def and remotes then
		(remotes :: any).Notify:FireClient(player, "NEW INDEX ENTRY: " .. def.name .. "!", BrainrotCatalog.rarity(def.rarity).color)
	end
	return true
end

function PlayerData.nextPedestalCost(profile: Profile): number
	local bought = profile.pedestals - GameConfig.BASE_PEDESTALS
	return math.floor(GameConfig.PEDESTAL_COST_BASE * GameConfig.PEDESTAL_COST_GROWTH ^ bought)
end

function PlayerData.rebirthCost(profile: Profile): number
	return GameConfig.REBIRTH_BASE_COST * GameConfig.REBIRTH_GROWTH ^ profile.rebirths
end

-- Pushes the profile to the player's attributes; the HUD reads nothing else.
function PlayerData.publish(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local found = 0
	local ids = {}
	for id in profile.discovered do
		found += 1
		table.insert(ids, id)
	end
	local carryName = ""
	local carryRarity = ""
	if profile.carrying then
		local def = BrainrotCatalog.get(profile.carrying.id)
		if def then
			local mutation = MutationRoller.get(profile.carrying.mut)
			carryName = (if mutation then mutation.tag .. " " else "") .. def.name
			carryRarity = def.rarity
		end
	end
	player:SetAttribute("Cash", profile.cash)
	player:SetAttribute("IncomePerSec", profile.incomePerSec)
	player:SetAttribute("Rebirths", profile.rebirths)
	player:SetAttribute("IncomeMultiplier", PlayerData.rebirthMultiplier(profile))
	player:SetAttribute("Pedestals", profile.pedestals)
	player:SetAttribute("PedestalsUsed", PlayerData.usedPedestals(profile))
	player:SetAttribute("SpeedLevel", profile.speedLevel)
	player:SetAttribute("LockLevel", profile.lockLevel)
	player:SetAttribute("LockUntil", profile.lockUntil)
	player:SetAttribute("LockCooldownUntil", profile.lockCooldownUntil)
	player:SetAttribute("NextPedestalCost", if profile.pedestals < GameConfig.MAX_PEDESTALS then PlayerData.nextPedestalCost(profile) else -1)
	player:SetAttribute("NextSpeedCost", GameConfig.SPEED_COSTS[profile.speedLevel + 1] or -1)
	player:SetAttribute("NextLockCost", GameConfig.LOCK_COSTS[profile.lockLevel + 1] or -1)
	player:SetAttribute("LockSeconds", GameConfig.LOCK_LEVELS[profile.lockLevel])
	player:SetAttribute("RebirthCost", PlayerData.rebirthCost(profile))
	player:SetAttribute("Carrying", carryName)
	player:SetAttribute("CarryingRarity", carryRarity)
	player:SetAttribute("IndexFound", found)
	player:SetAttribute("Discovered", table.concat(ids, ","))
	player:SetAttribute("PlotIndex", profile.plotIndex)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		(leaderstats :: any).Cash.Value = GameConfig.money(profile.cash);
		(leaderstats :: any).Rebirths.Value = profile.rebirths
	end
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = leaderstats
	leaderstats.Parent = player

	local profile = PlayerData.loadProfile(player)
	if not player.Parent then
		return
	end
	profiles[player] = profile
	PlayerData.publish(player)
	for _, callback in readyCallbacks do
		task.spawn(callback, player, profile)
	end
end

local function onPlayerRemoving(player: Player)
	for _, callback in leaveCallbacks do
		pcall(callback, player)
	end
	PlayerData.saveProfile(player)
	profiles[player] = nil
end

function PlayerData.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	task.spawn(function()
		while true do
			task.wait(GameConfig.SAVE_EVERY)
			for player in profiles do
				task.spawn(PlayerData.saveProfile, player)
			end
		end
	end)
	game:BindToClose(function()
		for player in profiles do
			PlayerData.saveProfile(player)
		end
	end)
end

return PlayerData
