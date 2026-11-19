-- PlayerState: the one place a player's game state lives on the server: cash, rebirths, upgrade
-- levels, discovered brainrots, the brainrots on their pedestals, what they carry and their gate
-- lock. Every service reads and writes through here; `publish` mirrors it to Player attributes
-- for the HUD. Saves to a DataStore on a published server and runs without one in Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local GameConfig = require(ReplicatedStorage.GameConfig)
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)

local PlayerState = {}

export type Brainrot = { id: string, mutation: string?, model: Model? }
export type State = {
	cash: number,
	rebirths: number,
	upgrades: { [string]: number },
	discovered: { [string]: boolean },
	pedestals: { [number]: Brainrot },
	carrying: Brainrot?,
	booth: number?,
	lockUntil: number,
	lockReadyAt: number,
	income: number,
	stolen: number,
	bonks: number,
}

local states: { [Player]: State } = {}
local store = nil
local services = nil

-- Adds cash (income, sales, bonk rewards) and republishes.
function PlayerState.addCash(player: Player, amount: number)
	local state = states[player]
	if state then
		state.cash += amount
		player:SetAttribute("Cash", state.cash)
	end
end

-- Takes `amount` only if the player can afford it. The server is the only place cash changes.
function PlayerState.trySpend(player: Player, amount: number): boolean
	local state = states[player]
	if not state or state.cash < amount then
		return false
	end
	state.cash -= amount
	player:SetAttribute("Cash", state.cash)
	return true
end

function PlayerState.get(player: Player): State?
	return states[player]
end

function PlayerState.all(): { [Player]: State }
	return states
end

function PlayerState.markDiscovered(player: Player, brainrotId: string): boolean
	local state = states[player]
	if not state or state.discovered[brainrotId] then
		return false
	end
	state.discovered[brainrotId] = true
	PlayerState.publish(player)
	return true
end

function PlayerState.pedestalCapacity(player: Player): number
	local state = states[player]
	return if state then GameConfig.upgradeValue("Pedestals", state.upgrades.Pedestals) else 0
end

-- Mirrors the state to attributes the HUD listens to.
function PlayerState.publish(player: Player)
	local state = states[player]
	if not state then
		return
	end
	local index = table.create(BrainrotCatalog.COUNT, "0")
	local found = 0
	for order, entry in BrainrotCatalog.LIST do
		if state.discovered[entry.id] then
			index[order] = "1"
			found += 1
		end
	end
	local owned = 0
	for _ in state.pedestals do
		owned += 1
	end
	local carrying = state.carrying
	player:SetAttribute("Cash", state.cash)
	player:SetAttribute("Income", state.income)
	player:SetAttribute("Rebirths", state.rebirths)
	player:SetAttribute("Index", table.concat(index))
	player:SetAttribute("Found", found)
	player:SetAttribute("Owned", owned)
	player:SetAttribute("Capacity", PlayerState.pedestalCapacity(player))
	player:SetAttribute("Booth", state.booth or 0)
	player:SetAttribute("Carrying", if carrying then BrainrotCatalog.BY_ID[carrying.id].name else "")
	player:SetAttribute("LockUntil", state.lockUntil)
	player:SetAttribute("LockReadyAt", state.lockReadyAt)
	for _, key in GameConfig.UPGRADE_ORDER do
		player:SetAttribute("Upgrade" .. key, state.upgrades[key])
	end
end

local function freshState(): State
	return {
		cash = GameConfig.START_CASH,
		rebirths = 0,
		upgrades = { Pedestals = 0, Speed = 0, LockTime = 0 },
		discovered = {},
		pedestals = {},
		carrying = nil,
		booth = nil,
		lockUntil = 0,
		lockReadyAt = 0,
		income = 0,
		stolen = 0,
		bonks = 0,
	}
end

local function loadSaved(player: Player, state: State)
	if not store then
		return
	end
	local ok, saved = pcall(function()
		return store:GetAsync("p" .. player.UserId)
	end)
	if not ok or type(saved) ~= "table" then
		return
	end
	state.cash = tonumber(saved.cash) or state.cash
	state.rebirths = tonumber(saved.rebirths) or 0
	for key in state.upgrades do
		state.upgrades[key] = tonumber(saved.upgrades and saved.upgrades[key]) or 0
	end
	for _, id in saved.discovered or {} do
		if BrainrotCatalog.BY_ID[id] then
			state.discovered[id] = true
		end
	end
	state.pedestals = {}
	for _, kept in saved.pedestals or {} do
		if BrainrotCatalog.BY_ID[kept.id] and type(kept.slot) == "number" then
			state.pedestals[kept.slot] = { id = kept.id, mutation = kept.mutation }
		end
	end
end

local function save(player: Player)
	local state = states[player]
	if not store or not state then
		return
	end
	local discovered, pedestals = {}, {}
	for id in state.discovered do
		table.insert(discovered, id)
	end
	for slot, brainrot in state.pedestals do
		table.insert(pedestals, { slot = slot, id = brainrot.id, mutation = brainrot.mutation })
	end
	pcall(function()
		store:SetAsync("p" .. player.UserId, { cash = state.cash, rebirths = state.rebirths, upgrades = state.upgrades, discovered = discovered, pedestals = pedestals })
	end)
end

local function onPlayerAdded(player: Player)
	local state = freshState()
	states[player] = state
	services.BasePedestals.claimBooth(player)
	PlayerState.publish(player)
	loadSaved(player, state)
	services.BasePedestals.restorePedestals(player)
	services.IncomeTicker.refreshIncome(player)
end

local function onPlayerRemoving(player: Player)
	save(player)
	services.BasePedestals.releaseBooth(player)
	states[player] = nil
end

function PlayerState.start(allServices)
	services = allServices
	if not RunService:IsStudio() then
		local ok, result = pcall(function()
			return DataStoreService:GetDataStore("RotCarnivalV1")
		end)
		store = if ok then result else nil
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	game:BindToClose(function()
		for player in states do
			save(player)
		end
	end)
end

return PlayerState
