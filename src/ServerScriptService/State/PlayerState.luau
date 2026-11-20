-- PlayerState: the one place every player's progress lives (money, rebirths, upgrades, pedestals, index).
-- Services read and change it here; the client only sees the attributes syncToClient mirrors onto the Player.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.GameConfig)

local PlayerState = {}

local states = {}
local store = nil

-- Open the save store. A Studio session or an unpublished place has none, and the game then runs without saving.
function PlayerState.openSaveStore()
	if RunService:IsStudio() then
		return false
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("RotCarnivalSave_v1")
	end)
	store = ok and result or nil
	return store ~= nil
end

local function blankState()
	return {
		money = GameConfig.START_MONEY,
		income = 0,
		rebirths = 0,
		upgrades = { pedestals = 0, speed = 0, lock = 0 },
		placed = {}, -- slot -> { id, mutation, model }
		index = {}, -- brainrot id -> true once owned
		carrying = nil, -- { id, mutation, model }
		booth = 0,
		lockUntil = 0,
		lockReadyAt = 0,
		saved = nil, -- pedestal contents loaded from the store, restored once the booth is assigned
	}
end

function PlayerState.createFor(player: Player)
	local state = blankState()
	if store then
		local ok, saved = pcall(function()
			return store:GetAsync("p" .. player.UserId)
		end)
		if ok and type(saved) == "table" then
			state.money = tonumber(saved.money) or state.money
			state.rebirths = tonumber(saved.rebirths) or 0
			for key in state.upgrades do
				state.upgrades[key] = tonumber(saved.upgrades and saved.upgrades[key]) or 0
			end
			for _, id in saved.index or {} do
				state.index[id] = true
			end
			state.saved = saved.placed
		end
	end
	states[player] = state
	return state
end

function PlayerState.get(player: Player)
	return states[player]
end

function PlayerState.all()
	return states
end

function PlayerState.saveAndForget(player: Player)
	local state = states[player]
	states[player] = nil
	if not (state and store) then
		return
	end
	local placed, index = {}, {}
	for slot, item in state.placed do
		table.insert(placed, { slot = slot, id = item.id, mutation = item.mutation })
	end
	for id in state.index do
		table.insert(index, id)
	end
	pcall(function()
		store:SetAsync("p" .. player.UserId, {
			money = state.money,
			rebirths = state.rebirths,
			upgrades = state.upgrades,
			placed = placed,
			index = index,
		})
	end)
end

function PlayerState.addMoney(player: Player, amount: number)
	local state = states[player]
	if state then
		state.money += amount
		player:SetAttribute("Money", state.money)
	end
end

function PlayerState.trySpend(player: Player, amount: number): boolean
	local state = states[player]
	if not state or state.money < amount then
		return false
	end
	state.money -= amount
	player:SetAttribute("Money", state.money)
	return true
end

function PlayerState.discover(player: Player, id: string)
	local state = states[player]
	if state and not state.index[id] then
		state.index[id] = true
		PlayerState.syncToClient(player)
	end
end

-- Mirror what the HUD shows onto the Player's attributes.
function PlayerState.syncToClient(player: Player)
	local state = states[player]
	if not state then
		return
	end
	local found = {}
	for id in state.index do
		table.insert(found, id)
	end
	local placedCount = 0
	for _ in state.placed do
		placedCount += 1
	end
	player:SetAttribute("Money", state.money)
	player:SetAttribute("Income", state.income)
	player:SetAttribute("Rebirths", state.rebirths)
	player:SetAttribute("Booth", state.booth)
	player:SetAttribute("Placed", placedCount)
	player:SetAttribute("Pedestals", GameConfig.pedestalCount(state.upgrades.pedestals))
	player:SetAttribute("UpPedestals", state.upgrades.pedestals)
	player:SetAttribute("UpSpeed", state.upgrades.speed)
	player:SetAttribute("UpLock", state.upgrades.lock)
	player:SetAttribute("Index", table.concat(found, ","))
	player:SetAttribute("LockUntil", state.lockUntil)
	player:SetAttribute("LockReadyAt", state.lockReadyAt)
end

return PlayerState
