-- Main: starts ROT CARNIVAL. Builds the world first, then starts each service on its own, so one failing
-- service never stops the rest. The server owns all state; clients send three requests and get notices back.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.GameConfig)
local PlayerState = require(script.Parent.State.PlayerState)
local CarnivalBuilder = require(script.Parent.World.CarnivalBuilder)
local BrainrotModels = require(script.Parent.World.BrainrotModels)

-- The world: baked into the place file as Workspace.Carnival; built here when a build has none.
if not Workspace:FindFirstChild("Carnival") then
	CarnivalBuilder.buildCarnival(Workspace, GameConfig)
end
CarnivalBuilder.applyLighting(Lighting)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local playerAction = Instance.new("RemoteEvent")
playerAction.Name = "PlayerAction"
playerAction.Parent = remotes
local notice = Instance.new("RemoteEvent")
notice.Name = "Notice"
notice.Parent = remotes
remotes.Parent = ReplicatedStorage

local services = {
	BasePedestals = require(script.Parent.Economy.BasePedestals),
	CarryService = require(script.Parent.Economy.CarryService),
	ConveyorSpawner = require(script.Parent.Economy.ConveyorSpawner),
	IncomeTicker = require(script.Parent.Economy.IncomeTicker),
	RebirthService = require(script.Parent.Economy.RebirthService),
	UpgradeShop = require(script.Parent.Economy.UpgradeShop),
	EventScheduler = require(script.Parent.Events.EventScheduler),
	GateLock = require(script.Parent.Hazards.GateLock),
	PopcornWave = require(script.Parent.Hazards.PopcornWave),
	ThiefRaids = require(script.Parent.Hazards.ThiefRaids),
	TourDirector = require(script.Parent.World.TourDirector),
	PlayerState = PlayerState,
}

function services.notify(player: Player, kind: string, data)
	notice:FireClient(player, kind, data)
end

function services.notifyAll(kind: string, data)
	notice:FireAllClients(kind, data)
end

local function startSafely(label: string, start: () -> ())
	local ok, problem = pcall(start)
	if not ok then
		warn("[ROT CARNIVAL] " .. label .. " failed to start: " .. tostring(problem))
	end
end

local START_ORDER = { "BasePedestals", "IncomeTicker", "EventScheduler", "CarryService", "ConveyorSpawner", "RebirthService", "UpgradeShop", "GateLock", "PopcornWave", "ThiefRaids", "TourDirector" }
for _, name in START_ORDER do
	startSafely(name, function()
		services[name].init(services)
	end)
end
startSafely("save store", PlayerState.openSaveStore)
startSafely("index previews", BrainrotModels.publishPreviews)
startSafely("belt", services.ConveyorSpawner.start)
startSafely("carrying", services.CarryService.start)
task.spawn(services.IncomeTicker.payIncomeEverySecond)
task.spawn(services.EventScheduler.runSchedule)
task.spawn(services.PopcornWave.runWaveLoop)
task.spawn(services.ThiefRaids.runRaidLoop)

-- Tools outside the game's own scripts (the tour, tests) reach the live services through this one function.
local serviceCall = Instance.new("BindableFunction")
serviceCall.Name = "ServiceCall"
serviceCall.OnInvoke = function(serviceName: string, functionName: string, ...)
	return services[serviceName][functionName](...)
end
serviceCall.Parent = ServerStorage

local function onCharacterAdded(player: Player, character: Model)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	services.CarryService.dropCarried(player)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	services.UpgradeShop.applyWalkSpeed(player)
	if state.booth > 0 then
		-- Start at your own gate, facing the Prize Belt.
		task.defer(function()
			local _, dir = GameConfig.boothOrigin(state.booth)
			local spot = GameConfig.boothPoint(state.booth, -6, 0, 4)
			character:PivotTo(CFrame.lookAt(spot, spot + Vector3.new(0, 0, -dir)))
		end)
	end
end

local function onPlayerAdded(player: Player)
	PlayerState.createFor(player)
	services.BasePedestals.assignBooth(player)
	services.IncomeTicker.recomputeIncome(player)
	player:SetAttribute("Carrying", "")
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	services.ThiefRaids.dismissThief(player)
	services.CarryService.dropCarried(player)
	services.BasePedestals.releaseBooth(player)
	PlayerState.saveAndForget(player)
end)

-- The only things a client may ask for. Each service checks money, ownership and timers itself.
local REQUESTS = {
	lock = function(player)
		services.GateLock.lockGate(player)
	end,
	rebirth = function(player)
		services.RebirthService.tryRebirth(player)
	end,
	upgrade = function(player, key)
		if type(key) == "string" then
			services.UpgradeShop.buyUpgrade(player, key)
		end
	end,
}

playerAction.OnServerEvent:Connect(function(player, action, argument)
	local handle = type(action) == "string" and REQUESTS[action]
	if handle and PlayerState.get(player) then
		handle(player, argument)
	end
end)
