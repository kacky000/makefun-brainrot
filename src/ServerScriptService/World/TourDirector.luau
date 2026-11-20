-- TourDirector: brings the running game to each screenshot's scene (TOUR.json calls showcase with a scene name).
-- It only drives the real services: it places and buys real brainrots, locks the real gate, sends a real clown
-- and a real popcorn wave, then points the player's camera at them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local GameConfig = require(ReplicatedStorage.GameConfig)
local PlayerState = require(script.Parent.Parent.State.PlayerState)

local TourDirector = {}

local services

-- A well-stocked booth: twelve brainrots across the rarity ladder, some mutated.
-- Each row is { pedestal slot, brainrot, mutation }. Slots 1 and 2 stay free for the scene's own purchases.
local SHOWCASE_BOOTH = {
	{ 3, "rhinoccino", nil },
	{ 4, "kernelcorn", "Gold" },
	{ 5, "elefanfare", "Neon" },
	{ 6, "fortuna", nil },
	{ 7, "wheelio", "Buttered" },
	{ 8, "clowncumber", nil },
	{ 9, "pandacotta", nil },
	{ 10, "lobsteroni", nil },
	{ 11, "dragonoli", nil },
	{ 12, "sharkuterie", "Gold" },
	{ 13, "carousello", "Galaxy" },
	{ 14, "rollercobra", nil },
	{ 15, "gelato", "Neon" },
	{ 16, "candalfo", nil },
	{ 17, "octopopcorn", "Buttered" },
	{ 18, "duckuccino", "Gold" },
}

local function standPlayer(player: Player, position: Vector3, facing: Vector3)
	local character = player.Character
	if character then
		character:PivotTo(CFrame.lookAt(position, position + facing))
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			rootPart.AssemblyLinearVelocity = Vector3.zero
		end
	end
end

-- Reset the player to the tour's starting point: paused raids and waves, a rich wallet, a stocked booth.
local function stageBooth(player: Player)
	local state = PlayerState.get(player)
	services.ThiefRaids.paused = true
	services.PopcornWave.paused = true
	services.EventScheduler.paused = true
	services.CarryService.holdDelivery(true)
	services.ConveyorSpawner.paused = true
	services.ConveyorSpawner.clearBelt()
	services.ThiefRaids.dismissThief(player)
	services.PopcornWave.stopWave()
	services.EventScheduler.stopEvent()
	services.GateLock.unlockGate(player)
	services.CarryService.dropCarried(player)
	services.BasePedestals.clearBooth(player)
	state.rebirths = 2
	state.upgrades.pedestals = 5
	state.upgrades.speed = 2
	state.upgrades.lock = 2
	state.money = 312000000
	services.BasePedestals.refreshPedestals(player)
	for _, pick in SHOWCASE_BOOTH do
		services.BasePedestals.placeBrainrotOnPedestal(player, pick[2], pick[3], nil, pick[1])
	end
	for _, entry in BrainrotCatalog.ENTRIES do
		if entry.number % 9 ~= 8 and entry.id ~= "jackpotto" then
			state.index[entry.id] = true
		end
	end
	services.IncomeTicker.recomputeIncome(player)
	services.notify(player, "panel", { close = true })
	return state
end

-- Buy a chosen brainrot off the belt for real, right beside the player.
local function buyFromBelt(player: Player, id: string, mutation: string?, x: number)
	local item = services.ConveyorSpawner.spawnOnBelt(BrainrotCatalog.byId[id], mutation, x)
	-- Let the new brainrot reach the player's client before it is bought, or its carry weld is made too early.
	task.wait(0.5)
	services.CarryService.buyAndCarryFromBelt(player, item)
	task.wait(0.3)
end

local SCENES = {}

-- The cover: Golden Hour, the gate locked against a Sneaky Clown, a held popcorn wave on the street,
-- a Secret placed on a pedestal and a Rainbow Legendary carried in.
function SCENES.cover(player: Player)
	local state = stageBooth(player)
	local booth = state.booth
	local _, dir = GameConfig.boothOrigin(booth)
	services.EventScheduler.startEvent("GoldenHour", 600)
	services.GateLock.lockGate(player, 600)
	services.BasePedestals.placeBrainrotOnPedestal(player, "trofeo", "Gold", nil, 1)
	buyFromBelt(player, "popcornado", "Rainbow", GameConfig.boothPoint(booth, 0, 0, 0).X)
	standPlayer(player, GameConfig.boothPoint(booth, 8, 2, 3.5), Vector3.new(-0.7, 0, -0.7 * dir))
	services.ThiefRaids.sendThief(player, 600, 1)
	services.PopcornWave.startPopcornWave(GameConfig.boothPoint(booth, 0, 48, 0).X, 600)
	services.notify(player, "camera", { from = GameConfig.boothPoint(booth, -24, -25, 15), to = GameConfig.boothPoint(booth, 10, 4, 9) })
	return "cover staged"
end

-- The belt: the player on the street buying a Gold Mythic off the Prize Belt while the wave closes in.
function SCENES.belt(player: Player)
	local state = stageBooth(player)
	local booth = state.booth
	local x = GameConfig.boothPoint(booth, 0, 0, 0).X
	services.EventScheduler.startEvent("RainbowRain", 600)
	services.ConveyorSpawner.spawnOnBelt(BrainrotCatalog.byId.nachito, nil, x - 30)
	services.ConveyorSpawner.spawnOnBelt(BrainrotCatalog.byId.gelato, "Neon", x - 18)
	services.ConveyorSpawner.spawnOnBelt(BrainrotCatalog.byId.fortuna, nil, x - 5)
	services.ConveyorSpawner.spawnOnBelt(BrainrotCatalog.byId.tendone, nil, x + 9)
	buyFromBelt(player, "kernelcorn", "Gold", x - 12)
	standPlayer(player, GameConfig.boothPoint(booth, -36, -16, 3.5), Vector3.new(-1, 0, -0.3))
	services.PopcornWave.startPopcornWave(x + 40, 600)
	services.notify(player, "camera", { from = GameConfig.boothPoint(booth, -44, -42, 11), to = GameConfig.boothPoint(booth, -29, -4, 8) })
	return "belt staged"
end

-- The panels: INDEX (3D previews, found count) beside the REBIRTH panel.
function SCENES.panels(player: Player)
	local state = stageBooth(player)
	standPlayer(player, GameConfig.boothPoint(state.booth, 30, 0, 3.5), Vector3.new(0, 0, -1))
	services.notify(player, "camera", { from = GameConfig.boothPoint(state.booth, -30, 0, 26), to = GameConfig.boothPoint(state.booth, 26, 0, 2) })
	services.notify(player, "panel", { open = { "index", "rebirth" } })
	return "panels staged"
end

-- Give the game back to the player: timers resume, the camera returns.
function SCENES.play(player: Player)
	services.ThiefRaids.paused = false
	services.PopcornWave.paused = false
	services.EventScheduler.paused = false
	services.CarryService.holdDelivery(false)
	services.ConveyorSpawner.paused = false
	services.PopcornWave.stopWave()
	services.ThiefRaids.dismissThief(player)
	services.GateLock.unlockGate(player)
	services.notify(player, "camera", {})
	services.notify(player, "panel", { close = true })
	return "play resumed"
end

-- Stage one scene for the first player: "cover", "belt", "panels", or "play" to resume normal play.
function TourDirector.showcase(scene: string): string
	if not services then
		-- Required from outside the running game's own modules (a tour call): hand over to the live services.
		return ServerStorage.ServiceCall:Invoke("TourDirector", "showcase", scene)
	end
	local player = Players:GetPlayers()[1]
	local stage = SCENES[scene]
	if not (player and stage and PlayerState.get(player)) then
		return "no player or scene"
	end
	return stage(player)
end

function TourDirector.init(shared)
	services = shared
end

return TourDirector
