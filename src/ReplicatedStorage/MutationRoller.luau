-- MutationRoller: decides whether a brainrot leaves the Prize Cannon mutated
-- (Gold x2, Buttered x3, Neon x4, Rainbow x6, Galaxy x10) and how a mutation recolours a model.

local GameConfig = require(script.Parent.GameConfig)

local MutationRoller = {}

-- Rolls from the rarest mutation down; `luck` multiplies every chance (rebirths, Rainbow Rain).
function MutationRoller.rollMutation(roll: () -> number, luck: number?): string?
	local scale = luck or 1
	for index = #GameConfig.MUTATIONS, 1, -1 do
		local mutation = GameConfig.MUTATIONS[index]
		if roll() < math.min(0.6, mutation.chance * scale) then
			return mutation.key
		end
	end
	return nil
end

function MutationRoller.multiplierOf(mutationKey: string?): number
	local mutation = mutationKey and GameConfig.MUTATION_BY_KEY[mutationKey]
	return if mutation then mutation.mult else 1
end

-- Label text such as "GOLD x2".
function MutationRoller.badgeText(mutationKey: string?): string?
	local mutation = mutationKey and GameConfig.MUTATION_BY_KEY[mutationKey]
	if not mutation then
		return nil
	end
	return string.upper(mutation.key) .. " x" .. mutation.mult
end

-- Recolours the painted parts of a brainrot model for its mutation. Eyes and teeth keep their look.
function MutationRoller.paintMutation(model: Model, mutationKey: string?)
	local mutation = mutationKey and GameConfig.MUTATION_BY_KEY[mutationKey]
	if not mutation then
		return
	end
	local index = 0
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("Paint") then
			index += 1
			if mutation.key == "Gold" then
				part.Color = Color3.fromRGB(255, 200 - (index % 3) * 18, 40)
				part.Material = Enum.Material.Foil
				part.Reflectance = 0.25
			elseif mutation.key == "Buttered" then
				part.Color = Color3.fromRGB(255, 238 - (index % 2) * 20, 140)
				part.Material = Enum.Material.Glass
				part.Reflectance = 0.15
			elseif mutation.key == "Neon" then
				part.Color = if index % 2 == 0 then Color3.fromRGB(60, 255, 120) else Color3.fromRGB(40, 230, 255)
				part.Material = Enum.Material.Neon
			elseif mutation.key == "Rainbow" then
				part.Color = Color3.fromHSV((index * 0.13) % 1, 0.85, 1)
				part.Material = Enum.Material.SmoothPlastic
			elseif mutation.key == "Galaxy" then
				part.Color = if index % 3 == 0 then Color3.fromRGB(255, 120, 255) else Color3.fromRGB(50, 30, 120)
				part.Material = if index % 3 == 0 then Enum.Material.Neon else Enum.Material.Glass
			end
		end
	end
end

return MutationRoller
