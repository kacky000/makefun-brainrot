-- BrainrotModels: builds each carnival brainrot as a 3D model from its catalog recipe
-- (a body shape, googly eyes, buck teeth, limbs and props), paints its mutation, and hangs the
-- name card over it: mutation, name, rarity, money a second and, on the Prize Belt, its price.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.GameConfig)
local BrainrotCatalog = require(ReplicatedStorage.BrainrotCatalog)
local MutationRoller = require(ReplicatedStorage.MutationRoller)

local BrainrotModels = {}

local WHITE = Color3.fromRGB(255, 255, 255)
local INK = Color3.fromRGB(25, 22, 30)
local AXIS_Y = CFrame.Angles(0, 0, math.pi / 2) -- stands a cylinder upright
local AXIS_Z = CFrame.Angles(0, math.pi / 2, 0) -- points a cylinder at the viewer

-- One welded piece of a brainrot. `at` is in model space before scaling, feet on y = 0, face toward -Z.
local function piece(build, shape: string, size: Vector3, at: CFrame, color: Color3, paint: boolean?, material: Enum.Material?)
	local part = Instance.new("Part")
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color
	local s = build.scale
	part.Size = size * s
	if shape == "ball" then
		part.Shape = Enum.PartType.Ball
	elseif shape == "cyl" then
		part.Shape = Enum.PartType.Cylinder
	elseif shape == "oval" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
	end
	part.CFrame = CFrame.new(at.Position * s) * at.Rotation
	if paint then
		part:SetAttribute("Paint", true)
	end
	local weld = Instance.new("Weld")
	weld.Part0 = build.root
	weld.Part1 = part
	weld.C0 = part.CFrame
	weld.Parent = part
	part.Parent = build.model
	return part
end

local function at(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z)
end

-- Body builders return the frame the props hang on: top, face height, face depth, half width.
local BODY_BUILDERS = {}

function BODY_BUILDERS.ball(build, c)
	piece(build, "ball", Vector3.new(3.2, 3.2, 3.2), at(0, 2.4, 0), c[1], true)
	return { top = 4.0, midY = 2.4, faceY = 2.6, faceZ = -1.5, faceX = 0, halfX = 1.6, backZ = 1.6, round = true, half = 1.6 }
end

function BODY_BUILDERS.egg(build, c)
	piece(build, "oval", Vector3.new(3.0, 3.8, 3.0), at(0, 2.7, 0), c[1], true)
	piece(build, "oval", Vector3.new(2.2, 1.8, 0.6), at(0, 2.0, -1.25), c[2], true)
	return { top = 4.6, midY = 2.7, faceY = 3.2, faceZ = -1.35, faceX = 0, halfX = 1.5, backZ = 1.5, round = true, half = 1.9 }
end

function BODY_BUILDERS.cube(build, c)
	piece(build, "block", Vector3.new(3, 3, 3), at(0, 2.3, 0), c[1], true)
	piece(build, "block", Vector3.new(3.15, 0.5, 3.15), at(0, 1.1, 0), c[2], true)
	return { top = 3.8, midY = 2.3, faceY = 2.7, faceZ = -1.5, faceX = 0, halfX = 1.5, backZ = 1.5, round = false, half = 1.5 }
end

function BODY_BUILDERS.slab(build, c)
	piece(build, "block", Vector3.new(3.2, 3.6, 1.0), at(0, 2.6, 0), c[1], true)
	piece(build, "block", Vector3.new(3.45, 3.85, 0.7), at(0, 2.6, 0), c[2], true)
	return { top = 4.5, midY = 2.6, faceY = 3.0, faceZ = -0.5, faceX = 0, halfX = 1.7, backZ = 0.5, round = false, half = 1.8 }
end

function BODY_BUILDERS.cyl(build, c)
	piece(build, "cyl", Vector3.new(3.8, 2.6, 2.6), at(0, 2.7, 0) * AXIS_Y, c[1], true)
	piece(build, "ball", Vector3.new(2.6, 2.6, 2.6), at(0, 4.5, 0), c[1], true)
	return { top = 5.7, midY = 2.9, faceY = 3.6, faceZ = -1.3, faceX = 0, halfX = 1.3, backZ = 1.3, round = true, half = 2.2 }
end

function BODY_BUILDERS.long(build, c)
	piece(build, "cyl", Vector3.new(4.4, 2.2, 2.2), at(-0.4, 2.4, 0), c[1], true)
	piece(build, "ball", Vector3.new(2.2, 2.2, 2.2), at(-2.6, 2.4, 0), c[1], true)
	piece(build, "ball", Vector3.new(2.7, 2.7, 2.7), at(2.1, 3.5, 0), c[1], true)
	piece(build, "oval", Vector3.new(3.2, 1.0, 2.3), at(-0.4, 1.7, 0), c[2], true)
	return { top = 4.85, midY = 2.4, faceY = 3.6, faceZ = -1.3, faceX = 2.1, halfX = 3.0, backZ = 1.1, round = true, half = 1.1, long = true }
end

function BODY_BUILDERS.tiers(build, c)
	piece(build, "cyl", Vector3.new(1.3, 3.6, 3.6), at(0, 1.45, 0) * AXIS_Y, c[1], true)
	piece(build, "cyl", Vector3.new(1.3, 2.8, 2.8), at(0, 2.75, 0) * AXIS_Y, c[2], true)
	piece(build, "cyl", Vector3.new(1.2, 1.9, 1.9), at(0, 4.0, 0) * AXIS_Y, c[1], true)
	return { top = 4.6, midY = 2.6, faceY = 2.9, faceZ = -1.4, faceX = 0, halfX = 1.8, backZ = 1.8, round = true, half = 1.9 }
end

function BODY_BUILDERS.cup(build, c)
	piece(build, "cyl", Vector3.new(3.2, 2.8, 2.8), at(0, 2.4, 0) * AXIS_Y, c[1], true)
	piece(build, "cyl", Vector3.new(0.7, 2.95, 2.95), at(0, 1.5, 0) * AXIS_Y, c[2], true)
	piece(build, "cyl", Vector3.new(0.35, 3.2, 3.2), at(0, 4.15, 0) * AXIS_Y, c[3], true)
	return { top = 4.3, midY = 2.4, faceY = 3.0, faceZ = -1.4, faceX = 0, halfX = 1.4, backZ = 1.4, round = true, half = 1.6 }
end

function BODY_BUILDERS.disc(build, c)
	piece(build, "cyl", Vector3.new(1.0, 3.8, 3.8), at(0, 2.7, 0) * AXIS_Z, c[1], true)
	piece(build, "cyl", Vector3.new(1.15, 2.7, 2.7), at(0, 2.7, 0) * AXIS_Z, c[2], true)
	return { top = 4.6, midY = 2.7, faceY = 3.0, faceZ = -0.6, faceX = 0, halfX = 1.9, backZ = 0.5, round = false, half = 1.9, flat = true }
end

function BODY_BUILDERS.tent(build, c)
	local sizes = { 3.6, 3.0, 2.3, 1.5, 0.8 }
	for tier, diameter in sizes do
		piece(build, "cyl", Vector3.new(0.85, diameter, diameter), at(0, 0.8 + tier * 0.8 - 0.4, 0) * AXIS_Y, c[(tier - 1) % 2 + 1], true)
	end
	return { top = 4.8, midY = 2.2, faceY = 2.1, faceZ = -1.5, faceX = 0, halfX = 1.6, backZ = 1.6, round = true, half = 2.0, taper = true }
end

-- Props: each adds a few pieces around the body frame `f` using the recipe colours `c`.
local PROP_BUILDERS = {}
BrainrotModels.PROP_BUILDERS = PROP_BUILDERS

function PROP_BUILDERS.legs(build, f, c)
	for _, side in { -1, 1 } do
		local x = f.faceX * 0.4 + side * 0.7
		piece(build, "cyl", Vector3.new(1.0, 0.4, 0.4), at(x, 0.7, 0) * AXIS_Y, INK)
		piece(build, "oval", Vector3.new(0.9, 0.5, 1.3), at(x, 0.25, -0.25), c[3], true)
	end
	if f.long then
		for _, side in { -1, 1 } do
			piece(build, "cyl", Vector3.new(1.0, 0.4, 0.4), at(-2.2, 0.7, side * 0.5) * AXIS_Y, INK)
			piece(build, "oval", Vector3.new(0.9, 0.5, 1.3), at(-2.2, 0.25, side * 0.5 - 0.25), c[3], true)
		end
	end
end

function PROP_BUILDERS.arms(build, f, c)
	for _, side in { -1, 1 } do
		local x = f.faceX + side * (if f.long then 1.5 else f.halfX + 0.45)
		local lift = if side > 0 then 0.9 else 0.3
		piece(build, "cyl", Vector3.new(1.5, 0.3, 0.3), at(x, f.midY + lift * 0.5, -0.2) * CFrame.Angles(0, 0, side * (0.5 + lift * 0.5)), INK)
		piece(build, "ball", Vector3.new(0.75, 0.75, 0.75), at(x + side * 0.6, f.midY + lift + 0.25, -0.2), WHITE)
	end
end

function PROP_BUILDERS.tophat(build, f, c)
	local tilt = at(f.faceX + 0.2, f.top, 0) * CFrame.Angles(0, 0, -0.18)
	piece(build, "cyl", Vector3.new(0.15, 2.1, 2.1), tilt * at(0, 0.05, 0) * AXIS_Y, INK)
	piece(build, "cyl", Vector3.new(1.3, 1.35, 1.35), tilt * at(0, 0.75, 0) * AXIS_Y, INK)
	piece(build, "cyl", Vector3.new(0.3, 1.42, 1.42), tilt * at(0, 0.35, 0) * AXIS_Y, c[3], true)
end

function PROP_BUILDERS.crown(build, f, c)
	local gold = Color3.fromRGB(255, 205, 50)
	piece(build, "cyl", Vector3.new(0.55, 1.9, 1.9), at(f.faceX, f.top + 0.2, 0) * AXIS_Y, gold, false, Enum.Material.Foil)
	for spike = 1, 5 do
		local angle = spike / 5 * math.pi * 2
		local x, z = math.cos(angle) * 0.8, math.sin(angle) * 0.8
		piece(build, "block", Vector3.new(0.4, 0.7, 0.4), at(f.faceX + x, f.top + 0.75, z) * CFrame.Angles(0, -angle, math.pi / 4), gold, false, Enum.Material.Foil)
		piece(build, "ball", Vector3.new(0.3, 0.3, 0.3), at(f.faceX + x, f.top + 1.2, z), if spike % 2 == 0 then Color3.fromRGB(255, 60, 90) else Color3.fromRGB(70, 200, 255), false, Enum.Material.Neon)
	end
end

function PROP_BUILDERS.propeller(build, f, c)
	piece(build, "cyl", Vector3.new(0.8, 0.2, 0.2), at(f.faceX, f.top + 0.35, 0) * AXIS_Y, INK)
	piece(build, "block", Vector3.new(2.8, 0.1, 0.5), at(f.faceX, f.top + 0.75, 0) * CFrame.Angles(0, 0.6, 0.12), c[3], true)
	piece(build, "block", Vector3.new(2.8, 0.1, 0.5), at(f.faceX, f.top + 0.78, 0) * CFrame.Angles(0, 0.6 + math.pi / 2, 0.12), c[2], true)
	piece(build, "ball", Vector3.new(0.45, 0.45, 0.45), at(f.faceX, f.top + 0.85, 0), Color3.fromRGB(255, 60, 60))
end

function PROP_BUILDERS.moustache(build, f, c)
	for _, side in { -1, 1 } do
		piece(build, "block", Vector3.new(1.0, 0.3, 0.2), at(f.faceX + side * 0.5, f.faceY - 0.48, f.faceZ - 0.2) * CFrame.Angles(0, 0, side * -0.35), Color3.fromRGB(60, 36, 24))
		piece(build, "ball", Vector3.new(0.35, 0.35, 0.35), at(f.faceX + side * 1.0, f.faceY - 0.3, f.faceZ - 0.2), Color3.fromRGB(60, 36, 24))
	end
end

function PROP_BUILDERS.wings(build, f, c)
	for _, side in { -1, 1 } do
		local hinge = at(f.faceX * 0.3 + side * (f.half * 0.6 + 0.4), f.midY + 0.6, f.backZ * 0.6) * CFrame.Angles(0, side * -0.5, side * -0.5)
		piece(build, "oval", Vector3.new(2.2, 1.3, 0.25), hinge * at(side * 1.0, 0, 0), WHITE)
		piece(build, "oval", Vector3.new(1.5, 0.9, 0.25), hinge * at(side * 1.3, -0.6, 0), c[2], true)
	end
end

function PROP_BUILDERS.horns(build, f, c)
	for _, side in { -1, 1 } do
		piece(build, "cyl", Vector3.new(0.6, 0.5, 0.5), at(f.faceX + side * 0.8, f.top - 0.1, 0) * CFrame.Angles(0, 0, math.pi / 2 - side * 0.35), WHITE)
		piece(build, "cyl", Vector3.new(0.5, 0.3, 0.3), at(f.faceX + side * 1.0, f.top + 0.4, 0) * CFrame.Angles(0, 0, math.pi / 2 - side * 0.6), c[3], true)
	end
end

function PROP_BUILDERS.antenna(build, f, c)
	piece(build, "cyl", Vector3.new(1.3, 0.12, 0.12), at(f.faceX - 0.5, f.top + 0.5, 0.2) * CFrame.Angles(0, 0, math.pi / 2 + 0.2), INK)
	piece(build, "ball", Vector3.new(0.5, 0.5, 0.5), at(f.faceX - 0.65, f.top + 1.2, 0.2), c[3], true, Enum.Material.Neon)
end

function PROP_BUILDERS.tail(build, f, c)
	local x = if f.long then -3.4 else 0
	local z = if f.long then 0 else f.backZ
	for link = 1, 3 do
		local reach = link * 0.5
		piece(build, "ball", Vector3.new(0.9 - link * 0.18, 0.9 - link * 0.18, 0.9 - link * 0.18), at(x - (if f.long then reach else 0), f.midY - 0.4 + link * 0.45, z + (if f.long then 0 else reach)), c[2], true)
	end
end

function PROP_BUILDERS.bowtie(build, f, c)
	local y = f.faceY - 1.25
	for _, side in { -1, 1 } do
		piece(build, "block", Vector3.new(0.7, 0.7, 0.2), at(f.faceX + side * 0.45, y, f.faceZ - 0.15) * CFrame.Angles(0, 0, math.pi / 4), c[3], true)
	end
	piece(build, "ball", Vector3.new(0.4, 0.4, 0.4), at(f.faceX, y, f.faceZ - 0.2), WHITE)
end

function PROP_BUILDERS.cherry(build, f, c)
	piece(build, "ball", Vector3.new(0.8, 0.8, 0.8), at(f.faceX + 0.3, f.top + 0.35, 0), Color3.fromRGB(230, 30, 50))
	piece(build, "cyl", Vector3.new(0.7, 0.1, 0.1), at(f.faceX + 0.45, f.top + 0.9, 0) * CFrame.Angles(0, 0, math.pi / 2 - 0.4), Color3.fromRGB(70, 150, 60))
end

function PROP_BUILDERS.cream(build, f, c)
	for blob = 1, 3 do
		local diameter = 2.1 - blob * 0.5
		piece(build, "ball", Vector3.new(diameter, diameter, diameter), at(f.faceX + (blob - 2) * 0.12, f.top - 0.5 + blob * 0.55, 0), WHITE)
	end
	for kernel = 1, 4 do
		local angle = kernel * 1.7
		piece(build, "ball", Vector3.new(0.75, 0.75, 0.75), at(f.faceX + math.cos(angle) * 0.9, f.top + 0.05, math.sin(angle) * 0.9), c[2], true)
	end
end

function PROP_BUILDERS.ears(build, f, c)
	for _, side in { -1, 1 } do
		piece(build, "cyl", Vector3.new(0.3, 1.4, 1.4), at(f.faceX + side * 1.25, f.top - 0.15, 0.1) * AXIS_Z, c[1], true)
		piece(build, "cyl", Vector3.new(0.34, 0.8, 0.8), at(f.faceX + side * 1.25, f.top - 0.15, 0.08) * AXIS_Z, c[2], true)
	end
end

function PROP_BUILDERS.beak(build, f, c)
	piece(build, "oval", Vector3.new(1.3, 0.55, 1.3), at(f.faceX, f.faceY - 0.3, f.faceZ - 0.45), c[2], true)
	piece(build, "oval", Vector3.new(1.1, 0.4, 1.0), at(f.faceX, f.faceY - 0.6, f.faceZ - 0.35), Color3.fromRGB(230, 90, 20))
end

function PROP_BUILDERS.trunk(build, f, c)
	for link = 0, 4 do
		piece(build, "ball", Vector3.new(0.85 - link * 0.08, 0.85 - link * 0.08, 0.85 - link * 0.08), at(f.faceX + math.sin(link * 0.5) * 0.25, f.faceY - 0.25 - link * 0.42, f.faceZ - 0.3 - link * 0.28), c[1], true)
	end
end

function PROP_BUILDERS.shades(build, f, c)
	piece(build, "block", Vector3.new(2.2, 0.55, 0.2), at(f.faceX, f.faceY + 0.28, f.faceZ - 0.5), INK, false, Enum.Material.Glass)
	piece(build, "block", Vector3.new(0.5, 0.12, 0.22), at(f.faceX - 0.5, f.faceY + 0.4, f.faceZ - 0.52) * CFrame.Angles(0, 0, 0.6), WHITE, false, Enum.Material.Neon)
end

function PROP_BUILDERS.halo(build, f, c)
	for bead = 1, 10 do
		local angle = bead / 10 * math.pi * 2
		piece(build, "ball", Vector3.new(0.32, 0.32, 0.32), at(f.faceX + math.cos(angle) * 1.0, f.top + 1.0, math.sin(angle) * 1.0), Color3.fromRGB(255, 240, 120), false, Enum.Material.Neon)
	end
end

function PROP_BUILDERS.flag(build, f, c)
	piece(build, "cyl", Vector3.new(1.6, 0.14, 0.14), at(f.faceX, f.top + 0.7, 0) * AXIS_Y, INK)
	piece(build, "block", Vector3.new(1.1, 0.6, 0.08), at(f.faceX + 0.6, f.top + 1.2, 0), c[3], true)
end

function PROP_BUILDERS.wheels(build, f, c)
	for _, sideX in { -1, 1 } do
		for _, sideZ in { -1, 1 } do
			piece(build, "cyl", Vector3.new(0.45, 1.2, 1.2), at(sideX * (f.halfX * 0.7), 0.6, sideZ * (f.backZ + 0.15)) * AXIS_Z, INK)
			piece(build, "cyl", Vector3.new(0.5, 0.5, 0.5), at(sideX * (f.halfX * 0.7), 0.6, sideZ * (f.backZ + 0.18)) * AXIS_Z, c[2], true)
		end
	end
end

function PROP_BUILDERS.straw(build, f, c)
	local lean = at(f.faceX + 0.5, f.top, 0.2) * CFrame.Angles(0, 0, -0.3)
	for band = 0, 3 do
		piece(build, "cyl", Vector3.new(0.45, 0.3, 0.3), lean * at(0, 0.2 + band * 0.45, 0) * AXIS_Y, if band % 2 == 0 then WHITE else c[2], band % 2 == 1)
	end
end

function PROP_BUILDERS.stick(build, f, c)
	piece(build, "cyl", Vector3.new(1.2, 0.35, 0.35), at(f.faceX * 0.3, 0.6, 0) * AXIS_Y, Color3.fromRGB(226, 196, 150))
	piece(build, "cyl", Vector3.new(0.2, 1.3, 1.3), at(f.faceX * 0.3, 0.1, 0) * AXIS_Y, Color3.fromRGB(190, 150, 110))
end

function PROP_BUILDERS.nose(build, f, c)
	piece(build, "ball", Vector3.new(0.65, 0.65, 0.65), at(f.faceX, f.faceY - 0.05, f.faceZ - 0.4), Color3.fromRGB(255, 40, 50), false, Enum.Material.Neon)
end

function PROP_BUILDERS.cape(build, f, c)
	piece(build, "block", Vector3.new(f.half * 2 + 0.6, 3.0, 0.15), at(f.faceX * 0.5, f.midY, f.backZ + 0.45) * CFrame.Angles(-0.25, 0, 0), c[2], true, Enum.Material.Fabric)
	piece(build, "block", Vector3.new(f.half * 2 + 0.9, 0.5, 0.5), at(f.faceX * 0.5, f.midY + 1.5, f.backZ + 0.1), Color3.fromRGB(255, 205, 50), false, Enum.Material.Foil)
end

function PROP_BUILDERS.tusks(build, f, c)
	for _, side in { -1, 1 } do
		piece(build, "cyl", Vector3.new(1.0, 0.28, 0.28), at(f.faceX + side * 0.75, f.faceY - 0.75, f.faceZ - 0.45) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.Angles(0, 0, 0.5), WHITE)
	end
end

function PROP_BUILDERS.mane(build, f, c)
	for tuft = 0, 4 do
		piece(build, "ball", Vector3.new(0.8, 0.8, 0.8), at(f.faceX - 0.3 - tuft * 0.55, f.top - 0.1 - tuft * 0.42, 0), c[3], true)
	end
end

function PROP_BUILDERS.flame(build, f, c)
	local x = if f.long then -3.3 else 0
	local z = if f.long then 0 else f.backZ + 0.4
	for lick = 1, 3 do
		local reach = lick * 0.55
		piece(build, "ball", Vector3.new(1.3 - lick * 0.3, 1.3 - lick * 0.3, 1.3 - lick * 0.3), at(x - (if f.long then reach else 0), f.midY + lick * 0.2, z + (if f.long then 0 else reach)), if lick == 1 then Color3.fromRGB(255, 220, 60) else Color3.fromRGB(255, 110, 30), false, Enum.Material.Neon)
	end
end

function PROP_BUILDERS.hoop(build, f, c)
	local radius = f.half + 1.1
	for bead = 1, 14 do
		local angle = bead / 14 * math.pi * 2
		piece(build, "ball", Vector3.new(0.5, 0.5, 0.5), at(math.cos(angle) * radius, f.midY + math.sin(angle) * radius, 0.3), if bead % 2 == 0 then c[2] else c[3], false, Enum.Material.Neon)
	end
end

function PROP_BUILDERS.juggle(build, f, c)
	local colors = { Color3.fromRGB(255, 70, 70), Color3.fromRGB(70, 200, 255), Color3.fromRGB(255, 225, 60) }
	for ball = 1, 3 do
		piece(build, "ball", Vector3.new(0.7, 0.7, 0.7), at(f.faceX + (ball - 2) * 1.5, f.top + 1.4 - math.abs(ball - 2) * 0.8, -0.3), colors[ball], false, Enum.Material.Neon)
	end
end

function PROP_BUILDERS.star(build, f, c)
	local center = at(f.faceX + f.half + 0.9, f.top + 0.2, -0.3)
	piece(build, "block", Vector3.new(0.9, 0.9, 0.2), center, Color3.fromRGB(255, 235, 90), false, Enum.Material.Neon)
	piece(build, "block", Vector3.new(0.9, 0.9, 0.2), center * CFrame.Angles(0, 0, math.pi / 4), Color3.fromRGB(255, 235, 90), false, Enum.Material.Neon)
	piece(build, "cyl", Vector3.new(1.2, 0.1, 0.1), center * at(-0.4, -0.8, 0) * CFrame.Angles(0, 0, math.pi / 2 - 0.4), INK)
end

function PROP_BUILDERS.stripes(build, f, c)
	if f.taper or f.flat then
		return
	end
	for _, lift in { -0.75, 0.2 } do
		local y = f.midY + lift - (if f.long then 0 else 0.4)
		if f.long then
			piece(build, "cyl", Vector3.new(0.5, 2.3, 2.3), at(-0.4 + lift * 2, f.midY, 0), c[2], true)
		elseif f.round then
			local reach = math.sqrt(math.max(0.3, f.halfX * f.halfX - (lift * 0.6) ^ 2)) * 2 + 0.12
			piece(build, "cyl", Vector3.new(0.4, reach, reach), at(0, y, 0) * AXIS_Y, c[2], true)
		else
			piece(build, "block", Vector3.new(f.halfX * 2 + 0.12, 0.4, f.backZ * 2 + 0.12), at(0, y, 0), c[2], true)
		end
	end
end

function PROP_BUILDERS.sprinkles(build, f, c)
	local palette = { c[2], c[3], Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 90, 160), Color3.fromRGB(90, 220, 255) }
	for bit = 1, 9 do
		local angle = bit * 2.4
		local reach = 0.95 + (bit % 3) * 0.3
		piece(build, "block", Vector3.new(0.34, 0.14, 0.14), at(f.faceX + math.cos(angle) * reach, f.faceY - 0.2 + math.sin(angle) * reach, f.faceZ - 0.08) * CFrame.Angles(0, 0, angle * 3), palette[bit % #palette + 1], false, Enum.Material.Neon)
	end
end

function PROP_BUILDERS.butter(build, f, c)
	piece(build, "block", Vector3.new(1.3, 0.35, 0.9), at(f.faceX + 0.2, f.top + 0.15, 0) * CFrame.Angles(0, 0.3, 0.1), Color3.fromRGB(255, 232, 90))
	piece(build, "block", Vector3.new(0.4, 0.9, 0.3), at(f.faceX + 0.9, f.top - 0.35, f.faceZ - 0.05), Color3.fromRGB(255, 232, 90))
end

function PROP_BUILDERS.spikes(build, f, c)
	for spike = -2, 2 do
		piece(build, "block", Vector3.new(0.5, 0.9 - math.abs(spike) * 0.12, 0.5), at(f.faceX + spike * 0.5, f.top + 0.3 - math.abs(spike) * 0.12, 0) * CFrame.Angles(0, 0, math.pi / 4), c[2], true)
	end
end

function PROP_BUILDERS.fin(build, f, c)
	piece(build, "block", Vector3.new(0.25, 1.2, 1.2), at(f.faceX, f.top + 0.05, 0.3) * CFrame.Angles(math.pi / 4, 0, 0), c[2], true)
	for _, side in { -1, 1 } do
		piece(build, "oval", Vector3.new(1.2, 0.3, 0.8), at(side * (f.halfX + 0.4), f.midY - 0.3, 0) * CFrame.Angles(0, 0, side * 0.5), c[2], true)
	end
end

-- Googly eyes of two sizes that never agree, a dark mouth and two buck teeth.
local function addFace(build, f, seed: number)
	local wander = (seed % 5 - 2) * 0.06
	for index, side in { -1, 1 } do
		local size = if index == 1 then 1.05 else 0.85
		local x = f.faceX + side * 0.62
		piece(build, "ball", Vector3.new(size, size, size), at(x, f.faceY + 0.3, f.faceZ - 0.05), WHITE)
		piece(build, "ball", Vector3.new(size * 0.48, size * 0.48, size * 0.48), at(x + wander * side + side * -0.1, f.faceY + 0.3 + wander * index, f.faceZ - 0.05 - size * 0.36), INK)
	end
	piece(build, "block", Vector3.new(1.1, 0.42, 0.2), at(f.faceX, f.faceY - 0.62, f.faceZ - 0.06), Color3.fromRGB(70, 20, 30))
	piece(build, "block", Vector3.new(0.3, 0.4, 0.16), at(f.faceX - 0.18, f.faceY - 0.74, f.faceZ - 0.14), WHITE)
	piece(build, "block", Vector3.new(0.3, 0.33, 0.16), at(f.faceX + 0.18, f.faceY - 0.7, f.faceZ - 0.14), WHITE)
end

-- The dark name card every brainrot wears: mutation, name, rarity, money a second, belt price.
function BrainrotModels.attachNameCard(model: Model, brainrotId: string, mutationKey: string?, beltPrice: number?, incomeScale: number?)
	local entry = BrainrotCatalog.BY_ID[brainrotId]
	local rarity = GameConfig.RARITY_BY_KEY[entry.rarity]
	local root = model.PrimaryPart :: BasePart
	local old = root:FindFirstChild("NameCard")
	if old then
		old:Destroy()
	end
	local rows = 3 + (if mutationKey then 1 else 0) + (if beltPrice then 1 else 0)
	local grow = 1 + (rarity.rank - 1) * 0.07
	local card = Instance.new("BillboardGui")
	card.Name = "NameCard"
	card.Size = UDim2.fromScale(8.6 * grow, rows * 1.02 * grow)
	card.StudsOffsetWorldSpace = Vector3.new(0, (model:GetAttribute("TopY") or 5) + rows * 0.55 * grow + 0.8, 0)
	card.MaxDistance = 48
	card.LightInfluence = 0
	card.Adornee = root

	local plate = Instance.new("Frame")
	plate.Size = UDim2.fromScale(1, 1)
	plate.BackgroundColor3 = Color3.fromRGB(22, 18, 34)
	plate.BackgroundTransparency = 0.12
	plate.Parent = card
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.12, 0)
	corner.Parent = plate
	local stroke = Instance.new("UIStroke")
	stroke.Color = rarity.color
	stroke.Thickness = 3
	stroke.Parent = plate
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = plate

	local function row(name: string, text: string, color: Color3, order: number)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Size = UDim2.fromScale(1, 1 / rows)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = text
		label.TextColor3 = color
		label.TextStrokeTransparency = 0.4
		label.LayoutOrder = order
		label.Parent = plate
		return label
	end

	local mutation = mutationKey and GameConfig.MUTATION_BY_KEY[mutationKey]
	if mutation then
		row("Mutation", MutationRoller.badgeText(mutationKey) :: string, mutation.color, 1)
	end
	row("BrainrotName", entry.name, WHITE, 2)
	row("Rarity", string.upper(entry.rarity), rarity.color, 3)
	local income = BrainrotCatalog.incomePerSecond(brainrotId, mutationKey) * (incomeScale or 1)
	row("Income", "+$" .. GameConfig.formatCash(income) .. "/s", Color3.fromRGB(110, 255, 130), 4)
	if beltPrice then
		row("Price", "BUY $" .. GameConfig.formatCash(beltPrice), Color3.fromRGB(255, 226, 90), 5)
	end
	card.Parent = root
	return card
end

-- Builds one brainrot. The model's PrimaryPart "Root" sits at its feet and is anchored;
-- every other piece is welded to it, so moving or welding Root moves the whole brainrot.
function BrainrotModels.buildBrainrotModel(brainrotId: string, mutationKey: string?): Model
	local entry = BrainrotCatalog.BY_ID[brainrotId]
	local rarity = GameConfig.RARITY_BY_KEY[entry.rarity]
	local model = Instance.new("Model")
	model.Name = entry.name
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root

	local build = { model = model, root = root, scale = rarity.scale }
	local frame = BODY_BUILDERS[entry.body](build, entry.colors)
	addFace(build, frame, entry.order)
	for _, prop in entry.props do
		PROP_BUILDERS[prop](build, frame, entry.colors)
	end
	MutationRoller.paintMutation(model, mutationKey)

	model:SetAttribute("BrainrotId", brainrotId)
	model:SetAttribute("Mutation", mutationKey or "")
	model:SetAttribute("TopY", (frame.top + 1) * rarity.scale)

	if rarity.rank >= 4 or mutationKey then
		local mutation = mutationKey and GameConfig.MUTATION_BY_KEY[mutationKey]
		local glow = Instance.new("PointLight")
		glow.Color = if mutation then mutation.color else rarity.color
		glow.Range = 10 + rarity.rank
		glow.Brightness = 1.2
		glow.Parent = root
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(glow.Color)
		sparkle.LightEmission = 0.8
		sparkle.Rate = 5 + rarity.rank
		sparkle.Lifetime = NumberRange.new(0.8, 1.4)
		sparkle.Speed = NumberRange.new(2, 4)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7 * rarity.scale), NumberSequenceKeypoint.new(1, 0) })
		sparkle.Parent = root
	end
	return model
end

-- One plain model of every brainrot, kept in ReplicatedStorage for the INDEX panel's 3D previews.
function BrainrotModels.buildPreviewLibrary()
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotPreviews"
	for _, entry in BrainrotCatalog.LIST do
		local model = BrainrotModels.buildBrainrotModel(entry.id, nil)
		model.Name = entry.id
		for _, extra in (model.PrimaryPart :: BasePart):GetChildren() do
			extra:Destroy()
		end
		model.Parent = folder
	end
	folder.Parent = ReplicatedStorage
	return folder
end

return BrainrotModels
