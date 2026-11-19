-- Main: boots ROT CARNIVAL: Popcorn Panic. Builds the world if the place holds none, starts every service on its
-- own (one failing never stops the rest), gives each player a booth, and routes the HUD's button presses.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local actionRemote = Instance.new("RemoteEvent")
actionRemote.Name = "Action"
actionRemote.Parent = remotes
local notifyRemote = Instance.new("RemoteEvent")
notifyRemote.Name = "Notify"
notifyRemote.Parent = remotes
remotes.Parent = ReplicatedStorage

local CarnivalBuilder = require(ServerScriptService.World.CarnivalBuilder)
if not Workspace:FindFirstChild("Carnival") then
	CarnivalBuilder.buildCarnival(Workspace)
end
CarnivalBuilder.dressLighting()

local services = {
	PlayerState = require(ServerScriptService.State.PlayerState),
	BrainrotModels = require(ServerScriptService.World.BrainrotModels),
	EventScheduler = require(ServerScriptService.Events.EventScheduler),
	IncomeTicker = require(ServerScriptService.Economy.IncomeTicker),
	RebirthService = require(ServerScriptService.Economy.RebirthService),
	UpgradeShop = require(ServerScriptService.Economy.UpgradeShop),
	BasePedestals = require(ServerScriptService.Economy.BasePedestals),
	GateLock = require(ServerScriptService.Hazards.GateLock),
	CarryService = require(ServerScriptService.Economy.CarryService),
	ConveyorSpawner = require(ServerScriptService.Economy.ConveyorSpawner),
	PopcornWave = require(ServerScriptService.Hazards.PopcornWave),
	ThiefRaids = require(ServerScriptService.Hazards.ThiefRaids),
	TourDirector = require(ServerScriptService.World.TourDirector),
}

local function boot(name: string, ...)
	local ok, problem = pcall(services[name].start, ...)
	if not ok then
		warn("[Main] " .. name .. " failed to start: " .. tostring(problem))
	end
end

boot("PlayerState", notifyRemote)
pcall(services.BrainrotModels.stockPreviews)
boot("EventScheduler")
boot("IncomeTicker")
boot("BasePedestals")
boot("CarryService")
boot("ConveyorSpawner")
boot("PopcornWave")
boot("ThiefRaids")

local PlayerState = services.PlayerState
local BasePedestals = services.BasePedestals
local CarryService = services.CarryService

local function placeAtBooth(player: Player, character: Model)
	if not BasePedestals.boothOf(player) then
		return
	end
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if rootPart then
		task.wait(0.1)
		local stand = BasePedestals.gatePoint(player, 9) + Vector3.new(0, 4, 0)
		local towardStreet = BasePedestals.gatePoint(player, -20) + Vector3.new(0, 4, 0)
		character:PivotTo(CFrame.lookAt(stand, towardStreet))
	end
	CarryService.applyWalkSpeed(player)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			CarryService.dropCarried(player, "fell")
		end)
	end
end

local function onPlayerAdded(player: Player)
	PlayerState.create(player)
	BasePedestals.claimBooth(player)
	PlayerState.mirror(player)
	player:SetAttribute("Income", services.IncomeTicker.incomePerSecond(player))
	player.CharacterAdded:Connect(function(character)
		placeAtBooth(player, character)
	end)
	if player.Character then
		placeAtBooth(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	CarryService.clearCarry(player)
	BasePedestals.releaseBooth(player)
	PlayerState.remove(player)
end)

-- The HUD's buttons. The server decides everything; the client only asks.
local lastAsk = {}
actionRemote.OnServerEvent:Connect(function(player, action, arg)
	if not PlayerState.get(player) or (lastAsk[player] or 0) + 0.15 > os.clock() then
		return
	end
	lastAsk[player] = os.clock()
	if action == "Lock" then
		services.GateLock.lockGate(player)
	elseif action == "Rebirth" then
		services.RebirthService.tryRebirth(player)
	elseif action == "Upgrade" and type(arg) == "string" then
		services.UpgradeShop.buyUpgrade(player, arg)
	end
end)

-- ServiceCall: lets Studio's command bar and make.fun's reviewers reach the running services by name.
local serviceCall = Instance.new("BindableFunction")
serviceCall.Name = "ServiceCall"
serviceCall.OnInvoke = function(serviceName: string, functionName: string, ...)
	return services[serviceName][functionName](...)
end
serviceCall.Parent = ServerStorage
