-- BrainrotModels: builds each brainrot of the cast as a 3D model out of parts (a body, googly eyes, buck teeth,
-- little legs and its accessories), paints its mutation, and hangs its name / rarity / $ a second label card.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local GameConfig = require(ReplicatedStorage.GameConfig)
local MutationRoller = require(ReplicatedStorage.MutationRoller)

local BrainrotModels = {}

local DARK = Color3.fromRGB(40, 30, 34)
local WHITE = Color3.fromRGB(255, 255, 255)
local GOLD = Color3.fromRGB(255, 205, 50)
local RED = Color3.fromRGB(232, 60, 60)
local RAINBOW = {
	Color3.fromRGB(255, 80, 80),
	Color3.fromRGB(255, 170, 60),
	Color3.fromRGB(255, 235, 80),
	Color3.fromRGB(90, 220, 110),
	Color3.fromRGB(80, 170, 255),
	Color3.fromRGB(190, 110, 255),
}
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2)
local FACING = CFrame.Angles(math.pi / 2, 0, 0)

local function newPart(m: Model, shape: Enum.PartType, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = m
	return p
end

local function blk(m, sx, sy, sz, x, y, z, color, rot: CFrame?, material: Enum.Material?)
	return newPart(m, Enum.PartType.Block, Vector3.new(sx, sy, sz), CFrame.new(x, y, z) * (rot or CFrame.identity), color, material)
end

local function ball(m, d, x, y, z, color, material: Enum.Material?)
	return newPart(m, Enum.PartType.Ball, Vector3.new(d, d, d), CFrame.new(x, y, z), color, material)
end

-- cyl: a cylinder standing upright unless rot tips it (FACING turns its flat face to the front).
local function cyl(m, d, h, x, y, z, color, rot: CFrame?, material: Enum.Material?)
	return newPart(m, Enum.PartType.Cylinder, Vector3.new(h, d, d), CFrame.new(x, y, z) * (rot or CFrame.identity) * UPRIGHT, color, material)
end

-- Each body returns where its face, top and sides are, so accessories and the label know where to sit.
local BODIES = {}

function BODIES.ball(m, c)
	ball(m, 3.2, 0, 2.7, 0, c[1])
	ball(m, 2.2, 0, 2.2, -0.5, c[2])
	return { top = 4.3, faceY = 3.1, faceZ = -1.5, half = 1.6 }
end

function BODIES.block(m, c)
	blk(m, 3, 3, 2.4, 0, 2.6, 0, c[1])
	for i = -1, 1, 2 do
		blk(m, 3.06, 0.14, 2.46, 0, 2.6 + i * 0.95, 0, c[2])
		blk(m, 0.14, 3.06, 2.46, i * 0.95, 2.6, 0, c[2])
	end
	return { top = 4.1, faceY = 3.0, faceZ = -1.24, half = 1.5 }
end

function BODIES.toast(m, c)
	blk(m, 3.5, 3.6, 0.8, 0, 2.9, 0, c[2])
	blk(m, 3.1, 3.2, 0.96, 0, 2.9, 0, c[1])
	ball(m, 1.5, -0.95, 4.5, 0, c[2])
	ball(m, 1.5, 0.95, 4.5, 0, c[2])
	blk(m, 0.9, 0.5, 0.2, 0.8, 2.0, -0.5, c[3])
	return { top = 5.0, faceY = 3.4, faceZ = -0.5, half = 1.75 }
end

function BODIES.cup(m, c)
	cyl(m, 2.8, 3, 0, 2.6, 0, c[1])
	cyl(m, 3.0, 0.25, 0, 4.1, 0, c[2])
	cyl(m, 2.5, 0.12, 0, 4.2, 0, c[3])
	cyl(m, 2.9, 0.7, 0, 1.7, 0, c[2])
	blk(m, 0.4, 1.6, 0.5, 1.8, 2.7, 0.2, c[2])
	blk(m, 0.6, 0.35, 0.5, 1.5, 3.4, 0.2, c[2])
	blk(m, 0.6, 0.35, 0.5, 1.5, 2.0, 0.2, c[2])
	return { top = 4.25, faceY = 3.2, faceZ = -1.38, half = 1.4 }
end

function BODIES.tube(m, c)
	cyl(m, 1.9, 3.6, 0, 2.9, 0, c[1])
	ball(m, 1.9, 0, 4.7, 0, c[1])
	blk(m, 0.7, 3.0, 1.7, -1.0, 2.8, 0.15, c[2])
	blk(m, 0.7, 3.0, 1.7, 1.0, 2.8, 0.15, c[2])
	for i = 0, 3 do
		ball(m, 0.45, (i % 2 - 0.5) * 0.5, 1.6 + i * 0.35, -0.95, c[3])
	end
	return { top = 5.6, faceY = 4.0, faceZ = -0.93, half = 1.35 }
end

function BODIES.banana(m, c)
	blk(m, 1.4, 1.7, 1.3, 0.45, 1.9, 0, c[1], CFrame.Angles(0, 0, math.rad(28)))
	blk(m, 1.4, 1.6, 1.3, 0, 3.1, 0, c[1])
	blk(m, 1.4, 1.7, 1.3, 0.45, 4.3, 0, c[1], CFrame.Angles(0, 0, math.rad(-28)))
	blk(m, 0.5, 0.5, 0.5, 1.0, 5.2, 0, c[2])
	blk(m, 0.45, 0.4, 0.45, 0.95, 1.05, 0, c[2])
	return { top = 5.4, faceY = 3.5, faceZ = -0.66, half = 1.0 }
end

function BODIES.cone(m, c)
	for i = 0, 3 do
		cyl(m, 2.4 - i * 0.5, 0.66, 0, 3.05 - i * 0.62, 0, c[1])
	end
	ball(m, 2.9, 0, 4.4, 0, c[2])
	ball(m, 1.9, 0.2, 5.9, 0.1, c[3])
	return { top = 6.8, faceY = 4.6, faceZ = -1.38, half = 1.45 }
end

function BODIES.donut(m, c)
	cyl(m, 3.6, 1.2, 0, 2.9, 0, c[1], FACING)
	cyl(m, 3.3, 0.2, 0, 2.9, -0.62, c[2], FACING)
	cyl(m, 1.1, 0.26, 0, 2.6, -0.66, DARK, FACING)
	return { top = 4.7, faceY = 3.75, faceZ = -0.72, half = 1.8, noMouth = true }
end

function BODIES.slice(m, c)
	blk(m, 3.5, 0.75, 0.7, 0, 4.4, 0, c[2])
	blk(m, 3.0, 1.0, 0.5, 0, 3.55, 0, c[1])
	blk(m, 2.1, 1.0, 0.5, 0, 2.55, 0, c[1])
	blk(m, 1.2, 0.9, 0.5, 0, 1.65, 0, c[1])
	cyl(m, 0.6, 0.1, 1.05, 3.8, -0.27, c[3], FACING)
	cyl(m, 0.55, 0.1, -0.55, 2.3, -0.27, c[3], FACING)
	cyl(m, 0.5, 0.1, 0.15, 1.55, -0.27, c[3], FACING)
	return { top = 4.8, faceY = 3.45, faceZ = -0.26, half = 1.7 }
end

function BODIES.bucket(m, c)
	blk(m, 2.6, 2.5, 2.6, 0, 2.35, 0, c[2])
	for i = -1, 1 do
		blk(m, 0.45, 2.5, 2.68, i * 0.95, 2.35, 0, c[1])
	end
	local puffs = { { -0.8, 3.9, -0.6 }, { 0.7, 3.95, -0.7 }, { 0, 4.3, 0 }, { -0.7, 3.9, 0.7 }, { 0.8, 4.0, 0.6 }, { 0.1, 4.9, -0.1 }, { -0.5, 4.5, 0.2 }, { 0.6, 4.6, 0.3 } }
	for i, at in puffs do
		ball(m, 1.15 - (i % 3) * 0.12, at[1], at[2], at[3], if i % 2 == 0 then c[3] else WHITE)
	end
	return { top = 5.3, faceY = 2.75, faceZ = -1.36, half = 1.3 }
end

function BODIES.knot(m, c)
	for i = 0, 15 do
		local t = i / 16 * math.pi * 2
		ball(m, 0.8, 1.6 * math.sin(t), 3.1 + 1.1 * math.sin(2 * t), 0.25 * math.cos(t), c[1])
	end
	for i = 0, 5 do
		ball(m, 0.22, -1.3 + i * 0.52, 3.1 + ((i * 7) % 5 - 2) * 0.3, -0.42, c[2])
	end
	return { top = 4.5, faceY = 3.3, faceZ = -0.3, half = 1.9 }
end

function BODIES.sock(m, c)
	blk(m, 1.7, 2.8, 1.7, 0, 3.4, 0.4, c[1])
	blk(m, 1.7, 1.4, 3.1, 0, 1.8, -0.3, c[1])
	blk(m, 1.8, 0.7, 1.8, 0, 4.7, 0.4, c[2])
	blk(m, 1.76, 1.0, 0.8, 0, 1.7, -1.5, c[2])
	blk(m, 1.76, 0.9, 0.8, 0, 1.7, 1.0, c[2])
	return { top = 5.05, faceY = 3.6, faceZ = -0.47, half = 0.9 }
end

function BODIES.jelly(m, c)
	cyl(m, 3.9, 0.22, 0, 1.2, 0, c[3])
	local wobble = blk(m, 3, 2.3, 3, 0, 2.45, 0, c[1])
	wobble.Transparency = 0.3
	local dome = ball(m, 2.9, 0, 3.5, 0, c[1])
	dome.Transparency = 0.3
	ball(m, 0.7, -0.6, 2.4, 0.3, c[2])
	ball(m, 0.6, 0.7, 2.9, -0.2, c[2])
	ball(m, 0.5, 0.1, 3.7, 0.4, c[2])
	return { top = 4.95, faceY = 2.9, faceZ = -1.52, half = 1.5 }
end

function BODIES.capsule(m, c)
	cyl(m, 2.7, 1.8, 0, 3.1, 0, c[1])
	ball(m, 2.7, 0, 4.0, 0, c[1])
	ball(m, 2.7, 0, 2.2, 0, c[1])
	ball(m, 2.0, 0, 2.5, -0.55, c[2])
	return { top = 5.35, faceY = 4.1, faceZ = -1.28, half = 1.35 }
end

function BODIES.cloud(m, c)
	local puffs = { { 0, 3.5, 0, 2.4 }, { -1.0, 3.2, 0.1, 1.8 }, { 1.0, 3.2, -0.1, 1.8 }, { -0.5, 4.3, 0, 1.7 }, { 0.6, 4.3, 0.1, 1.7 }, { 0, 2.6, 0.2, 1.9 }, { 0, 3.6, 0.8, 1.8 } }
	for _, at in puffs do
		ball(m, at[4], at[1], at[2], at[3], c[1])
	end
	for i = 0, 2 do
		cyl(m, 1.1 - i * 0.3, 0.5, 0, 1.7 - i * 0.4, 0, WHITE)
	end
	return { top = 5.15, faceY = 3.7, faceZ = -1.18, half = 1.7 }
end

function BODIES.trophy(m, c)
	blk(m, 2.3, 0.6, 2.3, 0, 1.4, 0, DARK)
	cyl(m, 0.7, 1.2, 0, 2.3, 0, c[1], nil, Enum.Material.Metal)
	cyl(m, 2.2, 1.2, 0, 3.4, 0, c[1], nil, Enum.Material.Metal)
	cyl(m, 2.9, 1.1, 0, 4.45, 0, c[1], nil, Enum.Material.Metal)
	cyl(m, 3.1, 0.2, 0, 5.05, 0, c[2], nil, Enum.Material.Metal)
	for i = -1, 1, 2 do
		blk(m, 0.35, 1.5, 0.4, i * 1.8, 4.0, 0, c[1], nil, Enum.Material.Metal)
		blk(m, 0.5, 0.35, 0.4, i * 1.55, 4.7, 0, c[1], nil, Enum.Material.Metal)
	end
	ball(m, 0.7, 0, 5.5, 0, c[3], Enum.Material.Neon)
	return { top = 5.8, faceY = 4.3, faceZ = -1.45, half = 1.6 }
end

function BODIES.tent(m, c)
	cyl(m, 3.8, 1.7, 0, 1.95, 0, c[2])
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		blk(m, 0.9, 1.72, 0.3, math.sin(a) * 1.78, 1.95, math.cos(a) * 1.78, c[1], CFrame.Angles(0, a, 0))
	end
	for i = 0, 4 do
		cyl(m, 4.3 - i * 0.85, 0.62, 0, 3.05 + i * 0.6, 0, if i % 2 == 0 then c[1] else c[2])
	end
	return { top = 5.8, faceY = 3.75, faceZ = -1.72, half = 1.9 }
end

function BODIES.slot(m, c)
	blk(m, 3.0, 3.8, 2.2, 0, 3.0, 0, c[1])
	blk(m, 2.5, 1.0, 0.12, 0, 2.3, -1.12, c[3])
	for i = -1, 1 do
		blk(m, 0.62, 0.8, 0.14, i * 0.8, 2.3, -1.16, if i == 0 then RED else c[2])
	end
	blk(m, 2.6, 0.7, 1.0, 0, 5.2, 0, c[2], nil, Enum.Material.Neon)
	blk(m, 2.4, 0.3, 0.7, 0, 1.3, -1.3, c[2])
	return { top = 5.55, faceY = 4.1, faceZ = -1.12, half = 1.5, noMouth = true }
end

-- Accessories. Each reads the body's metrics M and may raise M.top so the next one stacks above it.
local ACCESSORIES = {}

function ACCESSORIES.neck(m, M, c)
	cyl(m, 0.8, 2.6, 0, M.top + 1.0, 0, c[2])
	ball(m, 1.7, 0, M.top + 2.7, -0.1, c[2])
	for i = 0, 2 do
		ball(m, 0.35, (i % 2 - 0.5) * 0.5, M.top + 0.4 + i * 0.7, -0.38, c[3])
	end
	M.armY = M.faceY - 0.6
	M.faceY = M.top + 2.9
	M.faceZ = -0.82
	M.top += 3.55
	M.headHalf = 0.85
end

function ACCESSORIES.arms(m, M)
	for i = -1, 1, 2 do
		cyl(m, 0.34, 1.4, i * (M.half + 0.5), M.armY, 0, DARK, CFrame.Angles(0, 0, i * math.rad(55)))
		ball(m, 0.6, i * (M.half + 1.1), M.armY + 0.45, 0, WHITE)
	end
end

function ACCESSORIES.bigarms(m, M, c)
	for i = -1, 1, 2 do
		ball(m, 1.2, i * (M.half + 0.4), M.armY + 0.3, 0, c[1])
		cyl(m, 0.9, 1.7, i * (M.half + 0.95), M.armY + 1.2, 0, c[1], CFrame.Angles(0, 0, i * math.rad(-22)))
		ball(m, 1.1, i * (M.half + 1.3), M.armY + 2.2, 0, WHITE)
	end
	M.fistY = M.armY + 2.2
end

function ACCESSORIES.mustache(m, M)
	local brown = Color3.fromRGB(70, 42, 20)
	local w = M.headHalf or 1
	for i = -1, 1, 2 do
		blk(m, 0.9, 0.3, 0.22, i * 0.5, M.faceY - 0.55, M.faceZ - 0.12, brown, CFrame.Angles(0, 0, i * math.rad(-18)))
		ball(m, 0.42, i * math.min(1.05, w + 0.2), M.faceY - 0.45, M.faceZ - 0.12, brown)
	end
end

function ACCESSORIES.tophat(m, M)
	cyl(m, 2.1, 0.16, 0, M.top + 0.05, 0, DARK)
	cyl(m, 1.35, 1.3, 0, M.top + 0.75, 0, DARK)
	cyl(m, 1.4, 0.3, 0, M.top + 0.3, 0, RED)
	M.top += 1.4
end

function ACCESSORIES.partyhat(m, M, c)
	for i = 0, 3 do
		cyl(m, 1.3 - i * 0.33, 0.46, 0, M.top + 0.2 + i * 0.44, 0, if i % 2 == 0 then c[3] else WHITE)
	end
	ball(m, 0.5, 0, M.top + 2.1, 0, RED)
	M.top += 2.3
end

function ACCESSORIES.crown(m, M)
	cyl(m, 1.9, 0.5, 0, M.top + 0.2, 0, GOLD, nil, Enum.Material.Metal)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		blk(m, 0.32, 0.7, 0.32, math.sin(a) * 0.78, M.top + 0.7, math.cos(a) * 0.78, GOLD, nil, Enum.Material.Metal)
		ball(m, 0.3, math.sin(a) * 0.78, M.top + 1.15, math.cos(a) * 0.78, RED, Enum.Material.Neon)
	end
	M.top += 1.3
end

function ACCESSORIES.beak(m, M)
	local orange = Color3.fromRGB(255, 150, 40)
	blk(m, 0.8, 0.3, 1.0, 0, M.faceY - 0.5, M.faceZ - 0.45, orange)
	blk(m, 0.65, 0.22, 0.8, 0, M.faceY - 0.8, M.faceZ - 0.35, orange, CFrame.Angles(math.rad(-14), 0, 0))
	M.noMouth = true
end

function ACCESSORIES.wings(m, M, c)
	for i = -1, 1, 2 do
		blk(m, 0.25, 1.7, 1.3, i * (M.half + 0.25), M.armY + 0.5, 0.3, c[2], CFrame.Angles(0, 0, i * math.rad(-32)))
		blk(m, 0.22, 1.3, 1.0, i * (M.half + 0.75), M.armY + 1.0, 0.5, c[2], CFrame.Angles(0, 0, i * math.rad(-52)))
		blk(m, 0.2, 0.9, 0.7, i * (M.half + 1.2), M.armY + 1.35, 0.7, c[3], CFrame.Angles(0, 0, i * math.rad(-70)))
	end
end

function ACCESSORIES.propeller(m, M, c)
	cyl(m, 0.16, 0.7, 0, M.top + 0.3, 0, DARK)
	blk(m, 2.6, 0.1, 0.42, 0, M.top + 0.7, 0, c[3], CFrame.Angles(0, math.rad(20), 0))
	blk(m, 0.42, 0.1, 2.6, 0, M.top + 0.72, 0, RED, CFrame.Angles(0, math.rad(20), 0))
	ball(m, 0.35, 0, M.top + 0.75, 0, GOLD)
	M.top += 0.9
end

function ACCESSORIES.stink(m, M)
	local green = Color3.fromRGB(150, 220, 80)
	for i = 0, 8 do
		local puff = ball(m, 0.45 - (i % 3) * 0.08, -0.9 + (i // 3) * 0.9 + math.sin(i) * 0.2, M.top + 0.4 + (i % 3) * 0.5, 0, green)
		puff.Transparency = 0.35
	end
	M.top += 1.5
end

function ACCESSORIES.wheels(m, M)
	for i = -1, 1, 2 do
		for j = -1, 1, 2 do
			newPart(m, Enum.PartType.Cylinder, Vector3.new(0.45, 1.1, 1.1), CFrame.new(i * (M.half + 0.15), 0.55, j * 0.85), DARK)
			newPart(m, Enum.PartType.Cylinder, Vector3.new(0.5, 0.45, 0.45), CFrame.new(i * (M.half + 0.17), 0.55, j * 0.85), GOLD)
		end
	end
end

function ACCESSORIES.glasses(m, M)
	for i = -1, 1, 2 do
		blk(m, 1.0, 0.62, 0.16, i * 0.56, M.faceY, M.faceZ - 0.72, DARK)
	end
	blk(m, 0.4, 0.14, 0.14, 0, M.faceY + 0.1, M.faceZ - 0.72, DARK)
end

function ACCESSORIES.cherry(m, M)
	ball(m, 0.85, 0, M.top + 0.35, 0, RED)
	cyl(m, 0.1, 0.6, 0.15, M.top + 0.95, 0, Color3.fromRGB(70, 150, 60), CFrame.Angles(0, 0, math.rad(-20)))
	M.top += 1.2
end

function ACCESSORIES.ears(m, M, c)
	local w = M.headHalf or M.half
	for i = -1, 1, 2 do
		blk(m, 0.7, 1.0, 0.3, i * w * 0.62, M.top + 0.2, 0, c[1], CFrame.Angles(0, 0, i * math.rad(-16)))
		blk(m, 0.36, 0.6, 0.32, i * w * 0.62, M.top + 0.15, -0.02, Color3.fromRGB(255, 160, 190), CFrame.Angles(0, 0, i * math.rad(-16)))
	end
end

function ACCESSORIES.bigears(m, M, c)
	for i = -1, 1, 2 do
		cyl(m, 2.3, 0.22, i * (M.half + 0.85), M.faceY + 0.2, 0.25, c[2], FACING)
		cyl(m, 1.5, 0.24, i * (M.half + 0.85), M.faceY + 0.2, 0.22, c[3], FACING)
	end
end

function ACCESSORIES.tail(m, M, c)
	cyl(m, 0.32, 1.6, 0, 2.2, -M.faceZ + 0.75, c[2], CFrame.Angles(math.rad(55), 0, 0))
	ball(m, 0.6, 0, 2.7, -M.faceZ + 1.45, c[3])
end

function ACCESSORIES.rainbowtail(m, M)
	for i, color in RAINBOW do
		blk(m, 0.34, 2.2, 0.3, (i - 3.5) * 0.36, 2.6, -M.faceZ + 0.8 + math.abs(i - 3.5) * 0.12, color, CFrame.Angles(math.rad(38), 0, 0), Enum.Material.Neon)
	end
end

function ACCESSORIES.spring(m)
	for i = 0, 5 do
		cyl(m, 1.5 - (i % 2) * 0.25, 0.12, 0, 0.15 + i * 0.2, 0, Color3.fromRGB(170, 176, 190), nil, Enum.Material.Metal)
	end
end

function ACCESSORIES.stick(m, M, c)
	local x = M.half + 1.15
	cyl(m, 0.2, 3.2, x, M.armY + 0.9, -0.2, WHITE)
	cyl(m, 1.5, 0.36, x, M.armY + 2.9, -0.2, c[2], FACING)
	cyl(m, 0.8, 0.4, x, M.armY + 2.9, -0.2, WHITE, FACING)
	cyl(m, 0.3, 0.44, x, M.armY + 2.9, -0.2, c[2], FACING)
end

function ACCESSORIES.eyestalks(m, M, c)
	for i = -1, 1, 2 do
		cyl(m, 0.22, 1.0, i * 0.62, M.top + 0.35, -0.1, c[1])
	end
	M.mouthY = M.mouthY or (M.faceY - 0.85)
	M.mouthZ = M.faceZ
	M.faceY = M.top + 1.1
	M.eyeZ = 0.05
	M.top += 1.6
end

function ACCESSORIES.sprinkles(m, M)
	local rng = Random.new(#m:GetChildren())
	for i = 1, 12 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(0.2, M.half * 0.75)
		blk(m, 0.14, 0.14, 0.4, math.sin(a) * r, M.top - 0.25 + rng:NextNumber(0, 0.2), math.cos(a) * r * 0.5, RAINBOW[i % 6 + 1], CFrame.Angles(0, a, 0.5))
	end
end

function ACCESSORIES.juggle(m, M, c)
	local spots = { { -1.3, 0.9 }, { 0, 1.7 }, { 1.3, 0.9 } }
	for i, at in spots do
		ball(m, 0.75, at[1], M.top + at[2], -0.2, RAINBOW[i * 2 - 1])
	end
	M.top += 2.1
end

function ACCESSORIES.bowtie(m, M)
	local y = (M.mouthY or (M.faceY - 0.85)) - 0.75
	local z = (M.mouthZ or M.faceZ) - 0.12
	for i = -1, 1, 2 do
		blk(m, 0.7, 0.55, 0.2, i * 0.45, y, z, RED, CFrame.Angles(0, 0, i * math.rad(12)))
	end
	ball(m, 0.36, 0, y, z - 0.05, GOLD)
end

function ACCESSORIES.claws(m, M, c)
	for i = -1, 1, 2 do
		cyl(m, 0.36, 1.3, i * (M.half + 0.5), M.armY + 0.3, 0, c[1], CFrame.Angles(0, 0, i * math.rad(-40)))
		blk(m, 0.9, 0.5, 0.5, i * (M.half + 1.1), M.armY + 1.25, 0, c[1], CFrame.Angles(0, 0, i * math.rad(25)))
		blk(m, 0.9, 0.42, 0.5, i * (M.half + 1.15), M.armY + 0.75, 0, c[1], CFrame.Angles(0, 0, i * math.rad(-20)))
	end
end

function ACCESSORIES.neckfluff(m, M)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		ball(m, 0.9, math.sin(a) * M.half * 0.85, M.top - 0.15, math.cos(a) * M.half * 0.85, WHITE)
	end
end

function ACCESSORIES.balloon(m, M, c)
	local x = -(M.half + 0.9)
	cyl(m, 0.07, 3.0, x, M.armY + 1.9, 0, WHITE)
	ball(m, 1.7, x, M.armY + 4.1, 0, c[3])
	blk(m, 0.25, 0.25, 0.25, x, M.armY + 3.2, 0, c[3])
end

function ACCESSORIES.tentacles(m, M, c)
	for i = 0, 5 do
		local a = (i + 0.5) / 6 * math.pi * 2
		for j = 0, 2 do
			local r = M.half * 0.7 + j * 0.55
			ball(m, 0.75 - j * 0.15, math.sin(a) * r, 1.45 - j * 0.42, math.cos(a) * r, c[2])
		end
	end
end

function ACCESSORIES.antlers(m, M, c)
	for i = -1, 1, 2 do
		blk(m, 0.26, 1.5, 0.26, i * 0.7, M.top + 0.55, 0, c[2], CFrame.Angles(0, 0, i * math.rad(-22)))
		blk(m, 0.22, 0.8, 0.22, i * 1.15, M.top + 0.95, 0, c[2], CFrame.Angles(0, 0, i * math.rad(-60)))
		blk(m, 0.22, 0.7, 0.22, i * 0.62, M.top + 1.2, 0, c[2], CFrame.Angles(0, 0, i * math.rad(20)))
	end
	M.top += 1.6
end

function ACCESSORIES.fin(m, M, c)
	blk(m, 0.3, 1.3, 1.5, 0, M.top + 0.25, 0.35, c[1], CFrame.Angles(math.rad(-28), 0, 0))
	M.top += 0.8
end

function ACCESSORIES.teeth(m, M)
	M.bigTeeth = true
end

function ACCESSORIES.trunk(m, M, c)
	for i = 0, 4 do
		ball(m, 0.85 - i * 0.1, 0, M.faceY - 0.5 - i * 0.42, M.faceZ - 0.25 - i * 0.28, c[2])
	end
	M.noMouth = true
end

function ACCESSORIES.stripes(m, M, c)
	for _, y in { M.faceY - 1.45, M.faceY + 0.8 } do
		blk(m, M.half * 2 + 0.08, 0.26, -M.faceZ * 2 + 0.08, 0, y, 0, c[2])
	end
	for i = -1, 1, 2 do
		blk(m, 0.3, 0.9, -M.faceZ * 2 + 0.1, i * (M.half - 0.3), M.faceY - 0.3, 0, c[2])
	end
end

function ACCESSORIES.hoop(m, M, c)
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		ball(m, 0.42, math.sin(a) * (M.half + 0.9), 2.0 + math.sin(a) * 0.5, math.cos(a) * (M.half + 0.9), if i % 2 == 0 then c[3] else c[2], Enum.Material.Neon)
	end
end

function ACCESSORIES.horn(m, M, c)
	for i = 0, 3 do
		cyl(m, 0.62 - i * 0.15, 0.42, 0, M.faceY + 0.75 + i * 0.36, M.faceZ + 0.1 - i * 0.12, c[3], CFrame.Angles(math.rad(-22), 0, 0))
	end
end

function ACCESSORIES.cape(m, M)
	blk(m, M.half * 2 + 0.5, 2.9, 0.16, 0, M.armY - 0.2, -M.faceZ + 0.35, RED, CFrame.Angles(math.rad(-10), 0, 0))
	blk(m, M.half * 2 + 0.6, 0.4, 0.5, 0, M.armY + 1.2, -M.faceZ + 0.1, GOLD)
end

function ACCESSORIES.flame(m, M)
	local z = 0.5
	ball(m, 1.0, 0, M.top + 0.35, z, Color3.fromRGB(255, 110, 30), Enum.Material.Neon)
	ball(m, 0.7, 0.1, M.top + 0.95, z, Color3.fromRGB(255, 190, 40), Enum.Material.Neon)
	ball(m, 0.4, -0.05, M.top + 1.4, z, Color3.fromRGB(255, 240, 120), Enum.Material.Neon)
	M.top += 1.6
end

function ACCESSORIES.barbell(m, M)
	local y = (M.fistY or (M.top + 1)) + 0.5
	newPart(m, Enum.PartType.Cylinder, Vector3.new(6.2, 0.26, 0.26), CFrame.new(0, y, 0), Color3.fromRGB(170, 176, 190), Enum.Material.Metal)
	for i = -1, 1, 2 do
		newPart(m, Enum.PartType.Cylinder, Vector3.new(0.45, 1.7, 1.7), CFrame.new(i * 2.9, y, 0), DARK)
		newPart(m, Enum.PartType.Cylinder, Vector3.new(0.35, 1.2, 1.2), CFrame.new(i * 3.3, y, 0), DARK)
	end
	M.top = math.max(M.top, y + 0.9)
end

function ACCESSORIES.scepter(m, M, c)
	local x = M.half + 1.3
	cyl(m, 0.22, 3.4, x, (M.fistY or M.armY) + 0.6, -0.1, GOLD, nil, Enum.Material.Metal)
	ball(m, 0.9, x, (M.fistY or M.armY) + 2.5, -0.1, c[3], Enum.Material.Neon)
end

function ACCESSORIES.halo(m, M)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		ball(m, 0.34, math.sin(a) * 1.1, M.top + 0.6, math.cos(a) * 1.1, Color3.fromRGB(255, 240, 150), Enum.Material.Neon)
	end
	M.top += 0.9
end

function ACCESSORIES.flag(m, M, c)
	cyl(m, 0.14, 1.5, 0, M.top + 0.7, 0, DARK)
	blk(m, 1.0, 0.55, 0.08, 0.55, M.top + 1.15, 0, c[3])
	M.top += 1.5
end

function ACCESSORIES.lever(m, M)
	cyl(m, 0.22, 1.9, M.half + 0.5, 3.6, 0, Color3.fromRGB(170, 176, 190), nil, Enum.Material.Metal)
	ball(m, 0.8, M.half + 0.5, 4.7, 0, RED)
end

local function drawFace(m: Model, M)
	local eyeZ = M.eyeZ or M.faceZ
	for i = -1, 1, 2 do
		local eye = ball(m, 0.95, i * 0.56, M.faceY, eyeZ - 0.12, WHITE)
		eye.Name = "Eye"
		local pupil = ball(m, 0.44, i * 0.56 + (if i < 0 then 0.14 else -0.08), M.faceY + (if i < 0 then -0.12 else 0.16), eyeZ - 0.5, Color3.new(0, 0, 0))
		pupil.Name = "Pupil"
	end
	if M.noMouth then
		return
	end
	local y = M.mouthY or (M.faceY - 0.85)
	local z = M.mouthZ or M.faceZ
	local mouth = blk(m, if M.bigTeeth then 1.7 else 1.0, 0.3, 0.16, 0, y, z - 0.03, DARK)
	mouth.Name = "Mouth"
	if M.bigTeeth then
		for i = -2, 2 do
			blk(m, 0.26, 0.4, 0.18, i * 0.33, y - 0.2, z - 0.06, WHITE, CFrame.Angles(0, 0, math.rad(i * 6))).Name = "Tooth"
		end
	else
		blk(m, 0.3, 0.38, 0.18, -0.17, y - 0.24, z - 0.06, WHITE).Name = "Tooth"
		blk(m, 0.3, 0.44, 0.18, 0.17, y - 0.27, z - 0.06, WHITE).Name = "Tooth"
	end
end

local function drawLegs(m: Model, c)
	for i = -1, 1, 2 do
		cyl(m, 0.42, 1.1, i * 0.6, 0.7, 0, DARK)
		blk(m, 0.75, 0.36, 1.1, i * 0.6, 0.18, -0.22, c[3])
	end
end

local KEEP = { Eye = true, Pupil = true, Tooth = true, Mouth = true, Root = true }

-- paintMutation: Gold, Buttered, Neon, Rainbow and Galaxy each repaint the whole body so the mutation reads at a glance.
function BrainrotModels.paintMutation(model: Model, mutationName: string?)
	local mutation = MutationRoller.find(mutationName)
	if not mutation then
		return
	end
	local n = 0
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and not KEEP[part.Name] then
			n += 1
			if mutation.name == "Gold" then
				part.Color = GOLD:Lerp(Color3.fromRGB(255, 240, 150), (n % 3) / 4)
				part.Material = Enum.Material.Metal
				part.Reflectance = 0.25
			elseif mutation.name == "Buttered" then
				part.Color = part.Color:Lerp(mutation.color, 0.7)
				part.Material = Enum.Material.Glass
				part.Reflectance = 0.2
			elseif mutation.name == "Neon" then
				local h, _, v = part.Color:ToHSV()
				part.Color = Color3.fromHSV(h, 0.85, math.max(v, 0.9))
				part.Material = Enum.Material.Neon
			elseif mutation.name == "Rainbow" then
				part.Color = Color3.fromHSV((n * 0.11) % 1, 0.75, 1)
				part.Material = Enum.Material.Neon
			elseif mutation.name == "Galaxy" then
				part.Color = Color3.fromRGB(60, 30, 150):Lerp(Color3.fromRGB(40, 190, 255), (n % 5) / 5)
				part.Material = if n % 2 == 0 then Enum.Material.Neon else Enum.Material.Glass
			end
		end
	end
	local root = model.PrimaryPart
	if root then
		local light = Instance.new("PointLight")
		light.Color = mutation.color
		light.Brightness = 1.5
		light.Range = 12
		light.Parent = root
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Color = ColorSequence.new(mutation.color)
		sparkle.LightEmission = 0.8
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		sparkle.Lifetime = NumberRange.new(0.8, 1.4)
		sparkle.Rate = 9
		sparkle.Speed = NumberRange.new(1.5, 3)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Parent = root
	end
end

-- buildBrainrot: one brainrot at the origin, feet on y = 0, facing -Z, welded to an anchored Root.
function BrainrotModels.buildBrainrot(id: string, mutationName: string?, scaleOverride: number?): Model
	local entry = BrainrotCatalog.byId[id]
	local rarity = GameConfig.RARITIES[entry.rarity]
	local m = Instance.new("Model")
	m.Name = entry.name
	local M = BODIES[entry.body](m, entry.colors)
	M.armY = M.faceY - 0.6
	for _, name in entry.accessories do
		local draw = ACCESSORIES[name]
		if draw then
			draw(m, M, entry.colors)
		end
	end
	drawFace(m, M)
	drawLegs(m, entry.colors)

	local root = newPart(m, Enum.PartType.Block, Vector3.new(3, M.top, 2.5), CFrame.new(0, M.top / 2, 0), WHITE)
	root.Name = "Root"
	root.Transparency = 1
	root.Anchored = true
	for _, part in m:GetChildren() do
		if part:IsA("BasePart") and part ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = part
			weld.Parent = part
		end
	end
	m.PrimaryPart = root
	BrainrotModels.paintMutation(m, mutationName)
	local scale = scaleOverride or rarity.scale
	m:ScaleTo(scale)
	m:PivotTo(CFrame.new(0, M.top * scale / 2, 0))
	m:SetAttribute("BrainrotId", id)
	m:SetAttribute("Mutation", mutationName or "")
	m:SetAttribute("TopY", M.top * scale)
	return m
end

local function cardLine(parent: Instance, text: string, color: Color3, height: number, order: number): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, height, 0)
	label.LayoutOrder = order
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.TextStrokeTransparency = 0.4
	label.Parent = parent
	return label
end

-- attachLabel: the readable card over a brainrot: mutation, name, rarity, +$ a second and, on the belt, its price.
function BrainrotModels.attachLabel(model: Model, mutationName: string?, priceText: string?): BillboardGui
	local entry = BrainrotCatalog.byId[model:GetAttribute("BrainrotId")]
	local rarity = GameConfig.RARITIES[entry.rarity]
	local mutation = MutationRoller.find(mutationName)
	local lines = 3 + (if mutation then 1 else 0) + (if priceText then 1 else 0)
	local width = 7.5 + entry.rarity * 0.5
	local card = Instance.new("BillboardGui")
	card.Name = "LabelCard"
	card.Size = UDim2.fromScale(width, width * 0.13 * lines + 0.3)
	card.StudsOffsetWorldSpace = Vector3.new(0, model:GetAttribute("TopY") / 2 + width * 0.07 * lines + 0.9, 0)
	card.MaxDistance = 95
	card.LightInfluence = 0
	card.Adornee = model.PrimaryPart
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(24, 18, 34)
	back.BackgroundTransparency = 0.12
	back.Parent = card
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.14, 0)
	corner.Parent = back
	local stroke = Instance.new("UIStroke")
	stroke.Color = rarity.color
	stroke.Thickness = 3
	stroke.Parent = back
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.04, 0)
	pad.PaddingBottom = UDim.new(0.04, 0)
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.Parent = back
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = back
	local each = 1 / lines
	if mutation then
		cardLine(back, string.upper(mutation.name) .. " x" .. mutation.mult, mutation.color, each, 1)
	end
	cardLine(back, entry.name, Color3.new(1, 1, 1), each * 1.15, 2)
	cardLine(back, string.upper(rarity.name), rarity.color, each * 0.85, 3)
	local income = BrainrotCatalog.incomePerSecond(entry.id, mutationName)
	cardLine(back, "+" .. BrainrotCatalog.formatMoney(income) .. "/s", Color3.fromRGB(110, 255, 130), each, 4)
	if priceText then
		cardLine(back, priceText, Color3.fromRGB(255, 225, 80), each, 5).Name = "Price"
	end
	card.Parent = model.PrimaryPart
	return card
end

-- stockPreviews: one model of every brainrot in ReplicatedStorage, for the INDEX panel's 3D cards.
function BrainrotModels.stockPreviews()
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotPreviews"
	for _, entry in BrainrotCatalog.list do
		local model = BrainrotModels.buildBrainrot(entry.id, nil, 1)
		model.Name = entry.id
		model.Parent = folder
	end
	folder.Parent = ReplicatedStorage
end

return BrainrotModels
