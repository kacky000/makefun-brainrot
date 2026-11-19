-- GameConfig: every tunable number of ROT CARNIVAL: Popcorn Panic in one place.
-- 36 brainrots, 7 rarities, 5 mutations, 4 events, 3 upgrades, rebirths, Popcorn Wave, Sneaky Clown thieves, gate LOCK.
local GameConfig = {}

GameConfig.TITLE = "ROT CARNIVAL"
GameConfig.SUBTITLE = "POPCORN PANIC"
GameConfig.START_CASH = 150 -- buys the first three Commons, so the first minute already earns

-- Rarity ladder. weight = share of Prize Cannon shots, scale = model size, so rarer reads bigger.
GameConfig.RARITIES = {
	{ name = "Common", color = Color3.fromRGB(196, 204, 214), weight = 520, scale = 1.0 },
	{ name = "Uncommon", color = Color3.fromRGB(86, 214, 110), weight = 260, scale = 1.1 },
	{ name = "Rare", color = Color3.fromRGB(64, 156, 255), weight = 120, scale = 1.2 },
	{ name = "Epic", color = Color3.fromRGB(178, 96, 255), weight = 60, scale = 1.35 },
	{ name = "Legendary", color = Color3.fromRGB(255, 190, 40), weight = 26, scale = 1.5 },
	{ name = "Mythic", color = Color3.fromRGB(255, 72, 96), weight = 10, scale = 1.7 },
	{ name = "Secret", color = Color3.fromRGB(40, 240, 230), weight = 4, scale = 2.0 },
}

-- Mutation ladder. chance is out of 1000 shots before luck; mult multiplies money a second.
GameConfig.MUTATIONS = {
	{ name = "Gold", mult = 2, chance = 80, color = Color3.fromRGB(255, 205, 50) },
	{ name = "Buttered", mult = 3, chance = 45, color = Color3.fromRGB(255, 236, 130) },
	{ name = "Neon", mult = 4, chance = 25, color = Color3.fromRGB(60, 255, 150) },
	{ name = "Rainbow", mult = 6, chance = 12, color = Color3.fromRGB(255, 110, 220) },
	{ name = "Galaxy", mult = 10, chance = 5, color = Color3.fromRGB(130, 90, 255) },
}

-- The street runs along X. The Prize Belt carries brainrots from the Prize Cannon (west) to the Popcorn Machine (east).
GameConfig.STREET = { halfWidth = 16, xMin = -150, xMax = 150 }
GameConfig.BELT = { xStart = -112, xEnd = 116, y = 2.4, speed = 6, spawnEvery = 3.4, buyRange = 13 }

-- Six booths, three a side. side = 1 is north (+Z), -1 is south.
GameConfig.BOOTH = { halfWidth = 27, depth = 60, gateHalf = 7, maxPedestals = 20, startPedestals = 8 }
GameConfig.BOOTHS = {
	{ x = 0, side = 1 },
	{ x = 0, side = -1 },
	{ x = -84, side = 1 },
	{ x = 84, side = -1 },
	{ x = 84, side = 1 },
	{ x = -84, side = -1 },
}

-- Upgrades: cost(level) = base * growth ^ level.
GameConfig.UPGRADES = {
	Pedestals = { label = "MORE PEDESTALS", per = 2, max = 6, base = 400, growth = 3.2, unit = "+2 pedestals" },
	Speed = { label = "RUN FASTER", per = 2, max = 6, base = 250, growth = 2.8, unit = "+2 walk speed" },
	Lock = { label = "LONGER LOCK", per = 10, max = 5, base = 600, growth = 3.0, unit = "+10s gate lock" },
}
GameConfig.BASE_WALK_SPEED = 18
GameConfig.CARRY_SPEED_PENALTY = 2

-- Gate lock: seconds locked, then seconds before it can lock again.
GameConfig.LOCK = { seconds = 30, cooldown = 15 }

-- Rebirth n costs base * growth ^ n and gives +50% money a second and +20% mutation luck each.
GameConfig.REBIRTH = { base = 50000, growth = 5, incomeBonus = 0.5, luckBonus = 0.2 }

-- Hazards.
GameConfig.WAVE = { every = 75, warning = 8, speed = 34, hitHalfDepth = 5, first = 45 }
GameConfig.THIEF = { every = 55, first = 70, speed = 15, escapeSpeed = 19, bonkRange = 6, bonkReward = 0.25, minBrainrots = 2 }

-- Events, one at a time, picked by EventScheduler.
GameConfig.EVENTS = {
	{ id = "GoldenHour", banner = "GOLDEN HOUR! x2 MONEY", seconds = 30, income = 2, color = Color3.fromRGB(255, 200, 40) },
	{ id = "RainbowRain", banner = "RAINBOW RAIN! x5 MUTATION LUCK", seconds = 30, luck = 5, color = Color3.fromRGB(255, 110, 220) },
	{ id = "CannonFrenzy", banner = "CANNON FRENZY! RARE SHOTS x3", seconds = 25, spawn = 0.4, rare = 3, color = Color3.fromRGB(255, 90, 60) },
	{ id = "ButterStorm", banner = "BUTTER STORM! 30% OFF + SPEED", seconds = 25, price = 0.7, speed = 6, color = Color3.fromRGB(255, 236, 130) },
}
GameConfig.EVENT_EVERY = 80
GameConfig.EVENT_FIRST = 30

GameConfig.SELL_SHARE = 0.5

return GameConfig
