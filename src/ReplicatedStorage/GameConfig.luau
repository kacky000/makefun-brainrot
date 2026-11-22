-- GameConfig: every tuning number and the carnival's layout maths, shared by server and client.
-- ROT CARNIVAL: Popcorn Panic. 36 brainrots, 7 rarities, 5 mutations, popcorn wave, clown thieves, gate lock, rebirth.
local GameConfig = {}

function GameConfig.rebirthCost(rebirths: number): number
	return 2000000 * 20 ^ rebirths
end

function GameConfig.rebirthIncomeMultiplier(rebirths: number): number
	return 1 + 0.5 * rebirths
end

function GameConfig.rebirthLuck(rebirths: number): number
	return 1 + 0.35 * rebirths
end

GameConfig.TITLE = "ROT CARNIVAL"
GameConfig.SUBTITLE = "POPCORN PANIC"
GameConfig.START_MONEY = 150
GameConfig.SELL_REFUND = 0.5

-- The midway: a street along X. The Prize Cannon sits at its west end, the Popcorn Machine at its east end.
GameConfig.STREET = { minX = -176, maxX = 176, halfWidth = 22 }
GameConfig.BELT = { startX = -130, endX = 130, topY = 1.1, speed = 6.5, spawnEvery = 3.4, maxItems = 22 }

-- Six booths, three on each side of the street. dir is the side: +1 north (Z+), -1 south (Z-).
GameConfig.BOOTHS = {
	{ x = -92, dir = 1 },
	{ x = 0, dir = 1 },
	{ x = 92, dir = 1 },
	{ x = -92, dir = -1 },
	{ x = 0, dir = -1 },
	{ x = 92, dir = -1 },
}
GameConfig.BOOTH = { gateZ = 27, depth = 57, halfWidth = 27, gateHalf = 9, startPedestals = 8, maxPedestals = 20 }

-- The gate's centre on the ground, and the side of the street the booth is on.
function GameConfig.boothOrigin(booth: number): (Vector3, number)
	local spot = GameConfig.BOOTHS[booth]
	return Vector3.new(spot.x, 0, spot.dir * GameConfig.BOOTH.gateZ), spot.dir
end

-- A point in a booth's own frame: forward is into the booth from its gate, side is along the street (+X).
function GameConfig.boothPoint(booth: number, forward: number, side: number, height: number): Vector3
	local origin, dir = GameConfig.boothOrigin(booth)
	return Vector3.new(origin.X + side, height, origin.Z + dir * forward)
end

-- Where a point is in a booth's frame: forward, side.
function GameConfig.toBoothFrame(booth: number, position: Vector3): (number, number)
	local origin, dir = GameConfig.boothOrigin(booth)
	return (position.Z - origin.Z) * dir, position.X - origin.X
end

function GameConfig.isInsideBooth(booth: number, position: Vector3): boolean
	local forward, side = GameConfig.toBoothFrame(booth, position)
	return forward > 1.5 and forward < GameConfig.BOOTH.depth and math.abs(side) < GameConfig.BOOTH.halfWidth
end

-- Pedestal slots: 1..10 line the red carpet, 11..20 are the outer rows bought with upgrades.
function GameConfig.pedestalPoint(booth: number, slot: number): Vector3
	local inner = slot <= 10
	local index = inner and slot or slot - 10
	local row = math.ceil(index / 2)
	local sideSign = (index % 2 == 1) and -1 or 1
	local side = sideSign * (inner and 9.5 or 19.5)
	return GameConfig.boothPoint(booth, 3.5 + row * 9.5, side, 0)
end

GameConfig.PEDESTAL_TOP = 2.4

GameConfig.UPGRADES = {
	pedestals = { title = "MORE PEDESTALS", blurb = "+2 pedestals", maxLevel = 6, baseCost = 2500, growth = 3 },
	speed = { title = "FASTER SHOES", blurb = "+2 walk speed", maxLevel = 5, baseCost = 1500, growth = 2.5 },
	lock = { title = "LONGER LOCK", blurb = "+8s gate lock", maxLevel = 5, baseCost = 2000, growth = 2.5 },
}
GameConfig.UPGRADE_ORDER = { "pedestals", "speed", "lock" }

function GameConfig.upgradeCost(key: string, level: number): number
	local spec = GameConfig.UPGRADES[key]
	return math.floor(spec.baseCost * spec.growth ^ level)
end

function GameConfig.pedestalCount(level: number): number
	return math.min(GameConfig.BOOTH.maxPedestals, GameConfig.BOOTH.startPedestals + 2 * level)
end

function GameConfig.walkSpeed(level: number): number
	return 18 + 2 * level
end

function GameConfig.lockSeconds(level: number): number
	return 20 + 8 * level
end

GameConfig.LOCK_COOLDOWN = 25

GameConfig.WAVE = { every = 75, warning = 8, speed = 46, hitRange = 7 }
GameConfig.THIEF = { firstAfter = 50, minOwned = 3, minGap = 70, maxGap = 110, walkSpeed = 15, fleeSpeed = 13, bonkRange = 7 }

GameConfig.EVENTS = {
	GoldenHour = { title = "GOLDEN HOUR! x2 INCOME", color = Color3.fromRGB(255, 196, 40), seconds = 40 },
	RainbowRain = { title = "RAINBOW RAIN! x4 MUTATIONS", color = Color3.fromRGB(255, 96, 200), seconds = 40 },
	CannonFrenzy = { title = "CANNON FRENZY! x3 PRIZES", color = Color3.fromRGB(80, 200, 255), seconds = 35 },
	ButterStorm = { title = "BUTTER STORM! HALF PRICE", color = Color3.fromRGB(255, 232, 110), seconds = 30 },
}
GameConfig.EVENT_ORDER = { "GoldenHour", "RainbowRain", "CannonFrenzy", "ButterStorm" }
GameConfig.EVENT_GAP = 95

local SUFFIXES = { "", "K", "M", "B", "T" }

function GameConfig.formatMoney(amount: number): string
	local value = math.max(0, amount)
	local tier = 1
	while value >= 1000 and tier < #SUFFIXES do
		value /= 1000
		tier += 1
	end
	if tier == 1 then
		return "$" .. tostring(math.floor(value))
	end
	return string.format("$%.2f%s", math.floor(value * 100) / 100, SUFFIXES[tier])
end

return GameConfig
