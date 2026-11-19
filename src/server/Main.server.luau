--!strict
-- Server bootstrap: builds the carnival first (ground and spawn before anyone falls), makes the remotes,
-- then wires and starts every service, each in its own pcall so one fault never stops the rest.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local REMOTES = { "Notify", "IncomeTick", "ShopRequest", "Celebrate", "Sfx" }

local function makeRemotes()
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in REMOTES do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	folder.Parent = ReplicatedStorage
end

-- Start order: the world, then the state, then everything that reads them.
local ORDER = {
	"CarnivalWorld",
	"PlayerData",
	"EventScheduler",
	"BasePedestals",
	"GateLock",
	"CarryService",
	"ConveyorSpawner",
	"IncomeTicker",
	"PopcornWave",
	"ThiefRaids",
	"RebirthService",
	"UpgradeShop",
	"TourDirector",
}

makeRemotes()

local services: { [string]: any } = {}
for _, name in ORDER do
	local ok, result = pcall(require, ServerScriptService:WaitForChild(name))
	if ok then
		services[name] = result
	else
		warn("[Main] could not load " .. name .. ": " .. tostring(result))
	end
end

for _, name in ORDER do
	local service = services[name]
	if service and service.init then
		local ok, err = pcall(service.init, services)
		if not ok then
			warn("[Main] " .. name .. ".init failed: " .. tostring(err))
		end
	end
end

for _, name in ORDER do
	local service = services[name]
	if service and service.start then
		local ok, err = pcall(service.start)
		if not ok then
			warn("[Main] " .. name .. ".start failed: " .. tostring(err))
		end
	end
end

-- ServerStorage.ServiceCall lets server-side tools (the tour, Studio test harnesses running in another
-- context) call into the live services: ServiceCall:Invoke("TourDirector", "showcase", "cover").
local serviceCall = Instance.new("BindableFunction")
serviceCall.Name = "ServiceCall"
serviceCall.OnInvoke = function(serviceName: string, fnName: string, ...)
	local service = services[serviceName]
	local fn = service and service[fnName]
	if type(fn) ~= "function" then
		return "no such function " .. tostring(serviceName) .. "." .. tostring(fnName)
	end
	return fn(...)
end
serviceCall.Parent = game:GetService("ServerStorage")

print("[Main] ROT CARNIVAL is open")
