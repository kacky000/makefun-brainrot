-- Bakes the carnival world into world/Carnival.rbxm so the place file holds the built 3D world.
-- Runs the game's own CarnivalBuilder (the same module the server falls back to) under lune:
--   lune run tools/bake-world.luau
-- then `rojo build default.project.json --output game.rbxl` puts it in Workspace.Carnival.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local environment = {
	Instance = roblox.Instance,
	Vector3 = roblox.Vector3,
	Vector2 = roblox.Vector2,
	CFrame = roblox.CFrame,
	Color3 = roblox.Color3,
	UDim = roblox.UDim,
	UDim2 = roblox.UDim2,
	Font = roblox.Font,
	Enum = roblox.Enum,
	NumberRange = roblox.NumberRange,
	NumberSequence = roblox.NumberSequence,
	ColorSequence = roblox.ColorSequence,
}

local function loadModule(path: string)
	local bytecode = luau.compile(fs.readFile(path))
	return luau.load(bytecode, { debugName = path, environment = environment })()
end

local GameConfig = loadModule("src/ReplicatedStorage/GameConfig.luau")
local CarnivalBuilder = loadModule("src/ServerScriptService/World/CarnivalBuilder.luau")

local holder = roblox.Instance.new("Folder")
local world = CarnivalBuilder.buildCarnival(holder, GameConfig)

local count = 0
for _ in world:GetDescendants() do
	count += 1
end

if not fs.isDir("world") then
	fs.writeDir("world")
end
fs.writeFile("world/Carnival.rbxm", roblox.serializeModel({ world }))
print("baked world/Carnival.rbxm with " .. (count + 1) .. " instances")
