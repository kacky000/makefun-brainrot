--!strict
-- Every tuning number of ROT CARNIVAL in one place (map layout, economy, wave, thieves, upgrades)
-- and the money formatting every label shares.

local GameConfig = {
	TITLE = "ROT CARNIVAL",
	SUBTITLE = "Popcorn Panic",

	-- Map: the Midway street runs along X; the Prize Belt is its centre line, plots line both sides.
	STREET_HALF_WIDTH = 16,
	BELT_WIDTH = 8,
	BELT_START_X = -168,
	BELT_END_X = 172,
	PLOT_XS = { -108, 0, 108 },
	PLOT_SIDES = { 1, -1 }, -- +Z row (north) and -Z row (south)
	PLOT_WIDTH = 92,
	PLOT_DEPTH = 64,
	PLOT_GAP = 20, -- from the street edge to the plot's gate
	PEDESTAL_COLUMNS = 5,
	PEDESTAL_SPACING_X = 15,
	PEDESTAL_SPACING_Z = 12,

	-- Economy
	START_CASH = 100,
	BASE_PEDESTALS = 10,
	MAX_PEDESTALS = 20,
	PEDESTAL_COST_BASE = 400,
	PEDESTAL_COST_GROWTH = 2.4,
	SPEED_LEVELS = { 18, 22, 26, 30, 35 },
	SPEED_COSTS = { 0, 900, 12000, 150000, 2000000 },
	LOCK_LEVELS = { 40, 60, 80, 100 },
	LOCK_COSTS = { 0, 5000, 80000, 1200000 },
	SELL_REFUND = 0.5,
	REBIRTH_BASE_COST = 1000000,
	REBIRTH_GROWTH = 8,
	REBIRTH_INCOME_BONUS = 0.5,
	REBIRTH_LUCK_BONUS = 0.25,

	-- Prize Belt
	BELT_SPEED = 6,
	BELT_SPAWN_EVERY = 3.2,
	BELT_MAX = 26,

	-- Popcorn Wave
	WAVE_INTERVAL = 75,
	WAVE_WARNING = 12,
	WAVE_SPEED = 26,
	WAVE_HEIGHT = 28,

	-- Gate lock and thief raids
	LOCK_COOLDOWN = 20,
	RAID_EVERY = 55,
	THIEF_WALK_SPEED = 12,
	THIEF_RUN_SPEED = 14,

	-- Events
	EVENT_EVERY = 100,
	EVENT_LENGTH = 50,

	SAVE_EVERY = 60,
	DATASTORE_NAME = "RotCarnival_v1",
}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }

function GameConfig.short(value: number): string
	local n = math.floor(value)
	if n < 1000 then
		return tostring(n)
	end
	local index = 1
	local scaled: number = n
	while scaled >= 1000 and index < #SUFFIXES do
		scaled /= 1000
		index += 1
	end
	local text
	if scaled >= 100 then
		text = string.format("%d", math.floor(scaled))
	else
		text = string.format("%.1f", math.floor(scaled * 10) / 10)
		text = (string.gsub(text, "%.0$", ""))
	end
	return text .. SUFFIXES[index]
end

function GameConfig.money(value: number): string
	return "$" .. GameConfig.short(value)
end

function GameConfig.perSecond(value: number): string
	return "$" .. GameConfig.short(value) .. "/s"
end

function GameConfig.clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end

return GameConfig
