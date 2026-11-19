--!strict
-- GameConfig: every number of ROT CARNIVAL: Popcorn Panic in one place (rarity ladder, mutations,
-- midway and booth layout, upgrades, rebirth, Popcorn Wave, Sneaky Clown thieves, carnival events).
-- Server and client both read it; nothing here holds state.

local GameConfig = {}

GameConfig.TITLE = "ROT CARNIVAL"
GameConfig.SUBTITLE = "POPCORN PANIC"
GameConfig.START_CASH = 150

export type Rarity = { key: string, color: Color3, weight: number, scale: number, payback: number, rank: number }
export type Mutation = { key: string, mult: number, chance: number, color: Color3 }

-- Seven rarities, rarer = bigger model, bigger label, slower payback.
GameConfig.RARITIES = {
	{ key = "Common", color = Color3.fromRGB(200, 205, 215), weight = 46, scale = 1.0, payback = 18, rank = 1 },
	{ key = "Uncommon", color = Color3.fromRGB(96, 222, 110), weight = 25, scale = 1.1, payback = 24, rank = 2 },
	{ key = "Rare", color = Color3.fromRGB(70, 160, 255), weight = 14, scale = 1.25, payback = 30, rank = 3 },
	{ key = "Epic", color = Color3.fromRGB(186, 96, 255), weight = 8, scale = 1.4, payback = 36, rank = 4 },
	{ key = "Legendary", color = Color3.fromRGB(255, 190, 40), weight = 4.5, scale = 1.6, payback = 42, rank = 5 },
	{ key = "Mythic", color = Color3.fromRGB(255, 70, 90), weight = 1.8, scale = 1.85, payback = 48, rank = 6 },
	{ key = "Secret", color = Color3.fromRGB(40, 255, 230), weight = 0.7, scale = 2.2, payback = 55, rank = 7 },
} :: { Rarity }

GameConfig.RARITY_BY_KEY = {} :: { [string]: Rarity }
for _, rarity in GameConfig.RARITIES do
	GameConfig.RARITY_BY_KEY[rarity.key] = rarity
end

-- Five mutations, each multiplies money a second. Chances are per belt spawn before luck.
GameConfig.MUTATIONS = {
	{ key = "Gold", mult = 2, chance = 0.08, color = Color3.fromRGB(255, 205, 50) },
	{ key = "Buttered", mult = 3, chance = 0.05, color = Color3.fromRGB(255, 240, 150) },
	{ key = "Neon", mult = 4, chance = 0.03, color = Color3.fromRGB(60, 255, 120) },
	{ key = "Rainbow", mult = 6, chance = 0.015, color = Color3.fromRGB(255, 110, 220) },
	{ key = "Galaxy", mult = 10, chance = 0.006, color = Color3.fromRGB(140, 100, 255) },
} :: { Mutation }

GameConfig.MUTATION_BY_KEY = {} :: { [string]: Mutation }
for _, mutation in GameConfig.MUTATIONS do
	GameConfig.MUTATION_BY_KEY[mutation.key] = mutation
end

-- The midway: a street along X. The Prize Belt runs down its middle from the Prize Cannon (west)
-- to the Popcorn Machine (east). Booths line both sides.
GameConfig.STREET = { halfLength = 150, halfWidth = 22 }
GameConfig.BELT = { x0 = -112, x1 = 112, z = 0, top = 2.2, width = 7, speed = 7, spawnEvery = 2.4 }

GameConfig.BOOTH_COUNT = 6
GameConfig.BOOTH = { halfWidth = 29, depth = 60, gateInset = 2, columnX = { -9, 9, -20, 20 }, rowStart = 13, rowStep = 10 }
GameConfig.MAX_PEDESTALS = 20
GameConfig.SELL_BACK = 0.5

-- Booth frame: origin at the gate (street edge), `dir` is +1 for the north row and -1 for the south row.
function GameConfig.boothOrigin(boothIndex: number): (Vector3, number)
	local column = (boothIndex - 1) % 3
	local dir = if boothIndex <= 3 then 1 else -1
	local x = (column - 1) * 84
	return Vector3.new(x, 0, dir * (GameConfig.STREET.halfWidth + GameConfig.BOOTH.gateInset)), dir
end

-- A point `across` studs along the booth's width and `depth` studs back from its gate.
function GameConfig.boothPoint(boothIndex: number, across: number, depth: number, height: number?): Vector3
	local origin, dir = GameConfig.boothOrigin(boothIndex)
	return origin + Vector3.new(across, height or 0, depth * dir)
end

function GameConfig.pedestalPosition(boothIndex: number, slot: number): Vector3
	local booth = GameConfig.BOOTH
	local row = math.floor((slot - 1) / 4)
	local across = booth.columnX[(slot - 1) % 4 + 1]
	return GameConfig.boothPoint(boothIndex, across, booth.rowStart + row * booth.rowStep, 0)
end

function GameConfig.isInsideBooth(boothIndex: number, position: Vector3): boolean
	local origin, dir = GameConfig.boothOrigin(boothIndex)
	local depth = (position.Z - origin.Z) * dir
	return math.abs(position.X - origin.X) < GameConfig.BOOTH.halfWidth and depth > 1 and depth < GameConfig.BOOTH.depth
end

function GameConfig.isOnStreet(position: Vector3): boolean
	return math.abs(position.Z) < GameConfig.STREET.halfWidth and math.abs(position.X) < GameConfig.STREET.halfLength
end

-- Upgrades bought with cash; they survive a rebirth.
GameConfig.UPGRADES = {
	Pedestals = { title = "MORE PEDESTALS", blurb = "+2 pedestals in your booth", base = 8, per = 2, costs = { 400, 2500, 15000, 90000, 500000, 3000000 } },
	Speed = { title = "ROLLER SKATES", blurb = "+2 walk speed", base = 18, per = 2, costs = { 300, 1500, 8000, 40000, 200000 } },
	LockTime = { title = "LONGER LOCK", blurb = "+10s gate lock", base = 30, per = 10, costs = { 500, 3000, 15000, 80000, 400000 } },
}
GameConfig.UPGRADE_ORDER = { "Pedestals", "Speed", "LockTime" }
GameConfig.LOCK_COOLDOWN = 15

function GameConfig.upgradeValue(key: string, level: number): number
	local upgrade = GameConfig.UPGRADES[key]
	return upgrade.base + upgrade.per * level
end

-- Rebirth: give up cash and brainrots for a permanent income multiplier and mutation luck.
GameConfig.REBIRTH = { baseCost = 50000, growth = 6, incomePer = 0.5, luckPer = 0.25, maxShown = 99 }

function GameConfig.rebirthCost(rebirths: number): number
	return GameConfig.REBIRTH.baseCost * GameConfig.REBIRTH.growth ^ rebirths
end

function GameConfig.rebirthMultiplier(rebirths: number): number
	return 1 + GameConfig.REBIRTH.incomePer * rebirths
end

-- Popcorn Wave: the Popcorn Machine overflows and a wall of popcorn rolls west down the midway.
GameConfig.WAVE = { interval = 75, warn = 9, speed = 52, height = 15, knock = 70 }

-- Sneaky Clown thieves raid booths that are not locked.
GameConfig.THIEF = { firstAfter = 45, every = 55, walkSpeed = 15, fleeSpeed = 13, bonkRange = 7, bonkRewardShare = 0.25 }

-- Carnival events, one at a time.
GameConfig.EVENTS = {
	GoldenHour = { banner = "GOLDEN HOUR! EVERY BOOTH PAYS x2", color = Color3.fromRGB(255, 196, 40), income = 2 },
	RainbowRain = { banner = "RAINBOW RAIN! MUTATION LUCK x5", color = Color3.fromRGB(255, 105, 200), luck = 5 },
	CannonFrenzy = { banner = "CANNON FRENZY! RARE PRIZES FLY OUT", color = Color3.fromRGB(90, 170, 255), spawn = 0.45, rarityLuck = 3 },
	ButterStorm = { banner = "BUTTER STORM! ALL PRIZES 50% OFF", color = Color3.fromRGB(255, 232, 120), price = 0.5 },
}
GameConfig.EVENT_ORDER = { "GoldenHour", "RainbowRain", "CannonFrenzy", "ButterStorm" }
GameConfig.EVENT_TIMING = { firstAfter = 50, every = 95, lasts = 32 }

local SUFFIXES = { "", "K", "M", "B", "T", "Qa" }

-- 1234567 -> "1.23M"; used by every label and by the HUD.
function GameConfig.formatCash(amount: number): string
	local value = math.max(0, amount)
	local tier = 1
	while value >= 1000 and tier < #SUFFIXES do
		value /= 1000
		tier += 1
	end
	local text
	if tier == 1 then
		text = tostring(math.floor(value))
	elseif value >= 100 then
		text = string.format("%d", math.floor(value))
	elseif value >= 10 then
		text = string.format("%.1f", math.floor(value * 10) / 10)
	else
		text = string.format("%.2f", math.floor(value * 100) / 100)
	end
	return text .. SUFFIXES[tier]
end

return GameConfig
