-- BrainrotModels: builds each brainrot's 3D body from parts (shape + three colours + props), its mutation look,
-- and the label card over its head (mutation, name, rarity, money a second, price on the belt).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local GameConfig = require(ReplicatedStorage.GameConfig)
local MutationRoller = require(ReplicatedStorage.MutationRoller)

local BrainrotModels = {}

local WHITE = Color3.fromRGB(252, 252, 252)
local INK = Color3.fromRGB(28, 24, 34)
local GOLD = Color3.fromRGB(255, 205, 50)
local RED = Color3.fromRGB(235, 50, 60)
local LEG_HEIGHT = 1

-- One welded part of a brainrot, placed in the model's own frame (the root sits on the ground, the face looks down -Z).
local function P(ctx, shape: string, size: Vector3, color, x: number, y: number, z: number, rx: number?, ry: number?, rz: number?)
	local part = Instance.new(shape == "Wedge" and "WedgePart" or "Part")
	if shape == "Ball" then
		part.Shape = Enum.PartType.Ball
	elseif shape == "Cylinder" then
		part.Shape = Enum.PartType.Cylinder
	end
	part.Size = size
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	if type(color) == "number" then
		part.Color = ctx.colors[color]
		part:SetAttribute("Skin", true)
	else
		part.Color = color
	end
	part.CFrame = ctx.root.CFrame * CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = ctx.root
	weld.Part1 = part
	weld.Parent = part
	part.Parent = ctx.model
	return part
end

local function ball(ctx, diameter, color, x, y, z)
	return P(ctx, "Ball", Vector3.new(diameter, diameter, diameter), color, x, y, z)
end

-- An upright cylinder: diameter, height, centred at x, y, z.
local function post(ctx, diameter, height, color, x, y, z, tiltX, tiltZ)
	return P(ctx, "Cylinder", Vector3.new(height, diameter, diameter), color, x, y, z, tiltX or 0, 0, 90 + (tiltZ or 0))
end

-- A disc whose flat face looks at the camera.
local function disc(ctx, diameter, thickness, color, x, y, z)
	return P(ctx, "Cylinder", Vector3.new(thickness, diameter, diameter), color, x, y, z, 0, 90, 0)
end

local function box(ctx, sx, sy, sz, color, x, y, z, rx, ry, rz)
	return P(ctx, "Block", Vector3.new(sx, sy, sz), color, x, y, z, rx, ry, rz)
end

-- A hat-like cone: stacked discs that shrink to a point.
local function coneStack(ctx, color, baseDiameter, height, x, y)
	for step = 0, 3 do
		post(ctx, baseDiameter * (1 - step * 0.24), height / 4, color, x, y + height / 8 + step * height / 4, 0)
	end
end

-- count things in a circle around the body, flat on the ground plane at height y.
local function ringOf(ctx, count, radius, y, make)
	for index = 1, count do
		local angle = (index / count) * math.pi * 2
		make(math.cos(angle) * radius, y, math.sin(angle) * radius, index, math.deg(angle))
	end
end

-- count things in a circle that faces the camera (a halo, a wheel, a burst).
local function wheelOf(ctx, count, radius, x, y, z, make)
	for index = 1, count do
		local angle = (index / count) * math.pi * 2
		make(x + math.cos(angle) * radius, y + math.sin(angle) * radius, z, index, math.deg(angle))
	end
end

local CANDY = { Color3.fromRGB(255, 80, 110), Color3.fromRGB(80, 200, 255), Color3.fromRGB(255, 220, 70), Color3.fromRGB(120, 230, 120), Color3.fromRGB(200, 120, 255) }

local BODIES = {}

function BODIES.ball(ctx)
	ctx.w, ctx.h, ctx.d, ctx.inset = 4, 4, 4, 0.35
	ball(ctx, 4, 1, 0, LEG_HEIGHT + 2, 0)
end

function BODIES.block(ctx)
	ctx.w, ctx.h, ctx.d, ctx.inset = 4, 3.6, 3.2, 0
	box(ctx, 4, 3.6, 3.2, 1, 0, LEG_HEIGHT + 1.8, 0)
end

function BODIES.slab(ctx)
	ctx.w, ctx.h, ctx.d, ctx.inset = 3.8, 4.2, 1.3, 0
	box(ctx, 3.8, 4.2, 1.3, 1, 0, LEG_HEIGHT + 2.1, 0)
	box(ctx, 4.1, 0.5, 1.5, 3, 0, LEG_HEIGHT + 4.2, 0)
end

function BODIES.can(ctx)
	ctx.w, ctx.h, ctx.d, ctx.inset = 3.2, 4.2, 3.2, 0.2
	post(ctx, 3.2, 4.2, 1, 0, LEG_HEIGHT + 2.1, 0)
	post(ctx, 3.35, 0.5, 2, 0, LEG_HEIGHT + 0.5, 0)
	post(ctx, 3.35, 0.5, 2, 0, LEG_HEIGHT + 3.7, 0)
end

function BODIES.cone(ctx)
	ctx.w, ctx.h, ctx.d, ctx.inset = 3.6, 4.5, 3.6, 0.2
	post(ctx, 1.7, 1.5, 1, 0, LEG_HEIGHT + 0.75, 0)
	post(ctx, 2.7, 1.5, 1, 0, LEG_HEIGHT + 2.25, 0)
	post(ctx, 3.6, 1.5, 1, 0, LEG_HEIGHT + 3.75, 0)
	ctx.eyeY = LEG_HEIGHT + 3.8
	ctx.mouthY = LEG_HEIGHT + 2.9
end

function BODIES.log(ctx)
	ctx.w, ctx.h, ctx.d, ctx.inset = 5.4, 2.8, 2.8, 0.15
	P(ctx, "Cylinder", Vector3.new(5.4, 2.8, 2.8), 1, 0, LEG_HEIGHT + 1.4, 0)
end

function BODIES.tall(ctx)
	ctx.w, ctx.h, ctx.d, ctx.inset = 2.8, 5.6, 2.4, 0
	box(ctx, 2.8, 5.6, 2.4, 1, 0, LEG_HEIGHT + 2.8, 0)
end

function BODIES.wedge(ctx)
	ctx.w, ctx.h, ctx.d, ctx.inset = 4.4, 4.4, 1.3, 0
	P(ctx, "Wedge", Vector3.new(1.3, 4.4, 2.2), 1, -1.1, LEG_HEIGHT + 2.2, 0, 0, 90, 0)
	P(ctx, "Wedge", Vector3.new(1.3, 4.4, 2.2), 1, 1.1, LEG_HEIGHT + 2.2, 0, 0, -90, 0)
	box(ctx, 4.6, 0.6, 1.5, 3, 0, LEG_HEIGHT + 0.3, 0)
	ctx.eyeY = LEG_HEIGHT + 1.9
	ctx.mouthY = LEG_HEIGHT + 0.95
	ctx.eyeGap = 0.6
end

function BODIES.ring(ctx)
	ctx.w, ctx.h, ctx.d, ctx.inset = 4.6, 4.6, 1.5, 0.15
	wheelOf(ctx, 12, 1.55, 0, LEG_HEIGHT + 2.3, 0, function(x, y, z)
		ball(ctx, 1.55, 1, x, y, z)
	end)
	ctx.eyeY = LEG_HEIGHT + 3.85
	ctx.mouthY = LEG_HEIGHT + 0.85
end

local PROPS = {}

function PROPS.butter(ctx)
	box(ctx, 1.5, 0.45, 1.2, Color3.fromRGB(255, 238, 120), 0.3, ctx.top + 0.25, 0, 0, 20, 0)
end

function PROPS.arms(ctx)
	for _, side in { -1, 1 } do
		P(ctx, "Cylinder", Vector3.new(1.4, 0.45, 0.45), 1, side * (ctx.w / 2 + 0.55), ctx.mid, 0, 0, 0, side * 28)
		ball(ctx, 0.75, 3, side * (ctx.w / 2 + 1.2), ctx.mid + 0.35, 0)
	end
end

function PROPS.salt(ctx)
	for _ = 1, 9 do
		box(ctx, 0.28, 0.28, 0.2, WHITE, ctx.rng:NextNumber(-0.4, 0.4) * ctx.w, ctx.bottom + ctx.rng:NextNumber(0.1, 0.9) * ctx.h, ctx.front - 0.05)
	end
end

function PROPS.beak(ctx)
	box(ctx, 1.3, 0.4, 1.1, 2, 0, ctx.mid + 0.1, ctx.front - 0.35)
	box(ctx, 1.1, 0.3, 0.9, 2, 0, ctx.mid - 0.3, ctx.front - 0.25, 12)
end

function PROPS.cupHat(ctx)
	post(ctx, 1.7, 1.3, WHITE, 0, ctx.top + 0.6, 0)
	post(ctx, 1.4, 0.2, Color3.fromRGB(110, 70, 40), 0, ctx.top + 1.2, 0)
	box(ctx, 0.25, 0.8, 0.6, WHITE, 1.05, ctx.top + 0.6, 0)
end

function PROPS.wings(ctx)
	for _, side in { -1, 1 } do
		box(ctx, 0.3, 1.9, 1.5, 2, side * (ctx.w / 2 + 0.35), ctx.mid + 0.5, 0.6, 0, 0, side * -28)
		box(ctx, 0.3, 1.3, 1.1, 2, side * (ctx.w / 2 + 0.95), ctx.mid + 1.1, 0.6, 0, 0, side * -50)
	end
end

function PROPS.horns(ctx)
	for _, side in { -1, 1 } do
		box(ctx, 0.5, 1.3, 0.5, 3, side * ctx.w * 0.3, ctx.top + 0.45, 0, 0, 0, side * -22)
	end
end

function PROPS.scoops(ctx)
	ball(ctx, 2.6, 2, 0, ctx.top + 0.9, 0)
	ball(ctx, 2, 3, 0.2, ctx.top + 2.5, 0)
	ctx.top += 3.3
end

function PROPS.string(ctx)
	box(ctx, 0.12, 1.5, 0.12, 3, 1.3, 0.75, 0.4, 0, 0, 12)
end

function PROPS.partyHat(ctx)
	coneStack(ctx, 2, 1.7, 1.9, 0, ctx.top - 0.1)
	ball(ctx, 0.6, 3, 0, ctx.top + 1.9, 0)
	ctx.top += 2
end

function PROPS.topHat(ctx)
	post(ctx, 2.5, 0.22, INK, 0, ctx.top + 0.1, 0)
	post(ctx, 1.6, 1.5, INK, 0, ctx.top + 0.9, 0)
	post(ctx, 1.68, 0.35, 2, 0, ctx.top + 0.45, 0)
	ctx.top += 1.7
end

function PROPS.straw(ctx)
	post(ctx, 0.32, 2.4, WHITE, 0.7, ctx.top + 0.8, 0, 0, -14)
	post(ctx, 0.36, 0.4, RED, 0.82, ctx.top + 1.3, 0, 0, -14)
end

function PROPS.mustache(ctx)
	for _, side in { -1, 1 } do
		box(ctx, 1.15, 0.34, 0.25, INK, side * 0.55, ctx.mouthY + 0.45, ctx.front + ctx.inset - 0.2, 0, 0, side * -18)
	end
end

function PROPS.sombrero(ctx)
	post(ctx, 3.8, 0.25, 2, 0, ctx.top + 0.1, 0)
	post(ctx, 1.7, 1.1, 3, 0, ctx.top + 0.7, 0)
	ctx.top += 1.3
end

function PROPS.tail(ctx)
	P(ctx, "Cylinder", Vector3.new(1.6, 0.4, 0.4), 1, 0, ctx.mid, ctx.d / 2 + 0.6, 25, 90, 0)
	ball(ctx, 0.7, 2, 0, ctx.mid + 0.45, ctx.d / 2 + 1.35)
end

function PROPS.ears(ctx)
	for _, side in { -1, 1 } do
		box(ctx, 0.9, 1.1, 0.35, 1, side * ctx.w * 0.32, ctx.top + 0.4, 0, 0, 0, side * -14)
		box(ctx, 0.45, 0.6, 0.1, 3, side * ctx.w * 0.32, ctx.top + 0.4, -0.2, 0, 0, side * -14)
	end
end

function PROPS.mustardStripe(ctx)
	for index = -2, 2 do
		box(ctx, 0.9, 0.3, 0.5, 2, index * 0.95, ctx.top + 0.05, (index % 2 == 0) and 0.3 or -0.3, 0, (index % 2 == 0) and 35 or -35, 0)
	end
end

function PROPS.cherry(ctx)
	ball(ctx, 0.95, RED, 0, ctx.top + 0.45, 0)
	box(ctx, 0.12, 0.7, 0.12, Color3.fromRGB(70, 150, 60), 0.15, ctx.top + 1.1, 0, 0, 0, -20)
end

function PROPS.tutu(ctx)
	ringOf(ctx, 12, ctx.w / 2 + 0.2, ctx.bottom + 0.5, function(x, y, z, _, degrees)
		box(ctx, 0.25, 0.9, 1.1, 3, x, y, z * 0.6, 0, -degrees, 60)
	end)
end

function PROPS.bow(ctx)
	box(ctx, 0.8, 0.7, 0.3, 3, -0.5, ctx.top + 0.3, 0, 0, 0, 20)
	box(ctx, 0.8, 0.7, 0.3, 3, 0.5, ctx.top + 0.3, 0, 0, 0, -20)
	ball(ctx, 0.45, 2, 0, ctx.top + 0.3, 0)
end

function PROPS.sprinkles(ctx)
	wheelOf(ctx, 12, 1.55, 0, ctx.mid, ctx.front + 0.1, function(x, y, z, index, degrees)
		box(ctx, 0.5, 0.16, 0.16, CANDY[index % #CANDY + 1], x, y, z, 0, 0, degrees + index * 40)
	end)
end

function PROPS.bigEyes(ctx)
	for _, side in { -1, 1 } do
		ball(ctx, 1.6, 1, side * 1.1, ctx.top + 0.3, -0.4)
	end
	ctx.eyeY = ctx.top + 0.5
	ctx.eyeGap = 1.1
	ctx.eyeSize = 1.3
	ctx.eyeZ = -1.0
end

function PROPS.tongue(ctx)
	box(ctx, 0.6, 0.22, 1.3, Color3.fromRGB(245, 90, 120), 0, ctx.mouthY - 0.25, ctx.front + ctx.inset - 0.5, 22)
end

function PROPS.herbs(ctx)
	for _ = 1, 7 do
		box(ctx, 0.5, 0.15, 0.25, Color3.fromRGB(60, 140, 60), ctx.rng:NextNumber(-0.4, 0.4) * ctx.w, ctx.top + 0.08, ctx.rng:NextNumber(-0.35, 0.35) * ctx.d, 0, ctx.rng:NextNumber(0, 180), 0)
	end
end

function PROPS.syrup(ctx)
	box(ctx, ctx.w * 0.92, 0.3, ctx.d + 0.25, 2, 0, ctx.top + 0.5, 0)
	for index = -1, 1 do
		box(ctx, 0.5, 0.8 + (index % 2) * 0.5, 0.2, 2, index * 1.1, ctx.top - 0.1, ctx.front - 0.08)
	end
end

function PROPS.ponyHead(ctx)
	box(ctx, 1.1, 2, 1.2, 1, ctx.w / 2 - 0.5, ctx.top + 0.7, 0, 0, 0, -20)
	box(ctx, 1.9, 1.2, 1.3, 1, ctx.w / 2 + 0.5, ctx.top + 1.6, 0)
	box(ctx, 0.4, 2, 0.5, 2, ctx.w / 2 - 0.9, ctx.top + 1.3, 0, 0, 0, -20)
	ctx.eyeX, ctx.eyeY, ctx.eyeGap = ctx.w / 2 + 0.5, ctx.top + 1.9, 0.45
	ctx.eyeZ = -0.65
	ctx.eyeSize = 0.8
end

function PROPS.pole(ctx)
	post(ctx, 0.35, 7.5, 3, -0.6, 3.75, 0)
	ball(ctx, 0.8, 3, -0.6, 7.6, 0)
end

function PROPS.lemonSlice(ctx)
	disc(ctx, 1.9, 0.25, Color3.fromRGB(255, 232, 70), -1.2, ctx.top + 0.2, 0)
	disc(ctx, 1.5, 0.3, Color3.fromRGB(255, 250, 190), -1.2, ctx.top + 0.2, 0)
end

function PROPS.tentacles(ctx)
	ringOf(ctx, 8, ctx.w / 2 - 0.3, ctx.bottom + 0.2, function(x, y, z, _, degrees)
		P(ctx, "Cylinder", Vector3.new(1.8, 0.55, 0.55), 1, x * 1.25, y - 0.2, z * 1.25, 0, -degrees, -40)
		ball(ctx, 0.6, 2, x * 1.6, y - 0.75, z * 1.6)
	end)
end

function PROPS.popcornPile(ctx)
	for index = 1, 11 do
		local color = (index % 3 == 0) and Color3.fromRGB(255, 214, 90) or Color3.fromRGB(255, 248, 225)
		ball(ctx, ctx.rng:NextNumber(0.8, 1.2), color, ctx.rng:NextNumber(-1.1, 1.1), ctx.top + ctx.rng:NextNumber(0.1, 1.2), ctx.rng:NextNumber(-0.9, 0.9))
	end
	ctx.top += 1.5
end

function PROPS.stripes(ctx)
	for index = 0, 3 do
		box(ctx, 0.3, 1.3 - index * 0.2, 0.12, 2, -1.4 + index * 0.95, ctx.bottom + 1.2, ctx.front - 0.05, 0, 0, 12)
	end
end

function PROPS.wheels(ctx)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			P(ctx, "Cylinder", Vector3.new(0.5, 1.3, 1.3), INK, sx * (ctx.w / 2 + 0.1), 0.65, sz * (ctx.d / 2 - 0.4))
		end
	end
end

function PROPS.antenna(ctx)
	for _, side in { -1, 1 } do
		box(ctx, 0.12, 1.8, 0.12, 3, side * 0.6, ctx.top + 0.8, 0, 0, 0, side * -18)
		ball(ctx, 0.45, 2, side * 0.88, ctx.top + 1.7, 0)
	end
end

function PROPS.bumper(ctx)
	box(ctx, ctx.w + 0.9, 0.7, ctx.d + 0.9, INK, 0, ctx.bottom + 0.4, 0)
	box(ctx, ctx.w + 0.95, 0.25, ctx.d + 0.95, 2, 0, ctx.bottom + 0.4, 0)
end

function PROPS.fluff(ctx)
	ringOf(ctx, 9, 1.5, ctx.top - 0.4, function(x, y, z, index)
		ball(ctx, 1.7, (index % 2 == 0) and 2 or 1, x, y + (index % 3) * 0.3, z)
	end)
end

function PROPS.wizardHat(ctx)
	post(ctx, 3.2, 0.2, Color3.fromRGB(86, 60, 190), 0, ctx.top + 0.5, 0)
	coneStack(ctx, Color3.fromRGB(86, 60, 190), 2, 2.6, 0, ctx.top + 0.5)
	ball(ctx, 0.5, GOLD, 0, ctx.top + 3.2, 0)
	ctx.top += 3.2
end

function PROPS.beard(ctx)
	box(ctx, 1.9, 1.1, 0.4, WHITE, 0, ctx.mouthY - 0.6, ctx.front + ctx.inset - 0.2)
	box(ctx, 1.2, 0.9, 0.4, WHITE, 0, ctx.mouthY - 1.4, ctx.front + ctx.inset - 0.2)
end

function PROPS.horn(ctx)
	box(ctx, 0.6, 1.5, 0.6, WHITE, 0, ctx.mid + 0.25, ctx.front - 0.6, -55)
end

function PROPS.coat(ctx)
	box(ctx, ctx.w + 0.25, ctx.h * 0.45, ctx.d + 0.25, 2, 0, ctx.bottom + ctx.h * 0.225, 0)
	for index = 0, 2 do
		ball(ctx, 0.35, GOLD, 0, ctx.bottom + 0.35 + index * 0.5, ctx.front - 0.15)
	end
end

function PROPS.cane(ctx)
	post(ctx, 0.2, 3.2, INK, ctx.w / 2 + 1.25, 1.7, -0.2)
	ball(ctx, 0.45, GOLD, ctx.w / 2 + 1.25, 3.4, -0.2)
end

function PROPS.longNeck(ctx)
	box(ctx, 1.1, 3.4, 1.1, 1, 0, ctx.top + 1.6, 0)
	box(ctx, 2.2, 1.6, 1.8, 1, 0, ctx.top + 3.9, -0.2)
	for _, side in { -1, 1 } do
		box(ctx, 0.25, 0.8, 0.25, 2, side * 0.6, ctx.top + 5, 0)
	end
	ctx.eyeY, ctx.mouthY, ctx.eyeGap = ctx.top + 4.2, ctx.top + 3.5, 0.6
	ctx.eyeZ, ctx.inset = -1.1, 0
	ctx.mouthZ = -1.15
	ctx.top += 5.2
end

function PROPS.wheelHalo(ctx)
	wheelOf(ctx, 10, 2.1, 0, ctx.top - 1.2, 1, function(x, y, z, index)
		ball(ctx, 0.7, CANDY[index % #CANDY + 1], x, y, z)
	end)
	for index = 0, 4 do
		box(ctx, 4.2, 0.14, 0.14, 3, 0, ctx.top - 1.2, 1.05, 0, 0, index * 36)
	end
end

function PROPS.spots(ctx)
	for _ = 1, 7 do
		disc(ctx, ctx.rng:NextNumber(0.4, 0.8), 0.1, 2, ctx.rng:NextNumber(-0.4, 0.4) * ctx.w, ctx.bottom + ctx.rng:NextNumber(0.1, 0.6) * ctx.h, ctx.front - 0.02)
	end
end

function PROPS.salamiSpots(ctx)
	for _ = 1, 8 do
		disc(ctx, ctx.rng:NextNumber(0.35, 0.6), 0.1, 3, ctx.rng:NextNumber(-0.42, 0.42) * ctx.w, ctx.bottom + ctx.rng:NextNumber(0.25, 0.75) * ctx.h, ctx.front + 0.12)
	end
end

function PROPS.eyePatches(ctx)
	for _, side in { -1, 1 } do
		ball(ctx, 1.6, 2, side * 0.85, ctx.eyeY - 0.05, ctx.front + ctx.inset + 0.55)
	end
end

function PROPS.claws(ctx)
	for _, side in { -1, 1 } do
		ball(ctx, 1.5, 1, side * (ctx.w / 2 + 0.9), ctx.mid + 0.9, -0.5)
		box(ctx, 0.5, 1.1, 0.5, 1, side * (ctx.w / 2 + 0.6), ctx.mid + 1.9, -0.5, 0, 0, side * -25)
		box(ctx, 0.5, 1.1, 0.5, 1, side * (ctx.w / 2 + 1.3), ctx.mid + 1.9, -0.5, 0, 0, side * 25)
	end
end

function PROPS.chefHat(ctx)
	post(ctx, 1.5, 1, WHITE, 0, ctx.top + 0.5, 0)
	ball(ctx, 2.1, WHITE, 0, ctx.top + 1.4, 0)
	ctx.top += 2.3
end

function PROPS.clownNose(ctx)
	ball(ctx, 1, RED, 0, ctx.eyeY - 0.75, ctx.front - 0.3)
end

function PROPS.afro(ctx)
	for index = 1, 9 do
		ball(ctx, 1.5, CANDY[index % #CANDY + 1], ctx.rng:NextNumber(-1.4, 1.4), ctx.top + ctx.rng:NextNumber(0, 1), ctx.rng:NextNumber(-0.6, 0.9))
	end
	ctx.top += 1.5
end

function PROPS.ruff(ctx)
	ringOf(ctx, 12, ctx.w / 2 + 0.25, ctx.bottom + ctx.h * 0.36, function(x, y, z, index, degrees)
		box(ctx, 0.9, 0.3, 0.7, (index % 2 == 0) and WHITE or 3, x, y, z, 0, -degrees, 0)
	end)
end

function PROPS.tornadoRings(ctx)
	for level = 0, 2 do
		ringOf(ctx, 9, 1.3 + level * 0.65, ctx.bottom + 0.6 + level * 1.5, function(x, y, z, index)
			ball(ctx, 0.6, (index % 2 == 0) and 2 or WHITE, x, y + (index % 3) * 0.2, z)
		end)
	end
end

function PROPS.spikes(ctx)
	for index = -2, 2 do
		box(ctx, 0.7, 0.9, 0.3, 2, index * 1, ctx.top + 0.3, 0.3, 0, 0, 45)
	end
end

function PROPS.cream(ctx)
	for _, side in { -1, 1 } do
		ball(ctx, 2.2, 3, side * (ctx.w / 2 - 0.1), ctx.mid, 0)
	end
end

function PROPS.trunkHorn(ctx)
	P(ctx, "Cylinder", Vector3.new(1.6, 0.8, 0.8), 1, 0, ctx.mid - 0.2, ctx.front - 0.6, 0, 90, 0)
	P(ctx, "Cylinder", Vector3.new(0.5, 1.2, 1.2), 2, 0, ctx.mid - 0.2, ctx.front - 1.6, 0, 90, 0)
	P(ctx, "Cylinder", Vector3.new(0.4, 1.9, 1.9), 2, 0, ctx.mid - 0.2, ctx.front - 2, 0, 90, 0)
	ctx.mouthY = ctx.bottom + 0.5
end

function PROPS.bigEars(ctx)
	for _, side in { -1, 1 } do
		disc(ctx, 2.8, 0.3, 1, side * (ctx.w / 2 + 0.9), ctx.mid + 0.5, 0.3)
		disc(ctx, 1.9, 0.34, 3, side * (ctx.w / 2 + 0.9), ctx.mid + 0.5, 0.25)
	end
end

function PROPS.fin(ctx)
	P(ctx, "Wedge", Vector3.new(0.4, 1.8, 1.8), 1, 0, ctx.top + 0.8, 0.1, 0, 90, 0)
end

function PROPS.teethRow(ctx)
	for index = -3, 3 do
		box(ctx, 0.36, 0.5, 0.2, WHITE, index * 0.42, ctx.mouthY - 0.1 - (index % 2) * 0.12, ctx.front + ctx.inset - 0.12)
	end
end

function PROPS.crown(ctx)
	post(ctx, 2, 0.5, GOLD, 0, ctx.top + 0.25, 0)
	ringOf(ctx, 6, 0.85, ctx.top + 0.85, function(x, y, z, index)
		box(ctx, 0.4, 0.8, 0.4, GOLD, x, y, z, 0, 45, 0)
		ball(ctx, 0.35, (index % 2 == 0) and RED or Color3.fromRGB(80, 200, 255), x, y + 0.5, z)
	end)
	ctx.top += 1.5
end

function PROPS.cape(ctx)
	box(ctx, ctx.w + 0.9, ctx.h * 0.95, 0.25, 3, 0, ctx.mid - 0.2, ctx.d / 2 + 0.25, -8)
end

function PROPS.husk(ctx)
	for _, side in { -1, 1 } do
		box(ctx, 0.45, ctx.h * 0.75, ctx.d * 0.95, 2, side * (ctx.w / 2 + 0.15), ctx.bottom + ctx.h * 0.36, 0, 0, 0, side * 10)
	end
end

function PROPS.scepter(ctx)
	post(ctx, 0.22, 4, GOLD, -(ctx.w / 2 + 1.25), 2.4, -0.2)
	ball(ctx, 0.8, 3, -(ctx.w / 2 + 1.25), 4.6, -0.2)
end

function PROPS.turban(ctx)
	ball(ctx, 3, 2, 0, ctx.top + 0.2, 0.1)
	ball(ctx, 0.7, 3, 0, ctx.top + 0.5, -1.4)
	box(ctx, 0.3, 1.2, 0.3, WHITE, 0, ctx.top + 1.5, -1.2)
	ctx.top += 1.8
end

function PROPS.crystalBall(ctx)
	local orb = ball(ctx, 1.6, Color3.fromRGB(150, 240, 255), 0, ctx.bottom + 0.6, ctx.front - 0.7)
	orb.Material = Enum.Material.Neon
	orb.Transparency = 0.25
	ctx.mouthY = ctx.bottom + 1.55
end

function PROPS.spaghetti(ctx)
	for _ = 1, 9 do
		P(ctx, "Cylinder", Vector3.new(2.6, 0.2, 0.2), Color3.fromRGB(255, 226, 130), ctx.rng:NextNumber(-0.8, 0.8), ctx.bottom + ctx.rng:NextNumber(0.3, 1), ctx.rng:NextNumber(-1.6, 1.6), 0, ctx.rng:NextNumber(0, 180), ctx.rng:NextNumber(-30, 30))
	end
end

function PROPS.hood(ctx)
	box(ctx, ctx.w + 2.6, 3, 0.3, 1, 0, ctx.top - 1.3, ctx.d / 2 + 0.1)
	disc(ctx, 1.4, 0.2, 2, 0, ctx.top - 1.1, ctx.d / 2 + 0.3)
	for _, side in { -1, 1 } do
		disc(ctx, 0.8, 0.2, 2, side * 1.9, ctx.top - 0.9, ctx.d / 2 - 0.08)
	end
end

function PROPS.coasterRings(ctx)
	for level = 0, 1 do
		ringOf(ctx, 10, ctx.w / 2 + 0.7, ctx.bottom + 1 + level * 2, function(x, y, z, index, degrees)
			box(ctx, 0.25, 0.25, 1.1, (index % 2 == 0) and 2 or 3, x, y + math.sin(index) * 0.3, z, 0, -degrees, 0)
		end)
	end
end

function PROPS.cupHandles(ctx)
	for _, side in { -1, 1 } do
		box(ctx, 1, 0.35, 0.4, 1, side * (ctx.w / 2 + 0.4), ctx.mid + 1, 0)
		box(ctx, 0.35, 1.9, 0.4, 1, side * (ctx.w / 2 + 0.85), ctx.mid + 0.2, 0)
		box(ctx, 1, 0.35, 0.4, 1, side * (ctx.w / 2 + 0.4), ctx.mid - 0.6, 0)
	end
end

function PROPS.starBurst(ctx)
	for index = 0, 5 do
		local ray = box(ctx, ctx.w + 4.4, 0.45, 0.15, Color3.fromRGB(255, 240, 130), 0, ctx.mid + 0.4, ctx.d / 2 + 0.5, 0, 0, index * 30)
		ray.Material = Enum.Material.Neon
	end
end

function PROPS.tentStripes(ctx)
	ringOf(ctx, 8, 1.82, LEG_HEIGHT + 3.75, function(x, y, z, _, degrees)
		box(ctx, 0.12, 1.5, 0.6, 2, x, y, z, 0, -degrees, 0)
	end)
	ringOf(ctx, 6, 1.37, LEG_HEIGHT + 2.25, function(x, y, z, _, degrees)
		box(ctx, 0.12, 1.5, 0.5, 2, x, y, z, 0, -degrees, 0)
	end)
end

function PROPS.flag(ctx)
	post(ctx, 0.16, 2, INK, 0, ctx.top + 1, 0)
	box(ctx, 1.2, 0.7, 0.1, 3, 0.65, ctx.top + 1.6, 0)
	ctx.top += 2
end

function PROPS.orbit(ctx)
	ringOf(ctx, 12, ctx.w / 2 + 1.5, ctx.mid, function(x, y, z, index)
		local star = ball(ctx, 0.5, (index % 2 == 0) and Color3.fromRGB(150, 240, 255) or 3, x, y + x * 0.3, z)
		star.Material = Enum.Material.Neon
	end)
end

function PROPS.slotFace(ctx)
	box(ctx, 3.2, 1.1, 0.2, INK, 0, ctx.bottom + 0.95, ctx.front - 0.05)
	for index = -1, 1 do
		box(ctx, 0.9, 0.9, 0.2, WHITE, index * 1, ctx.bottom + 0.95, ctx.front - 0.12)
		ball(ctx, 0.55, CANDY[index + 2], index * 1, ctx.bottom + 0.95, ctx.front - 0.25)
	end
	ctx.mouthY = ctx.bottom + 1.95
	ctx.eyeY = ctx.bottom + 2.95
end

function PROPS.lever(ctx)
	post(ctx, 0.25, 2.4, Color3.fromRGB(200, 200, 210), ctx.w / 2 + 0.5, ctx.mid + 1, 0, 0, -20)
	ball(ctx, 0.9, RED, ctx.w / 2 + 0.95, ctx.mid + 2.2, 0)
end

function PROPS.coins(ctx)
	for index = 1, 7 do
		post(ctx, 0.9, 0.18, GOLD, ctx.rng:NextNumber(-2.6, 2.6), 0.1 + (index % 3) * 0.18, ctx.rng:NextNumber(-1.9, -0.9))
	end
end

-- Googly eyes, a buck-toothed grin, stubby legs and shoes: every brainrot gets them.
local function addFaceAndLegs(ctx)
	local z = ctx.eyeZ or (ctx.front + ctx.inset)
	local size = ctx.eyeSize or 1.15
	local centre = ctx.eyeX or 0
	for _, side in { -1, 1 } do
		local x = centre + side * (ctx.eyeGap or ctx.w * 0.2)
		ball(ctx, size, WHITE, x, ctx.eyeY, z - 0.1)
		ball(ctx, size * 0.5, INK, x + side * -0.12, ctx.eyeY - 0.08, z - 0.1 - size * 0.36)
		post(ctx, 0.6, LEG_HEIGHT + 0.4, 3, side * 0.8, LEG_HEIGHT / 2 + 0.2, 0)
		box(ctx, 1, 0.45, 1.5, INK, side * 0.8, 0.22, -0.3)
	end
	local mouthZ = ctx.mouthZ or (ctx.front + ctx.inset - 0.05)
	box(ctx, 1.3, 0.34, 0.2, INK, centre, ctx.mouthY, mouthZ)
	box(ctx, 0.36, 0.42, 0.22, WHITE, centre - 0.2, ctx.mouthY - 0.3, mouthZ - 0.02)
	box(ctx, 0.36, 0.42, 0.22, WHITE, centre + 0.2, ctx.mouthY - 0.3, mouthZ - 0.02)
end

local function addSparkles(root: BasePart, color: Color3, rate: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.8
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Rate = rate
	emitter.Speed = NumberRange.new(2, 4)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = root
end

-- Repaint a built brainrot for its mutation: Gold, Buttered, Neon, Rainbow or Galaxy.
function BrainrotModels.applyMutationLook(model: Model, mutation: string?)
	if not mutation then
		return
	end
	local root = model.PrimaryPart
	local index = 0
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("Skin") then
			index += 1
			if mutation == "Gold" then
				part.Color = Color3.fromRGB(255, 196 + (index % 3) * 14, 40)
				part.Material = Enum.Material.Metal
				part.Reflectance = 0.25
			elseif mutation == "Buttered" then
				part.Color = Color3.fromRGB(255, 240 - (index % 3) * 12, 130)
				part.Material = Enum.Material.Glass
				part.Reflectance = 0.15
			elseif mutation == "Neon" then
				part.Color = Color3.fromHSV(0.42 + (index % 3) * 0.05, 0.85, 1)
				part.Material = Enum.Material.Neon
			elseif mutation == "Rainbow" then
				part.Color = Color3.fromHSV((index * 0.13) % 1, 0.8, 1)
			elseif mutation == "Galaxy" then
				part.Color = Color3.fromHSV(0.7 + (index % 4) * 0.035, 0.75, 0.45 + (index % 2) * 0.2)
				part.Material = Enum.Material.Neon
			end
		end
	end
	local light = Instance.new("PointLight")
	light.Color = MutationRoller.colorOf(mutation) or WHITE
	light.Brightness = 1.4
	light.Range = 12
	light.Parent = root
	addSparkles(root, MutationRoller.colorOf(mutation) or WHITE, mutation == "Galaxy" and 14 or 7)
end

local function labelLine(card: Frame, text: string, color: Color3, weight: number, order: number)
	local line = Instance.new("TextLabel")
	line.BackgroundTransparency = 1
	line.Size = UDim2.fromScale(1, weight)
	line.LayoutOrder = order
	line.Font = Enum.Font.FredokaOne
	line.Text = text
	line.TextColor3 = color
	line.TextScaled = true
	line.TextStrokeColor3 = INK
	line.TextStrokeTransparency = 0.4
	line.Parent = card
	return line
end

-- The card over a brainrot's head: mutation, name, rarity, money a second, and its price while it rides the belt.
function BrainrotModels.attachLabel(model: Model, entry, mutation: string?, price: number?)
	local root = model.PrimaryPart
	local old = root:FindFirstChild("Label")
	if old then
		old:Destroy()
	end
	local rarity = BrainrotCatalog.rarityOf(entry)
	local rows = 3 + (mutation and 1 or 0) + (price and 1 or 0)
	local grow = 1 + (rarity.order - 1) * 0.07
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromScale(9.6 * grow, rows * 1.2 * grow)
	gui.StudsOffset = Vector3.new(0, ((model:GetAttribute("TopY") or 6) + 1.3) * model:GetScale() + rows * 0.6 * grow + 0.5, 0)
	gui.MaxDistance = price and 62 or 54
	-- Closer than this the card stops growing on screen, so a brainrot at arm's length does not hide the view.
	gui.DistanceLowerLimit = 24
	gui.LightInfluence = 0
	gui.Adornee = root
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(26, 18, 44)
	card.BackgroundTransparency = 0.08
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.16, 0)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = rarity.color
	stroke.Thickness = 3
	stroke.Parent = card
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = card
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.Parent = card
	local share = 1 / rows
	if mutation then
		labelLine(card, string.upper(mutation) .. " x" .. MutationRoller.incomeMultiplier(mutation), MutationRoller.colorOf(mutation), share * 0.9, 1)
	end
	labelLine(card, entry.name, WHITE, share * 1.1, 2)
	labelLine(card, string.upper(entry.rarity), rarity.color, share * 0.85, 3)
	labelLine(card, "+" .. GameConfig.formatMoney(entry.income * MutationRoller.incomeMultiplier(mutation)) .. "/s", Color3.fromRGB(110, 255, 140), share * 1.05, 4)
	if price then
		labelLine(card, "BUY " .. GameConfig.formatMoney(price), Color3.fromRGB(255, 224, 90), share, 5)
	end
	gui.Parent = root
	return gui
end

-- Build one brainrot: body, props, face, mutation look, rarity size. Its root part sits on the ground under it.
function BrainrotModels.buildBrainrot(entry, mutation: string?, price: number?, withLabel: boolean?): Model
	local model = Instance.new("Model")
	model.Name = entry.id
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2, 0.4, 2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CFrame = CFrame.new(0, 0, 0)
	root.Parent = model
	model.PrimaryPart = root
	-- The root's centre is the ground point under the brainrot, so every part is placed from the ground up.
	local ctx = { model = model, root = root, colors = entry.colors, rng = Random.new(entry.number * 77) }
	local build = BODIES[entry.body] or BODIES.ball
	build(ctx)
	ctx.bottom = LEG_HEIGHT
	ctx.top = LEG_HEIGHT + ctx.h
	ctx.mid = LEG_HEIGHT + ctx.h / 2
	ctx.front = -ctx.d / 2
	ctx.eyeY = ctx.eyeY or (ctx.mid + ctx.h * 0.2)
	ctx.mouthY = ctx.mouthY or (ctx.mid - ctx.h * 0.14)
	for _, prop in entry.props do
		local make = PROPS[prop]
		if make then
			make(ctx)
		end
	end
	addFaceAndLegs(ctx)
	model:SetAttribute("TopY", ctx.top)
	model:SetAttribute("BrainrotId", entry.id)
	model:SetAttribute("Mutation", mutation or "")
	BrainrotModels.applyMutationLook(model, mutation)
	local scale = BrainrotCatalog.rarityOf(entry).scale
	model:SetAttribute("FullScale", scale)
	model:ScaleTo(scale)
	if withLabel ~= false then
		BrainrotModels.attachLabel(model, entry, mutation, price)
	end
	return model
end

-- Unlabelled copies of the whole cast for the INDEX panel's 3D previews, kept where clients can clone them.
function BrainrotModels.publishPreviews()
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotPreviews"
	for _, entry in BrainrotCatalog.ENTRIES do
		local model = BrainrotModels.buildBrainrot(entry, nil, nil, false)
		model:ScaleTo(1)
		model.Parent = folder
	end
	folder.Parent = ReplicatedStorage
	return folder
end

return BrainrotModels
