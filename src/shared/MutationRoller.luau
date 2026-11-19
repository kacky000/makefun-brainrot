--!strict
-- Mutations: a rare roll on every brainrot that multiplies its price and income and changes its finish.

export type Mutation = {
	name: string,
	multiplier: number,
	chance: number,
	color: Color3,
	material: Enum.Material?,
	tag: string,
}

local MutationRoller = {}

MutationRoller.list = {
	{ name = "Gold", multiplier = 2, chance = 0.08, color = Color3.fromRGB(255, 200, 40), material = Enum.Material.Metal, tag = "GOLD" },
	{ name = "Buttered", multiplier = 3, chance = 0.035, color = Color3.fromRGB(255, 236, 140), material = Enum.Material.SmoothPlastic, tag = "BUTTERED" },
	{ name = "Neon", multiplier = 4, chance = 0.018, color = Color3.fromRGB(60, 255, 210), material = Enum.Material.Neon, tag = "NEON" },
	{ name = "Rainbow", multiplier = 6, chance = 0.008, color = Color3.fromRGB(255, 90, 200), material = nil, tag = "RAINBOW" },
	{ name = "Galaxy", multiplier = 10, chance = 0.003, color = Color3.fromRGB(140, 70, 255), material = Enum.Material.Neon, tag = "GALAXY" },
} :: { Mutation }

local byName: { [string]: Mutation } = {}
for _, mutation in MutationRoller.list do
	byName[mutation.name] = mutation
end

function MutationRoller.get(name: string?): Mutation?
	if name == nil or name == "" then
		return nil
	end
	return byName[name]
end

function MutationRoller.multiplier(name: string?): number
	local mutation = MutationRoller.get(name)
	return if mutation then mutation.multiplier else 1
end

-- Rolls from the rarest down, so luck raises every chance; nil means a plain brainrot.
function MutationRoller.rollMutation(luck: number, rng: Random): string?
	for index = #MutationRoller.list, 1, -1 do
		local mutation = MutationRoller.list[index]
		if rng:NextNumber() < mutation.chance * luck then
			return mutation.name
		end
	end
	return nil
end

return MutationRoller
