-- MutationRoller: the 5 mutations a brainrot can leave the Prize Cannon with, and their income multipliers.
local MutationRoller = {}

MutationRoller.MUTATIONS = {
	{ key = "Gold", multiplier = 2, chance = 0.08, color = Color3.fromRGB(255, 200, 40) },
	{ key = "Buttered", multiplier = 3, chance = 0.045, color = Color3.fromRGB(255, 238, 120) },
	{ key = "Neon", multiplier = 4, chance = 0.028, color = Color3.fromRGB(60, 255, 190) },
	{ key = "Rainbow", multiplier = 6, chance = 0.014, color = Color3.fromRGB(255, 110, 220) },
	{ key = "Galaxy", multiplier = 10, chance = 0.005, color = Color3.fromRGB(150, 110, 255) },
}

local byKey = {}
for _, mutation in MutationRoller.MUTATIONS do
	byKey[mutation.key] = mutation
end

-- Roll one mutation (or nil). boost scales every chance: rebirth luck times the Rainbow Rain event.
function MutationRoller.rollMutation(boost: number?, random: Random?): string?
	local rng = random or Random.new()
	local roll = rng:NextNumber()
	local scale = boost or 1
	local edge = 0
	for index = #MutationRoller.MUTATIONS, 1, -1 do
		local mutation = MutationRoller.MUTATIONS[index]
		edge += math.min(0.3, mutation.chance * scale)
		if roll < edge then
			return mutation.key
		end
	end
	return nil
end

function MutationRoller.incomeMultiplier(key: string?): number
	local mutation = key and byKey[key]
	return mutation and mutation.multiplier or 1
end

-- A mutated brainrot costs more, but less than its extra income is worth.
function MutationRoller.priceMultiplier(key: string?): number
	return 1 + (MutationRoller.incomeMultiplier(key) - 1) * 0.5
end

function MutationRoller.colorOf(key: string?): Color3?
	local mutation = key and byKey[key]
	return mutation and mutation.color or nil
end

return MutationRoller
