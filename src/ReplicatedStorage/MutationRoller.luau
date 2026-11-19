-- MutationRoller: rolls one of 5 mutations for a brainrot as the Prize Cannon fires it.
local GameConfig = require(script.Parent.GameConfig)

local MutationRoller = {}
local rng = Random.new()

function MutationRoller.rollMutation(luck) -- Gold Buttered Neon Rainbow Galaxy
	local roll = rng:NextNumber(0, 1000)
	local edge = 0
	-- Rarest first, so luck stretches the rare bands before the common ones.
	for i = #GameConfig.MUTATIONS, 1, -1 do
		local mutation = GameConfig.MUTATIONS[i]
		edge += mutation.chance * luck
		if roll < edge then
			return mutation.name
		end
	end
	return nil
end

function MutationRoller.incomeMultiplier(mutationName: string?): number
	local mutation = MutationRoller.find(mutationName)
	return if mutation then mutation.mult else 1
end

function MutationRoller.find(mutationName: string?)
	if not mutationName then
		return nil
	end
	for _, mutation in GameConfig.MUTATIONS do
		if mutation.name == mutationName then
			return mutation
		end
	end
	return nil
end

return MutationRoller
