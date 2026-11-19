-- Main: boots ROT CARNIVAL: Popcorn Panic on the server. Builds the world first (so nobody
-- falls), then starts each service in its own pcall so one failure cannot stop the rest.
-- All game rules run here on the server; clients only send three requests through Remotes.Action.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage.GameConfig)
local CarnivalBuilder = require(script.Parent.World.CarnivalBuilder)
local BrainrotModels = require(script.Parent.World.BrainrotModels)

-- 1. The world: use the baked carnival if the place has it, else build it now.
if not workspace:FindFirstChild("Carnival") then
	CarnivalBuilder.buildCarnival(workspace, GameConfig)
end
CarnivalBuilder.dressLighting(Lighting)

-- 2. Remotes and the INDEX preview models.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local actionRemote = Instance.new("RemoteEvent")
actionRemote.Name = "Action"
actionRemote.Parent = remotes
local notifyRemote = Instance.new("RemoteEvent")
notifyRemote.Name = "Notify"
notifyRemote.Parent = remotes
remotes.Parent = ReplicatedStorage
pcall(BrainrotModels.buildPreviewLibrary)

-- 3. Services. Each gets the shared table so they can call one another without circular requires.
local services = {}

function services.notify(player: Player, kind: string, payload)
	notifyRemote:FireClient(player, kind, payload)
end

function services.notifyAll(kind: string, payload)
	notifyRemote:FireAllClients(kind, payload)
end

local START_ORDER = {
	{ "PlayerState", script.Parent.State.PlayerState },
	{ "BasePedestals", script.Parent.Economy.BasePedestals },
	{ "EventScheduler", script.Parent.Events.EventScheduler },
	{ "IncomeTicker", script.Parent.Economy.IncomeTicker },
	{ "ConveyorSpawner", script.Parent.Economy.ConveyorSpawner },
	{ "CarryService", script.Parent.Economy.CarryService },
	{ "RebirthService", script.Parent.Economy.RebirthService },
	{ "UpgradeShop", script.Parent.Economy.UpgradeShop },
	{ "GateLock", script.Parent.Hazards.GateLock },
	{ "PopcornWave", script.Parent.Hazards.PopcornWave },
	{ "ThiefRaids", script.Parent.Hazards.ThiefRaids },
	{ "TourDirector", script.Parent.World.TourDirector },
}

for _, entry in START_ORDER do
	local ok, result = pcall(require, entry[2])
	if ok then
		services[entry[1]] = result
	else
		warn("[Main] could not load " .. entry[1] .. ": " .. tostring(result))
	end
end

-- PlayerState starts last: it hands joining players a booth, which needs every other service up.
for index = 2, #START_ORDER do
	local name = START_ORDER[index][1]
	local service = services[name]
	if service then
		local ok, problem = pcall(service.start, services)
		if not ok then
			warn("[Main] " .. name .. " failed to start: " .. tostring(problem))
		end
	end
end
local ok, problem = pcall(services.PlayerState.start, services)
if not ok then
	warn("[Main] PlayerState failed to start: " .. tostring(problem))
end

-- 4. Client requests. The server decides everything; the client only asks.
local lastRequest: { [Player]: number } = {}
actionRemote.OnServerEvent:Connect(function(player: Player, action: unknown, detail: unknown)
	local now = os.clock()
	if now - (lastRequest[player] or 0) < 0.15 then
		return
	end
	lastRequest[player] = now
	if action == "lock" then
		services.GateLock.lockGate(player)
	elseif action == "rebirth" then
		services.RebirthService.tryRebirth(player)
	elseif action == "upgrade" and type(detail) == "string" then
		services.UpgradeShop.tryBuyUpgrade(player, detail)
	end
end)
Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
end)

-- 5. A test hook: ServiceCall:Invoke("PopcornWave", "startPopcornWave") calls a live service.
local serviceCall = Instance.new("BindableFunction")
serviceCall.Name = "ServiceCall"
serviceCall.OnInvoke = function(serviceName: string, functionName: string, ...)
	return services[serviceName][functionName](...)
end
serviceCall.Parent = ServerStorage
