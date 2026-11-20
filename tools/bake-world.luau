-- bake-world: runs CarnivalBuilder outside Roblox (lune) and writes the carnival to world/Carnival.rbxm,
-- which default.project.json puts in the place as Workspace.Carnival.
--   lune run tools/bake-world.luau
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local environment = {
	Instance = roblox.Instance,
	Vector3 = roblox.Vector3,
	CFrame = roblox.CFrame,
	Color3 = roblox.Color3,
	UDim = roblox.UDim,
	UDim2 = roblox.UDim2,
	Enum = roblox.Enum,
	Font = roblox.Font,
}

local function loadModule(path: string)
	return luau.load(fs.readFile(path), { debugName = path, environment = environment })()
end

local GameConfig = loadModule("src/ReplicatedStorage/GameConfig.luau")
local CarnivalBuilder = loadModule("src/ServerScriptService/World/CarnivalBuilder.luau")

local carnival = CarnivalBuilder.buildCarnival(nil, GameConfig)
fs.writeFile("world/Carnival.rbxm", roblox.serializeModel({ carnival }))
print("baked world/Carnival.rbxm with " .. #carnival:GetDescendants() .. " instances")
