-- bake-world: runs CarnivalBuilder outside Roblox (with Lune) and saves the carnival as world/Carnival.rbxm, which
-- default.project.json puts in Workspace. The same builder runs on the server when a place holds no baked world.
--   lune run tools/bake-world.luau
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

-- Lune has no Random; the builder only needs NextNumber and NextInteger.
local Random = {}
Random.__index = Random
function Random.new(seed: number?)
	return setmetatable({ state = (seed or 1) % 2147483647 }, Random)
end
function Random:step(): number
	self.state = (self.state * 48271) % 2147483647
	return self.state / 2147483647
end
function Random:NextNumber(low: number?, high: number?): number
	local a, b = low or 0, high or 1
	return a + (b - a) * self:step()
end
function Random:NextInteger(low: number, high: number): number
	return math.floor(low + (high - low + 1) * self:step())
end

local modules = {}
local function loadModule(path: string, name: string)
	local env = {
		Instance = roblox.Instance,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		CFrame = roblox.CFrame,
		Color3 = roblox.Color3,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Enum = roblox.Enum,
		Font = roblox.Font,
		Random = Random,
		game = {
			GetService = function(_, service: string)
				return { GameConfig = "GameConfig" }
			end,
		},
		require = function(key: string)
			return modules[key]
		end,
	}
	local chunk = luau.load(fs.readFile(path), { debugName = name, environment = env })
	modules[name] = chunk()
	return modules[name]
end

loadModule("src/ReplicatedStorage/GameConfig.luau", "GameConfig")
local CarnivalBuilder = loadModule("src/ServerScriptService/World/CarnivalBuilder.luau", "CarnivalBuilder")

local holder = roblox.Instance.new("Folder")
local carnival = CarnivalBuilder.buildCarnival(holder)
fs.writeDir("world")
fs.writeFile("world/Carnival.rbxm", roblox.serializeModel({ carnival }))
print("baked " .. #carnival:GetDescendants() .. " instances into world/Carnival.rbxm")
