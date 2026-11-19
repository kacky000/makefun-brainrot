--!strict
-- Shape helpers the hand-built cast is written with: blocks, balls, cylinders and googly eyes as part specs.

local PartShapes = {}

local rgb = Color3.fromRGB
local v3 = Vector3.new

function PartShapes.block(sx, sy, sz, x, y, z, color, extra: { [string]: any }?): any
	local spec: any = { shape = "Block", size = v3(sx, sy, sz), pos = v3(x, y, z), color = color }
	if extra then
		for key, value in extra do
			spec[key] = value
		end
	end
	return spec
end

function PartShapes.ball(d, x, y, z, color, extra: { [string]: any }?): any
	local spec = PartShapes.block(d, d, d, x, y, z, color, extra)
	spec.shape = "Ball"
	return spec
end

-- An upright cylinder: height along Y.
function PartShapes.pillar(height, diameter, x, y, z, color, extra: { [string]: any }?): any
	local spec = PartShapes.block(height, diameter, diameter, x, y, z, color, extra)
	spec.shape = "Cylinder"
	spec.rot = v3(0, 0, 90)
	return spec
end

-- A cylinder lying along X (a wheel seen from the side, a log across).
function PartShapes.wheel(width, diameter, x, y, z, color, extra: { [string]: any }?): any
	local spec = PartShapes.block(width, diameter, diameter, x, y, z, color, extra)
	spec.shape = "Cylinder"
	return spec
end

-- A cylinder lying along Z (a rocket, a tail).
function PartShapes.tube(length, diameter, x, y, z, color, extra: { [string]: any }?): any
	local spec = PartShapes.block(length, diameter, diameter, x, y, z, color, extra)
	spec.shape = "Cylinder"
	spec.rot = v3(0, 90, 0)
	return spec
end

-- Two googly eyes on the front face at height y, surface z.
function PartShapes.eyes(y, z, spacing, size): { any }
	local white = rgb(255, 255, 255)
	local black = rgb(20, 20, 25)
	return {
		PartShapes.ball(size, -spacing, y, z, white, { keep = true }),
		PartShapes.ball(size, spacing, y, z, white, { keep = true }),
		PartShapes.ball(size * 0.5, -spacing + size * 0.08, y - size * 0.05, z - size * 0.32, black, { keep = true }),
		PartShapes.ball(size * 0.5, spacing - size * 0.08, y + size * 0.06, z - size * 0.32, black, { keep = true }),
	}
end

function PartShapes.join(...: { any }): { any }
	local out = {}
	for _, list in { ... } do
		for _, spec in list do
			table.insert(out, spec)
		end
	end
	return out
end

return PartShapes
