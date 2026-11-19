-- PlayerState: the one place a player's game state lives on the server (cash, stash, pedestal slots, upgrades,
-- rebirths, index, what they carry). Every service reads and writes it here; attributes mirror it to the client HUD.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.GameConfig)
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)

local PlayerState = {}
local states = {}
local store = nil
local notifyRemote: RemoteEvent? = nil

function PlayerState.get(player: Player)
	return states[player]
end

function PlayerState.all()
	return states
end

local function freshState()
	return {
		cash = GameConfig.START_CASH,
		stash = 0,
		rebirths = 0,
		upgrades = { Pedestals = 0, Speed = 0, Lock = 0 },
		found = {},
		slots = {}, -- [slot] = { id = string, mutation = string? }
		carrying = nil, -- { id, mutation, model, stolenFrom }
		booth = 0,
		lockedUntil = 0,
		lockReadyAt = 0,
		earned = 0,
	}
end

-- mirror: publish the state the HUD draws as attributes of the Player.
function PlayerState.mirror(player: Player)
	local s = states[player]
	if not s then
		return
	end
	local found = {}
	for id in s.found do
		table.insert(found, id)
	end
	local filled = 0
	for _ in s.slots do
		filled += 1
	end
	player:SetAttribute("Cash", math.floor(s.cash))
	player:SetAttribute("Stash", math.floor(s.stash))
	player:SetAttribute("Rebirths", s.rebirths)
	player:SetAttribute("UpPedestals", s.upgrades.Pedestals)
	player:SetAttribute("UpSpeed", s.upgrades.Speed)
	player:SetAttribute("UpLock", s.upgrades.Lock)
	player:SetAttribute("Found", table.concat(found, ","))
	player:SetAttribute("Booth", s.booth)
	player:SetAttribute("Filled", filled)
	player:SetAttribute("Capacity", PlayerState.capacity(player))
	player:SetAttribute("Carrying", if s.carrying then s.carrying.id else "")
	player:SetAttribute("CarryMutation", if s.carrying then s.carrying.mutation or "" else "")
	player:SetAttribute("LockedUntil", s.lockedUntil)
	player:SetAttribute("LockReadyAt", s.lockReadyAt)
end

function PlayerState.capacity(player: Player): number
	local s = states[player]
	local config = GameConfig.UPGRADES.Pedestals
	return math.min(GameConfig.BOOTH.maxPedestals, GameConfig.BOOTH.startPedestals + s.upgrades.Pedestals * config.per)
end

function PlayerState.addCash(player: Player, amount: number)
	local s = states[player]
	if s then
		s.cash += amount
		s.earned += math.max(0, amount)
		player:SetAttribute("Cash", math.floor(s.cash))
	end
end

function PlayerState.trySpend(player: Player, amount: number): boolean
	local s = states[player]
	if not s or s.cash < amount then
		return false
	end
	s.cash -= amount
	player:SetAttribute("Cash", math.floor(s.cash))
	return true
end

function PlayerState.markFound(player: Player, id: string): boolean
	local s = states[player]
	if s.found[id] then
		return false
	end
	s.found[id] = true
	return true
end

-- notify: one line to the player's HUD (receipts, banners, popups). kind picks how the HUD shows it.
function PlayerState.notify(player: Player, kind: string, payload: { [string]: any }?)
	if notifyRemote and player.Parent then
		notifyRemote:FireClient(player, kind, payload or {})
	end
end

function PlayerState.notifyAll(kind: string, payload: { [string]: any }?)
	if notifyRemote then
		notifyRemote:FireAllClients(kind, payload or {})
	end
end

local function loadSaved(player: Player, s)
	if not store then
		return
	end
	local ok, saved = pcall(function()
		return store:GetAsync("p" .. player.UserId)
	end)
	if ok and type(saved) == "table" then
		s.cash = saved.cash or s.cash
		s.rebirths = saved.rebirths or 0
		for key, level in saved.upgrades or {} do
			if s.upgrades[key] then
				s.upgrades[key] = level
			end
		end
		for _, id in saved.found or {} do
			if BrainrotCatalog.byId[id] then
				s.found[id] = true
			end
		end
		for slot, held in saved.slots or {} do
			if BrainrotCatalog.byId[held.id] then
				s.slots[tonumber(slot) :: number] = { id = held.id, mutation = held.mutation }
			end
		end
	end
end

function PlayerState.save(player: Player)
	local s = states[player]
	if not store or not s then
		return
	end
	local found, slots = {}, {}
	for id in s.found do
		table.insert(found, id)
	end
	for slot, held in s.slots do
		slots[tostring(slot)] = { id = held.id, mutation = held.mutation }
	end
	pcall(function()
		store:SetAsync("p" .. player.UserId, { cash = s.cash + s.stash, rebirths = s.rebirths, upgrades = s.upgrades, found = found, slots = slots })
	end)
end

function PlayerState.create(player: Player)
	local s = freshState()
	states[player] = s
	loadSaved(player, s)
	return s
end

function PlayerState.remove(player: Player)
	PlayerState.save(player)
	states[player] = nil
end

-- start: saving is optional. A place that is not published has no DataStore, and the game runs without one.
function PlayerState.start(remote: RemoteEvent)
	notifyRemote = remote
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("RotCarnivalV2")
	end)
	store = if ok and not RunService:IsStudio() then result else nil
	task.spawn(function()
		while true do
			task.wait(90)
			for _, player in Players:GetPlayers() do
				PlayerState.save(player)
			end
		end
	end)
end

return PlayerState
