-- TourDirector: stages the game's real systems into the three screenshot scenes, so anyone can bring the running
-- game to the same screens: showcase("cover"), showcase("lock"), showcase("index"), and showcase("reset").
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local PlayerState = require(script.Parent.Parent.State.PlayerState)
local EventScheduler = require(script.Parent.Parent.Events.EventScheduler)
local BasePedestals = require(script.Parent.Parent.Economy.BasePedestals)
local CarryService = require(script.Parent.Parent.Economy.CarryService)
local ConveyorSpawner = require(script.Parent.Parent.Economy.ConveyorSpawner)
local IncomeTicker = require(script.Parent.Parent.Economy.IncomeTicker)
local GateLock = require(script.Parent.Parent.Hazards.GateLock)
local PopcornWave = require(script.Parent.Parent.Hazards.PopcornWave)
local ThiefRaids = require(script.Parent.Parent.Hazards.ThiefRaids)

local TourDirector = {}

-- A booth a few hours in: every rarity and every mutation on show.
local COLLECTION = {
	{ "kernelcorn", "Gold" },
	{ "trofeo", "Galaxy" },
	{ "rhinoccino", nil },
	{ "dragonzola", "Rainbow" },
	{ "krakenoli", nil },
	{ "jackpotto", nil },
	{ "sharkolato", "Neon" },
	{ "unicornetto", nil },
	{ "hippo", "Buttered" },
	{ "gorillasagna", nil },
	{ "giraffa", nil },
	{ "duckuccino", "Gold" },
	{ "octopizza", nil },
	{ "tentissimo", nil },
	{ "toastolini", nil },
	{ "penguini", "Rainbow" },
}

local function stockBooth(player: Player)
	local s = PlayerState.get(player)
	s.upgrades.Pedestals = 6
	s.upgrades.Speed = 3
	s.upgrades.Lock = 2
	s.rebirths = math.max(s.rebirths, 2)
	s.slots = {}
	for slot, pick in COLLECTION do
		s.slots[slot] = { id = pick[1], mutation = pick[2] }
		s.found[pick[1]] = true
	end
	for i = 1, 22 do
		s.found[BrainrotCatalog.list[i].id] = true
	end
	s.cash = 4865200
	s.stash = 38400
	BasePedestals.refreshBooth(player)
	PlayerState.mirror(player)
	IncomeTicker.payTick(player)
end

local function standAt(player: Player, position: Vector3, lookAt: Vector3)
	local character = player.Character
	if character then
		character:PivotTo(CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z)))
	end
end

local function aimCamera(player: Player, position: Vector3, lookAt: Vector3)
	PlayerState.notify(player, "TourCamera", { position = position, lookAt = lookAt })
end

function TourDirector.showcase(scene: string, playerName: string?): boolean -- "cover" | "lock" | "index" | "reset"
	local player = if playerName then Players:FindFirstChild(playerName) else Players:GetPlayers()[1]
	if not player or not PlayerState.get(player) or not BasePedestals.boothOf(player) then
		return false
	end
	local booth = BasePedestals.boothOf(player)
	local side = booth.spec.side
	local function inBooth(lx: number, y: number, lz: number): Vector3
		return Vector3.new(booth.spec.x + lx, y, booth.gateZ + side * lz)
	end
	if scene == "reset" then
		CarryService.deliveryPaused = false
		PopcornWave.frozenAt = nil
		ThiefRaids.frozen = false
		GateLock.unlockGate(player)
		PlayerState.notify(player, "TourCamera", {})
		PlayerState.notify(player, "ClosePanels", {})
		return true
	end
	stockBooth(player)
	if scene == "cover" then
		-- Running home with a fresh catch while the Popcorn Wave rolls past the gate, Golden Hour on.
		CarryService.deliveryPaused = true
		GateLock.unlockGate(player)
		EventScheduler.startEvent("GoldenHour", 600)
		CarryService.giveCarry(player, "phoenixpresso", "Rainbow")
		standAt(player, inBooth(-1.5, 4, 13), inBooth(2, 4, 60))
		PlayerState.notify(player, "Receipt", { line = "BOUGHT", name = "Phoenixpresso Infernale", detail = "-$4.33M", rarity = 6, mutation = "Rainbow" })
		PlayerState.notify(player, "Receipt", { line = "PLACED", name = "King Kernelcorn", detail = "+$18.00K/s", rarity = 6, mutation = "Gold" })
		PopcornWave.frozenAt = booth.spec.x + 13
		task.spawn(PopcornWave.startPopcornWave, 1)
		aimCamera(player, inBooth(6, 13, 40), inBooth(-1, 5, 6))
	elseif scene == "lock" then
		-- The Sneaky Clown bounces off the locked gate.
		CarryService.clearCarry(player)
		PopcornWave.frozenAt = nil
		GateLock.unlockGate(player)
		GateLock.lockGate(player, 600)
		standAt(player, inBooth(4, 4, 8), inBooth(0, 4, -20))
		task.spawn(function()
			ThiefRaids.sendThief(player)
		end)
		aimCamera(player, inBooth(-13, 9, -24), inBooth(1, 7, 2))
	elseif scene == "index" then
		-- The INDEX and REBIRTH panels open over the booth.
		CarryService.clearCarry(player)
		standAt(player, inBooth(0, 4, 20), inBooth(0, 4, 60))
		PlayerState.notify(player, "OpenPanels", { panels = { "Index", "Rebirth" } })
		aimCamera(player, inBooth(0, 16, -2), inBooth(0, 3, 34))
	else
		return false
	end
	Workspace:SetAttribute("TourScene", scene)
	return true
end

function TourDirector.beltCount(): number
	return ConveyorSpawner.itemCount()
end

return TourDirector
